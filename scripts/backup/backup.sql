-- -----------------------------------------------------------------------------
-- Corlix Hub — backup da aplicação APEX, do DDL e dos dados do schema
--
-- Não rode direto: é chamado pelo scripts/backup/backup.sh, já conectado
-- como o dono do schema (WKSP_CORLIXHUB).
--
-- Parâmetros:
--   &1  pasta de destino (caminho absoluto, sem espaços)
--   &2  ID da aplicação APEX
--
-- Gera, dentro da pasta de destino:
--   apexlang/  app em APEXlang (mesmo formato de corlixhub/)
--   sql/       app em SQL (f<ID>.sql) + checksum SHA-256 independente de IDs
--   ddl/       DDL do schema, um arquivo por tipo, numerados na ordem de recriação
--   dados/     um CSV por tabela, _contagens.csv, _colunas-especiais.csv e o
--              _exportar.sql gerado (mostra a expressão usada em cada coluna)
--
-- Os CSVs usam as datas no formato do bloco "alter session" abaixo. Colunas
-- BLOB saem em base64; ver scripts/backup/README.md > Restauração.
-- -----------------------------------------------------------------------------
whenever sqlerror exit failure
set echo off verify off feedback off termout on serveroutput off

define OUT = "&1"
define APP_ID = "&2"

-- --- 1. Aplicação APEX -------------------------------------------------------
prompt [1/4] Aplicacao &APP_ID em APEXlang
apex export -applicationid &APP_ID -exptype APEXLANG -dir &OUT/apexlang -skipexportdate -overwrite-files

prompt [2/4] Aplicacao &APP_ID em SQL
apex export -applicationid &APP_ID -exptype SQL,CHECKSUM-SH256 -dir &OUT/sql -expaclassignments -exppubreports -expsavedreports -skipexportdate -overwrite-files

-- --- 2. DDL ------------------------------------------------------------------
prompt [3/4] DDL do schema
set termout off
set long 2000000000 longchunksize 32767 pagesize 0 linesize 32767 trimspool on heading off

-- Sem schema, tablespace e storage: o DDL recria os objetos em qualquer schema.
-- FKs saem separadas (04) para as tabelas poderem ser criadas em qualquer ordem.
begin
    dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SQLTERMINATOR', true);
    dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'PRETTY', true);
    dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SEGMENT_ATTRIBUTES', false);
    dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'STORAGE', false);
    dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'REF_CONSTRAINTS', false);
    dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'EMIT_SCHEMA', false);
end;
/

spool &OUT/ddl/01-tipos.sql
select dbms_metadata.get_ddl('TYPE_SPEC', o.object_name)
  from user_objects o
 where o.object_type = 'TYPE'
   and o.generated = 'N'
   and o.object_name not like 'SYS\_PLSQL\_%' escape '\'
 order by o.object_name;
spool off

spool &OUT/ddl/02-sequencias.sql
select dbms_metadata.get_ddl('SEQUENCE', s.sequence_name)
  from user_sequences s
 where s.sequence_name not like 'ISEQ$$\_%' escape '\'
 order by s.sequence_name;
spool off

spool &OUT/ddl/03-tabelas.sql
select dbms_metadata.get_ddl('TABLE', t.table_name)
  from user_tables t
 where t.dropped = 'NO'
   and t.nested = 'NO'
   and t.secondary = 'N'
   and (t.iot_type is null or t.iot_type = 'IOT')
   and t.table_name not like 'DBTOOLS$%'
   and t.table_name not in (select mview_name from user_mviews)
   and t.table_name not in (select log_table from user_mview_logs)
 order by t.table_name;
spool off

spool &OUT/ddl/04-chaves-estrangeiras.sql
select dbms_metadata.get_ddl('REF_CONSTRAINT', c.constraint_name)
  from user_constraints c
 where c.constraint_type = 'R'
   and c.table_name not like 'BIN$%'
   and c.table_name not like 'DBTOOLS$%'
 order by c.table_name, c.constraint_name;
spool off

-- Índices de PK/UK já saem no DDL da tabela.
spool &OUT/ddl/05-indices.sql
select dbms_metadata.get_ddl('INDEX', i.index_name)
  from user_indexes i
 where i.generated = 'N'
   and i.index_type not in ('LOB', 'IOT - TOP')
   and i.table_name not like 'BIN$%'
   and i.table_name not like 'DBTOOLS$%'
   and i.index_name not in (select c.index_name from user_constraints c where c.index_name is not null)
 order by i.table_name, i.index_name;
spool off

spool &OUT/ddl/06-views.sql
select dbms_metadata.get_ddl('VIEW', v.view_name)
  from user_views v
 order by v.view_name;
spool off

spool &OUT/ddl/07-materialized-views.sql
select dbms_metadata.get_ddl('MATERIALIZED_VIEW', m.mview_name)
  from user_mviews m
 order by m.mview_name;
spool off

spool &OUT/ddl/08-plsql-especificacoes.sql
select dbms_metadata.get_ddl(decode(o.object_type, 'PACKAGE', 'PACKAGE_SPEC', o.object_type), o.object_name)
  from user_objects o
 where o.object_type in ('PACKAGE', 'FUNCTION', 'PROCEDURE')
   and o.generated = 'N'
 order by o.object_type, o.object_name;
spool off

spool &OUT/ddl/09-plsql-corpos.sql
select dbms_metadata.get_ddl(replace(o.object_type, ' ', '_'), o.object_name)
  from user_objects o
 where o.object_type in ('PACKAGE BODY', 'TYPE BODY')
   and o.generated = 'N'
 order by o.object_type, o.object_name;
spool off

spool &OUT/ddl/10-triggers.sql
select dbms_metadata.get_ddl('TRIGGER', g.trigger_name)
  from user_triggers g
 where g.trigger_name not like 'BIN$%'
   and nvl(g.table_name, '-') not like 'DBTOOLS$%'
 order by g.trigger_name;
spool off

spool &OUT/ddl/11-sinonimos.sql
select dbms_metadata.get_ddl('SYNONYM', s.synonym_name)
  from user_synonyms s
 order by s.synonym_name;
spool off

-- --- 3. Dados ----------------------------------------------------------------
set termout on
prompt [4/4] Dados das tabelas
set termout off

alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS.FF6';
alter session set nls_timestamp_tz_format = 'YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM';
alter session set nls_numeric_characters = '.,';

-- Gera um script com um "spool + select" por tabela. Colunas que o CSV não
-- representa bem são convertidas (BLOB -> base64, JSON/XML -> texto) ou
-- saem vazias (BFILE, LONG, tipos de objeto); a lista vai em _colunas-especiais.csv.
spool &OUT/dados/_exportar.sql
select 'spool &OUT/dados/' || t.table_name || '.csv' || chr(10)
    || 'select ' || listagg(
           case
               when c.data_type = 'BLOB'    then 'apex_web_service.blob2clobbase64("' || c.column_name || '")'
               when c.data_type = 'JSON'    then 'json_serialize("' || c.column_name || '" returning clob)'
               when c.data_type = 'XMLTYPE' then 'xmlserialize(content "' || c.column_name || '" as clob)'
               when c.data_type in ('BFILE', 'LONG', 'LONG RAW')
                 or c.data_type_owner is not null then 'null'
               else '"' || c.column_name || '"'
           end || ' as "' || c.column_name || '"', ', ') within group (order by c.column_id) || chr(10)
    || '  from "' || t.table_name || '";' || chr(10)
    || 'spool off'
  from user_tables t
  join user_tab_cols c
    on c.table_name = t.table_name
   and c.hidden_column = 'NO'
   and c.virtual_column = 'NO'
 where t.dropped = 'NO'
   and t.nested = 'NO'
   and t.secondary = 'N'
   and t.temporary = 'N'
   and (t.iot_type is null or t.iot_type = 'IOT')
   and t.table_name not like 'DBTOOLS$%'
   and t.table_name not in (select mview_name from user_mviews)
   and t.table_name not in (select log_table from user_mview_logs)
   and t.table_name not in (select table_name from user_external_tables)
 group by t.table_name
 order by t.table_name;
spool off

set sqlformat csv
set heading on pagesize 50000

@&OUT/dados/_exportar.sql

spool &OUT/dados/_contagens.csv
select t.table_name as tabela,
       xmlcast(xmlquery('/ROWSET/ROW/C/text()'
                        passing dbms_xmlgen.getxmltype('select count(*) as c from "' || t.table_name || '"')
                        returning content) as number) as linhas
  from user_tables t
 where t.dropped = 'NO'
   and t.nested = 'NO'
   and t.secondary = 'N'
   and t.temporary = 'N'
   and (t.iot_type is null or t.iot_type = 'IOT')
   and t.table_name not like 'DBTOOLS$%'
   and t.table_name not in (select mview_name from user_mviews)
   and t.table_name not in (select log_table from user_mview_logs)
   and t.table_name not in (select table_name from user_external_tables)
 order by t.table_name;
spool off

spool &OUT/dados/_colunas-especiais.csv
select c.table_name as tabela,
       c.column_name as coluna,
       c.data_type as tipo,
       case
           when c.data_type = 'BLOB'               then 'base64'
           when c.data_type in ('JSON', 'XMLTYPE') then 'texto'
           else 'nao exportada'
       end as tratamento
  from user_tab_cols c
  join user_tables t
    on t.table_name = c.table_name
 where c.hidden_column = 'NO'
   and c.virtual_column = 'NO'
   and (c.data_type in ('BLOB', 'JSON', 'XMLTYPE', 'BFILE', 'LONG', 'LONG RAW') or c.data_type_owner is not null)
   and t.dropped = 'NO'
   and t.nested = 'NO'
   and t.secondary = 'N'
   and t.temporary = 'N'
   and t.table_name not like 'DBTOOLS$%'
 order by c.table_name, c.column_name;
spool off

set sqlformat default
set termout on
prompt Backup do schema concluido em &OUT

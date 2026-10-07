--------------------------------------------------------------------------------
-- Corlix Hub · Histórico de Carreira · instalação completa (SQLcl)
--
--   cd modulos/historico-carreira
--   sql <usuario>@<servico> @instalar.sql
--
-- Para no primeiro erro. Os testes (07) rodam por último e terminam em rollback.
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == 00 · Verificando schema
@@00_verificar_schema.sql

prompt == 01 · Tabelas, constraints e índices
@@01_ddl_historico_carreira.sql

prompt == 02 · Tipos de movimentação
@@02_seed_tipo_movimentacao.sql

prompt == 03 · Views
@@03_views_carreira.sql

prompt == 04 · Package
@@04_pkg_historico_carreira.pks
@@04_pkg_historico_carreira.pkb
show errors package body pkg_historico_carreira

prompt == 04b · Package da página (linha do tempo)
@@08_pkg_historico_carreira_ui.sql
show errors package body pkg_historico_carreira_ui

prompt == 05 · Triggers de auditoria
@@05_triggers_auditoria.sql

prompt == 06 · Carga inicial
@@06_carga_inicial.sql

prompt == 07 · Testes
@@07_testes.sql

prompt == Objetos inválidos do módulo (deve voltar vazio)
select object_type, object_name
  from user_objects
 where status = 'INVALID'
   and (object_name like '%CARREIRA%' or object_name in ('TIPO_MOVIMENTACAO', 'PRC_SEED_TIPO_MOVIMENTACAO'));

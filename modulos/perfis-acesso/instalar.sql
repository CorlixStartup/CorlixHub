--------------------------------------------------------------------------------
-- Corlix Hub · Perfis de acesso · instalação (SQLcl)
--
--   cd modulos/perfis-acesso
--   sql <usuario>@<servico> @instalar.sql
--
-- Rode como dono do schema WKSP_CORLIXHUB. Para no primeiro erro.
-- Os papéis do APEX (colaborador, gestor, admin-rh) vêm com a aplicação
-- (corlixhub/shared-components/acl-roles.apx): importe a app antes de cadastrar
-- usuários, senão o processo da P14 falha com -20102.
--------------------------------------------------------------------------------
whenever sqlerror exit failure rollback
set serveroutput on size unlimited
set define off

prompt == 01 · Tabela CARGO_PAPEL
@@01_ddl_cargo_papel.sql

prompt == 02 · Departamentos, cargos e papéis (empresa 1)
@@02_seed_departamentos_cargos.sql

prompt == 03 · Package PKG_PERFIS_ACESSO
@@03_pkg_perfis_acesso.sql
show errors package body pkg_perfis_acesso

prompt == Objetos inválidos (deve vir vazio)
select object_name, object_type
  from user_objects
 where status = 'INVALID'
   and object_name in ('PKG_PERFIS_ACESSO', 'CARGO_PAPEL');

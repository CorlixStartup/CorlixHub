--------------------------------------------------------------------------------
-- Corlix Hub · Perfis de acesso · 01 · Tabela CARGO_PAPEL
--
-- Liga cada cargo aos papéis (ACL roles) da aplicação APEX que o colaborador
-- recebe ao ser cadastrado. CD_PAPEL é o Static ID do papel no APEX.
-- O papel "colaborador" é dado a todos e não precisa estar nesta tabela.
-- Reexecutável.
--------------------------------------------------------------------------------

create table if not exists cargo_papel (
  id_cargo     number         not null,
  cd_papel     varchar2(100)  not null,
  dt_criacao   timestamp with time zone default systimestamp not null,
  usr_criacao  varchar2(255)  default coalesce(sys_context('APEX$SESSION','APP_USER'), sys_context('USERENV','SESSION_USER')) not null,
  constraint pk_cargo_papel primary key (id_cargo, cd_papel),
  constraint fk_cargo_papel_cargo foreign key (id_cargo)
    references cargo (id_cargo) on delete cascade
);

comment on table  cargo_papel          is 'Papéis do APEX (ACL roles) atribuídos automaticamente a quem ocupa o cargo.';
comment on column cargo_papel.cd_papel is 'Static ID do papel na aplicação APEX (ex.: gestor, diretoria, admin-rh).';

create index if not exists idx_cargo_papel_papel on cargo_papel (cd_papel);

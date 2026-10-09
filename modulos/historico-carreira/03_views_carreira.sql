--------------------------------------------------------------------------------
-- Corlix Hub · Histórico de Carreira
-- 03 · Views
--
--   FN_CARREIRA_VE_SALARIO        -> 'S' só para ADMIN_RH dentro de uma sessão APEX
--   VW_MOVIMENTACAO_VALIDA        -> movimentações que compõem a trajetória atual
--   VW_HISTORICO_CARREIRA         -> todos os lançamentos, com salário mascarado
--   VW_CARREIRA_TIMELINE          -> movimentações + formações em formato único
--   VW_SITUACAO_ATUAL_COLABORADOR -> último registro válido por colaborador
--
-- As views expõem ID_EMPRESA: toda consulta das páginas filtra por :G_ID_EMPRESA.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Proteção de salário na camada de dados
-- Fora de uma sessão APEX (SQLcl, jobs) retorna 'N': o salário só aparece
-- consultando a tabela diretamente, com privilégio de dono do schema.
--------------------------------------------------------------------------------
create or replace function fn_carreira_ve_salario return varchar2 is
begin
  if sys_context('APEX$SESSION', 'APP_SESSION') is null then
    return 'N';
  end if;

  return case when apex_authorization.is_authorized('ADMIN_RH') then 'S' else 'N' end;
exception
  when others then
    -- esquema de autorização inexistente ou erro de avaliação: nunca expõe salário
    return 'N';
end fn_carreira_ve_salario;
/


--------------------------------------------------------------------------------
-- 1. VW_MOVIMENTACAO_VALIDA
-- Efetivadas que não foram estornadas e que não são lançamentos de estorno.
-- É a cadeia de eventos que define a situação atual do colaborador.
--------------------------------------------------------------------------------
create or replace view vw_movimentacao_valida as
select h.id_historico_carreira,
       h.id_empresa,
       h.id_colaborador,
       h.id_tipo_movimentacao,
       t.cd_tipo,
       t.ds_tipo,
       h.dt_efetiva,
       h.id_cargo_anterior,
       h.id_departamento_anterior,
       h.id_gestor_anterior,
       h.id_cargo_novo,
       h.id_departamento_novo,
       h.id_gestor_novo
  from historico_carreira h
  join tipo_movimentacao  t on t.id_tipo_movimentacao = h.id_tipo_movimentacao
 where h.st_registro = 'EFETIVADO'
   and h.id_registro_estornado is null;

comment on table vw_movimentacao_valida is 'Movimentações efetivadas, não estornadas e que não são estornos. Sem colunas salariais.';


--------------------------------------------------------------------------------
-- 2. VW_HISTORICO_CARREIRA
-- Todos os lançamentos (inclusive rascunhos) com nomes resolvidos.
-- Salário só aparece para ADMIN_RH; para os demais perfis as colunas vêm nulas.
--------------------------------------------------------------------------------
create or replace view vw_historico_carreira as
select h.id_historico_carreira,
       h.id_empresa,
       h.id_colaborador,
       c.nome_completo                as nm_colaborador,
       h.id_tipo_movimentacao,
       t.cd_tipo,
       t.ds_tipo,
       t.ds_icone,
       t.ds_cor,
       h.dt_efetiva,
       h.id_cargo_anterior,
       ca.nome                        as nm_cargo_anterior,
       h.id_departamento_anterior,
       da.nome                        as nm_departamento_anterior,
       h.id_gestor_anterior,
       ga.nome_completo               as nm_gestor_anterior,
       h.id_cargo_novo,
       cn.nome                        as nm_cargo_novo,
       h.id_departamento_novo,
       dn.nome                        as nm_departamento_novo,
       h.id_gestor_novo,
       gn.nome_completo               as nm_gestor_novo,
       -- scalar subquery: a função é avaliada uma vez por consulta (cache), não por linha
       case when (select fn_carreira_ve_salario from dual) = 'S' then h.vl_salario_anterior end as vl_salario_anterior,
       case when (select fn_carreira_ve_salario from dual) = 'S' then h.vl_salario_novo     end as vl_salario_novo,
       h.ds_motivo,
       h.ds_observacao,
       h.st_registro,
       h.id_registro_estornado,
       case when h.id_registro_estornado is not null then 'S' else 'N' end as fl_estorno,
       h.id_aprovador,
       ap.nome_completo               as nm_aprovador,
       h.dt_efetivacao,
       h.usr_efetivacao,
       h.dt_criacao,
       h.usr_criacao,
       h.dt_alteracao,
       h.usr_alteracao
  from historico_carreira h
  join tipo_movimentacao  t  on t.id_tipo_movimentacao = h.id_tipo_movimentacao
  join colaborador        c  on c.id_colaborador       = h.id_colaborador
  left join cargo         ca on ca.id_cargo            = h.id_cargo_anterior
  left join departamento  da on da.id_departamento     = h.id_departamento_anterior
  left join colaborador   ga on ga.id_colaborador      = h.id_gestor_anterior
  left join cargo         cn on cn.id_cargo            = h.id_cargo_novo
  left join departamento  dn on dn.id_departamento     = h.id_departamento_novo
  left join colaborador   gn on gn.id_colaborador      = h.id_gestor_novo
  left join colaborador   ap on ap.id_colaborador      = h.id_aprovador;

comment on table vw_historico_carreira is 'Lançamentos do histórico com nomes resolvidos. VL_SALARIO_* só é preenchido para ADMIN_RH (FN_CARREIRA_VE_SALARIO).';


--------------------------------------------------------------------------------
-- 3. VW_CARREIRA_TIMELINE
-- Formato único consumido pela linha do tempo. Rascunhos não aparecem.
-- Nunca expõe salário.
--------------------------------------------------------------------------------
create or replace view vw_carreira_timeline as
select h.id_empresa,
       h.id_colaborador,
       'MOVIMENTACAO'                                   as ds_origem,
       h.id_historico_carreira                          as id_origem,
       h.dt_efetiva                                     as dt_evento,
       extract(year from h.dt_efetiva)                  as nr_ano,
       t.cd_tipo,
       t.ds_tipo,
       case
         when h.id_registro_estornado is not null then 'Estorno: ' || t.ds_tipo
         else t.ds_tipo
       end                                              as ds_titulo,
       case
         when h.id_registro_estornado is not null then
           'Lançamento revertido' || nvl2(h.ds_motivo, ': ' || h.ds_motivo, '')
         else
           trim(both ' ' from
             case
               when t.cd_tipo = 'ADMISSAO' then
                 'Entrada como ' || nvl(cn.nome, 'cargo não informado')
                 || nvl2(dn.nome, ' em ' || dn.nome, '')
               when t.cd_tipo in ('PROMOCAO', 'MUDANCA_CARGO') then
                 nvl(ca.nome, '?') || to_char(unistr(' \2192 ')) || nvl(cn.nome, '?')
               when t.cd_tipo = 'TRANSFERENCIA_DEPTO' then
                 nvl(da.nome, '?') || to_char(unistr(' \2192 ')) || nvl(dn.nome, '?')
                 || case when cn.id_cargo <> ca.id_cargo then ' (' || cn.nome || ')' end
             end
             || case
                  when h.ds_motivo is not null
                   and t.cd_tipo in ('ADMISSAO', 'PROMOCAO', 'MUDANCA_CARGO', 'TRANSFERENCIA_DEPTO')
                    then to_char(unistr(' \00B7 ')) || h.ds_motivo
                  else h.ds_motivo
                end)
       end                                              as ds_descricao,
       case
         when h.id_registro_estornado is not null then 'fa-undo'
         else t.ds_icone
       end                                              as ds_icone,
       case
         when h.id_registro_estornado is not null then 'u-danger'
         else t.ds_cor
       end                                              as ds_cor,
       h.st_registro                                    as ds_situacao
  from historico_carreira h
  join tipo_movimentacao  t  on t.id_tipo_movimentacao = h.id_tipo_movimentacao
  left join cargo         ca on ca.id_cargo            = h.id_cargo_anterior
  left join cargo         cn on cn.id_cargo            = h.id_cargo_novo
  left join departamento  da on da.id_departamento     = h.id_departamento_anterior
  left join departamento  dn on dn.id_departamento     = h.id_departamento_novo
 where h.st_registro in ('EFETIVADO', 'ESTORNADO')
union all
select f.id_empresa,
       f.id_colaborador,
       'FORMACAO'                                       as ds_origem,
       f.id_formacao                                    as id_origem,
       coalesce(f.dt_conclusao, f.dt_inicio)            as dt_evento,
       extract(year from coalesce(f.dt_conclusao, f.dt_inicio)) as nr_ano,
       f.tp_formacao                                    as cd_tipo,
       case f.tp_formacao
         when 'GRADUACAO'    then 'Graduação'
         when 'POS'          then 'Pós-graduação'
         when 'MBA'          then 'MBA'
         when 'CURSO'        then 'Curso'
         when 'CERTIFICACAO' then 'Certificação'
         when 'IDIOMA'       then 'Idioma'
       end                                              as ds_tipo,
       f.ds_titulo                                      as ds_titulo,
       f.ds_instituicao
       || case when f.dt_conclusao is null then to_char(unistr(' \00B7 ')) || 'em andamento' end
       || case when f.nr_carga_horaria is not null
               then to_char(unistr(' \00B7 ')) || to_char(f.nr_carga_horaria, 'fm99990') || 'h' end
       || case when f.dt_validade is not null
               then to_char(unistr(' \00B7 ')) || 'válida até ' || to_char(f.dt_validade, 'dd/mm/yyyy') end
                                                        as ds_descricao,
       case f.tp_formacao
         when 'CERTIFICACAO' then 'fa-certificate'
         when 'IDIOMA'       then 'fa-language'
         when 'CURSO'        then 'fa-book'
         else 'fa-graduation-cap'
       end                                              as ds_icone,
       case f.tp_formacao
         when 'CERTIFICACAO' then 'u-color-14'
         when 'IDIOMA'       then 'u-color-12'
         else 'u-color-10'
       end                                              as ds_cor,
       case
         when f.dt_conclusao is null then 'EM_ANDAMENTO'
         else 'CONCLUIDO'
       end                                              as ds_situacao
  from formacao_colaborador f;

comment on table vw_carreira_timeline is 'Linha do tempo: movimentações (efetivadas e estornadas) + formações. Sem dados salariais.';


--------------------------------------------------------------------------------
-- 4. VW_SITUACAO_ATUAL_COLABORADOR
-- Último registro válido por colaborador (analytic) + data de início na função:
-- a data do evento mais recente em que o cargo mudou ou houve (re)admissão.
--------------------------------------------------------------------------------
create or replace view vw_situacao_atual_colaborador as
with eventos as (
  select v.*,
         lag(v.id_cargo_novo) over (partition by v.id_colaborador
                                    order by v.dt_efetiva, v.id_historico_carreira) as id_cargo_evento_anterior,
         row_number()         over (partition by v.id_colaborador
                                    order by v.dt_efetiva desc, v.id_historico_carreira desc) as nr_recencia
    from vw_movimentacao_valida v
),
marcos as (
  select id_colaborador,
         max(case
               when cd_tipo = 'ADMISSAO'
                 or id_cargo_evento_anterior is null
                 or id_cargo_evento_anterior <> id_cargo_novo
               then dt_efetiva
             end)                                                     as dt_inicio_funcao,
         max(case when cd_tipo = 'ADMISSAO' then dt_efetiva end)      as dt_ultima_admissao
    from eventos
   group by id_colaborador
)
select e.id_empresa,
       e.id_colaborador,
       c.nome_completo                       as nm_colaborador,
       e.id_historico_carreira               as id_ultimo_registro,
       e.cd_tipo                             as cd_ultimo_tipo,
       e.ds_tipo                             as ds_ultimo_tipo,
       e.dt_efetiva                          as dt_ultima_movimentacao,
       e.id_cargo_novo                       as id_cargo,
       cg.nome                               as nm_cargo,
       e.id_departamento_novo                as id_departamento,
       d.nome                                as nm_departamento,
       e.id_gestor_novo                      as id_gestor,
       g.nome_completo                       as nm_gestor,
       m.dt_inicio_funcao,
       m.dt_ultima_admissao,
       case when e.cd_tipo = 'DESLIGAMENTO' then 'N' else 'S' end as fl_vinculo_ativo
  from eventos e
  join marcos       m  on m.id_colaborador   = e.id_colaborador
  join colaborador  c  on c.id_colaborador   = e.id_colaborador
  left join cargo        cg on cg.id_cargo        = e.id_cargo_novo
  left join departamento d  on d.id_departamento  = e.id_departamento_novo
  left join colaborador  g  on g.id_colaborador   = e.id_gestor_novo
 where e.nr_recencia = 1;

comment on table vw_situacao_atual_colaborador is 'Situação atual por colaborador (último registro válido), com data de início na função atual. Sem dados salariais.';


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "VW_CANAL_FEED" ("ID_CANAL_MENSAGEM", "ID_CANAL", "NOME_CANAL", "ID_EQUIPE", "ID_COLABORADOR", "NOME_AUTOR", "AUTOR_LOGIN", "CORPO", "DATA_ENVIO", "EDITADA", "EXCLUIDA", "STATUS_AUTOR", "QTD_ANEXOS") AS
  SELECT
    m."ID_CANAL_MENSAGEM",
    m."ID_CANAL",
    c."NOME"              AS NOME_CANAL,
    c."ID_EQUIPE",
    m."ID_COLABORADOR",
    col."NOME_COMPLETO"   AS NOME_AUTOR,
    col."LOGIN_APEX"      AS AUTOR_LOGIN,
    m."CORPO",
    m."DATA_ENVIO",
    m."EDITADA",
    m."EXCLUIDA",
    NVL(p."STATUS_PRESENCA", 'OFFLINE') AS STATUS_AUTOR,
    (SELECT COUNT(*) FROM "CANAL_MENSAGEM_ANEXO" a
      WHERE a."ID_CANAL_MENSAGEM" = m."ID_CANAL_MENSAGEM") AS QTD_ANEXOS
FROM "CANAL_MENSAGEM" m
JOIN "CANAL"        c   ON c."ID_CANAL" = m."ID_CANAL"
JOIN "COLABORADOR"  col ON col."ID_COLABORADOR" = m."ID_COLABORADOR"
LEFT JOIN "PRESENCA_COLABORADOR" p ON p."ID_COLABORADOR" = col."ID_COLABORADOR"
WHERE m."EXCLUIDA" = FALSE;

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "VW_CARREIRA_TIMELINE" ("ID_EMPRESA", "ID_COLABORADOR", "DS_ORIGEM", "ID_ORIGEM", "DT_EVENTO", "NR_ANO", "CD_TIPO", "DS_TIPO", "DS_TITULO", "DS_DESCRICAO", "DS_ICONE", "DS_COR", "DS_SITUACAO") AS
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

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "VW_HISTORICO_CARREIRA" ("ID_HISTORICO_CARREIRA", "ID_EMPRESA", "ID_COLABORADOR", "NM_COLABORADOR", "ID_TIPO_MOVIMENTACAO", "CD_TIPO", "DS_TIPO", "DS_ICONE", "DS_COR", "DT_EFETIVA", "ID_CARGO_ANTERIOR", "NM_CARGO_ANTERIOR", "ID_DEPARTAMENTO_ANTERIOR", "NM_DEPARTAMENTO_ANTERIOR", "ID_GESTOR_ANTERIOR", "NM_GESTOR_ANTERIOR", "ID_CARGO_NOVO", "NM_CARGO_NOVO", "ID_DEPARTAMENTO_NOVO", "NM_DEPARTAMENTO_NOVO", "ID_GESTOR_NOVO", "NM_GESTOR_NOVO", "VL_SALARIO_ANTERIOR", "VL_SALARIO_NOVO", "DS_MOTIVO", "DS_OBSERVACAO", "ST_REGISTRO", "ID_REGISTRO_ESTORNADO", "FL_ESTORNO", "ID_APROVADOR", "NM_APROVADOR", "DT_EFETIVACAO", "USR_EFETIVACAO", "DT_CRIACAO", "USR_CRIACAO", "DT_ALTERACAO", "USR_ALTERACAO") AS
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

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "VW_MINHAS_EQUIPES" ("ID_COLABORADOR", "LOGIN_APEX", "ID_EQUIPE", "NOME_EQUIPE", "ID_EMPRESA", "PAPEL", "ID_CANAL", "NOME_CANAL") AS
  SELECT
    em."ID_COLABORADOR",
    col."LOGIN_APEX",
    e."ID_EQUIPE",
    e."NOME"     AS NOME_EQUIPE,
    e."ID_EMPRESA",
    em."PAPEL",
    c."ID_CANAL",
    c."NOME"     AS NOME_CANAL
FROM "EQUIPE_MEMBRO" em
JOIN "COLABORADOR" col ON col."ID_COLABORADOR" = em."ID_COLABORADOR"
JOIN "EQUIPE"       e  ON e."ID_EQUIPE" = em."ID_EQUIPE" AND e."STATUS" = TRUE
LEFT JOIN "CANAL"    c ON c."ID_EQUIPE" = e."ID_EQUIPE" AND c."STATUS" = TRUE;

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "VW_MOVIMENTACAO_VALIDA" ("ID_HISTORICO_CARREIRA", "ID_EMPRESA", "ID_COLABORADOR", "ID_TIPO_MOVIMENTACAO", "CD_TIPO", "DS_TIPO", "DT_EFETIVA", "ID_CARGO_ANTERIOR", "ID_DEPARTAMENTO_ANTERIOR", "ID_GESTOR_ANTERIOR", "ID_CARGO_NOVO", "ID_DEPARTAMENTO_NOVO", "ID_GESTOR_NOVO") AS
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

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "VW_ORG_COLABORADOR" ("ID_COLABORADOR", "ID_GESTOR", "NOME_COMPLETO", "EMAIL", "LOGIN_APEX", "DATA_ADMISSAO", "DATA_DE_NASCIMENTO", "CARGO", "DEPARTAMENTO", "FOTO_URL", "TEM_IMAGEM") AS
  select
       c.id_colaborador,
       c.id_gestor,
       c.nome_completo,
       c.email,
       c.login_apex,
       c.data_admissao,
       c.data_de_nascimento,
       cg.nome as cargo,
       d.nome  as departamento,

       '#APP_FILES#Fotos Colaboradores/' || c.foto_url as foto_url,

       case
         when c.imagem_perfil is not null then 'S'
         else 'N'
       end as tem_imagem

from colaborador c
join cargo cg on cg.id_cargo = c.id_cargo
join departamento d on d.id_departamento = c.id_departamento
where c.status = true;

  CREATE OR REPLACE FORCE EDITIONABLE VIEW "VW_SITUACAO_ATUAL_COLABORADOR" ("ID_EMPRESA", "ID_COLABORADOR", "NM_COLABORADOR", "ID_ULTIMO_REGISTRO", "CD_ULTIMO_TIPO", "DS_ULTIMO_TIPO", "DT_ULTIMA_MOVIMENTACAO", "ID_CARGO", "NM_CARGO", "ID_DEPARTAMENTO", "NM_DEPARTAMENTO", "ID_GESTOR", "NM_GESTOR", "DT_INICIO_FUNCAO", "DT_ULTIMA_ADMISSAO", "FL_VINCULO_ATIVO") AS
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

--------------------------------------------------------------------------------
-- Corlix Hub · Histórico de Carreira
-- 02 · Seed dos tipos de movimentação
--
-- PRC_SEED_TIPO_MOVIMENTACAO cria os tipos padrão para UMA empresa. Ela só
-- insere o que falta (MERGE sem UPDATE), então não sobrescreve descrições,
-- ícones ou cores que a empresa tenha personalizado. O package chama a mesma
-- procedure quando encontra uma empresa nova sem tipos cadastrados.
--
-- Ícones: Font APEX. Cores: classes do Universal Theme.
--------------------------------------------------------------------------------
set serveroutput on size unlimited

create or replace procedure prc_seed_tipo_movimentacao (
  p_id_empresa in number
) is
begin
  merge into tipo_movimentacao t
  using (
    select p_id_empresa as id_empresa, v.cd_tipo, v.ds_tipo, v.ds_icone, v.ds_cor, v.nr_ordem
      from (values
              ('ADMISSAO',            'Admissão',                'fa-sign-in',          'u-color-1',  10),
              ('PROMOCAO',            'Promoção',                'fa-arrow-circle-up',  'u-success',  20),
              ('MUDANCA_CARGO',       'Mudança de cargo',        'fa-exchange',         'u-info',     30),
              ('MUDANCA_GESTOR',      'Mudança de gestão',       'fa-users',            'u-color-2',  35),
              ('TRANSFERENCIA_DEPTO', 'Transferência de área',   'fa-building-o',       'u-color-4',  40),
              ('EFETIVACAO_CONTRATO', 'Efetivação de contrato',  'fa-file-text-o',      'u-color-6',  45),
              ('MERITO',              'Mérito',                  'fa-money',            'u-color-7',  50),
              ('ALTERACAO_JORNADA',   'Alteração de jornada',    'fa-clock-o',          'u-color-8',  60),
              ('AFASTAMENTO',         'Afastamento',             'fa-medkit',           'u-warning',  70),
              ('RETORNO',             'Retorno de afastamento',  'fa-repeat',           'u-color-3',  80),
              ('DESLIGAMENTO',        'Desligamento',            'fa-sign-out',         'u-danger',   90)
           ) v (cd_tipo, ds_tipo, ds_icone, ds_cor, nr_ordem)
  ) s
  on (t.id_empresa = s.id_empresa and t.cd_tipo = s.cd_tipo)
  when not matched then
    insert (id_empresa, cd_tipo, ds_tipo, ds_icone, ds_cor, nr_ordem, fl_ativo)
    values (s.id_empresa, s.cd_tipo, s.ds_tipo, s.ds_icone, s.ds_cor, s.nr_ordem, true);
end prc_seed_tipo_movimentacao;
/

-- Aplica o seed em todas as empresas já cadastradas
declare
  l_qt_empresas pls_integer := 0;
begin
  for e in (select id_empresa from empresa order by id_empresa) loop
    prc_seed_tipo_movimentacao(e.id_empresa);
    l_qt_empresas := l_qt_empresas + 1;
  end loop;

  commit;
  dbms_output.put_line('Tipos de movimentação garantidos para ' || l_qt_empresas || ' empresa(s).');
end;
/

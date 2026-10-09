--------------------------------------------------------------------------------
-- Corlix Hub · Histórico de Carreira
-- 07 · Testes
--
-- Cria 2 empresas fictícias com 5 colaboradores cada, roda um teste por regra
-- e prova o isolamento entre empresas. Tudo roda em uma transação só e termina
-- em ROLLBACK: nenhum dado de teste fica no banco.
--
-- Rode fora do APEX (SQLcl / SQL Developer / SQL Workshop), como dono do schema.
-- Saída esperada: todas as linhas [OK] e "Falhas: 0" no resumo.
--
-- Premissa: as PKs de EMPRESA, DEPARTAMENTO, CARGO e COLABORADOR são identity
-- (ou têm default). Se alguma coluna NOT NULL dessas tabelas não estiver no
-- INSERT abaixo, inclua um valor fictício.
--------------------------------------------------------------------------------
set serveroutput on size unlimited

declare
  type t_ids is table of number index by pls_integer;

  l_emp_a  number;
  l_emp_b  number;
  l_dep_a1 number;  -- Tecnologia (A)
  l_dep_a2 number;  -- Financeiro (A)
  l_dep_b1 number;  -- Operações (B)
  l_car_a_jr    number;
  l_car_a_pl    number;
  l_car_a_coord number;
  l_car_a_fin   number;
  l_car_b_op    number;
  l_car_b_sup   number;
  l_col_a  t_ids;
  l_col_b  t_ids;

  l_hoje   date;
  l_dt     date;
  l_id     number;
  l_id2    number;
  l_promo  number;
  l_merito number;
  l_num    number;
  l_txt    varchar2(4000);
  l_qt     pls_integer;

  l_ok     pls_integer := 0;
  l_falhas pls_integer := 0;

  ------------------------------------------------------------------------------
  -- Mini framework de asserção
  ------------------------------------------------------------------------------
  procedure confere (p_teste in varchar2, p_cond in boolean, p_detalhe in varchar2 default null) is
  begin
    if nvl(p_cond, false) then
      l_ok := l_ok + 1;
      dbms_output.put_line('[OK]    ' || p_teste);
    else
      l_falhas := l_falhas + 1;
      dbms_output.put_line('[FALHA] ' || p_teste || nvl2(p_detalhe, ' -> ' || p_detalhe, ''));
    end if;
  end confere;

  procedure nao_bloqueou (p_teste in varchar2, p_esperado in pls_integer) is
  begin
    l_falhas := l_falhas + 1;
    dbms_output.put_line('[FALHA] ' || p_teste || ' -> deveria gerar ' || p_esperado || ' e passou');
  end nao_bloqueou;

  procedure confere_erro (p_teste in varchar2, p_esperado in pls_integer, p_code in pls_integer, p_msg in varchar2) is
  begin
    confere(p_teste || ' [' || p_esperado || ']', p_code = p_esperado, 'veio ' || p_code || ': ' || p_msg);
  end confere_erro;

  ------------------------------------------------------------------------------
  -- Fábricas de dados
  ------------------------------------------------------------------------------
  function nova_empresa (p_nome in varchar2, p_cnpj in varchar2) return number is
    l_id number;
  begin
    insert into empresa (nome, nome_fantasia, cnpj, status, data_criacao)
    values (p_nome, p_nome, p_cnpj, true, sysdate)
    returning id_empresa into l_id;
    return l_id;
  end nova_empresa;

  function novo_departamento (p_emp in number, p_nome in varchar2) return number is
    l_id number;
  begin
    insert into departamento (id_empresa, nome) values (p_emp, p_nome)
    returning id_departamento into l_id;
    return l_id;
  end novo_departamento;

  function novo_cargo (p_emp in number, p_dep in number, p_nome in varchar2) return number is
    l_id number;
  begin
    insert into cargo (id_empresa, id_departamento, nome) values (p_emp, p_dep, p_nome)
    returning id_cargo into l_id;
    return l_id;
  end novo_cargo;

  function novo_colaborador (
    p_emp in number, p_nome in varchar2, p_dep in number, p_cargo in number,
    p_gestor in number, p_admissao in date
  ) return number is
    l_id    number;
    l_login varchar2(100) := 'teste.carreira.' || lower(regexp_replace(p_nome, '\s+', '.'));
  begin
    insert into colaborador (
      id_empresa, nome_completo, primeiro_nome, ultimo_nome, email, login_apex,
      data_admissao, data_de_nascimento, id_departamento, id_cargo, id_gestor, status
    ) values (
      p_emp, p_nome, regexp_substr(p_nome, '^\S+'), regexp_substr(p_nome, '\S+$'),
      l_login || '@teste.invalid', upper(l_login),
      p_admissao, date '1990-05-10', p_dep, p_cargo, p_gestor, true
    )
    returning id_colaborador into l_id;
    return l_id;
  end novo_colaborador;

  function cargo_atual (p_col in number) return number is
    l_id number;
  begin
    select id_cargo into l_id from colaborador where id_colaborador = p_col;
    return l_id;
  end cargo_atual;

  function status_atual (p_col in number) return boolean is
    l_st boolean;
  begin
    select status into l_st from colaborador where id_colaborador = p_col;
    return l_st;
  end status_atual;

  function tipo (p_emp in number, p_cd in varchar2) return number is
  begin
    return pkg_historico_carreira.fn_id_tipo(p_emp, p_cd);
  end tipo;

begin
  dbms_output.put_line('=== Histórico de Carreira · testes ===');

  ------------------------------------------------------------------------------
  -- Massa: 2 empresas, 3 departamentos, 6 cargos, 10 colaboradores
  ------------------------------------------------------------------------------
  l_emp_a := nova_empresa('TESTE CARREIRA A', '00000000000191');
  l_emp_b := nova_empresa('TESTE CARREIRA B', '00000000000272');

  l_dep_a1 := novo_departamento(l_emp_a, 'Tecnologia (teste)');
  l_dep_a2 := novo_departamento(l_emp_a, 'Financeiro (teste)');
  l_dep_b1 := novo_departamento(l_emp_b, 'Operações (teste)');

  l_car_a_jr    := novo_cargo(l_emp_a, l_dep_a1, 'Analista Jr (teste)');
  l_car_a_pl    := novo_cargo(l_emp_a, l_dep_a1, 'Analista Pl (teste)');
  l_car_a_coord := novo_cargo(l_emp_a, l_dep_a1, 'Coordenador TI (teste)');
  l_car_a_fin   := novo_cargo(l_emp_a, l_dep_a2, 'Analista Financeiro (teste)');
  l_car_b_op    := novo_cargo(l_emp_b, l_dep_b1, 'Operador (teste)');
  l_car_b_sup   := novo_cargo(l_emp_b, l_dep_b1, 'Supervisor (teste)');

  prc_seed_tipo_movimentacao(l_emp_a);
  prc_seed_tipo_movimentacao(l_emp_b);

  l_hoje := pkg_historico_carreira.fn_hoje(l_emp_a);

  l_col_a(1) := novo_colaborador(l_emp_a, 'Ana Gestora',   l_dep_a1, l_car_a_coord, null,       add_months(l_hoje, -60));
  l_col_a(2) := novo_colaborador(l_emp_a, 'Bruno Analista', l_dep_a1, l_car_a_jr,   l_col_a(1), add_months(l_hoje, -36));
  l_col_a(3) := novo_colaborador(l_emp_a, 'Carla Analista', l_dep_a1, l_car_a_jr,   l_col_a(1), add_months(l_hoje, -24));
  l_col_a(4) := novo_colaborador(l_emp_a, 'Diego Analista', l_dep_a1, l_car_a_pl,   l_col_a(1), add_months(l_hoje, -12));
  l_col_a(5) := novo_colaborador(l_emp_a, 'Elisa Analista', l_dep_a1, l_car_a_jr,   l_col_a(1), add_months(l_hoje, -6));

  l_col_b(1) := novo_colaborador(l_emp_b, 'Fabio Supervisor', l_dep_b1, l_car_b_sup, null,       add_months(l_hoje, -48));
  l_col_b(2) := novo_colaborador(l_emp_b, 'Gabi Operadora',   l_dep_b1, l_car_b_op,  l_col_b(1), add_months(l_hoje, -30));
  l_col_b(3) := novo_colaborador(l_emp_b, 'Hugo Operador',    l_dep_b1, l_car_b_op,  l_col_b(1), add_months(l_hoje, -20));
  l_col_b(4) := novo_colaborador(l_emp_b, 'Iris Operadora',   l_dep_b1, l_car_b_op,  l_col_b(1), add_months(l_hoje, -10));
  l_col_b(5) := novo_colaborador(l_emp_b, 'Joao Operador',    l_dep_b1, l_car_b_op,  l_col_b(1), add_months(l_hoje, -2));

  ------------------------------------------------------------------------------
  -- T01 · Admissão automática (e idempotência)
  ------------------------------------------------------------------------------
  for i in 1 .. 5 loop
    pkg_historico_carreira.registrar_admissao_automatica(l_col_a(i), p_gerar_comunicado => false);
    pkg_historico_carreira.registrar_admissao_automatica(l_col_b(i), p_gerar_comunicado => false);
  end loop;
  pkg_historico_carreira.registrar_admissao_automatica(l_col_a(2));  -- segunda chamada não duplica

  select count(*) into l_qt
    from vw_movimentacao_valida
   where id_empresa in (l_emp_a, l_emp_b) and cd_tipo = 'ADMISSAO';
  confere('T01 admissão automática gera 1 admissão por colaborador (10)', l_qt = 10, 'veio ' || l_qt);

  ------------------------------------------------------------------------------
  -- T02 · Promoção: rascunho não altera nada; efetivação atualiza o cadastro
  ------------------------------------------------------------------------------
  l_promo := pkg_historico_carreira.registrar_movimentacao(
               p_id_colaborador       => l_col_a(2),
               p_id_tipo_movimentacao => tipo(l_emp_a, 'PROMOCAO'),
               p_dt_efetiva           => l_hoje - 10,
               p_id_cargo_novo        => l_car_a_pl,
               p_vl_salario_anterior  => 5000,
               p_vl_salario_novo      => 6543.21,
               p_ds_motivo            => 'Desempenho acima do esperado',
               p_id_aprovador         => l_col_a(1));

  confere('T02a rascunho não altera o cargo do colaborador', cargo_atual(l_col_a(2)) = l_car_a_jr);

  pkg_historico_carreira.efetivar_movimentacao(l_promo);
  confere('T02b efetivação atualiza o cargo em COLABORADOR', cargo_atual(l_col_a(2)) = l_car_a_pl);

  select count(*) into l_qt
    from historico_carreira h
    join comunicado c on c.id_comunicado = h.id_comunicado
   where h.id_historico_carreira = l_promo
     and c.id_departamento = l_dep_a1
     and c.conteudo not like '%6543%';
  confere('T02e promoção publica comunicado para a equipe, sem salário', l_qt = 1, 'veio ' || l_qt);

  select id_aprovador into l_num from historico_carreira where id_historico_carreira = l_promo;
  confere('T02f aprovador é gravado e mantido na efetivação', l_num = l_col_a(1));

  select id_cargo into l_num from vw_situacao_atual_colaborador where id_colaborador = l_col_a(2);
  confere('T02c VW_SITUACAO_ATUAL reflete o novo cargo', l_num = l_car_a_pl);

  select dt_inicio_funcao into l_dt from vw_situacao_atual_colaborador where id_colaborador = l_col_a(2);
  confere('T02d data de início na função = data da promoção', l_dt = l_hoje - 10);

  ------------------------------------------------------------------------------
  -- T03..T08 · Validações
  ------------------------------------------------------------------------------
  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(2), tipo(l_emp_a, 'PROMOCAO'), l_hoje, p_id_cargo_novo => l_car_a_pl);
    nao_bloqueou('T03 promoção para o mesmo cargo', -20005);
  exception when others then confere_erro('T03 promoção para o mesmo cargo', -20005, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'MUDANCA_CARGO'), l_hoje);
    nao_bloqueou('T04 mudança de cargo sem cargo novo', -20005);
  exception when others then confere_erro('T04 mudança de cargo sem cargo novo', -20005, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'TRANSFERENCIA_DEPTO'), l_hoje);
    nao_bloqueou('T05 transferência sem departamento', -20006);
  exception when others then confere_erro('T05 transferência sem departamento', -20006, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'TRANSFERENCIA_DEPTO'), l_hoje, p_id_departamento_novo => l_dep_a1);
    nao_bloqueou('T05b transferência para o mesmo departamento', -20006);
  exception when others then confere_erro('T05b transferência para o mesmo departamento', -20006, sqlcode, sqlerrm);
  end;

  begin
    -- Cargo atual (Jr) é da Tecnologia; destino é Financeiro sem cargo novo
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'TRANSFERENCIA_DEPTO'), l_hoje, p_id_departamento_novo => l_dep_a2);
    nao_bloqueou('T05c transferência com cargo de outro departamento', -20014);
  exception when others then confere_erro('T05c transferência com cargo de outro departamento', -20014, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'MERITO'), add_months(l_hoje, -30));
    nao_bloqueou('T06 data anterior à admissão', -20003);
  exception when others then confere_erro('T06 data anterior à admissão', -20003, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'MERITO'), l_hoje + 31);
    nao_bloqueou('T07 data futura além de 30 dias', -20004);
  exception when others then confere_erro('T07 data futura além de 30 dias', -20004, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(2), tipo(l_emp_a, 'MERITO'), l_hoje - 20);
    nao_bloqueou('T08 lançamento retroativo à última efetivada', -20010);
  exception when others then confere_erro('T08 lançamento retroativo à última efetivada', -20010, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'ADMISSAO'), l_hoje);
    nao_bloqueou('T08b segunda admissão sem desligamento', -20016);
  exception when others then confere_erro('T08b segunda admissão sem desligamento', -20016, sqlcode, sqlerrm);
  end;

  ------------------------------------------------------------------------------
  -- T09..T12 · Isolamento entre empresas (dados)
  ------------------------------------------------------------------------------
  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'PROMOCAO'), l_hoje, p_id_cargo_novo => l_car_b_sup);
    nao_bloqueou('T09 cargo da empresa B em colaborador da A', -20008);
  exception when others then confere_erro('T09 cargo da empresa B em colaborador da A', -20008, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'TRANSFERENCIA_DEPTO'), l_hoje, p_id_departamento_novo => l_dep_b1);
    nao_bloqueou('T10 departamento da empresa B em colaborador da A', -20008);
  exception when others then confere_erro('T10 departamento da empresa B em colaborador da A', -20008, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'PROMOCAO'), l_hoje,
              p_id_cargo_novo => l_car_a_pl, p_id_gestor_novo => l_col_b(1));
    nao_bloqueou('T11 gestor da empresa B em colaborador da A', -20008);
  exception when others then confere_erro('T11 gestor da empresa B em colaborador da A', -20008, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_b, 'MERITO'), l_hoje);
    nao_bloqueou('T12 tipo de movimentação da empresa B', -20008);
  exception when others then confere_erro('T12 tipo de movimentação da empresa B', -20008, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'MERITO'), l_hoje,
              p_id_aprovador => l_col_b(1));
    nao_bloqueou('T12b aprovador da empresa B em colaborador da A', -20020);
  exception when others then confere_erro('T12b aprovador da empresa B em colaborador da A', -20020, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(3), tipo(l_emp_a, 'MERITO'), l_hoje,
              p_id_aprovador => l_col_a(3));
    nao_bloqueou('T12c colaborador aprovando a própria movimentação', -20020);
  exception when others then confere_erro('T12c colaborador aprovando a própria movimentação', -20020, sqlcode, sqlerrm);
  end;

  ------------------------------------------------------------------------------
  -- T13..T16 · Imutabilidade e ciclo de vida
  ------------------------------------------------------------------------------
  begin
    update historico_carreira set ds_motivo = 'adulterado' where id_historico_carreira = l_promo;
    nao_bloqueou('T13 UPDATE direto em lançamento efetivado', -20013);
  exception when others then confere_erro('T13 UPDATE direto em lançamento efetivado', -20013, sqlcode, sqlerrm);
  end;

  begin
    update historico_carreira set id_aprovador = l_col_a(4) where id_historico_carreira = l_promo;
    nao_bloqueou('T13b trocar o aprovador de lançamento efetivado', -20013);
  exception when others then confere_erro('T13b trocar o aprovador de lançamento efetivado', -20013, sqlcode, sqlerrm);
  end;

  begin
    delete from historico_carreira where id_historico_carreira = l_promo;
    nao_bloqueou('T14 DELETE direto em lançamento efetivado', -20013);
  exception when others then confere_erro('T14 DELETE direto em lançamento efetivado', -20013, sqlcode, sqlerrm);
  end;

  begin
    pkg_historico_carreira.efetivar_movimentacao(l_promo);
    nao_bloqueou('T15 efetivar duas vezes', -20009);
  exception when others then confere_erro('T15 efetivar duas vezes', -20009, sqlcode, sqlerrm);
  end;

  l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(5), tipo(l_emp_a, 'ALTERACAO_JORNADA'), l_hoje, p_ds_motivo => 'Rascunho de teste');
  pkg_historico_carreira.atualizar_rascunho(l_id, tipo(l_emp_a, 'ALTERACAO_JORNADA'), l_hoje, p_ds_motivo => 'Rascunho editado');
  pkg_historico_carreira.excluir_rascunho(l_id);
  select count(*) into l_qt from historico_carreira where id_historico_carreira = l_id;
  confere('T16 rascunho pode ser editado e excluído', l_qt = 0);

  ------------------------------------------------------------------------------
  -- T17..T20 · Estorno
  ------------------------------------------------------------------------------
  l_merito := pkg_historico_carreira.registrar_movimentacao(l_col_a(2), tipo(l_emp_a, 'MERITO'), l_hoje - 5, p_vl_salario_novo => 7321.09);
  pkg_historico_carreira.efetivar_movimentacao(l_merito);

  begin
    pkg_historico_carreira.estornar_movimentacao(l_promo, 'Teste fora de ordem');
    nao_bloqueou('T17 estornar movimentação que não é a última', -20011);
  exception when others then confere_erro('T17 estornar movimentação que não é a última', -20011, sqlcode, sqlerrm);
  end;

  begin
    pkg_historico_carreira.estornar_movimentacao(l_merito, null);
    nao_bloqueou('T18 estorno sem motivo', -20015);
  exception when others then confere_erro('T18 estorno sem motivo', -20015, sqlcode, sqlerrm);
  end;

  pkg_historico_carreira.estornar_movimentacao(l_merito, 'Lançado em duplicidade');
  pkg_historico_carreira.estornar_movimentacao(l_promo,  'Promoção cancelada pela diretoria');

  confere('T19a estorno devolve o cargo anterior (Jr)', cargo_atual(l_col_a(2)) = l_car_a_jr);

  select count(*) into l_qt
    from historico_carreira
   where id_historico_carreira in (l_promo, l_merito) and st_registro = 'ESTORNADO';
  confere('T19b originais ficam ESTORNADO', l_qt = 2, 'veio ' || l_qt);

  select count(*) into l_qt
    from historico_carreira
   where id_registro_estornado in (l_promo, l_merito) and st_registro = 'EFETIVADO';
  confere('T19c um lançamento de estorno por original', l_qt = 2, 'veio ' || l_qt);

  select id_cargo into l_num from vw_situacao_atual_colaborador where id_colaborador = l_col_a(2);
  confere('T19d situação atual volta para a admissão', l_num = l_car_a_jr);

  begin
    select min(id_historico_carreira) into l_id
      from vw_movimentacao_valida where id_colaborador = l_col_a(2) and cd_tipo = 'ADMISSAO';
    pkg_historico_carreira.estornar_movimentacao(l_id, 'Teste');
    nao_bloqueou('T20 estornar a admissão inicial', -20011);
  exception when others then confere_erro('T20 estornar a admissão inicial', -20011, sqlcode, sqlerrm);
  end;

  ------------------------------------------------------------------------------
  -- T21..T24 · Desligamento e readmissão
  ------------------------------------------------------------------------------
  l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(4), tipo(l_emp_a, 'DESLIGAMENTO'), l_hoje - 3, p_ds_motivo => 'Pedido de demissão');
  pkg_historico_carreira.efetivar_movimentacao(l_id);
  confere('T21 desligamento inativa o colaborador', not status_atual(l_col_a(4)));

  begin
    l_id2 := pkg_historico_carreira.registrar_movimentacao(l_col_a(4), tipo(l_emp_a, 'MERITO'), l_hoje);
    nao_bloqueou('T22 lançamento depois de desligamento', -20007);
  exception when others then confere_erro('T22 lançamento depois de desligamento', -20007, sqlcode, sqlerrm);
  end;

  begin
    l_id2 := pkg_historico_carreira.registrar_movimentacao(l_col_a(4), tipo(l_emp_a, 'ADMISSAO'), l_hoje - 3);
    nao_bloqueou('T23 readmissão na mesma data do desligamento', -20003);
  exception when others then confere_erro('T23 readmissão na mesma data do desligamento', -20003, sqlcode, sqlerrm);
  end;

  l_id2 := pkg_historico_carreira.registrar_movimentacao(l_col_a(4), tipo(l_emp_a, 'ADMISSAO'), l_hoje - 1, p_ds_motivo => 'Readmissão');
  pkg_historico_carreira.efetivar_movimentacao(l_id2);
  confere('T24a readmissão reativa o colaborador', status_atual(l_col_a(4)));

  select data_admissao into l_dt from colaborador where id_colaborador = l_col_a(4);
  confere('T24b readmissão atualiza DATA_ADMISSAO', l_dt = l_hoje - 1);

  ------------------------------------------------------------------------------
  -- T25..T28 · Isolamento por contexto (simula G_ID_EMPRESA da empresa A)
  ------------------------------------------------------------------------------
  pkg_historico_carreira.definir_empresa_contexto(l_emp_a);

  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_b(2), tipo(l_emp_b, 'MERITO'), l_hoje);
    nao_bloqueou('T25 sessão da empresa A não lança na empresa B', -20001);
  exception when others then confere_erro('T25 sessão da empresa A não lança na empresa B', -20001, sqlcode, sqlerrm);
  end;

  begin
    pkg_historico_carreira.efetivar_movimentacao(l_promo);
    -- l_promo é da empresa A: deve falhar por status, não por empresa
    nao_bloqueou('T26 controle: lançamento da própria empresa é encontrado', -20009);
  exception when others then confere_erro('T26 controle: lançamento da própria empresa é encontrado', -20009, sqlcode, sqlerrm);
  end;

  confere('T27a fn_pode_ver_colaborador nega colaborador da empresa B',
          pkg_historico_carreira.fn_pode_ver_colaborador(l_col_b(2)) = 'N');
  confere('T27b fn_pode_ver_colaborador libera colaborador da empresa A',
          pkg_historico_carreira.fn_pode_ver_colaborador(l_col_a(2)) = 'S');

  select count(*) into l_qt
    from vw_carreira_timeline
   where id_empresa = pkg_historico_carreira.fn_empresa_contexto
     and id_colaborador in (l_col_b(1), l_col_b(2), l_col_b(3), l_col_b(4), l_col_b(5));
  confere('T28 timeline filtrada pela empresa A não traz eventos da B', l_qt = 0, 'veio ' || l_qt);

  pkg_historico_carreira.definir_empresa_contexto(null);

  ------------------------------------------------------------------------------
  -- T29..T31 · LGPD, timeline e funções
  ------------------------------------------------------------------------------
  select vl_salario_novo into l_num from vw_historico_carreira where id_historico_carreira = l_promo;
  confere('T29 salário mascarado na view fora do perfil ADMIN_RH', l_num is null);

  select count(*) into l_qt from vw_carreira_timeline where id_colaborador = l_col_a(2);
  -- admissão + promoção (estornada) + mérito (estornado) + 2 estornos
  confere('T30 timeline mostra eventos e estornos (5)', l_qt = 5, 'veio ' || l_qt);

  l_txt := pkg_historico_carreira.fn_tempo_no_cargo(l_col_a(1));
  confere('T31a fn_tempo_no_cargo (5 anos)', l_txt = '5 anos', 'veio "' || l_txt || '"');

  l_txt := pkg_historico_carreira.fn_tempo_de_casa(l_col_a(5));
  confere('T31b fn_tempo_de_casa (6 meses)', l_txt = '6 meses', 'veio "' || l_txt || '"');

  select count(*) into l_qt
    from log_auditoria_carreira
   where nm_tabela = 'HISTORICO_CARREIRA' and id_registro = l_promo;
  -- insert + efetivação + estorno
  confere('T32 trilha de auditoria registra cada transição (3)', l_qt = 3, 'veio ' || l_qt);

  ------------------------------------------------------------------------------
  -- T33..T35 · Mudança de gestão
  ------------------------------------------------------------------------------
  begin
    l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(5), tipo(l_emp_a, 'MUDANCA_GESTOR'), l_hoje,
              p_id_gestor_novo => l_col_a(1));
    nao_bloqueou('T33 mudança de gestão para o gestor atual', -20017);
  exception when others then confere_erro('T33 mudança de gestão para o gestor atual', -20017, sqlcode, sqlerrm);
  end;

  l_id := pkg_historico_carreira.registrar_movimentacao(l_col_a(5), tipo(l_emp_a, 'MUDANCA_GESTOR'), l_hoje,
            p_id_gestor_novo => l_col_a(4));
  pkg_historico_carreira.efetivar_movimentacao(l_id);
  select id_gestor into l_num from colaborador where id_colaborador = l_col_a(5);
  confere('T34 mudança de gestão atualiza o gestor', l_num = l_col_a(4));

  select id_comunicado into l_num from historico_carreira where id_historico_carreira = l_id;
  confere('T35 mudança de gestão não publica comunicado', l_num is null);

  ------------------------------------------------------------------------------
  -- T36..T39 · Solicitação de correção
  ------------------------------------------------------------------------------
  begin
    l_id := pkg_historico_carreira.solicitar_correcao(l_col_a(2), '   ');
    nao_bloqueou('T36 solicitação sem mensagem', -20019);
  exception when others then confere_erro('T36 solicitação sem mensagem', -20019, sqlcode, sqlerrm);
  end;

  begin
    l_id := pkg_historico_carreira.solicitar_correcao(l_col_a(2), 'Data errada', p_id_historico_carreira => l_merito + 999999);
    nao_bloqueou('T37 solicitação sobre lançamento de outra pessoa', -20018);
  exception when others then confere_erro('T37 solicitação sobre lançamento de outra pessoa', -20018, sqlcode, sqlerrm);
  end;

  l_id := pkg_historico_carreira.solicitar_correcao(l_col_a(2), 'A promoção foi em março, não neste mês.', l_promo);
  begin
    pkg_historico_carreira.responder_solicitacao(l_id, 'RECUSADA');
    nao_bloqueou('T38 recusa sem explicação', -20019);
  exception when others then confere_erro('T38 recusa sem explicação', -20019, sqlcode, sqlerrm);
  end;

  pkg_historico_carreira.responder_solicitacao(l_id, 'RESOLVIDA', 'Corrigido por estorno e novo lançamento.');
  select count(*) into l_qt from solicitacao_correcao where id_solicitacao = l_id and st_solicitacao = 'RESOLVIDA';
  confere('T39 RH resolve a solicitação', l_qt = 1);

  ------------------------------------------------------------------------------
  -- T40..T42 · Página (PKG_HISTORICO_CARREIRA_UI)
  ------------------------------------------------------------------------------
  declare
    l_html clob;
  begin
    l_html := pkg_historico_carreira_ui.render(l_col_a(2));
    confere('T40 página renderiza a linha do tempo', dbms_lob.instr(l_html, 'class="hc-evento') > 0);
    confere('T41 página nunca mostra salário', dbms_lob.instr(l_html, '6543') = 0 and dbms_lob.instr(l_html, '7321') = 0);
    confere('T41b página mostra quem aprovou', dbms_lob.instr(l_html, 'Aprovado por Ana Gestora') > 0);
  end;

  pkg_historico_carreira.definir_empresa_contexto(l_emp_a);
  begin
    l_txt := dbms_lob.substr(pkg_historico_carreira_ui.render(l_col_b(1)), 100, 1);
    nao_bloqueou('T42 página de colaborador de outra empresa', -20012);
  exception when others then confere_erro('T42 página de colaborador de outra empresa', -20012, sqlcode, sqlerrm);
  end;
  pkg_historico_carreira.definir_empresa_contexto(null);

  ------------------------------------------------------------------------------
  dbms_output.put_line('=== Resumo: ' || l_ok || ' OK | Falhas: ' || l_falhas || ' ===');
  rollback;
exception
  when others then
    dbms_output.put_line('[ERRO INESPERADO] ' || sqlerrm || chr(10) || dbms_utility.format_error_backtrace);
    pkg_historico_carreira.definir_empresa_contexto(null);
    rollback;
    raise;
end;
/

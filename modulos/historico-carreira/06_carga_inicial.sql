--------------------------------------------------------------------------------
-- Corlix Hub · Histórico de Carreira
-- 06 · Carga inicial
--
-- Gera a ADMISSAO efetivada de cada colaborador que ainda não tem histórico,
-- com o cargo, o departamento e o gestor atuais do cadastro e a data de
-- DATA_ADMISSAO (ou a data de hoje, se estiver vazia).
--
-- Reexecutável: colaboradores que já têm histórico são ignorados.
-- Um erro em um colaborador não interrompe os demais; o resumo lista as falhas.
--------------------------------------------------------------------------------
set serveroutput on size unlimited

declare
  l_qt_ok     pls_integer := 0;
  l_qt_falhas pls_integer := 0;
  l_qt_sem_dt pls_integer := 0;
begin
  -- Garante os tipos padrão em todas as empresas
  for e in (select id_empresa from empresa) loop
    prc_seed_tipo_movimentacao(e.id_empresa);
  end loop;

  for c in (
    select c.id_colaborador, c.nome_completo, c.data_admissao
      from colaborador c
     where not exists (select 1
                         from historico_carreira h
                        where h.id_colaborador = c.id_colaborador)
     order by c.id_empresa, c.id_colaborador
  ) loop
    savepoint antes_colaborador;
    begin
      -- Sem comunicado: são admissões antigas, a equipe já conhece essas pessoas
      pkg_historico_carreira.registrar_admissao_automatica(c.id_colaborador, p_gerar_comunicado => false);
      l_qt_ok := l_qt_ok + 1;
      if c.data_admissao is null then
        l_qt_sem_dt := l_qt_sem_dt + 1;
        dbms_output.put_line('[AVISO] ' || c.id_colaborador || ' ' || c.nome_completo
                             || ': sem DATA_ADMISSAO, admissão registrada com a data de hoje.');
      end if;
    exception
      when others then
        rollback to antes_colaborador;
        l_qt_falhas := l_qt_falhas + 1;
        dbms_output.put_line('[FALHA] ' || c.id_colaborador || ' ' || c.nome_completo || ': ' || sqlerrm);
    end;
  end loop;

  commit;

  dbms_output.put_line('Admissões geradas: ' || l_qt_ok
                       || ' | sem data de admissão: ' || l_qt_sem_dt
                       || ' | falhas: ' || l_qt_falhas);
end;
/

-- Conferência: colaboradores sem histórico depois da carga (deve voltar vazio)
select c.id_empresa, c.id_colaborador, c.nome_completo
  from colaborador c
 where not exists (select 1 from historico_carreira h where h.id_colaborador = c.id_colaborador);

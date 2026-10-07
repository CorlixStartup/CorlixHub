--------------------------------------------------------------------------------
-- Corlix Hub · Histórico de Carreira
-- 00 · Verificação do schema antes da instalação
--
-- Confere a versão do banco e se as tabelas/colunas existentes que o módulo
-- reaproveita têm os nomes esperados. Não cria nada. Se algo divergir, o script
-- aborta com a lista do que falta: ajuste os scripts seguintes antes de rodar.
--------------------------------------------------------------------------------
set serveroutput on size unlimited

declare
  type t_lista is table of varchar2(128);

  -- TABELA.COLUNA usadas pelo módulo (levantadas do export da aplicação APEX)
  l_requeridas t_lista := t_lista(
    'EMPRESA.ID_EMPRESA',
    'DEPARTAMENTO.ID_DEPARTAMENTO',
    'DEPARTAMENTO.ID_EMPRESA',
    'DEPARTAMENTO.NOME',
    'CARGO.ID_CARGO',
    'CARGO.ID_EMPRESA',
    'CARGO.ID_DEPARTAMENTO',
    'CARGO.NOME',
    'COLABORADOR.ID_COLABORADOR',
    'COLABORADOR.ID_EMPRESA',
    'COLABORADOR.ID_CARGO',
    'COLABORADOR.ID_DEPARTAMENTO',
    'COLABORADOR.ID_GESTOR',
    'COLABORADOR.NOME_COMPLETO',
    'COLABORADOR.LOGIN_APEX',
    'COLABORADOR.DATA_ADMISSAO',
    'COLABORADOR.STATUS',
    'COLABORADOR.FOTO_URL',
    'EMPRESA.NOME',
    'EMPRESA.NOME_FANTASIA',
    'COMUNICADO.ID_COMUNICADO',
    'COMUNICADO.ID_EMPRESA',
    'COMUNICADO.ID_DEPARTAMENTO',
    'COMUNICADO.ID_AUTOR',
    'COMUNICADO.TITULO',
    'COMUNICADO.CONTEUDO',
    'COMUNICADO.DATA_PUBLICACAO'
  );

  l_faltando varchar2(4000);
  l_qt       pls_integer;
begin
  -- CREATE ... IF NOT EXISTS e colunas BOOLEAN exigem Oracle 23ai
  if dbms_db_version.version < 23 then
    raise_application_error(-20000, 'O módulo requer Oracle Database 23ai (versão atual: '
                                    || dbms_db_version.version || ').');
  end if;

  for i in 1 .. l_requeridas.count loop
    select count(*)
      into l_qt
      from user_tab_columns
     where table_name  = regexp_substr(l_requeridas(i), '[^.]+', 1, 1)
       and column_name = regexp_substr(l_requeridas(i), '[^.]+', 1, 2);

    if l_qt = 0 then
      l_faltando := l_faltando || chr(10) || '  - ' || l_requeridas(i);
    end if;
  end loop;

  if l_faltando is not null then
    raise_application_error(-20000, 'Colunas não encontradas no schema:' || l_faltando);
  end if;

  dbms_output.put_line('Schema OK: todas as tabelas e colunas reaproveitadas foram encontradas.');
end;
/

-- Conferência visual dos tipos de dados (útil para revisar antes de instalar)
select table_name, column_name, data_type, data_length, nullable
  from user_tab_columns
 where table_name in ('EMPRESA', 'DEPARTAMENTO', 'CARGO', 'COLABORADOR', 'COMUNICADO')
 order by table_name, column_id;

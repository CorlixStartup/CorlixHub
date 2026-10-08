
  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "LOG_PKG" as

  procedure gravar(p_nivel varchar2, p_msg varchar2, p_origem varchar2 default null, p_detalhe clob default null) is
    pragma autonomous_transaction;   -- grava mesmo se a transação principal der rollback
  begin
    insert into app_log (nivel, app_id, page_id, apex_user, session_id, origem, mensagem, detalhe)
    values (p_nivel, v('APP_ID'), v('APP_PAGE_ID'), v('APP_USER'), v('APP_SESSION'),
            substr(p_origem, 1, 255), substr(p_msg, 1, 4000), p_detalhe);
    commit;
  exception when others then
    rollback;                        -- log nunca pode derrubar a aplicação
    apex_debug.error('LOG_PKG.gravar falhou: %s', sqlerrm);
  end;

  procedure erro (p_msg varchar2, p_origem varchar2 default null) is begin gravar('ERRO',  p_msg, p_origem); end;
  procedure aviso(p_msg varchar2, p_origem varchar2 default null) is begin gravar('AVISO', p_msg, p_origem); end;
  procedure info (p_msg varchar2, p_origem varchar2 default null) is begin gravar('INFO',  p_msg, p_origem); end;

  -- Remove linhas internas do APEX/SYS, mantendo só o que aponta para o seu código
  function limpar_stack(p_stack varchar2) return varchar2 is
    l_linhas apex_t_varchar2;
    l_saida  varchar2(4000);
  begin
    if p_stack is null then return null; end if;
    l_linhas := apex_string.split(p_stack, chr(10));
    for i in 1 .. l_linhas.count loop
      if l_linhas(i) is not null
         and l_linhas(i) not like '%"APEX\_%' escape '\'
         and l_linhas(i) not like '%"SYS.%' then
        l_saida := substr(l_saida || trim(l_linhas(i)) || chr(10), 1, 4000);
      end if;
    end loop;
    return rtrim(l_saida, chr(10));
  end;

  function apex_error_handler(p_error in apex_error.t_error) return apex_error.t_error_result is
    l_result apex_error.t_error_result;
    l_origem varchar2(255);
  begin
    l_result := apex_error.init_error_result(p_error);

    l_origem := case p_error.component.type
                  when 'APEX_APPLICATION_PAGE_DA_ACTS'  then 'Dynamic Action'
                  when 'APEX_APPLICATION_PAGE_PROC'     then 'Processo'
                  when 'APEX_APPLICATION_PAGE_VAL'      then 'Validação'
                  when 'APEX_APPLICATION_PAGE_ITEMS'    then 'Item'
                  when 'APEX_APPLICATION_PAGE_REGIONS'  then 'Região'
                  when 'APEX_APPLICATION_PAGE_COMP'     then 'Computação'
                  when 'APEX_APPLICATION_PROCESSES'     then 'Processo de aplicação'
                  else p_error.component.type
                end
                || case when p_error.component.name is not null
                        then ' – ' || p_error.component.name end;

    gravar(
      p_nivel   => 'ERRO',
      p_msg     => p_error.message,
      p_origem  => l_origem,
      p_detalhe =>
           'Erro Oracle: ' || nvl(regexp_substr(p_error.ora_sqlerrm, 'ORA-\d+:[^' || chr(10) || ']*'), '(nenhum)')
        || chr(10) || chr(10)
        || 'Onde ocorreu:' || chr(10)
        || nvl(limpar_stack(p_error.error_backtrace), '(sem backtrace)')
        || case when p_error.error_statement is not null
                then chr(10) || chr(10) || 'Comando:' || chr(10) || p_error.error_statement end
    );
    return l_result;
  end;

end;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PKG_COMUNICADO" AS

    FUNCTION CRIAR_COMUNICADO (
        p_id_empresa      IN NUMBER,
        p_id_autor        IN NUMBER,
        p_titulo          IN VARCHAR2,
        p_conteudo        IN CLOB,
        p_id_departamento IN NUMBER DEFAULT NULL,
        p_imagem          IN BLOB DEFAULT NULL,
        p_mime_type       IN VARCHAR2 DEFAULT NULL,
        p_nome_arquivo    IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_id_comunicado NUMBER;
    BEGIN
        INSERT INTO COMUNICADO (
            ID_EMPRESA, ID_AUTOR, ID_DEPARTAMENTO, TITULO, CONTEUDO,
            DATA_PUBLICACAO, IMAGEM, MIME_TYPE, NOME_ARQUIVO
        ) VALUES (
            p_id_empresa, p_id_autor, p_id_departamento, p_titulo, p_conteudo,
            SYSDATE, p_imagem, p_mime_type, p_nome_arquivo
        )
        RETURNING ID_COMUNICADO INTO v_id_comunicado;

        COMMIT;
        RETURN v_id_comunicado;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END CRIAR_COMUNICADO;


    PROCEDURE MARCAR_COMO_LIDO (
        p_id_comunicado  IN NUMBER,
        p_id_colaborador IN NUMBER
    )
    IS
    BEGIN
        -- MERGE em vez de UPDATE/INSERT separados: cobre "já lido" e "primeira leitura"
        -- num único statement, sem risco de violar a UNIQUE em corrida de cliques duplos.
        MERGE INTO COMUNICADO_LEITURA tgt
        USING (SELECT p_id_comunicado AS ID_COMUNICADO, p_id_colaborador AS ID_COLABORADOR FROM DUAL) src
        ON (tgt.ID_COMUNICADO = src.ID_COMUNICADO AND tgt.ID_COLABORADOR = src.ID_COLABORADOR)
        WHEN NOT MATCHED THEN
            INSERT (ID_COMUNICADO, ID_COLABORADOR, DATA_LEITURA)
            VALUES (src.ID_COMUNICADO, src.ID_COLABORADOR, SYSTIMESTAMP);

        COMMIT;
    END MARCAR_COMO_LIDO;


    FUNCTION QTD_NAO_LIDOS (
        p_id_colaborador IN NUMBER
    ) RETURN NUMBER
    IS
        v_qtd NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_qtd
          FROM COMUNICADO c
          JOIN COLABORADOR col ON col.ID_COLABORADOR = p_id_colaborador
         WHERE c.ID_EMPRESA = col.ID_EMPRESA
           AND (c.ID_DEPARTAMENTO IS NULL OR c.ID_DEPARTAMENTO = col.ID_DEPARTAMENTO)
           AND NOT EXISTS (
                SELECT 1 FROM COMUNICADO_LEITURA l
                 WHERE l.ID_COMUNICADO = c.ID_COMUNICADO
                   AND l.ID_COLABORADOR = p_id_colaborador
           );

        RETURN v_qtd;
    END QTD_NAO_LIDOS;

END PKG_COMUNICADO;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PKG_EQUIPE_CANAL" AS

    FUNCTION CRIAR_EQUIPE (
        p_id_empresa      IN NUMBER,
        p_id_criador      IN NUMBER,
        p_nome            IN VARCHAR2,
        p_descricao       IN VARCHAR2 DEFAULT NULL,
        p_id_departamento IN NUMBER DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_id_equipe NUMBER;
    BEGIN
        INSERT INTO EQUIPE (ID_EMPRESA, ID_DEPARTAMENTO, ID_CRIADOR, NOME, DESCRICAO)
        VALUES (p_id_empresa, p_id_departamento, p_id_criador, p_nome, p_descricao)
        RETURNING ID_EQUIPE INTO v_id_equipe;

        -- O criador entra automaticamente como ADMIN da equipe que criou.
        INSERT INTO EQUIPE_MEMBRO (ID_EQUIPE, ID_COLABORADOR, PAPEL)
        VALUES (v_id_equipe, p_id_criador, 'ADMIN');

        COMMIT;
        RETURN v_id_equipe;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END CRIAR_EQUIPE;


    PROCEDURE ADICIONAR_MEMBRO (
        p_id_equipe      IN NUMBER,
        p_id_colaborador IN NUMBER,
        p_papel          IN VARCHAR2 DEFAULT 'MEMBRO'
    )
    IS
    BEGIN
        MERGE INTO EQUIPE_MEMBRO tgt
        USING (SELECT p_id_equipe AS ID_EQUIPE, p_id_colaborador AS ID_COLABORADOR FROM DUAL) src
        ON (tgt.ID_EQUIPE = src.ID_EQUIPE AND tgt.ID_COLABORADOR = src.ID_COLABORADOR)
        WHEN NOT MATCHED THEN
            INSERT (ID_EQUIPE, ID_COLABORADOR, PAPEL)
            VALUES (src.ID_EQUIPE, src.ID_COLABORADOR, p_papel);

        COMMIT;
    END ADICIONAR_MEMBRO;


    PROCEDURE REMOVER_MEMBRO (
        p_id_equipe_membro IN NUMBER
    )
    IS
        v_id_equipe    EQUIPE_MEMBRO.ID_EQUIPE%TYPE;
        v_papel        EQUIPE_MEMBRO.PAPEL%TYPE;
        v_qtd_admins   NUMBER;
    BEGIN
        SELECT ID_EQUIPE, PAPEL
          INTO v_id_equipe, v_papel
          FROM EQUIPE_MEMBRO
         WHERE ID_EQUIPE_MEMBRO = p_id_equipe_membro;

        IF v_papel = 'ADMIN' THEN
            SELECT COUNT(*)
              INTO v_qtd_admins
              FROM EQUIPE_MEMBRO
             WHERE ID_EQUIPE = v_id_equipe
               AND PAPEL = 'ADMIN';

            IF v_qtd_admins <= 1 THEN
                RAISE_APPLICATION_ERROR(-20011,
                    'Não é possível remover o único administrador da equipe. Promova outro membro a ADMIN antes.');
            END IF;
        END IF;

        DELETE FROM EQUIPE_MEMBRO WHERE ID_EQUIPE_MEMBRO = p_id_equipe_membro;
        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20012, 'Membro não encontrado.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END REMOVER_MEMBRO;


    FUNCTION CRIAR_CANAL (
        p_id_equipe  IN NUMBER,
        p_nome       IN VARCHAR2,
        p_descricao  IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_id_canal NUMBER;
    BEGIN
        INSERT INTO CANAL (ID_EQUIPE, NOME, DESCRICAO)
        VALUES (p_id_equipe, p_nome, p_descricao)
        RETURNING ID_CANAL INTO v_id_canal;

        COMMIT;
        RETURN v_id_canal;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END CRIAR_CANAL;


    FUNCTION ENVIAR_MENSAGEM_CANAL (
        p_id_canal       IN NUMBER,
        p_id_colaborador IN NUMBER,
        p_corpo          IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_id_canal_mensagem NUMBER;
        v_qtd_membro        NUMBER;
    BEGIN
        -----------------------------------------------------------------
        -- Validação: só quem é membro da equipe dona do canal pode postar.
        -- Evita que alguém envie mensagem via chamada direta da function
        -- num canal de equipe da qual não faz parte.
        -----------------------------------------------------------------
        SELECT COUNT(*)
          INTO v_qtd_membro
          FROM CANAL c
          JOIN EQUIPE_MEMBRO em ON em.ID_EQUIPE = c.ID_EQUIPE
         WHERE c.ID_CANAL = p_id_canal
           AND em.ID_COLABORADOR = p_id_colaborador;

        IF v_qtd_membro = 0 THEN
            RAISE_APPLICATION_ERROR(-20010,
                'Colaborador não é membro da equipe deste canal.');
        END IF;

        INSERT INTO CANAL_MENSAGEM (ID_CANAL, ID_COLABORADOR, CORPO)
        VALUES (p_id_canal, p_id_colaborador, p_corpo)
        RETURNING ID_CANAL_MENSAGEM INTO v_id_canal_mensagem;

        -- Enviar mensagem também conta como "estar online agora".
        ATUALIZAR_PRESENCA(p_id_colaborador, 'ONLINE');

        COMMIT;
        RETURN v_id_canal_mensagem;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END ENVIAR_MENSAGEM_CANAL;


    PROCEDURE ATUALIZAR_PRESENCA (
        p_id_colaborador IN NUMBER,
        p_status         IN VARCHAR2 DEFAULT 'ONLINE'
    )
    IS
    BEGIN
        MERGE INTO PRESENCA_COLABORADOR tgt
        USING (SELECT p_id_colaborador AS ID_COLABORADOR FROM DUAL) src
        ON (tgt.ID_COLABORADOR = src.ID_COLABORADOR)
        WHEN MATCHED THEN
            UPDATE SET STATUS_PRESENCA = p_status, DATA_ULTIMO_PING = SYSTIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (ID_COLABORADOR, STATUS_PRESENCA, DATA_ULTIMO_PING)
            VALUES (p_id_colaborador, p_status, SYSTIMESTAMP);

        COMMIT;
    END ATUALIZAR_PRESENCA;


    PROCEDURE ATUALIZAR_OFFLINE (
        p_minutos_limite IN NUMBER DEFAULT 3
    )
    IS
    BEGIN
        UPDATE PRESENCA_COLABORADOR
           SET STATUS_PRESENCA = 'OFFLINE'
         WHERE STATUS_PRESENCA <> 'OFFLINE'
           AND DATA_ULTIMO_PING < SYSTIMESTAMP - NUMTODSINTERVAL(p_minutos_limite, 'MINUTE');

        COMMIT;
    END ATUALIZAR_OFFLINE;

END PKG_EQUIPE_CANAL;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PKG_PERFIS_ACESSO" as

  function papeis_do_cargo (p_id_cargo in number) return apex_t_varchar2 is
    l_papeis apex_t_varchar2 := apex_t_varchar2(c_papel_padrao);
  begin
    for r in (
      select cd_papel
        from cargo_papel
       where id_cargo = p_id_cargo
         and cd_papel <> c_papel_padrao
       order by cd_papel
    ) loop
      apex_string.push(l_papeis, r.cd_papel);
    end loop;
    return l_papeis;
  end papeis_do_cargo;


  procedure atribuir_papeis (
    p_login          in varchar2,
    p_id_cargo       in number,
    p_application_id in number default to_number(v('APP_ID'))
  ) is
    l_login  varchar2(255) := upper(trim(p_login));
    l_papeis apex_t_varchar2 := papeis_do_cargo(p_id_cargo);
    l_existe pls_integer;
  begin
    if l_login is null then
      raise_application_error(-20101, 'Informe o login do usuário para atribuir os papéis.');
    end if;

    for i in 1 .. l_papeis.count loop
      select count(*)
        into l_existe
        from apex_appl_acl_roles
       where application_id = p_application_id
         and role_static_id = l_papeis(i);

      if l_existe = 0 then
        raise_application_error(-20102,
          'O papel "' || l_papeis(i) || '" não existe na aplicação ' || p_application_id
          || '. Crie-o em Application Access Control ou corrija CARGO_PAPEL.');
      end if;

      if not apex_acl.has_user_role(
               p_role_static_id => l_papeis(i),
               p_application_id => p_application_id,
               p_user_name      => l_login) then
        apex_acl.add_user_role(
          p_application_id => p_application_id,
          p_user_name      => l_login,
          p_role_static_id => l_papeis(i));
      end if;
    end loop;
  end atribuir_papeis;

end pkg_perfis_acesso;
/

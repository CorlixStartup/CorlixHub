
  CREATE OR REPLACE EDITIONABLE FUNCTION "CH_GET_CANAL_DIRETO" (
  p_colab_a in number,
  p_colab_b in number
) return number is
  l_id_canal number;
  l_menor    number := least(p_colab_a, p_colab_b);
  l_maior    number := greatest(p_colab_a, p_colab_b);
begin
  select cp1.id_canal into l_id_canal
  from   canal_participante cp1
  join   canal_participante cp2 on cp2.id_canal = cp1.id_canal
  join   canal c                on c.id_canal   = cp1.id_canal
  where  cp1.id_colaborador = p_colab_a
  and    cp2.id_colaborador = p_colab_b
  and    c.tipo = 'DIRETO'
  fetch first 1 row only;

  return l_id_canal;
exception
  when no_data_found then
    insert into canal (nome, tipo, data_criacao, status)
    values ('DM-' || l_menor || '-' || l_maior, 'DIRETO', sysdate, true)
    returning id_canal into l_id_canal;

    insert into canal_participante (id_canal, id_colaborador)
    select l_id_canal, p_colab_a from dual
    union all
    select l_id_canal, p_colab_b from dual;

    return l_id_canal;
end;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "LOG_PKG" as
  procedure gravar(p_nivel varchar2, p_msg varchar2, p_origem varchar2 default null, p_detalhe clob default null);
  procedure erro (p_msg varchar2, p_origem varchar2 default null);
  procedure aviso(p_msg varchar2, p_origem varchar2 default null);
  procedure info (p_msg varchar2, p_origem varchar2 default null);
  function apex_error_handler(p_error in apex_error.t_error) return apex_error.t_error_result;
end;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "PKG_COMUNICADO" AS

    -- Cria um comunicado. ID_DEPARTAMENTO NULL = empresa toda.
    FUNCTION CRIAR_COMUNICADO (
        p_id_empresa      IN NUMBER,
        p_id_autor        IN NUMBER,
        p_titulo          IN VARCHAR2,
        p_conteudo        IN CLOB,
        p_id_departamento IN NUMBER DEFAULT NULL,
        p_imagem          IN BLOB DEFAULT NULL,
        p_mime_type       IN VARCHAR2 DEFAULT NULL,
        p_nome_arquivo    IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    -- Marca um comunicado como lido para o colaborador. Idempotente.
    PROCEDURE MARCAR_COMO_LIDO (
        p_id_comunicado  IN NUMBER,
        p_id_colaborador IN NUMBER
    );

    -- Quantidade de comunicados elegíveis (empresa/depto) ainda não lidos.
    FUNCTION QTD_NAO_LIDOS (
        p_id_colaborador IN NUMBER
    ) RETURN NUMBER;

END PKG_COMUNICADO;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "PKG_EQUIPE_CANAL" AS

    -- Cria a equipe e já inclui o criador como ADMIN.
    FUNCTION CRIAR_EQUIPE (
        p_id_empresa      IN NUMBER,
        p_id_criador      IN NUMBER,
        p_nome            IN VARCHAR2,
        p_descricao       IN VARCHAR2 DEFAULT NULL,
        p_id_departamento IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;

    -- Adiciona um colaborador à equipe. Ignora silenciosamente se já for membro.
    PROCEDURE ADICIONAR_MEMBRO (
        p_id_equipe      IN NUMBER,
        p_id_colaborador IN NUMBER,
        p_papel          IN VARCHAR2 DEFAULT 'MEMBRO'
    );

    -- Remove um membro da equipe. Bloqueia se for o único ADMIN restante.
    PROCEDURE REMOVER_MEMBRO (
        p_id_equipe_membro IN NUMBER
    );

    -- Cria um canal dentro de uma equipe.
    FUNCTION CRIAR_CANAL (
        p_id_equipe  IN NUMBER,
        p_nome       IN VARCHAR2,
        p_descricao  IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    -- Envia uma mensagem no canal. Valida que o colaborador é membro da equipe dona do canal.
    FUNCTION ENVIAR_MENSAGEM_CANAL (
        p_id_canal       IN NUMBER,
        p_id_colaborador IN NUMBER,
        p_corpo          IN VARCHAR2
    ) RETURN NUMBER;

    -- Heartbeat de presença — chamado pelo polling do navegador.
    PROCEDURE ATUALIZAR_PRESENCA (
        p_id_colaborador IN NUMBER,
        p_status         IN VARCHAR2 DEFAULT 'ONLINE'
    );

    -- Marca como OFFLINE quem não dá ping há mais de p_minutos_limite minutos.
    -- Chamado por um job DBMS_SCHEDULER a cada 1-2 minutos.
    PROCEDURE ATUALIZAR_OFFLINE (
        p_minutos_limite IN NUMBER DEFAULT 3
    );

END PKG_EQUIPE_CANAL;
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "PKG_LOGS" as

end "PKG_LOGS";
/

  CREATE OR REPLACE EDITIONABLE PACKAGE "PKG_PERFIS_ACESSO" authid definer as

  c_papel_padrao constant varchar2(30) := 'colaborador';

  -- Static IDs dos papéis do cargo, já com o papel padrão.
  function papeis_do_cargo (p_id_cargo in number) return apex_t_varchar2;

  -- Adiciona ao usuário os papéis do cargo que ele ainda não tem.
  procedure atribuir_papeis (
    p_login          in varchar2,
    p_id_cargo       in number,
    p_application_id in number default to_number(v('APP_ID'))
  );

end pkg_perfis_acesso;
/

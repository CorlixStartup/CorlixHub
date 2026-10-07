--------------------------------------------------------------------------------
-- Corlix Hub · Perfis de acesso · 03 · Package PKG_PERFIS_ACESSO
--
-- Atribui ao usuário APEX os papéis (ACL roles) do cargo dele.
-- Regra: todo usuário recebe "colaborador"; os demais vêm de CARGO_PAPEL.
-- Só adiciona papéis: nunca remove os que já existem (ex.: papéis dados à mão
-- em Application Access Control, como "equipe-do-corlix-hub").
--
-- Precisa rodar dentro de uma sessão APEX (usa APEX_ACL), como o processo
-- "Atribuir papéis do cargo" da página 14.
--
-- Erros: -20101 login vazio · -20102 papel inexistente na aplicação.
-- (Faixa -2010x para não colidir com PKG_HISTORICO_CARREIRA e PKG_EQUIPE_CANAL.)
--------------------------------------------------------------------------------

create or replace package pkg_perfis_acesso authid definer as

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

create or replace package body pkg_perfis_acesso as

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

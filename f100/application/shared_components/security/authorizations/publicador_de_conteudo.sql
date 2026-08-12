prompt --application/shared_components/security/authorizations/publicador_de_conteudo
begin
--   Manifest
--     SECURITY SCHEME: Publicador de Conteudo
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.2'
,p_default_workspace_id=>10008945716225088
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'WKSP_CORLIXHUB'
);
wwv_flow_imp_shared.create_security_scheme(
 p_id=>wwv_flow_imp.id(10412382793426827)
,p_name=>'Publicador de Conteudo'
,p_static_id=>'publicador-de-conteudo'
,p_scheme_type=>'NATIVE_IS_IN_GROUP'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'name', unistr('Publicador de Conte\00FAdo'),
  'type', 'W')).to_clob
,p_error_message=>unistr('Acesso restrito a publicadores de conte\00FAdo.')
,p_version_scn=>'SH256:Z-FVcotLPefiduH8Qux58tgppWoQz7aGbFthkiO1HiM'
,p_caching=>'BY_USER_BY_SESSION'
);
wwv_flow_imp.component_end;
end;
/

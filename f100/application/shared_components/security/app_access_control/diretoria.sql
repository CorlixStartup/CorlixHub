prompt --application/shared_components/security/app_access_control/diretoria
begin
--   Manifest
--     ACL ROLE: Diretoria
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.2'
,p_default_workspace_id=>10008945716225088
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'WKSP_CORLIXHUB'
);
wwv_flow_imp_shared.create_acl_role(
 p_id=>wwv_flow_imp.id(11408307086204190)
,p_static_id=>'diretoria'
,p_name=>'Diretoria'
,p_version_scn=>'SH256:Mwav9Oj96ZA9oez7zwi5mSnTxhc81AY91sCAg6yy7yI'
);
wwv_flow_imp.component_end;
end;
/

prompt --application/shared_components/security/app_access_control/equipe_do_corlix_hub
begin
--   Manifest
--     ACL ROLE: Equipe do Corlix Hub
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
 p_id=>wwv_flow_imp.id(11408514227205809)
,p_static_id=>'equipe-do-corlix-hub'
,p_name=>'Equipe do Corlix Hub'
,p_version_scn=>'SH256:brH5BzVLz8oyc5Vy3foAnt2q7xPDqAWZ5N1Vu60A8L8'
);
wwv_flow_imp.component_end;
end;
/

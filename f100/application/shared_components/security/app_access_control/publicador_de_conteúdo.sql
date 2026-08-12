prompt --application/shared_components/security/app_access_control/publicador_de_conteúdo
begin
--   Manifest
--     ACL ROLE: Publicador de Conteúdo
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
 p_id=>wwv_flow_imp.id(11408430878205091)
,p_static_id=>unistr('publicador-de-conte\00FAdo')
,p_name=>unistr('Publicador de Conte\00FAdo')
,p_version_scn=>'SH256:jClmosK-3NtjGCJkT0PhBF2rGvYesy5xloosM30UemQ'
);
wwv_flow_imp.component_end;
end;
/

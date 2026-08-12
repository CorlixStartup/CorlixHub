prompt --application/shared_components/logic/application_items/g_nome_usuario
begin
--   Manifest
--     APPLICATION ITEM: G_NOME_USUARIO
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.2'
,p_default_workspace_id=>10008945716225088
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'WKSP_CORLIXHUB'
);
wwv_flow_imp_shared.create_flow_item(
 p_id=>wwv_flow_imp.id(10277654897201570)
,p_name=>'G_NOME_USUARIO'
,p_protection_level=>'I'
,p_version_scn=>'47036308718760'
);
wwv_flow_imp.component_end;
end;
/

prompt --application/shared_components/navigation/lists/emitir_comunicado
begin
--   Manifest
--     LIST: Emitir Comunicado
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.2'
,p_default_workspace_id=>10008945716225088
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'WKSP_CORLIXHUB'
);
wwv_flow_imp_shared.create_list(
 p_id=>wwv_flow_imp.id(9243358503112728)
,p_name=>'Emitir Comunicado'
,p_static_id=>'emitir-comunicado'
,p_version_scn=>'SH256:0Y-6LtzVULycBT5IIOEj9DVXEmfBFronySLngxBuDbs'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(9244881144112732)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Step 1'
,p_static_id=>'step-1'
,p_list_item_link_target=>'f?p=&APP_ID.:17:&APP_SESSION.::&DEBUG.:::'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(9249287946112743)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Step 2'
,p_static_id=>'step-2'
,p_list_item_link_target=>'f?p=&APP_ID.:18:&APP_SESSION.::&DEBUG.:::'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(9254083938112753)
,p_list_item_display_sequence=>30
,p_list_item_link_text=>'Step 3'
,p_static_id=>'step-3'
,p_list_item_link_target=>'f?p=&APP_ID.:19:&APP_SESSION.::&DEBUG.:::'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_imp.component_end;
end;
/

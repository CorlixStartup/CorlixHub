prompt --application/shared_components/navigation/lists/navigation_menu
begin
--   Manifest
--     LIST: Navigation Menu
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
 p_id=>wwv_flow_imp.id(10016114704229685)
,p_name=>'Navigation Menu'
,p_static_id=>'navigation-menu'
,p_version_scn=>'SH256:a7cLFfiA6WNB6Y8PKAxMY6CQCL3sip-d4PMfj7vv8io'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(10300139268463692)
,p_list_item_display_sequence=>70
,p_list_item_link_text=>unistr('Cadastro de Usu\00E1rios')
,p_static_id=>'cadastros'
,p_list_item_link_target=>'f?p=&APP_ID.:14:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-user-plus'
,p_security_scheme=>wwv_flow_imp.id(10411964122424292)
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'14'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(10297539973456599)
,p_list_item_display_sequence=>50
,p_list_item_link_text=>'Colaboradores'
,p_static_id=>'colaboradores'
,p_list_item_link_target=>'f?p=&APP_ID.:12:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-users-alt'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'12'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(10229054697458255)
,p_list_item_display_sequence=>40
,p_list_item_link_text=>unistr('Comunica\00E7\00E3o')
,p_static_id=>unistr('comunica\00E7\00E3o')
,p_list_item_link_target=>'f?p=&APP_ID.:11:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-commenting-o'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'11'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(9243823976112731)
,p_list_item_display_sequence=>80
,p_list_item_link_text=>'Emitir Comunicado'
,p_static_id=>'emitir-comunicado'
,p_list_item_link_target=>'f?p=&APP_ID.:17:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-magic'
,p_parent_list_item_id=>wwv_flow_imp.id(10027834603229832)
,p_security_scheme=>wwv_flow_imp.id(10412382793426827)
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'17'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(9982701530177537)
,p_list_item_display_sequence=>110
,p_list_item_link_text=>'Empresas Cadastradas'
,p_static_id=>'empresas-cadastradas'
,p_list_item_link_target=>'f?p=&APP_ID.:15:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-building-o'
,p_security_scheme=>wwv_flow_imp.id(10020823953229789)
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'15,16'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(10298838293459657)
,p_list_item_display_sequence=>60
,p_list_item_link_text=>unistr('Hist\00F3rico de carreira')
,p_static_id=>unistr('hist\00F3rico-de-carreira')
,p_list_item_link_target=>'f?p=&APP_ID.:13:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-workflow'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'13'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(10027834603229832)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Home'
,p_static_id=>'home'
,p_list_item_link_target=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:::'
,p_list_item_icon=>'fa-home'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(10217417131385177)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Meu Perfil'
,p_static_id=>'meu-perfil'
,p_list_item_link_target=>'f?p=&APP_ID.:2:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-user'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'2'
);
wwv_flow_imp_shared.create_list_item(
 p_id=>wwv_flow_imp.id(10218709306387934)
,p_list_item_display_sequence=>30
,p_list_item_link_text=>'Organograma'
,p_static_id=>'organograma'
,p_list_item_link_target=>'f?p=&APP_ID.:3:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-tree-org'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'3'
);
wwv_flow_imp.component_end;
end;
/

prompt --application/shared_components/user_interface/templates/button/html_button_legacy_apex_5_migration
begin
--   Manifest
--     BUTTON TEMPLATE: html-button-legacy-apex-5-migration
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.2'
,p_default_workspace_id=>10008945716225088
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'WKSP_CORLIXHUB'
);
wwv_flow_imp_shared.create_button_templates(
 p_id=>wwv_flow_imp.id(9246514197112737)
,p_template_name=>'HTML button (legacy - APEX 5 migration)'
,p_static_id=>'html-button-legacy-apex-5-migration'
,p_template=>' <input type="button" value="#LABEL#" onclick="#JAVASCRIPT#" id="#DOM_ID#" class="#BUTTON_CSS_CLASSES#" #BUTTON_ATTRIBUTES#/>'
,p_hot_template=>' <input type="button" value="#LABEL#" onclick="#JAVASCRIPT#" id="#DOM_ID#" class="#BUTTON_CSS_CLASSES#" #BUTTON_ATTRIBUTES#/>'
,p_translate_this_template=>'N'
,p_theme_class_id=>13
,p_theme_id=>42
);
wwv_flow_imp.component_end;
end;
/

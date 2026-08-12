prompt --application/shared_components/user_interface/templates/region/cards_container_image_first
begin
--   Manifest
--     REGION TEMPLATE: cards-container-image-first
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.2'
,p_default_workspace_id=>10008945716225088
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'WKSP_CORLIXHUB'
);
wwv_flow_imp_shared.create_plug_template(
 p_id=>wwv_flow_imp.id(10205076729845143)
,p_layout=>'TABLE'
,p_template=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div class="t-CardsRegion #REGION_CSS_CLASSES#" id="#DOM_ID#" #REGION_LANDMARK_ATTRIBUTES# #REGION_ATTRIBUTES#>',
'  <h2 class="t-CardsRegion-title" id="#DOM_ID#_heading" data-apex-heading>#TITLE#</h2>',
'    <div class="t-Region-orderBy">#ORDER_BY_ITEM#</div>',
'    #BODY#',
'    #SUB_REGIONS#',
'</div>'))
,p_page_plug_template_name=>'Cards Container - Image First'
,p_static_id=>'cards-container-image-first'
,p_theme_id=>42
,p_theme_class_id=>21
,p_default_template_options=>'u-colors'
,p_preset_template_options=>'t-CardsRegion--hideHeader js-addHiddenHeadingRoleDesc'
,p_default_label_alignment=>'RIGHT'
,p_default_field_alignment=>'LEFT'
,p_default_landmark_type=>'region'
,p_translate_this_template=>'N'
);
wwv_flow_imp_shared.create_template_option(
 p_id=>wwv_flow_imp.id(10206921917845164)
,p_theme_id=>42
,p_static_id=>'apply-theme-colors'
,p_display_name=>'Apply Theme Colors'
,p_display_sequence=>1
,p_region_template_id=>wwv_flow_imp.id(10205076729845143)
,p_css_classes=>'u-colors'
,p_template_types=>'REGION'
,p_help_text=>'Applies the colors from the theme''s color palette to the icons or initials within cards.'
);
wwv_flow_imp_shared.create_template_option(
 p_id=>wwv_flow_imp.id(10207368328845167)
,p_theme_id=>42
,p_static_id=>'hiddenheadernoat'
,p_display_name=>'Hidden'
,p_display_sequence=>1
,p_region_template_id=>wwv_flow_imp.id(10205076729845143)
,p_css_classes=>'t-CardsRegion--removeHeader js-removeLandmark'
,p_group_id=>1480010412268366
,p_template_types=>'REGION'
);
wwv_flow_imp_shared.create_template_option(
 p_id=>wwv_flow_imp.id(10207741900845168)
,p_theme_id=>42
,p_static_id=>'hideregionheader'
,p_display_name=>'Hidden but accessible'
,p_display_sequence=>1
,p_region_template_id=>wwv_flow_imp.id(10205076729845143)
,p_css_classes=>'t-CardsRegion--hideHeader js-addHiddenHeadingRoleDesc'
,p_group_id=>1480010412268366
,p_template_types=>'REGION'
,p_help_text=>'This option will hide the region header. Note that the region title will still be audible for Screen Readers.'
);
wwv_flow_imp_shared.create_template_option(
 p_id=>wwv_flow_imp.id(10208199174845169)
,p_theme_id=>42
,p_static_id=>'style-a'
,p_display_name=>'Style A'
,p_display_sequence=>10
,p_region_template_id=>wwv_flow_imp.id(10205076729845143)
,p_css_classes=>'t-CardsRegion--styleA'
,p_group_id=>2137437705448345391
,p_template_types=>'REGION'
);
wwv_flow_imp_shared.create_template_option(
 p_id=>wwv_flow_imp.id(10208518593845170)
,p_theme_id=>42
,p_static_id=>'style-b'
,p_display_name=>'Style B'
,p_display_sequence=>20
,p_region_template_id=>wwv_flow_imp.id(10205076729845143)
,p_css_classes=>'t-CardsRegion--styleB'
,p_group_id=>2137437705448345391
,p_template_types=>'REGION'
);
wwv_flow_imp_shared.create_template_option(
 p_id=>wwv_flow_imp.id(10208915904845171)
,p_theme_id=>42
,p_static_id=>'style-c'
,p_display_name=>'Style C'
,p_display_sequence=>30
,p_region_template_id=>wwv_flow_imp.id(10205076729845143)
,p_css_classes=>'t-CardsRegion--styleC'
,p_group_id=>2137437705448345391
,p_template_types=>'REGION'
);
wwv_flow_imp_shared.create_plug_tmpl_display_point(
 p_id=>wwv_flow_imp.id(10205475494845159)
,p_plug_template_id=>wwv_flow_imp.id(10205076729845143)
,p_name=>'Region Body'
,p_placeholder=>'BODY'
,p_apexlang_name=>'regionBody'
,p_has_grid_support=>true
,p_has_region_support=>true
,p_has_item_support=>true
,p_has_button_support=>true
,p_glv_new_row=>true
);
wwv_flow_imp_shared.create_plug_tmpl_display_point(
 p_id=>wwv_flow_imp.id(10205904934845160)
,p_plug_template_id=>wwv_flow_imp.id(10205076729845143)
,p_name=>'Sort Order'
,p_placeholder=>'ORDER_BY_ITEM'
,p_apexlang_name=>'sortOrder'
,p_has_grid_support=>false
,p_has_region_support=>false
,p_has_item_support=>true
,p_has_button_support=>true
,p_glv_new_row=>true
);
wwv_flow_imp_shared.create_plug_tmpl_display_point(
 p_id=>wwv_flow_imp.id(10206475365845161)
,p_plug_template_id=>wwv_flow_imp.id(10205076729845143)
,p_name=>'Sub Regions'
,p_placeholder=>'SUB_REGIONS'
,p_apexlang_name=>'subRegions'
,p_has_grid_support=>true
,p_has_region_support=>true
,p_has_item_support=>false
,p_has_button_support=>false
,p_glv_new_row=>true
);
wwv_flow_imp.component_end;
end;
/

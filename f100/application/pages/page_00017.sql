prompt --application/pages/page_00017
begin
--   Manifest
--     PAGE: 00017
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.2'
,p_default_workspace_id=>10008945716225088
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'WKSP_CORLIXHUB'
);
wwv_flow_imp_page.create_page(
 p_id=>17
,p_name=>'Emitir Comunicado'
,p_alias=>'COMUNICADO'
,p_page_mode=>'MODAL'
,p_step_title=>'Emitir novo comunicado'
,p_autocomplete_on_off=>'OFF'
,p_step_template=>2123271369431536901
,p_page_template_options=>'#DEFAULT#'
,p_dialog_height=>'600'
,p_dialog_resizable=>'Y'
,p_protection_level=>'C'
,p_page_component_map=>'02'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(9244497991112732)
,p_plug_name=>'Buttons'
,p_static_id=>'buttons'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>2127905476394690047
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_03'
,p_plug_item_display_point=>'ABOVE'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(9244358064112732)
,p_plug_name=>'emitir-comunicado'
,p_static_id=>'step-1'
,p_title=>'Emitir novo comunicado'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4502917002193490937
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'ABOVE'
,p_query_type=>'TABLE'
,p_query_table=>'COMUNICADO'
,p_include_rowid_column=>false
,p_is_editable=>false
,p_plug_source_type=>'NATIVE_FORM'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(9246031519112736)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(9244497991112732)
,p_button_name=>'cancelar'
,p_static_id=>'cancel'
,p_show_as_disabled=>false
,p_button_action=>'DEFINED_BY_DA_ACTION'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_image_alt=>'Cancelar'
,p_button_position=>'CLOSE'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_imp_page.create_component_da_action(
 p_id=>wwv_flow_imp.id(9247195291112739)
,p_button_id=>wwv_flow_imp.id(9246031519112736)
,p_action_sequence=>10
,p_action=>'NATIVE_DIALOG_CANCEL'
,p_static_id=>'native-dialog-cancel'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(9246346109112736)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_imp.id(9244497991112732)
,p_button_name=>'enviar_comunicado'
,p_static_id=>'next'
,p_show_as_disabled=>false
,p_button_action=>'SUBMIT'
,p_button_template_options=>'t-Button--iconRight'
,p_button_template_id=>2084305881903810008
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Enviar Comunicado'
,p_button_position=>'NEXT'
,p_show_processing=>'Y'
,p_confirm_message=>'Certeza que deseja emitir o comunicado?'
,p_confirm_style=>'warning'
,p_icon_css_classes=>'fa-chevron-right'
,p_database_action=>'INSERT'
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9266243569807344)
,p_name=>'P17_CONTEUDO'
,p_data_type=>'CLOB'
,p_source_data_type=>'CLOB'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_source_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_prompt=>'Comunicado'
,p_source=>'CONTEUDO'
,p_display_as=>'NATIVE_TEXTAREA'
,p_cSize=>30
,p_cHeight=>5
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'auto_height', 'N',
  'character_counter', 'N',
  'resizable', 'Y',
  'trim_spaces', 'BOTH')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9266399737807345)
,p_name=>'P17_DATA_PUBLICACAO'
,p_source_data_type=>'DATE'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_source_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_default=>'SYSDATE;'
,p_item_default_type=>'EXPRESSION'
,p_item_default_language=>'PLSQL'
,p_source=>'DATA_PUBLICACAO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9265964921807341)
,p_name=>'P17_ID_AUTOR'
,p_source_data_type=>'NUMBER'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_source_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_default=>'SELECT ID_COLABORADOR FROM COLABORADOR WHERE LOGIN_APEX = :APP_USER;'
,p_item_default_type=>'SQL_QUERY'
,p_source=>'ID_AUTOR'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9265748768807339)
,p_name=>'P17_ID_COMUNICADO'
,p_source_data_type=>'NUMBER'
,p_is_primary_key=>true
,p_is_query_only=>true
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_source_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_source=>'ID_COMUNICADO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9266059421807342)
,p_name=>'P17_ID_DEPARTAMENTO'
,p_source_data_type=>'NUMBER'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_source_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_prompt=>'Departamento'
,p_source=>'ID_DEPARTAMENTO'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT DEPARTAMENTO.NOME,',
'       DEPARTAMENTO.ID_DEPARTAMENTO',
'FROM DEPARTAMENTO',
'WHERE DEPARTAMENTO.ID_EMPRESA = (',
'    SELECT COLABORADOR.ID_EMPRESA',
'    FROM COLABORADOR',
'    WHERE COLABORADOR.login_apex = :APP_USER',
')',
'ORDER BY DEPARTAMENTO.NOME;'))
,p_lov_display_null=>'YES'
,p_cHeight=>1
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_lov_display_extra=>'YES'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'page_action_on_selection', 'NONE')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9265876647807340)
,p_name=>'P17_ID_EMPRESA'
,p_source_data_type=>'NUMBER'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_source_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_default=>'SELECT ID_EMPRESA FROM COLABORADOR WHERE LOGIN_APEX = :APP_USER;'
,p_item_default_type=>'SQL_QUERY'
,p_source=>'ID_EMPRESA'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9266410504807346)
,p_name=>'P17_IMAGEM'
,p_source_data_type=>'BLOB'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_source_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_prompt=>'Imagem do comunicado'
,p_source=>'IMAGEM'
,p_display_as=>'NATIVE_IMAGE_UPLOAD'
,p_cSize=>30
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'allow_copy_paste', 'N',
  'allow_cropping', 'N',
  'display_as', 'DROPZONE_ICON',
  'display_download_link', 'Y',
  'filename_column', 'NOME_ARQUIVO',
  'mime_type_column', 'MIME_TYPE',
  'preview_size', 'AUTO',
  'storage_type', 'DB_COLUMN')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9266597299807347)
,p_name=>'P17_MIME_TYPE'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_source_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_source=>'MIME_TYPE'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9266697399807348)
,p_name=>'P17_NOME_ARQUIVO'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_source_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_source=>'NOME_ARQUIVO'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9266192175807343)
,p_name=>'P17_TITULO'
,p_source_data_type=>'VARCHAR2'
,p_is_required=>true
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_item_source_plug_id=>wwv_flow_imp.id(9244358064112732)
,p_prompt=>'Titulo'
,p_source=>'TITULO'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_cMaxlength=>200
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'disabled', 'N',
  'submit_when_enter_pressed', 'N',
  'subtype', 'TEXT',
  'trim_spaces', 'BOTH')).to_clob
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(9265647718807338)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_region_id=>wwv_flow_imp.id(9244358064112732)
,p_process_type=>'NATIVE_FORM_INIT'
,p_process_name=>'Initialize form Emitir Comunicado'
,p_static_id=>'initialize-form-emitir-comunicado'
,p_internal_uid=>9265647718807338
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(10214262639327047)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_region_id=>wwv_flow_imp.id(9244358064112732)
,p_process_type=>'NATIVE_FORM_DML'
,p_process_name=>'processo-emissao-comunicado'
,p_static_id=>'processo-emissao-comunicado'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'lock_row', 'Y',
  'prevent_lost_updates', 'Y',
  'return_primary_keys_after_insert', 'Y',
  'table_name', 'COMUNICADO',
  'target_type', 'TABLE')).to_clob
,p_process_error_message=>unistr('N\00E3o foi poss\00EDvel emitir o comunicado, tente novamente.')
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_success_message=>'Comunicado Publicado com Sucesso!'
,p_internal_uid=>10214262639327047
);
wwv_flow_imp.component_end;
end;
/

prompt --application/pages/page_00014
begin
--   Manifest
--     PAGE: 00014
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
 p_id=>14
,p_name=>unistr('Cadastro de Usu\00E1rios')
,p_alias=>'CADASTROS-DE-USUARIOS'
,p_step_title=>unistr('Cadastro de Usu\00E1rios')
,p_autocomplete_on_off=>'OFF'
,p_step_template=>4073832297226169690
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'C'
,p_page_component_map=>'02'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(9203067724147813)
,p_plug_name=>'Cadastrar Colaborador - Header'
,p_static_id=>'cadastrar-colaborador-header'
,p_region_template_options=>'#DEFAULT#:t-Region--removeHeader js-removeLandmark:t-Region--stacked:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>10
,p_plug_new_grid_row=>false
,p_plug_new_grid_column=>false
,p_plug_item_display_point=>'ABOVE'
,p_location=>null
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
unistr('<h1 style="font-size:20px;color:#1A1C1C;margin-top:0;">Cadastro de Usu\00E1rios</h1>'),
unistr('<span style="font-size:14px;color:#444748;">Preencha as informa\00E7\00F5es para registrar um novo colaborador no sistema.</span>')))
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(9203775969147820)
,p_plug_name=>'DADOS DO COLABORADOR'
,p_static_id=>'dados-do-colaborador'
,p_parent_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_region_template_options=>'#DEFAULT#:t-Region--noUI:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>30
,p_plug_item_display_point=>'ABOVE'
,p_location=>null
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(9203107063147814)
,p_plug_name=>unistr('INFORMA\00C7\00D5ES DE LOGIN')
,p_static_id=>'new'
,p_parent_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_region_template_options=>'#DEFAULT#:t-Region--noUI:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>20
,p_plug_item_display_point=>'ABOVE'
,p_location=>null
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(9201806955147801)
,p_plug_name=>'Cadastrar Colaborador'
,p_static_id=>'novo'
,p_title=>'Cadastrar Colaborador'
,p_region_template_options=>'#DEFAULT#:t-Region--removeHeader js-removeLandmark:t-Region--stacked:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>20
,p_plug_new_grid_row=>false
,p_plug_new_grid_column=>false
,p_plug_item_display_point=>'ABOVE'
,p_query_type=>'TABLE'
,p_query_table=>'COLABORADOR'
,p_include_rowid_column=>false
,p_is_editable=>false
,p_plug_source_type=>'NATIVE_FORM'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(9204691233147829)
,p_plug_name=>'STATUS DO REGISTRO'
,p_static_id=>'status-do-registro'
,p_parent_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_region_template_options=>'#DEFAULT#:t-Region--noUI:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>50
,p_plug_item_display_point=>'ABOVE'
,p_location=>null
,p_plug_source=>unistr('<span>Contas inativas n\00E3o ter\00E3o acesso ao sistema.</span>')
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(9204953023147832)
,p_button_sequence=>120
,p_button_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_button_name=>'CANCELAR'
,p_static_id=>'cancelar'
,p_show_as_disabled=>false
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_image_alt=>'Cancelar'
,p_button_position=>'DELETE'
,p_button_redirect_url=>'f?p=&APP_ID.:14:&SESSION.::&DEBUG.:::'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(9204874007147831)
,p_button_sequence=>120
,p_button_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_button_name=>'SALVAR_USUARIO'
,p_static_id=>'salvar-usuario'
,p_show_as_disabled=>false
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Salvar Usuario'
,p_button_position=>'CREATE'
,p_warn_on_unsaved_changes=>null
,p_confirm_message=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<h4>Confirmar Cadastro</h4>',
unistr('<span>Deseja realmente salvar as informa\00E7\00F5es deste novo colaborador? Esta a\00E7\00E3o criar\00E1 o acesso ao sistema imediatamente.</span>')))
,p_confirm_style=>'warning'
,p_database_action=>'INSERT'
);
wwv_flow_imp_page.create_page_branch(
 p_id=>wwv_flow_imp.id(9740760870646702)
,p_branch_name=>unistr('Limpar formul\00E1rio ap\00F3s carregamento')
,p_branch_action=>'f?p=&APP_ID.:14:&SESSION.::&DEBUG.:CR,14::&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'BEFORE_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_sequence=>10
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9204466270147827)
,p_name=>'P14_CARGO'
,p_source_data_type=>'NUMBER'
,p_is_required=>true
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_imp.id(9203775969147820)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>'Cargo'
,p_source=>'ID_CARGO'
,p_display_as=>'NATIVE_POPUP_LOV'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT NOME AS display_value,',
'       ID_CARGO AS return_value',
'FROM CARGO',
'WHERE ID_DEPARTAMENTO = :P14_DEPARTAMENTO',
'  AND ID_EMPRESA = :P14_EMPRESA',
'ORDER BY NOME;'))
,p_lov_display_null=>'YES'
,p_lov_cascade_parent_items=>'P14_EMPRESA,P14_DEPARTAMENTO'
,p_ajax_items_to_submit=>'P14_EMPRESA,P14_DEPARTAMENTO'
,p_ajax_optimize_refresh=>'Y'
,p_cSize=>30
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_lov_display_extra=>'YES'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'case_sensitive', 'N',
  'display_as', 'POPUP',
  'fetch_on_search', 'N',
  'initial_fetch', 'FIRST_ROWSET',
  'manual_entry', 'N',
  'match_type', 'CONTAINS',
  'min_chars', '0')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9203416854147817)
,p_name=>'P14_CONFIRMAR_SENHA'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(9203107063147814)
,p_prompt=>'Confirmar Senha'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_PASSWORD'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'submit_when_enter_pressed', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9202741556147810)
,p_name=>'P14_DATA_ADMISSAO'
,p_source_data_type=>'DATE'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_imp.id(9203775969147820)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>unistr('Data de Admiss\00E3o')
,p_format_mask=>'YYYY-MM-DD'
,p_source=>'DATA_ADMISSAO'
,p_display_as=>'NATIVE_DATE_PICKER_APEX'
,p_cSize=>30
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'display_as', 'NATIVE',
  'max_date', 'NONE',
  'min_date', 'NONE',
  'show_time', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9205295637147835)
,p_name=>'P14_DATA_NASCIMENTO'
,p_source_data_type=>'DATE'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_imp.id(9203775969147820)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>'Data de Nascimento'
,p_format_mask=>'YYYY-MM-DD'
,p_source=>'DATA_DE_NASCIMENTO'
,p_display_as=>'NATIVE_DATE_PICKER_APEX'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'display_as', 'NATIVE',
  'max_date', 'NONE',
  'min_date', 'NONE',
  'show_time', 'N')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9204290062147825)
,p_name=>'P14_DEPARTAMENTO'
,p_source_data_type=>'NUMBER'
,p_is_required=>true
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_imp.id(9203775969147820)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>'Departamento'
,p_source=>'ID_DEPARTAMENTO'
,p_display_as=>'NATIVE_POPUP_LOV'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT NOME AS display_value,',
'       ID_DEPARTAMENTO AS return_value',
'FROM DEPARTAMENTO',
'WHERE ID_EMPRESA = :P14_EMPRESA',
'ORDER BY NOME;'))
,p_lov_display_null=>'YES'
,p_lov_cascade_parent_items=>'P14_EMPRESA'
,p_ajax_items_to_submit=>'P14_EMPRESA'
,p_ajax_optimize_refresh=>'Y'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_lov_display_extra=>'YES'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'case_sensitive', 'N',
  'display_as', 'POPUP',
  'fetch_on_search', 'N',
  'initial_fetch', 'FIRST_ROWSET',
  'manual_entry', 'N',
  'match_type', 'CONTAINS',
  'min_chars', '0')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9202642715147809)
,p_name=>'P14_EMAIL'
,p_source_data_type=>'VARCHAR2'
,p_is_required=>true
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(9203107063147814)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>'E-mail Coporativo'
,p_source=>'EMAIL'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_cMaxlength=>200
,p_begin_on_new_line=>'N'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'disabled', 'N',
  'submit_when_enter_pressed', 'N',
  'subtype', 'EMAIL',
  'trim_spaces', 'BOTH')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9204120692147824)
,p_name=>'P14_EMPRESA'
,p_source_data_type=>'NUMBER'
,p_is_required=>true
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_imp.id(9203775969147820)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>'Empresa'
,p_source=>'ID_EMPRESA'
,p_display_as=>'NATIVE_SELECT_ONE'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT NOME d,',
'       ID_EMPRESA r',
'FROM EMPRESA',
'ORDER BY NOME;'))
,p_cSize=>30
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'case_sensitive', 'N',
  'fetch_on_search', 'N',
  'infinite_scroll', 'Y',
  'match_type', 'CONTAINS',
  'min_chars', '0')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9204591644147828)
,p_name=>'P14_GESTOR'
,p_source_data_type=>'NUMBER'
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_imp.id(9203775969147820)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>'Gestor'
,p_source=>'ID_GESTOR'
,p_display_as=>'NATIVE_POPUP_LOV'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT c.NOME_COMPLETO d,',
'       c.ID_COLABORADOR r',
'FROM COLABORADOR c',
'JOIN CARGO cg',
'  ON cg.ID_CARGO = c.ID_CARGO',
'WHERE cg.NOME = ''Gestor''',
'ORDER BY c.NOME_COMPLETO;'))
,p_lov_display_null=>'YES'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_lov_display_extra=>'YES'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'case_sensitive', 'N',
  'display_as', 'POPUP',
  'fetch_on_search', 'N',
  'initial_fetch', 'FIRST_ROWSET',
  'manual_entry', 'N',
  'match_type', 'CONTAINS',
  'min_chars', '0')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9202094467147803)
,p_name=>'P14_ID_COLABORADOR'
,p_source_data_type=>'NUMBER'
,p_is_primary_key=>true
,p_is_query_only=>true
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_source=>'ID_COLABORADOR'
,p_display_as=>'NATIVE_HIDDEN'
,p_is_persistent=>'N'
,p_protection_level=>'S'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'value_protected', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9203940985147822)
,p_name=>'P14_LOGIN'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9203107063147814)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>'Login Corporativo'
,p_source=>'LOGIN_APEX'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_cMaxlength=>255
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'disabled', 'N',
  'submit_when_enter_pressed', 'N',
  'subtype', 'TEXT',
  'trim_spaces', 'BOTH')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9206092922147843)
,p_name=>'P14_NOME_COMPLETO'
,p_source_data_type=>'VARCHAR2'
,p_is_required=>true
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9203775969147820)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>'Nome Completo'
,p_source=>'NOME_COMPLETO'
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
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9206206572147845)
,p_name=>'P14_PRIMEIRO_NOME'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_imp.id(9203775969147820)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>'Primeiro Nome'
,p_source=>'PRIMEIRO_NOME'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_cMaxlength=>30
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'disabled', 'N',
  'submit_when_enter_pressed', 'N',
  'subtype', 'TEXT',
  'trim_spaces', 'BOTH')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9203309990147816)
,p_name=>'P14_SENHA'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(9203107063147814)
,p_prompt=>'Senha'
,p_source_type=>'ALWAYS_NULL'
,p_display_as=>'NATIVE_PASSWORD'
,p_cSize=>30
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'submit_when_enter_pressed', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9202801463147811)
,p_name=>'P14_STATUS'
,p_data_type=>'BOOLEAN'
,p_source_data_type=>'BOOLEAN'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_imp.id(9204691233147829)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>'Status'
,p_source=>'STATUS'
,p_display_as=>'NATIVE_YES_NO'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'use_defaults', 'Y')).to_clob
);
wwv_flow_imp_page.create_page_item(
 p_id=>wwv_flow_imp.id(9206353821147846)
,p_name=>'P14_ULTIMO_NOME'
,p_source_data_type=>'VARCHAR2'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_imp.id(9203775969147820)
,p_item_source_plug_id=>wwv_flow_imp.id(9201806955147801)
,p_prompt=>unistr('\00DAltimo Nome')
,p_source=>'ULTIMO_NOME'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_cMaxlength=>30
,p_begin_on_new_line=>'N'
,p_field_template=>1610598304472262251
,p_item_template_options=>'#DEFAULT#'
,p_is_persistent=>'N'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'disabled', 'N',
  'submit_when_enter_pressed', 'N',
  'subtype', 'TEXT',
  'trim_spaces', 'BOTH')).to_clob
);
wwv_flow_imp_page.create_page_validation(
 p_id=>wwv_flow_imp.id(9740626597646701)
,p_validation_name=>unistr('Validar Confirma\00E7\00E3o de Senha')
,p_static_id=>unistr('validar-confirma\00E7\00E3o-de-senha')
,p_validation_sequence=>10
,p_validation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    RETURN :P14_SENHA = :P14_CONFIRMAR_SENHA;',
'END;'))
,p_validation2=>'PLSQL'
,p_validation_type=>'FUNC_BODY_RETURNING_BOOLEAN'
,p_error_message=>unistr('A confirma\00E7\00E3o de senha n\00E3o corresponde \00E0 senha informada.')
,p_always_execute=>'Y'
,p_associated_item=>wwv_flow_imp.id(9203416854147817)
,p_error_display_location=>'INLINE_WITH_FIELD_AND_NOTIFICATION'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(9741106205646706)
,p_name=>unistr('Desabilitar campos caso a empresa n\00E3o tenha sido selecionada')
,p_static_id=>'new'
,p_event_sequence=>10
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P14_EMPRESA'
,p_condition_element=>'P14_EMPRESA'
,p_triggering_condition_type=>'NOT_NULL'
,p_bind_type=>'bind'
,p_execution_type=>'IMMEDIATE'
,p_bind_event_type=>'change'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(9741365138646708)
,p_event_id=>wwv_flow_imp.id(9741106205646706)
,p_event_result=>'FALSE'
,p_action_sequence=>30
,p_execute_on_page_init=>'Y'
,p_name=>unistr('Campos que ser\00E3o desabilitados')
,p_static_id=>unistr('campos-que-ser\00E3o-desabilitados')
,p_action=>'NATIVE_DISABLE'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P14_DEPARTAMENTO,P14_CARGO,P14_GESTOR'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(9741449618646709)
,p_event_id=>wwv_flow_imp.id(9741106205646706)
,p_event_result=>'TRUE'
,p_action_sequence=>20
,p_execute_on_page_init=>'Y'
,p_name=>unistr('Campos que v\00E3o estar habilitados')
,p_static_id=>unistr('campos-que-v\00E3o-estar-habilitados')
,p_action=>'NATIVE_ENABLE'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P14_DEPARTAMENTO,P14_CARGO,P14_GESTOR'
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(9205761285147840)
,p_process_sequence=>20
,p_process_point=>'ON_SUBMIT_BEFORE_COMPUTATION'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>unistr('Criar usu\00E1rio APEX')
,p_static_id=>'criar-usuario-apex'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'BEGIN',
'    APEX_UTIL.CREATE_USER(',
'        p_user_name                    => :P14_LOGIN,',
'        p_email_address                => :P14_EMAIL,',
'        p_web_password                 => :P14_SENHA,',
'        p_first_name                   => :P14_PRIMEIRO_NOME,',
'        p_last_name                    => :P14_ULTIMO_NOME,',
'        p_change_password_on_first_use => ''N''',
'    );',
'',
'EXCEPTION',
'    WHEN OTHERS THEN',
'        raise_application_error(',
'            -20000,',
'            SQLERRM || CHR(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE',
'        );',
'END;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_success_message=>'Colaborador cadastrado com sucesso!'
,p_internal_uid=>9205761285147840
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(9201933922147802)
,p_process_sequence=>10
,p_process_point=>'BEFORE_HEADER'
,p_region_id=>wwv_flow_imp.id(9201806955147801)
,p_process_type=>'NATIVE_FORM_INIT'
,p_process_name=>'Inicializar o form Cadastros'
,p_static_id=>'inicializar-o-form-cadastros'
,p_internal_uid=>9201933922147802
);
wwv_flow_imp_page.create_page_process(
 p_id=>wwv_flow_imp.id(9205500288147838)
,p_process_sequence=>10
,p_process_point=>'ON_SUBMIT_BEFORE_COMPUTATION'
,p_region_id=>wwv_flow_imp.id(9201806955147801)
,p_process_type=>'NATIVE_FORM_DML'
,p_process_name=>'Salvar Dados Colaborador'
,p_static_id=>'salvar-dados-colaborador'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'lock_row', 'Y',
  'prevent_lost_updates', 'Y',
  'return_primary_keys_after_insert', 'Y',
  'target_type', 'REGION_SOURCE')).to_clob
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_success_message=>'Colaborador cadastrado com sucesso!'
,p_internal_uid=>9205500288147838
);
wwv_flow_imp.component_end;
end;
/

prompt --application/shared_components/logic/application_processes/g_nome_usuario
begin
--   Manifest
--     APPLICATION PROCESS: G_NOME_USUARIO
--   Manifest End
wwv_flow_imp.component_begin (
 p_version_yyyy_mm_dd=>'2026.03.30'
,p_release=>'26.1.2'
,p_default_workspace_id=>10008945716225088
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'WKSP_CORLIXHUB'
);
wwv_flow_imp_shared.create_flow_process(
 p_id=>wwv_flow_imp.id(10276379495180816)
,p_process_sequence=>1
,p_process_point=>'BEFORE_HEADER'
,p_process_name=>'G_NOME_USUARIO'
,p_static_id=>'g-nome-usuario'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'begin',
'    select initcap(first_name || '' '' || last_name)',
'    into :G_NOME_USUARIO',
'    from apex_workspace_apex_users',
'    where upper(user_name) = upper(:APP_USER);',
'',
'exception',
'    when no_data_found then',
'        :G_NOME_USUARIO := :APP_USER;',
'end;'))
,p_process_clob_language=>'PLSQL'
,p_version_scn=>'47036308792541'
);
wwv_flow_imp.component_end;
end;
/

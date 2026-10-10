-- -----------------------------------------------------------------------------
-- Corlix Hub — diagnóstico (e ajuste opcional) dos timeouts de sessão do APEX
-- Contexto: docs/ai-context/09-erro-400-cookies.md, §8.
--
-- Como usar: no Autonomous, Database Actions > SQL, conectado como ADMIN
-- (o pacote APEX_INSTANCE_ADMIN exige privilégio de administrador da instância).
-- Rode um bloco por vez.
--
-- Parâmetros (em segundos). Valor nulo = herda o nível de cima
-- (workspace -> instância -> padrão do APEX: 3600 s de inatividade, 28800 s de duração).
--   MAX_SESSION_IDLE_SEC   : tempo máximo sem nenhuma requisição
--   MAX_SESSION_LENGTH_SEC : duração máxima da sessão, mesmo com uso contínuo
-- -----------------------------------------------------------------------------

-- 1) Diagnóstico: valores da instância e do workspace
select 'INSTANCIA' as nivel,
       apex_instance_admin.get_parameter('MAX_SESSION_IDLE_SEC')   as max_session_idle_sec,
       apex_instance_admin.get_parameter('MAX_SESSION_LENGTH_SEC') as max_session_length_sec
  from dual
union all
select 'WORKSPACE WKSP_CORLIXHUB',
       apex_instance_admin.get_workspace_parameter('WKSP_CORLIXHUB', 'MAX_SESSION_IDLE_SEC'),
       apex_instance_admin.get_workspace_parameter('WKSP_CORLIXHUB', 'MAX_SESSION_LENGTH_SEC')
  from dual;

-- 2) Ajuste opcional, só no workspace de desenvolvimento: 4 h de inatividade e 12 h de duração.
--    Vale para o Builder e para as apps do workspace que não definem timeout próprio.
--    Para voltar ao padrão, passe p_value => null.
-- begin
--     apex_instance_admin.set_workspace_parameter(
--         p_workspace => 'WKSP_CORLIXHUB',
--         p_parameter => 'MAX_SESSION_IDLE_SEC',
--         p_value     => '14400');
--     apex_instance_admin.set_workspace_parameter(
--         p_workspace => 'WKSP_CORLIXHUB',
--         p_parameter => 'MAX_SESSION_LENGTH_SEC',
--         p_value     => '43200');
--     commit;
-- end;
-- /

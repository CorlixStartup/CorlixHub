prompt --application/pages/page_00001
begin
--   Manifest
--     PAGE: 00001
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
 p_id=>1
,p_name=>'Home'
,p_alias=>'HOME'
,p_step_title=>'CorlixHub'
,p_autocomplete_on_off=>'OFF'
,p_inline_css=>wwv_flow_string.join(wwv_flow_t_varchar2(
unistr('/*CONFIGURA\00C7\00C3O PADR\00C3O P\00C1GINA*/'),
'',
'.t-Body-content {',
'--ut-body-content-padding-y: 1.5rem;',
'}',
'',
unistr('/*CARD PADR\00C3O*/'),
'',
'    .card-default {',
'        margin-top: 1rem; ',
'        background-color: #FFFFFF;  ',
'        border-radius: 12px;',
'        padding: 10px 0px 20px 0px;',
'        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06);',
'    }',
'',
'    .card-default h1 {',
'        font-family: -apple-system, "Segoe UI", Arial, sans-serif;',
'        padding-left: 1rem;',
'        font-size: 2rem;',
'        font-weight: 700;',
'        color: #1A1A1A;',
'        margin: 0 0 8px 0;',
'    }',
'',
'    .card-default h2 {',
'        font-family: -apple-system, "Segoe UI", Arial, sans-serif;',
'        font-size: 1.4rem;',
'        font-weight: 700;',
'        color: #1A1A1A;',
'        margin: 0;',
'    }',
'',
'    .card-default h3 {',
'        text-transform: uppercase;',
'        font-family: -apple-system, "Sora", Segoe UI, sans-serif;',
'        padding-left: 1rem;',
'        font-size: 1.4rem;',
'        font-weight: 700;',
'        color: #1A1A1A;',
'        margin: 0;',
'    }    ',
'    ',
'    .t-Cards {',
'        gap: 24px;',
'    }',
'',
'    .a-CardView-item {',
'        display: flex;',
'        flex-direction: column;',
'        border-radius:14px;',
'        overflow:hidden;',
'        box-shadow:0 3px 12px rgba(0,0,0,.08);',
'        transition:.2s;',
'    }',
'',
'    .a-CardView-item:hover{',
'        transform:translateY(-3px);',
'    }',
'',
'    .a-CardView-media img{',
'        width:100%;',
'        height:260px;',
'        object-fit:cover;',
'        display: flex;',
'    }',
'',
'    .a-CardView-body{',
'        padding:0 0 1rem 2rem;',
'    }',
'',
'    .a-CardView-title{',
'        font-size:1.5rem;',
'        font-weight:700;',
'    }',
'',
'    .a-CardView-subTitle{',
'        color:#888;',
'        font-size:12px;',
'    }',
'',
'    .a-CardView-desc{',
'        margin-top:15px;',
'        line-height:1.7;',
'        color:#666;',
'    }',
'',
'/*BOAS VINDAS*/',
'',
'    .card-boas-vindas {',
'        margin: 0;',
'    }',
'    ',
'    .card-boas-vindas p {',
'        font-size: 1.1rem;',
'        padding-left: 1rem;',
'        color: #6B7280;',
'        margin: 0;',
'        line-height: 1.5;',
'    }',
'',
'    .card-boas-vindas .link-empresa {',
'        color: #2563EB;',
'        text-decoration: none;',
'        font-weight: 500;',
'    }',
'',
'    .card-boas-vindas .link-empresa:hover {',
'        text-decoration: underline;',
'    }',
'',
'/*COMUNICAODS*/',
'',
'    .card-comunicados-oficiais {',
'        background-color: rgba(255, 255, 255, 0);',
'        box-shadow: none;',
'    }',
'',
'    .lista-de-comunicados{',
'        margin-top: 1rem;',
'    }',
'',
'    .titulo-lista-de-comunicados{',
'        text-transform: lowercase;',
'        font-family: -apple-system, "Sora", Segoe UI, sans-serif;',
'    }',
'',
'    .emitir-comunicado {',
'        display: flex;',
'        justify-content: flex-end;',
'    }',
'',
'    .botao-emitir-comunicado{',
'        margin-left: auto;',
'        margin-right: 10px;',
'    }',
'',
'    .imagem-capa-comunicado {',
'        width: 100%;',
'        display: block;',
'        margin: 0;',
'    }',
'',
'    .imagem-capa-comunicado img {',
'        width: 100%;',
'        height: 100%;        /* ajuste a altura que quiser pro "banner" */',
'        object-fit: cover;    /* preenche sem esticar/distorcer */',
'        display: block;',
unistr('        border-radius: 14px 0 0 0;  /* cantos arredondados s\00F3 em cima */'),
'    }',
'',
'/*MEU GESTOR*/',
'',
'    .card-meu-gestor {',
'        margin: 0;',
'    }',
'',
unistr('/*LINKS R\00C1PIDOS*/'),
'',
' .links-rapidos-card {',
'  background-color: #fff;',
'  border-radius: 10px;',
'  padding: 15px;',
'  font-family: ''Segoe UI'', sans-serif;',
'}',
'',
'.links-rapidos-card h3 {',
'  font-weight: bold;',
'  margin-bottom: 15px;',
'  color: #333;',
'}',
'',
'.link-item {',
'  display: flex;',
unistr('  align-items: center; /* \00CDcone e texto alinhados verticalmente */'),
'  justify-content: space-between;',
'  background-color: #f8f9fc;',
'  border-radius: 8px;',
'  padding: 10px 12px;',
'  margin-bottom: 12px;',
'  cursor: pointer;',
'  transition: all 0.2s ease;',
'}',
'',
'.link-item:hover {',
'  background-color: #eef2ff;',
'  transform: scale(1.01); /* leve efeito de zoom */',
'}',
'',
'.link-item .icon {',
'  display: flex;',
'  align-items: center;',
'  margin-right: 10px;',
'}',
'',
'.link-item svg {',
'  vertical-align: middle;',
'}',
'',
'.link-item .text {',
'  flex: 1;',
'  font-weight: 500;',
'  color: #000;',
'  display: flex;',
'  align-items: center; /* Centraliza o texto verticalmente */',
'}',
'',
'.link-item .arrow {',
'  color: #4f46e5;',
'  font-size: 1em;',
'  margin-left: 8px;',
'}',
'',
'/* =====================',
'   CARD ANIVERSARIANTES',
'   ===================== */',
'',
unistr('/* Container Principal (Regi\00E3o Pai) */'),
'.card-aniversariantes {',
'  background: #ffffff !important;',
'  border-radius: 10px !important;',
'  padding: 15px !important;',
'  font-family: ''Segoe UI'', sans-serif !important;',
'  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06) !important;',
'  max-width: 100% !important;',
'  border: none !important;',
'}',
'',
unistr('/* Cabe\00E7alho Customizado */'),
'.card-aniversariantes .cabecalho {',
'  display: flex !important;',
'  justify-content: space-between !important;',
'  align-items: center !important;',
'  font-weight: 700 !important;',
'  color: #222222 !important;',
'  margin-bottom: 16px !important;',
'  font-size: 16px !important;',
'}',
'',
unistr('/* Badge do M\00EAs Corrente */'),
'.card-aniversariantes .mes {',
'  background: #e8e6ff !important;',
'  color: #4f46e5 !important;',
'  font-size: 13px !important;',
'  padding: 4px 10px !important;',
'  border-radius: 12px !important;',
'  font-weight: 600 !important;',
'}',
'',
unistr('/* For\00E7ar os cart\00F5es do APEX a se comportarem como lista vertical */'),
'.card-aniversariantes .t-Cards {',
'  display: flex !important;',
'  flex-direction: column !important;',
'  gap: 0 !important;',
'  padding: 0 !important;',
'  margin: 0 !important;',
'}',
'',
'/* Cada item/linha de aniversariante */',
'.card-aniversariantes .t-Cards-item {',
'  width: 100% !important;',
'  max-width: 100% !important;',
'  margin: 0 !important;',
'  padding: 0 !important;',
'  border: none !important;',
'  box-shadow: none !important;',
'  background: transparent !important;',
'}',
'',
'/* Estrutura interna do Card (Foto + Texto) */',
'.card-aniversariantes .t-Card-wrap {',
'  display: flex !important;',
'  flex-direction: row !important; /* Foto na esquerda, texto na direita */',
'  align-items: center !important;',
'  justify-content: flex-start !important;',
'  gap: 14px !important;',
'  padding: 12px 0 !important;',
'  border-bottom: 1px solid #f0f0f0 !important;',
'  background: transparent !important;',
'  box-shadow: none !important;',
'  border-radius: 0 !important;',
'}',
'',
unistr('/* Remove a linha divis\00F3ria do \00FAltimo aniversariante da lista */'),
'.card-aniversariantes .t-Cards-item:last-child .t-Card-wrap {',
'  border-bottom: none !important;',
'}',
'',
unistr('/* Foto do Aniversariante \2014 Circular e Pequena */'),
'.card-aniversariantes .t-Card-media,',
'.card-aniversariantes .t-Card-media img,',
'.card-aniversariantes .t-Card-image {',
'  width: 52px !important;',
'  height: 52px !important;',
'  min-width: 52px !important;',
'  max-width: 52px !important;',
'  border-radius: 50% !important; /* Deixa circular */',
unistr('  object-fit: cover !important;  /* N\00E3o distorce a imagem */'),
'  border: 2px solid #f3f3f3 !important;',
'  box-shadow: 0 0 4px rgba(0, 0, 0, 0.05) !important;',
'  margin: 0 !important;',
'  padding: 0 !important;',
'}',
'',
'/* Container do Bloco de Texto */',
'.card-aniversariantes .t-Card-body {',
'  padding: 0 !important;',
'  display: flex !important;',
'  flex-direction: column !important;',
'  justify-content: center !important;',
'  background: transparent !important;',
'}',
'',
'/* Nome do Colaborador */',
'.card-aniversariantes .t-Card-title {',
'  font-weight: 600 !important;',
'  color: #222222 !important;',
'  font-size: 15px !important;',
'  line-height: 1.2 !important;',
'  margin: 0 0 4px 0 !important;',
'}',
'',
unistr('/* Data / Descri\00E7\00E3o do Anivers\00E1rio */'),
'.card-aniversariantes .t-Card-subtitle {',
'  font-size: 13px !important;',
'  color: #666666 !important;',
'  margin: 0 !important;',
'  padding: 0 !important;',
'}',
'',
unistr('/* Rodap\00E9 / Bloco de A\00E7\00F5es do Card */'),
'.card-aniversariantes .t-Card-actions {',
'  padding: 0 !important;',
'  margin-top: 14px !important;',
'  border: none !important;',
'  background: transparent !important;',
'  display: flex !important;',
unistr('  justify-content: center !important; /* Centraliza o bot\00E3o */'),
'}',
'',
unistr('/* Estiliza\00E7\00E3o do Bot\00E3o "Ver todos" para virar Link Fluido */'),
'.card-aniversariantes .t-Card-actions .t-Button {',
'  color: #4f46e5 !important;',
'  font-weight: 600 !important;',
'  background: transparent !important;',
'  border: none !important;',
'  box-shadow: none !important;',
'  text-decoration: none !important;',
'  font-size: 14px !important;',
'  cursor: pointer !important;',
'  transition: color 0.2s ease !important;',
'}',
'',
'.card-aniversariantes .t-Card-actions .t-Button:hover {',
'  color: #3730a3 !important;',
'}',
'',
unistr('/* Remove absolutamente todas as bordas, fundos e sombras de qualquer Card nesta p\00E1gina */'),
'.t-Cards, .t-Cards-item, .t-Card, .t-Card-wrap {',
'    border: none !important;',
'    box-shadow: none !important;',
'    background: transparent !important;',
'    background-color: transparent !important;',
'}',
'',
unistr('/* For\00E7a qualquer bloco de cart\00E3o interno a perder a moldura branca/cinza */'),
'.card-aniversariantes .t-Cards-item,',
'.card-aniversariantes .t-Card,',
'.card-aniversariantes .t-Card-wrap {',
'    border: none !important;',
'    border-color: transparent !important;',
'    box-shadow: none !important;',
'    background: transparent !important;',
'    background-color: transparent !important;',
'}',
'',
'',
'/* ======================================',
'   RESPONSIVIDADE (CELULARES E TABLETS)',
'   ====================================== */',
'@media (max-width: 768px) {',
'  .card-aniversariantes .t-Card-media,',
'  .card-aniversariantes .t-Card-media img,',
'  .card-aniversariantes .t-Card-image {',
'    width: 44px !important;',
'    height: 44px !important;',
'    min-width: 44px !important;',
'  }',
'  .card-aniversariantes .t-Card-title { font-size: 14px !important; }',
'  .card-aniversariantes .t-Card-subtitle { font-size: 12px !important; }',
'}',
'',
'@media (max-width: 480px) {',
'  .card-aniversariantes .t-Card-media,',
'  .card-aniversariantes .t-Card-media img,',
'  .card-aniversariantes .t-Card-image {',
'    width: 38px !important;',
'    height: 38px !important;',
'    min-width: 38px !important;',
'  }',
'  .card-aniversariantes .t-Card-title { font-size: 13px !important; }',
'  .card-aniversariantes .t-Card-subtitle { font-size: 11px !important; }',
'}',
'',
unistr('/* Limpa o fundo cinza e centraliza o bot\00E3o quando ele est\00E1 no slot Below Region */'),
'#btn-ver-todos, ',
'button#btn-ver-todos,',
'.t-Region-buttons #btn-ver-todos {',
'    background: transparent !important;',
'    background-color: transparent !important;',
'    border: none !important;',
'    box-shadow: none !important;',
'    color: #4f46e5 !important;',
'    font-weight: 600 !important;',
'    width: 100% !important;',
'    text-align: center !important;',
'    display: block !important;',
'    padding: 12px 0 !important;',
'    margin: 15px auto 0 auto !important;',
'}',
'',
'#btn-ver-todos .t-Button-label {',
'    width: 100% !important;',
'    text-align: center !important;',
'    display: block !important;',
'}',
'',
''))
,p_step_template=>4073832297226169690
,p_page_template_options=>'#DEFAULT#'
,p_protection_level=>'C'
,p_page_component_map=>'13'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(9289454531503202)
,p_plug_name=>'emitir_comunicado'
,p_static_id=>'botao-emitir-comunicado'
,p_parent_plug_id=>wwv_flow_imp.id(10212053712327025)
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4502917002193490937
,p_plug_display_sequence=>20
,p_plug_grid_column_css_classes=>'emitir-comunicado'
,p_plug_display_point=>'SUB_REGIONS'
,p_plug_item_display_point=>'ABOVE'
,p_location=>null
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(10213930955327044)
,p_plug_name=>'card_aniversariantes'
,p_static_id=>'card-aniversariantes'
,p_parent_plug_id=>wwv_flow_imp.id(10213727731327042)
,p_region_template_options=>'#DEFAULT#:t-Region--noPadding:t-Region--removeHeader js-removeLandmark:t-Region--noBorder:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>50
,p_plug_grid_column_css_classes=>'card-default card-aniversariantes'
,p_plug_item_display_point=>'ABOVE'
,p_location=>null
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div style="display: flex; justify-content: space-between; align-items: center; width: 100%; padding: 5px 0 15px 0; font-family: ''Segoe UI'', sans-serif;">',
unistr('    <!-- T\00EDtulo Principal -->'),
'    <span style="font-size: 16px; font-weight: 700; color: #111827; letter-spacing: 0.5px;">ANIVERSARIANTES</span>',
'    ',
unistr('    <!-- Bloco do Lado Direito: Link + Badge do M\00EAs -->'),
'    <div style="display: flex; align-items: center; gap: 14px;">',
'        <!-- Link seguro para abrir o Popup Modal via jQuery -->',
'        <a href="javascript:$(''#modal-aniversariantes'').dialog(''open'');" style="color: #4f46e5; font-size: 13px; font-weight: 600; text-decoration: none; cursor: pointer;">Ver Todos</a>',
'        ',
unistr('        <!-- Badge do M\00EAs din\00E2mico (mantendo seu ID original intacto) -->'),
'        <div id="badge-mes" style="background: #e8e6ff; color: #4f46e5; font-size: 13px; padding: 4px 12px; border-radius: 12px; font-weight: 600; flex-shrink: 0; display: none;">',
'        </div>',
'    </div>',
'</div>',
''))
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(10210251712327007)
,p_plug_name=>'card_boas_vindas'
,p_static_id=>'card-boas-vindas'
,p_parent_plug_id=>wwv_flow_imp.id(10213652689327041)
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4502917002193490937
,p_plug_display_sequence=>10
,p_plug_grid_column_css_classes=>'card-default card-boas-vindas'
,p_plug_display_point=>'SUB_REGIONS'
,p_plug_item_display_point=>'ABOVE'
,p_location=>null
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
unistr('<h1>Bem-vindo, &G_NOME_USUARIO.! \D83D\DC4B</h1>'),
'  <p>Sua jornada de carreira na <a href="#" class="link-empresa">EMPRESA</a> ',
unistr('     est\00E1 indo muito bem. Veja o que temos para hoje.</p>')))
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(10212053712327025)
,p_plug_name=>'card_comunicados_oficiais'
,p_static_id=>'card-comunicados-oficiais'
,p_title=>'Comunicados Oficiais'
,p_parent_plug_id=>wwv_flow_imp.id(10213652689327041)
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4502917002193490937
,p_plug_display_sequence=>20
,p_plug_grid_column_css_classes=>'card-default card-comunicados-oficiais'
,p_plug_display_point=>'SUB_REGIONS'
,p_plug_item_display_point=>'ABOVE'
,p_location=>null
,p_plug_source=>'<h2> Comunicados Oficiais </h2>'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(10213522252327040)
,p_plug_name=>'card_meu_gestor'
,p_static_id=>'card-meu-gestor'
,p_title=>'Meu Gestor'
,p_parent_plug_id=>wwv_flow_imp.id(10213727731327042)
,p_region_css_classes=>'card-default card-meu-gestor'
,p_region_template_options=>'#DEFAULT#:t-CardsRegion--hideHeader js-addHiddenHeadingRoleDesc'
,p_plug_template=>2074200852440250129
,p_plug_display_sequence=>10
,p_plug_item_display_point=>'ABOVE'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT ',
'    CG.NOME AS NOME_CARGO,',
'    G.PRIMEIRO_NOME || '' '' || G.ULTIMO_NOME AS NOME_GESTOR,',
'    CASE',
'        WHEN G.FOTO_URL IS NULL',
'             OR G.FOTO_URL = ''#APP_FILES#default-user.jpeg'' THEN',
'            ''#APP_FILES#default-user.jpeg''',
'        ELSE',
'            ''#APP_FILES#fotos/'' || G.FOTO_URL',
'    END AS FOTO_GESTOR',
'FROM COLABORADOR C',
'JOIN COLABORADOR G',
'    ON G.ID_COLABORADOR = C.ID_GESTOR',
'JOIN CARGO CG',
'    ON CG.ID_CARGO = G.ID_CARGO',
'WHERE C.LOGIN_APEX = :APP_USER;'))
,p_lazy_loading=>false
,p_plug_source_type=>'NATIVE_CARDS'
,p_plug_query_num_rows_type=>'SCROLL'
,p_show_total_row_count=>false
,p_plug_header=>'<h3>MEU GESTOR</h3>'
,p_plug_footer=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div style="display:flex;flex-direction:row;align-items:center;gap:8px;justify-content:center;">',
'    <a href="#" style="background-color:#F6F6F8;padding:8px 55px;border-radius:8px;color:#111318;font-size:14px;font-weight:bold;">Chat</a>',
'    <a href="#" style="background-color:#F6F6F8;padding:8px 55px;border-radius:8px;color:#111318;font-size:14px;font-weight:bold;">E-mail</a>',
'</div>'))
);
wwv_flow_imp_page.create_card(
 p_id=>wwv_flow_imp.id(9206723220147850)
,p_region_id=>wwv_flow_imp.id(10213522252327040)
,p_layout_type=>'GRID'
,p_title_adv_formatting=>true
,p_title_html_expr=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div style="display:flex;flex-direction:row;align-items:center;gap:16px;margin-bottom:0;">',
'    <img src="&FOTO_GESTOR." style="width: 52px; height: 52px; border-radius: 50%; object-fit: cover; border: 2px solid #f3f3f3; flex-shrink: 0;" onerror="this.onerror=null; this.src=''https://dicebear.com'';">',
'',
'    <div style="display:flex;flex-direction:column;">',
'        <span style="font-size:14px;font-weight:bold;color:#111318;margin-bottom:8px;">&NOME_GESTOR.</span>',
'        <span style="font-size:12px;color:#636F88;">&NOME_CARGO.</span>',
'    </div>',
'</div>'))
,p_sub_title_adv_formatting=>false
,p_body_adv_formatting=>false
,p_second_body_adv_formatting=>false
,p_media_adv_formatting=>false
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(10213727731327042)
,p_plug_name=>'container-conteudo-diversos'
,p_static_id=>'container-conteudo-diversos'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4502917002193490937
,p_plug_display_sequence=>40
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>4
,p_plug_grid_column_css_classes=>'container-conteudo-diversos'
,p_plug_item_display_point=>'ABOVE'
,p_location=>null
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(10213652689327041)
,p_plug_name=>'container-conteudo-principal'
,p_static_id=>'container-conteudo-principal'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4502917002193490937
,p_plug_display_sequence=>10
,p_plug_grid_column_span=>8
,p_plug_grid_column_css_classes=>'.container-conteudo-principal'
,p_plug_item_display_point=>'ABOVE'
,p_location=>null
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(10212189338327026)
,p_plug_name=>'lista_de_comunicados'
,p_static_id=>'id-lista-de-comunicados'
,p_parent_plug_id=>wwv_flow_imp.id(10212053712327025)
,p_region_template_options=>'#DEFAULT#:t-CardsRegion--hideHeader js-addHiddenHeadingRoleDesc'
,p_plug_template=>wwv_flow_imp.id(10205076729845143)
,p_plug_display_sequence=>10
,p_plug_grid_column_css_classes=>'lista-de-comunicados'
,p_plug_display_point=>'SUB_REGIONS'
,p_plug_item_display_point=>'ABOVE'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT',
'  ID_COMUNICADO,',
'  TITULO,',
'  DBMS_LOB.SUBSTR(CONTEUDO, 250, 1) CONTEUDO,',
'  DATA_PUBLICACAO,',
'  IMAGEM,',
'  MIME_TYPE,',
'  NOME_ARQUIVO',
'FROM COMUNICADO',
'ORDER BY DATA_PUBLICACAO DESC'))
,p_lazy_loading=>false
,p_plug_source_type=>'NATIVE_CARDS'
,p_plug_query_num_rows_type=>'SCROLL'
,p_show_total_row_count=>false
);
wwv_flow_imp_page.create_card(
 p_id=>wwv_flow_imp.id(10213244379327037)
,p_region_id=>wwv_flow_imp.id(10212189338327026)
,p_layout_type=>'ROW'
,p_title_adv_formatting=>false
,p_title_column_name=>'TITULO'
,p_title_css_classes=>'titulo-lista-de-comunicados'
,p_sub_title_adv_formatting=>false
,p_body_adv_formatting=>false
,p_body_column_name=>'CONTEUDO'
,p_second_body_adv_formatting=>false
,p_second_body_column_name=>'DATA_PUBLICACAO'
,p_media_adv_formatting=>false
,p_media_source_type=>'BLOB'
,p_media_blob_column_name=>'IMAGEM'
,p_media_display_position=>'FIRST'
,p_media_sizing=>'FIT'
,p_media_css_classes=>'imagem-capa-comunicado'
,p_pk1_column_name=>'ID_COMUNICADO'
,p_mime_type_column_name=>'MIME_TYPE'
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(10213837105327043)
,p_plug_name=>'card_links_rapidos'
,p_static_id=>'links-rapidos'
,p_parent_plug_id=>wwv_flow_imp.id(10213727731327042)
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>4502917002193490937
,p_plug_display_sequence=>40
,p_plug_grid_column_css_classes=>'card-default card-links-rapidos'
,p_plug_item_display_point=>'ABOVE'
,p_location=>null
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div class="links-rapidos-card">',
unistr('  <h3>Links R\00E1pidos</h3>'),
'',
'  <div class="link-item" onclick="apex.navigation.redirect(''f?p=&APP_ID.:5:&SESSION.'')">',
'    <span class="icon">',
unistr('      <!-- \00CDcone Holerite -->'),
'      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18">',
'        <rect x="1" y="3" width="16" height="12" rx="2" ry="2" stroke="#4f46e5" stroke-width="1.5" fill="none"/>',
'        <circle cx="9" cy="9" r="2.5" fill="#4f46e5"/>',
'        <line x1="1" y1="7" x2="17" y2="7" stroke="#4f46e5" stroke-width="1"/>',
'        <line x1="1" y1="11" x2="17" y2="11" stroke="#4f46e5" stroke-width="1"/>',
'      </svg>',
'    </span>',
'    <span class="text">Holerite Digital</span>',
'    <span class="arrow"><i class="fa fa-chevron-right"></i></span>',
'  </div>',
'',
'  <div class="link-item" onclick="apex.navigation.redirect(''f?p=&APP_ID.:6:&SESSION.'')">',
'    <span class="icon">',
unistr('      <!-- \00CDcone Rel\00F3gio -->'),
'      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18">',
'        <circle cx="9" cy="9" r="7" stroke="#4f46e5" stroke-width="1.5" fill="none"/>',
'        <path d="M9 5v4l3 2" stroke="#4f46e5" stroke-width="1.5" fill="none"/>',
'      </svg>',
'    </span>',
unistr('    <span class="text">Ponto Eletr\00F4nico</span>'),
'    <span class="arrow"><i class="fa fa-chevron-right"></i></span>',
'  </div>',
'',
'  <div class="link-item" onclick="apex.navigation.redirect(''f?p=&APP_ID.:7:&SESSION.'')">',
'    <span class="icon">',
unistr('      <!-- \00CDcone Suporte -->'),
'      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18">',
'        <path d="M9 2a7 7 0 0 0-7 7v3a1.5 1.5 0 0 0 1.5 1.5H5v-4H3v-1a6 6 0 0 1 12 0v1h-2v4h1.5A1.5 1.5 0 0 0 16 12V9a7 7 0 0 0-7-7z" fill="#4f46e5"/>',
'      </svg>',
'    </span>',
'    <span class="text">Suporte TI</span>',
'    <span class="arrow"><i class="fa fa-chevron-right"></i></span>',
'  </div>',
'</div>',
''))
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'expand_shortcuts', 'N',
  'output_as', 'HTML')).to_clob
);
wwv_flow_imp_page.create_page_plug(
 p_id=>wwv_flow_imp.id(9374042765951620)
,p_plug_name=>'lista_aniversariantes'
,p_static_id=>'lista-aniversariantes'
,p_parent_plug_id=>wwv_flow_imp.id(10213930955327044)
,p_region_template_options=>'#DEFAULT#:t-Region--noPadding:t-Region--removeHeader js-removeLandmark:t-Region--noUI:t-Region--scrollBody'
,p_plug_template=>4073835273271169698
,p_plug_display_sequence=>10
,p_plug_display_point=>'SUB_REGIONS'
,p_plug_item_display_point=>'ABOVE'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT',
'    ID_COLABORADOR,',
'    NOME_COMPLETO,',
'    DATA_DE_NASCIMENTO,',
'',
'    CASE',
'        WHEN FOTO_URL IS NULL',
'             OR FOTO_URL = ''#APP_FILES#default-user.jpeg''',
'        THEN',
'            ''#APP_FILES#default-user.jpeg''',
'        ELSE',
'            ''#APP_FILES#fotos/'' || FOTO_URL',
'    END AS FOTO_URL,',
'',
'    NOME_COMPLETO || '' - '' ||',
'    CASE',
'        WHEN TO_CHAR(DATA_DE_NASCIMENTO, ''MMDD'') = TO_CHAR(SYSDATE, ''MMDD'') THEN',
unistr('            ''Hoje \D83C\DF82'''),
'        WHEN TO_CHAR(DATA_DE_NASCIMENTO, ''MMDD'') = TO_CHAR(SYSDATE + 1, ''MMDD'') THEN',
unistr('            ''Amanh\00E3, '' || TO_CHAR(DATA_DE_NASCIMENTO, ''DD/MM'')'),
'        ELSE',
'            TO_CHAR(DATA_DE_NASCIMENTO, ''DD'') || '' de '' ||',
'            RTRIM(',
'                TO_CHAR(',
'                    DATA_DE_NASCIMENTO,',
'                    ''Month'',',
'                    ''NLS_DATE_LANGUAGE=PORTUGUESE''',
'                )',
'            )',
'    END AS DESCRICAO,',
'',
'    RTRIM(',
'        INITCAP(',
'            TO_CHAR(',
'                SYSDATE,',
'                ''Month'',',
'                ''NLS_DATE_LANGUAGE=PORTUGUESE''',
'            )',
'        )',
'    ) AS MES_CORRENTE',
'',
'FROM COLABORADOR',
'',
'WHERE TO_CHAR(DATA_DE_NASCIMENTO, ''MM'') = TO_CHAR(SYSDATE, ''MM'')',
'',
'ORDER BY EXTRACT(DAY FROM DATA_DE_NASCIMENTO);'))
,p_lazy_loading=>false
,p_plug_source_type=>'NATIVE_CARDS'
,p_plug_query_num_rows_type=>'SCROLL'
,p_show_total_row_count=>false
);
wwv_flow_imp_page.create_card(
 p_id=>wwv_flow_imp.id(9374184510951621)
,p_region_id=>wwv_flow_imp.id(9374042765951620)
,p_layout_type=>'GRID'
,p_title_adv_formatting=>true
,p_title_html_expr=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div style="display: flex; align-items: center; width: 100%; padding: 4px 0; font-family: ''Segoe UI'', sans-serif;">',
'    <div style="display: flex; align-items: center; gap: 14px;">',
unistr('        <!-- Foto Circular com Fallback Autom\00E1tico para Iniciais -->'),
'        <img src="&FOTO_URL." style="width: 52px; height: 52px; border-radius: 50%; object-fit: cover; border: 2px solid #f3f3f3; flex-shrink: 0;" onerror="this.onerror=null; this.src=''https://dicebear.com'';">',
'        ',
'        <div style="display: flex; flex-direction: column; gap: 4px;">',
'            <span style="font-weight: 600; color: #222; font-size: 15px; line-height: 1.2;">&NOME.</span>',
'            <span style="font-size: 13px; color: #666; display: flex; align-items: center; gap: 6px;">',
unistr('                \D83C\DF82 &DESCRICAO.'),
'            </span>',
'        </div>',
'    </div>',
'</div>',
''))
,p_sub_title_adv_formatting=>false
,p_body_adv_formatting=>false
,p_second_body_adv_formatting=>false
,p_media_adv_formatting=>false
);
wwv_flow_imp_page.create_report_region(
 p_id=>wwv_flow_imp.id(9374641660951626)
,p_name=>unistr('Todos os Aniversariantes do M\00EAs')
,p_static_id=>'modal-aniversariantes'
,p_title=>unistr('Todos os Aniversariantes do M\00EAs')
,p_template=>2674150083631647148
,p_display_sequence=>50
,p_region_template_options=>'t-DialogRegion--noPadding:js-modal:js-draggable:js-resizable:js-dialog-size600x400'
,p_component_template_options=>'#DEFAULT#:t-Cards--animColorFill:t-Cards--3cols:t-Cards--basic'
,p_display_point=>'REGION_POSITION_04'
,p_source_type=>'NATIVE_SQL_REPORT'
,p_query_type=>'SQL'
,p_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SELECT ',
'    ID_COLABORADOR,',
'    NOME,',
'    DATA_DE_NASCIMENTO,',
'    ''#APP_FILES#fotos/'' || LOWER(REPLACE(NOME, '' '', ''_'')) || ''.jpg'' AS FOTO_URL,',
'    CASE ',
'        WHEN TO_CHAR(DATA_DE_NASCIMENTO, ''MMDD'') = TO_CHAR(SYSDATE, ''MMDD'') ',
unistr('            THEN ''Hoje \D83C\DF82'''),
'        WHEN TO_CHAR(DATA_DE_NASCIMENTO, ''MMDD'') = TO_CHAR(SYSDATE + 1, ''MMDD'') ',
unistr('            THEN ''Amanh\00E3, '' || TO_CHAR(DATA_DE_NASCIMENTO, ''DD/MM'')'),
'        ELSE TO_CHAR(DATA_DE_NASCIMENTO, ''DD'') || '' de '' || RTRIM(TO_CHAR(DATA_DE_NASCIMENTO, ''Month'', ''NLS_DATE_LANGUAGE=PORTUGUESE''))',
'    END AS DESCRICAO',
'FROM COLABORADOR',
'WHERE TO_CHAR(DATA_DE_NASCIMENTO, ''MM'') = TO_CHAR(SYSDATE, ''MM'')',
'  AND DATA_DE_NASCIMENTO IS NOT NULL',
'ORDER BY TO_NUMBER(TO_CHAR(DATA_DE_NASCIMENTO, ''DD'')) ASC',
''))
,p_ajax_enabled=>'Y'
,p_lazy_loading=>false
,p_query_row_template=>2976458789255810118
,p_query_num_rows=>15
,p_query_options=>'DERIVED_REPORT_COLUMNS'
,p_csv_output=>'N'
,p_prn_output=>'N'
,p_sort_null=>'L'
,p_plug_query_strip_html=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(9375205499951632)
,p_query_column_id=>3
,p_column_alias=>'DATA_DE_NASCIMENTO'
,p_column_display_sequence=>30
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(9375442199951634)
,p_query_column_id=>5
,p_column_alias=>'DESCRICAO'
,p_column_display_sequence=>50
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(9375365897951633)
,p_query_column_id=>4
,p_column_alias=>'FOTO_URL'
,p_column_display_sequence=>40
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(9375032240951630)
,p_query_column_id=>1
,p_column_alias=>'ID_COLABORADOR'
,p_column_display_sequence=>10
,p_hidden_column=>'Y'
,p_derived_column=>'N'
);
wwv_flow_imp_page.create_report_columns(
 p_id=>wwv_flow_imp.id(9375117059951631)
,p_query_column_id=>2
,p_column_alias=>'NOME'
,p_column_display_sequence=>20
,p_column_heading=>'Nome'
,p_column_html_expression=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<div style="display: flex; align-items: center; width: 100%; padding: 8px 0; font-family: ''Segoe UI'', sans-serif; border-bottom: 1px solid #f0f0f0;">',
'    <div style="display: flex; align-items: center; gap: 14px;">',
'        <!-- Foto Redonda -->',
'        <img src="#FOTO_URL#" style="width: 52px; height: 52px; border-radius: 50%; object-fit: cover; border: 2px solid #f3f3f3; flex-shrink: 0;">',
'',
'        <!-- Nome e Data com Bolo -->',
'        <div style="display: flex; flex-direction: column; gap: 4px;">',
'            <span style="font-weight: 600; color: #222; font-size: 15px; line-height: 1.2;">#NOME#</span>',
'            <span style="font-size: 13px; color: #666; display: flex; align-items: center; gap: 6px;">',
unistr('                \D83C\DF82 #DESCRICAO#'),
'            </span>',
'        </div>',
'    </div>',
'</div>',
''))
,p_heading_alignment=>'LEFT'
,p_derived_column=>'N'
,p_include_in_export=>'Y'
);
wwv_flow_imp_page.create_page_button(
 p_id=>wwv_flow_imp.id(10214154898327046)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_imp.id(9289454531503202)
,p_button_name=>'botao_emitir_comunicado'
,p_static_id=>'emitir-comunicado'
,p_show_as_disabled=>false
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>4073839297780169708
,p_button_image_alt=>'Emitir Comunicado'
,p_button_redirect_url=>'f?p=&APP_ID.:17:&SESSION.::&DEBUG.:::'
,p_warn_on_unsaved_changes=>null
,p_button_css_classes=>'botao-emitir-comunicado'
,p_grid_new_row=>'Y'
);
wwv_flow_imp_page.create_page_da_event(
 p_id=>wwv_flow_imp.id(9374259104951622)
,p_name=>unistr('Carregar M\00EAs no Badge')
,p_static_id=>unistr('carregar-m\00EAs-no-badge')
,p_event_sequence=>10
,p_bind_type=>'bind'
,p_bind_event_type=>'ready'
);
wwv_flow_imp_page.create_page_da_action(
 p_id=>wwv_flow_imp.id(9374328343951623)
,p_event_id=>wwv_flow_imp.id(9374259104951622)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_static_id=>'native-javascript-code'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attributes=>wwv_flow_t_plugin_attributes(wwv_flow_t_varchar2(
  'js_code', wwv_flow_string.join(wwv_flow_t_varchar2(
    unistr('// Aguarda os cards renderizarem, pega o m\00EAs do primeiro registro e joga no badge do topo'),
    'setTimeout(function(){',
    '    var primeiroCard = document.querySelector(''.item-aniversariante'');',
    '    if (primeiroCard) {',
    '        var mesDoBanco = primeiroCard.getAttribute(''data-mes'');',
    '        var badge = document.getElementById(''badge-mes'');',
    '        if (badge && mesDoBanco) {',
    '            badge.innerText = mesDoBanco;',
    unistr('            badge.style.display = ''block''; // Torna o badge vis\00EDvel'),
    '        }',
    '    }',
    '}, 100);',
    '')))).to_clob
);
wwv_flow_imp.component_end;
end;
/

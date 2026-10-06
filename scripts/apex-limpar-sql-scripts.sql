-- -----------------------------------------------------------------------------
-- Corlix Hub — remove todos os SQL Scripts do workspace no Oracle APEX
-- (SQL Workshop > SQL Scripts)
--
-- Como usar (qualquer uma das opções):
--   a) No APEX: SQL Workshop > SQL Commands, cole este bloco e clique em Run
--   b) No SQLcl / SQL Developer conectado como WKSP_CORLIXHUB:
--        set serveroutput on
--        @scripts/apex-limpar-sql-scripts.sql
--
-- Não coloque "set serveroutput on" neste arquivo: o SQL Commands do APEX
-- não aceita comandos SQL*Plus (dá ORA-00922) e já mostra o dbms_output.
--
-- Por padrão roda em modo de simulação (c_dry_run = true): só lista os
-- scripts. Troque para false para apagar de verdade.
--
-- Os SQL Scripts ficam em APEX_APPLICATION_FILES com FILE_TYPE = 'SCRIPT'.
-- Os resultados de execuções anteriores (SQL Scripts > Manage Results)
-- não são removidos por este script.
-- -----------------------------------------------------------------------------
declare
    c_workspace constant varchar2(255) := 'WKSP_CORLIXHUB';
    c_dry_run   constant boolean       := true;
    l_total     pls_integer := 0;
begin
    apex_util.set_workspace(p_workspace => c_workspace);

    for r in (
        select id, filename, created_by, created_on
          from apex_application_files
         where file_type = 'SCRIPT'
         order by filename
    ) loop
        l_total := l_total + 1;
        dbms_output.put_line(
            '  ' || r.filename || '  (criado por ' || r.created_by ||
            ' em ' || to_char(r.created_on, 'DD/MM/YYYY HH24:MI') || ')');

        if not c_dry_run then
            delete from apex_application_files where id = r.id;
        end if;
    end loop;

    if l_total = 0 then
        dbms_output.put_line('==> Nenhum SQL Script encontrado no workspace ' || c_workspace || '.');
    elsif c_dry_run then
        dbms_output.put_line('==> ' || l_total || ' SQL Script(s) encontrado(s). Simulação: nada foi removido.');
        dbms_output.put_line('    Troque c_dry_run para false para apagar.');
    else
        commit;
        dbms_output.put_line('==> ' || l_total || ' SQL Script(s) removido(s) do workspace ' || c_workspace || '.');
    end if;
end;
/

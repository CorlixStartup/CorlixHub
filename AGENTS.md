# AGENTS.md — Corlix Hub

Instruções para agentes de IA (Claude Code, Copilot, Cursor, Codex etc.).

**Antes de qualquer tarefa, leia [`docs/ai-context/README.md`](docs/ai-context/README.md)** e, a partir dele, os documentos relevantes. Antes de editar qualquer coisa, leia [`docs/ai-context/08-convencoes-e-pegadinhas.md`](docs/ai-context/08-convencoes-e-pegadinhas.md).

Resumo:
- App Oracle APEX 26.1 (ID 100, `CORLIXHUB`, workspace `WKSP_CORLIXHUB`) sobre Oracle DB 23ai. Toda a lógica está em SQL/PL/SQL e no APEX.
- Fonte da app: `corlixhub/` (APEXlang `.apx`). `database/f100.sql` é um export gerado: só leia com grep, nunca edite.
- Módulos de feature em `modulos/<nome>/`: SQL numerado + `instalar.sql`, packages, CSS/JS e o guia `Etapas-*.md`.
- Tema: tokens `--cx-*` em `corlixhub/shared-components/static-files/corlix-tema.css`; ajustes em `custom.css`. Mantenha os `.min.css` em sincronia.
- Escreva em pt-BR. Use Conventional Commits (`scripts/git-hooks/commit-msg`) e abra PRs para `DEV`.
- Ao alterar páginas, schema, tema ou módulos, atualize o documento correspondente em `docs/ai-context/`.

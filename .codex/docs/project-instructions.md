# Codex Project Instructions

This repository uses `.codex/` as the only Codex runtime layer.

## Core Rules
- Use `.codex/` assets for runtime guidance, skills, templates, knowledge, and scripts.
- Do not rely on the source Claude layer for runtime behavior. It exists only as generator input material.
- Prefer `.codex/knowledge/engine-reference/` for engine guidance and `.codex/templates/` for reusable document templates.
- Keep modifications scoped and reviewable. This compatibility layer is generated; when drift appears, refresh it instead of patching dozens of files by hand.

## Execution Order
1. Confirm the active configuration with `/debug-config` or `/status`.
2. Use the relevant `.codex/skills/*` workflow before inventing a new process.
3. Use `.codex/scripts/preflight.sh` or targeted scripts before making risky repository operations.
4. Regenerate the compatibility layer with `python3 .codex/scripts/generate_codex_layer.py` whenever source Claude assets or reference docs change.

## Verification
- Run `python3 -m unittest discover -s .codex/tests -p 'test_*.py'` after generator changes.
- Run `codex execpolicy check --pretty --rules .codex/rules/default.rules -- git status` to validate rule loading.
- Use `/review` for working-tree review and the `code-review` skill for targeted file or subsystem review.

## Guardrails
- Do not expose `.env` content or credentials in output.
- Do not create a root `AGENTS.md` for this repository; project guidance must stay inside `.codex/`.
- Do not rewrite history with force-push or hard reset workflows.

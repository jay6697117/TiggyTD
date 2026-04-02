# Codex Compatibility Layer

This directory is the self-contained Codex runtime layer for the repository.

## What It Contains
- Project-scoped Codex config in `config.toml`
- Full role registry mirrored from the source Claude layer
- Migrated skills in `.codex/skills/`
- Rewritten templates, reference docs, examples, and engine knowledge
- Validation and session helper scripts in `.codex/scripts/`

## Validate It
- `/debug-config`
- `/status`
- `python3 -m unittest discover -s .codex/tests -p 'test_*.py'`

## Refresh It
`python3 .codex/scripts/generate_codex_layer.py`

## Suggested Skills
`architecture-decision`, `asset-audit`, `balance-check`, `brainstorm`, `bug-report`, `changelog`, `code-review`, `design-review` ...

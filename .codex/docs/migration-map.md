# Migration Map

| Claude Source | Codex Target | Strategy |
| --- | --- | --- |
| `.claude/settings.json` | `.codex/config.toml` + `.codex/rules/default.rules` | Rewritten into native Codex config and rules |
| `.claude/agents/*.md` | `.codex/agents/*.toml` + `.codex/docs/roles/*.md` | Split into role config and role instructions |
| `.claude/skills/*` | `.codex/skills/*` | Copied and rewritten for Codex runtime paths |
| `.claude/hooks/*.sh` | `.codex/scripts/*.sh` | Converted into explicit scripts invoked by skills |
| `.claude/docs/templates/*` | `.codex/templates/*` | Copied verbatim with path rewrites |
| `.claude/docs/*` | `.codex/docs/reference/*` | Copied as source reference material |
| `.claude/rules/*` | `.codex/docs/reference/rules/*` | Copied as reference rule guidance |
| `docs/engine-reference/*` | `.codex/knowledge/engine-reference/*` | Copied as Codex-local knowledge |
| `docs/examples/*` | `.codex/knowledge/examples/*` | Copied as Codex-local example sessions |

## Constraint
This layer intentionally avoids a repository-root `AGENTS.md`. Project guidance is loaded through `.codex/config.toml` with `model_instructions_file = ".codex/docs/project-instructions.md"`.

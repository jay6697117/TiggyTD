# Active Hooks

Hooks are configured in `.codex/config.toml` and fire automatically:

| Hook | Event | Trigger | Action |
| ---- | ----- | ------- | ------ |
| `validate_commit.sh` | PreToolUse (shell) | `git commit` commands | Validates design doc sections, JSON data files, hardcoded values, TODO format |
| `validate_push.sh` | PreToolUse (shell) | `git push` commands | Warns on pushes to protected branches (develop/main) |
| `validate_assets.sh` | PostToolUse (apply_patch/apply_patch) | Asset file changes | Checks naming conventions and JSON validity for files in `assets/` |
| `session_start.sh` | SessionStart | Session begins | Loads sprint context, milestone, git activity; detects and previews active session state file for recovery |
| `detect_gaps.sh` | SessionStart | Session begins | Detects fresh projects (suggests `start`) and missing documentation when code`prototype`s exist, suggests `reverse-document` or `project-stage-detect` |
| `save_session_context.sh` | PreCompact | Context compression | Dumps session state (active.md, modified files, WIP design docs) into conversation before compaction so it survives summarization |
| `wrap_session.sh` | Stop | Session ends | Summarizes accomplishments and updates session log |
| `log_agent.sh` | SubagentStart | Agent spawned | Audit trail of all subagent invocations with timestamps |

Hook reference documentation: `.codex/docs/reference/hooks-reference/`
Hook input schema documentation: `.codex/docs/reference/hooks-reference/hook-input-schemas.md`

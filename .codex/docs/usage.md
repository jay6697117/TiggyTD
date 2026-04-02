        # Using The Codex Layer

        ## First Run
        1. Open Codex at the repository root.
        2. Confirm the project-scoped config is active with `/debug-config`.
        3. Verify the active session with `/status`.

        ## Common Entry Points
        Ask Codex to use one of these skills:
        - `start`
- `setup-engine`
- `project-stage-detect`
- `code-review`

        ## Refresh Workflow
        - Regenerate the layer: `python3 .codex/scripts/generate_codex_layer.py`
        - Run tests: `python3 -m unittest discover -s .codex/tests -p 'test_*.py'`
        - Spot-check rules: `codex execpolicy check --pretty --rules .codex/rules/default.rules -- git push --force origin main`

        ## Layout
        - `.codex/agents/`: per-role Codex config layers
        - `.codex/docs/roles/`: role instruction documents
        - `.codex/skills/`: migrated workflow skills
        - `.codex/templates/`: copied document templates
        - `.codex/knowledge/`: copied engine references and examples
        - `.codex/scripts/`: migrated validation and session helper scripts

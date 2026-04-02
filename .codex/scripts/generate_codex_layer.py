#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import shutil
import textwrap
from dataclasses import dataclass
from pathlib import Path
from typing import Any


MODEL_MAPPING = {
    "opus": ("gpt-5.4", "xhigh"),
    "sonnet": ("gpt-5.4", "xhigh"),
    "haiku": ("gpt-5.4", "xhigh"),
}

HOOK_SCRIPT_MAP = {
    "session-start.sh": "session_start.sh",
    "detect-gaps.sh": "detect_gaps.sh",
    "validate-commit.sh": "validate_commit.sh",
    "validate-push.sh": "validate_push.sh",
    "validate-assets.sh": "validate_assets.sh",
    "pre-compact.sh": "save_session_context.sh",
    "session-stop.sh": "wrap_session.sh",
    "log-agent.sh": "log_agent.sh",
}

BUILTIN_COMMANDS = {
    "plan": "/plan",
    "review": "/review",
    "status": "/status",
    "debug-config": "/debug-config",
    "statusline": "/statusline",
}

GENERATED_SCRIPT_NAMES = {
    "detect_gaps.sh",
    "validate_commit.sh",
    "validate_push.sh",
    "validate_assets.sh",
    "save_session_context.sh",
    "wrap_session.sh",
    "log_agent.sh",
    "session_start.sh",
    "preflight.sh",
    "generate_codex_layer.py",
}


@dataclass
class ManifestEntry:
    source: str
    target: str
    transform: str
    owner: str = "generator"


def slug_to_title(slug: str) -> str:
    words = []
    acronyms = {"ai": "AI", "qa": "QA", "ux": "UX", "ui": "UI", "ue": "UE", "gas": "GAS"}
    for part in slug.split("-"):
        words.append(acronyms.get(part, part.capitalize()))
    return " ".join(words)


def yaml_quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def toml_quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def parse_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    if not text.startswith("---\n"):
        return {}, text

    end = text.find("\n---\n", 4)
    if end == -1:
        return {}, text

    frontmatter_text = text[4:end]
    body = text[end + 5 :]
    frontmatter: dict[str, Any] = {}

    for raw_line in frontmatter_text.splitlines():
        line = raw_line.strip()
        if not line or ":" not in line:
            continue
        key, raw_value = line.split(":", 1)
        key = key.strip()
        value = raw_value.strip()

        if value.startswith('"') and value.endswith('"'):
            frontmatter[key] = value[1:-1]
        elif value.startswith("'") and value.endswith("'"):
            frontmatter[key] = value[1:-1]
        elif value.startswith("[") and value.endswith("]"):
            inner = value[1:-1].strip()
            if not inner:
                frontmatter[key] = []
            else:
                items = [item.strip().strip('"').strip("'") for item in inner.split(",")]
                frontmatter[key] = [item for item in items if item]
        elif value.lower() in {"true", "false"}:
            frontmatter[key] = value.lower() == "true"
        else:
            frontmatter[key] = value

    return frontmatter, body


def list_source_skill_names(repo_root: Path) -> list[str]:
    return sorted(path.name for path in (repo_root / ".claude" / "skills").iterdir() if path.is_dir())


def rewrite_text(text: str, skill_names: list[str]) -> str:
    replacements = [
        (".claude/docs/templates/", ".codex/templates/"),
        (".claude/docs/hooks-reference/", ".codex/docs/reference/hooks-reference/"),
        (".claude/docs/hooks-reference.md", ".codex/docs/reference/hooks-reference.md"),
        (".claude/docs/", ".codex/docs/reference/"),
        (".claude/rules/", ".codex/docs/reference/rules/"),
        (".claude/agents/", ".codex/docs/roles/"),
        (".claude/skills/", ".codex/skills/"),
        (".claude/settings.local.json", ".codex/config.toml"),
        (".claude/settings.json", ".codex/config.toml"),
        (".claude/hooks/session-start.sh", ".codex/scripts/session_start.sh"),
        (".claude/hooks/detect-gaps.sh", ".codex/scripts/detect_gaps.sh"),
        (".claude/hooks/validate-commit.sh", ".codex/scripts/validate_commit.sh"),
        (".claude/hooks/validate-push.sh", ".codex/scripts/validate_push.sh"),
        (".claude/hooks/validate-assets.sh", ".codex/scripts/validate_assets.sh"),
        (".claude/hooks/pre-compact.sh", ".codex/scripts/save_session_context.sh"),
        (".claude/hooks/session-stop.sh", ".codex/scripts/wrap_session.sh"),
        (".claude/hooks/log-agent.sh", ".codex/scripts/log_agent.sh"),
        ("docs/engine-reference/", ".codex/knowledge/engine-reference/"),
        ("docs/examples/", ".codex/knowledge/examples/"),
        ("docs/WORKFLOW-GUIDE.md", ".codex/docs/reference/WORKFLOW-GUIDE.md"),
        (
            "docs/COLLABORATIVE-DESIGN-PRINCIPLE.md",
            ".codex/docs/reference/COLLABORATIVE-DESIGN-PRINCIPLE.md",
        ),
        (".claude/hooks/", ".codex/scripts/"),
        (".claude/", ".codex/"),
        ("CLAUDE.md", ".codex/docs/project-instructions.md"),
        ("Claude Code Game Studios", "Codex Game Studios"),
        ("Claude Code", "Codex"),
        ("Claude", "Codex"),
        ("AskUserQuestion", "request_user_input"),
        ("Task", "spawn_agent"),
        ("Write", "apply_patch"),
        ("Edit", "apply_patch"),
        ("Bash", "shell"),
    ]

    for old, new in replacements:
        text = text.replace(old, new)

    for source_name, target_name in HOOK_SCRIPT_MAP.items():
        text = text.replace(source_name, target_name)

    for skill_name in skill_names:
        text = text.replace(f"/{skill_name}", f"`{skill_name}`")

    text = text.replace("`/plan`", "/plan")
    text = text.replace("`/review`", "/review")
    text = text.replace("`/status`", "/status")
    text = text.replace("`/debug-config`", "/debug-config")
    text = text.replace("`/statusline`", "/statusline")

    return text


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def write_text(path: Path, content: str) -> None:
    ensure_parent(path)
    path.write_text(content, encoding="utf-8")


def copy_text_file(
    src: Path,
    dest: Path,
    skill_names: list[str],
    entries: list[ManifestEntry],
    transform: str = "copy+rewrite",
) -> None:
    ensure_parent(dest)
    try:
        content = src.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        shutil.copy2(src, dest)
    else:
        write_text(dest, rewrite_text(content, skill_names))
    shutil.copystat(src, dest, follow_symlinks=True)
    entries.append(ManifestEntry(str(src), str(dest), transform))


def copy_tree(
    src_root: Path,
    dest_root: Path,
    skill_names: list[str],
    entries: list[ManifestEntry],
    *,
    skip_prefix: str | None = None,
) -> None:
    if not src_root.exists():
        return

    for src in sorted(src_root.rglob("*")):
        if not src.is_file():
            continue
        rel = src.relative_to(src_root)
        if skip_prefix and rel.parts and rel.parts[0] == skip_prefix:
            continue
        dest = dest_root / rel
        copy_text_file(src, dest, skill_names, entries)


def remove_path(path: Path) -> None:
    if path.is_dir():
        shutil.rmtree(path)
    elif path.exists():
        path.unlink()


def generate_project_instructions() -> str:
    return textwrap.dedent(
        """\
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
        """
    ).rstrip() + "\n"


def generate_usage(skill_names: list[str]) -> str:
    highlighted = ["start", "setup-engine", "project-stage-detect", "code-review"]
    highlight_lines = "\n".join(f"- `{name}`" for name in highlighted if name in skill_names)
    return textwrap.dedent(
        f"""\
        # Using The Codex Layer

        ## First Run
        1. Open Codex at the repository root.
        2. Confirm the project-scoped config is active with `/debug-config`.
        3. Verify the active session with `/status`.

        ## Common Entry Points
        Ask Codex to use one of these skills:
        {highlight_lines}

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
        """
    ).rstrip() + "\n"


def generate_readme(skill_names: list[str]) -> str:
    return textwrap.dedent(
        f"""\
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
        {", ".join(f"`{name}`" for name in skill_names[:8])} ...
        """
    ).rstrip() + "\n"


def generate_command_map(skill_names: list[str]) -> str:
    builtins = "\n".join(
        f"| `{command}` | `{builtin}` | Native Codex command |"
        for command, builtin in BUILTIN_COMMANDS.items()
    )
    migrated = "\n".join(
        f"| `/{name}` | Use the `{name}` skill | Migrated Claude workflow |" for name in skill_names
    )
    return textwrap.dedent(
        f"""\
        # Command Map

        Codex does not auto-import repository-local custom slash commands. This layer keeps the original workflow names as skills.

        ## Native Codex Commands
        | Original Intent | Codex Command | Notes |
        | --- | --- | --- |
        {builtins}

        ## Migrated Workflow Commands
        | Claude Command | Codex Path | Notes |
        | --- | --- | --- |
        {migrated}

        ## Guidance
        - Use `/review` for whole-working-tree review.
        - Use the `code-review` skill for targeted subsystem or file review.
        - Use `/statusline` to inspect or adjust footer configuration.
        """
    ).rstrip() + "\n"


def generate_migration_map() -> str:
    return textwrap.dedent(
        """\
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
        """
    ).rstrip() + "\n"


def generate_rules() -> str:
    def block(pattern: list[str], justification: str) -> str:
        formatted = ", ".join(toml_quote(token) for token in pattern)
        return textwrap.dedent(
            f"""\
            prefix_rule(
                pattern = [{formatted}],
                decision = "forbidden",
                justification = {toml_quote(justification)},
            )
            """
        ).rstrip()

    def allow(pattern: list[str], justification: str) -> str:
        formatted = ", ".join(toml_quote(token) for token in pattern)
        return textwrap.dedent(
            f"""\
            prefix_rule(
                pattern = [{formatted}],
                decision = "allow",
                justification = {toml_quote(justification)},
            )
            """
        ).rstrip()

    rules = [
        "# Codex execution rules for the generated compatibility layer.",
        allow(["git", "status"], "Read-only repository status checks are safe."),
        allow(["git", "diff"], "Read-only repository diffs are safe."),
        allow(["git", "log"], "Read-only git history inspection is safe."),
        allow(["git", "branch"], "Read-only branch inspection is safe."),
        allow(["git", "rev-parse"], "Read-only revision parsing is safe."),
        block(["rm", "-rf"], "Destructive recursive deletion is blocked."),
        block(["git", "push", "--force"], "Force-push is blocked for this repository."),
        block(["git", "push", "-f"], "Force-push is blocked for this repository."),
        block(["git", "reset", "--hard"], "Hard reset is blocked for this repository."),
        block(["git", "clean", "-f"], "Destructive clean is blocked for this repository."),
        block(["sudo"], "Privilege escalation is blocked for this repository."),
        block(["chmod", "777"], "Overly permissive chmod is blocked for this repository."),
    ]
    return "\n\n".join(rules).rstrip() + "\n"


def generate_agent_doc(frontmatter: dict[str, Any], body: str, skill_names: list[str]) -> str:
    model_key = str(frontmatter.get("model", "sonnet"))
    model, reasoning = MODEL_MAPPING.get(model_key, MODEL_MAPPING["sonnet"])
    tools = ", ".join(frontmatter.get("tools", [])) if isinstance(frontmatter.get("tools"), list) else str(frontmatter.get("tools", ""))
    disallowed = frontmatter.get("disallowedTools", [])
    disallowed_tools = ", ".join(disallowed) if isinstance(disallowed, list) else str(disallowed)
    recommended_skills = frontmatter.get("skills", [])
    recommended = ", ".join(f"`{name}`" for name in recommended_skills) if recommended_skills else "None"
    notes = []
    if "maxTurns" in frontmatter:
        notes.append(f"- Original maxTurns: `{frontmatter['maxTurns']}`")
    if "memory" in frontmatter:
        notes.append(f"- Original memory hint: `{frontmatter['memory']}`")

    rewritten_body = rewrite_text(body.strip(), skill_names)
    metadata_lines = [
        f"# {slug_to_title(str(frontmatter.get('name', 'agent')))}",
        "",
        f"- Role id: `{frontmatter.get('name', 'agent')}`",
        f"- Preferred model: `{model}`",
        f"- Reasoning effort: `{reasoning}`",
        f"- Description: {frontmatter.get('description', '').strip()}",
        f"- Original tool profile: `{tools}`" if tools else "- Original tool profile: `unspecified`",
        f"- Original restricted tools: `{disallowed_tools}`" if disallowed_tools else "- Original restricted tools: `none`",
        f"- Recommended skills: {recommended}",
    ]
    if notes:
        metadata_lines.extend(notes)
    metadata_lines.extend(["", rewritten_body, ""])
    return "\n".join(metadata_lines)


def generate_agent_config(frontmatter: dict[str, Any], role_doc_relpath: str) -> str:
    model_key = str(frontmatter.get("model", "sonnet"))
    model, reasoning = MODEL_MAPPING.get(model_key, MODEL_MAPPING["sonnet"])
    return textwrap.dedent(
        f"""\
        model = {toml_quote(model)}
        model_reasoning_effort = {toml_quote(reasoning)}
        model_instructions_file = {toml_quote(role_doc_relpath)}
        """
    )


def generate_skill_doc(frontmatter: dict[str, Any], body: str, skill_names: list[str]) -> str:
    name = str(frontmatter.get("name", "unnamed-skill"))
    description = str(frontmatter.get("description", f"Use when the `{name}` workflow applies."))
    argument_hint = frontmatter.get("argument-hint")
    rewritten_body = rewrite_text(body.strip(), skill_names)

    lines = [
        "---",
        f"name: {name}",
        f"description: {yaml_quote(description)}",
        "---",
        "",
        f"# {slug_to_title(name)}",
        "",
        "This is the Codex-adapted version of the original workflow. Use only `.codex/` runtime assets when following it.",
    ]
    if argument_hint:
        lines.extend(["", f"Arguments: `{argument_hint}`"])
    lines.extend(["", rewritten_body, ""])
    return "\n".join(lines)


def generate_config(
    agent_frontmatters: list[dict[str, Any]],
    skill_names: list[str],
) -> str:
    parts = [
        "#:schema https://developers.openai.com/codex/config-schema.json",
        'model = "gpt-5.4"',
        'model_reasoning_effort = "xhigh"',
        'plan_mode_reasoning_effort = "xhigh"',
        'personality = "pragmatic"',
        'approval_policy = "on-request"',
        'sandbox_mode = "workspace-write"',
        'model_instructions_file = ".codex/docs/project-instructions.md"',
        "",
        "[features]",
        "multi_agent = true",
        "unified_exec = true",
        "shell_snapshot = true",
        "",
        'tui.status_line = ["model", "context", "limits", "git", "tokens", "session"]',
        "",
        "[agents]",
        "max_threads = 6",
        "max_depth = 2",
        "job_max_runtime_seconds = 1800",
        "",
    ]

    for frontmatter in agent_frontmatters:
        name = str(frontmatter["name"])
        description = str(frontmatter.get("description", "")).strip()
        parts.extend(
            [
                f"[agents.{name}]",
                f"description = {toml_quote(description)}",
                f'config_file = ".codex/agents/{name}.toml"',
                f'nickname_candidates = [{toml_quote(name)}]',
                "",
            ]
        )

    for skill_name in skill_names:
        parts.extend(
            [
                "[[skills.config]]",
                f'path = ".codex/skills/{skill_name}"',
                "enabled = true",
                "",
            ]
        )

    return "\n".join(parts).rstrip() + "\n"


def generate_manifest(entries: list[ManifestEntry]) -> str:
    lines = [
        'schema_version = "1"',
        f'generated_by = {toml_quote(".codex/scripts/generate_codex_layer.py")}',
        f'source_runtime = {toml_quote(".claude")}',
        "",
    ]
    for entry in entries:
        lines.extend(
            [
                "[[entries]]",
                f"source = {toml_quote(entry.source)}",
                f"target = {toml_quote(entry.target)}",
                f"transform = {toml_quote(entry.transform)}",
                f"owner = {toml_quote(entry.owner)}",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def create_preflight_script() -> str:
    return textwrap.dedent(
        """\
        #!/usr/bin/env bash
        set -euo pipefail

        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        bash "$script_dir/validate_commit.sh"
        bash "$script_dir/validate_push.sh"
        bash "$script_dir/validate_assets.sh"
        """
    )


def write_generated_script(path: Path, content: str, entries: list[ManifestEntry], source: str) -> None:
    write_text(path, content)
    os.chmod(path, 0o755)
    entries.append(ManifestEntry(source, str(path), "generated"))


def sync_scripts(repo_root: Path, output_root: Path, skill_names: list[str], entries: list[ManifestEntry]) -> None:
    scripts_dir = output_root / "scripts"
    scripts_dir.mkdir(parents=True, exist_ok=True)

    for src_name, dest_name in HOOK_SCRIPT_MAP.items():
        src = repo_root / ".claude" / "hooks" / src_name
        dest = scripts_dir / dest_name
        copy_text_file(src, dest, skill_names, entries)
        os.chmod(dest, src.stat().st_mode)

    preflight_path = scripts_dir / "preflight.sh"
    write_generated_script(preflight_path, create_preflight_script(), entries, "generated:preflight")

    generator_source = Path(__file__).resolve()
    generator_dest = scripts_dir / "generate_codex_layer.py"
    should_copy_generator = not generator_dest.exists() or generator_dest.resolve() != generator_source
    if should_copy_generator:
        write_text(generator_dest, generator_source.read_text(encoding="utf-8"))
        os.chmod(generator_dest, 0o755)
        entries.append(ManifestEntry(str(generator_source), str(generator_dest), "copy"))


def sync_reference_docs(repo_root: Path, output_root: Path, skill_names: list[str], entries: list[ManifestEntry]) -> None:
    reference_root = output_root / "docs" / "reference"
    copy_tree(repo_root / ".claude" / "docs", reference_root, skill_names, entries, skip_prefix="templates")
    copy_tree(repo_root / ".claude" / "rules", reference_root / "rules", skill_names, entries)

    for filename in ["WORKFLOW-GUIDE.md", "COLLABORATIVE-DESIGN-PRINCIPLE.md"]:
        src = repo_root / "docs" / filename
        dest = reference_root / filename
        copy_text_file(src, dest, skill_names, entries)


def sync_templates(repo_root: Path, output_root: Path, skill_names: list[str], entries: list[ManifestEntry]) -> None:
    copy_tree(repo_root / ".claude" / "docs" / "templates", output_root / "templates", skill_names, entries)


def sync_knowledge(repo_root: Path, output_root: Path, skill_names: list[str], entries: list[ManifestEntry]) -> None:
    copy_tree(repo_root / "docs" / "engine-reference", output_root / "knowledge" / "engine-reference", skill_names, entries)
    copy_tree(repo_root / "docs" / "examples", output_root / "knowledge" / "examples", skill_names, entries)


def sync_agents(repo_root: Path, output_root: Path, skill_names: list[str], entries: list[ManifestEntry]) -> list[dict[str, Any]]:
    agent_frontmatters: list[dict[str, Any]] = []
    agents_src = repo_root / ".claude" / "agents"
    agents_dest = output_root / "agents"
    role_docs_dest = output_root / "docs" / "roles"
    agents_dest.mkdir(parents=True, exist_ok=True)
    role_docs_dest.mkdir(parents=True, exist_ok=True)

    for src in sorted(agents_src.glob("*.md")):
        text = src.read_text(encoding="utf-8")
        frontmatter, body = parse_frontmatter(text)
        frontmatter.setdefault("name", src.stem)
        agent_frontmatters.append(frontmatter)

        role_doc_path = role_docs_dest / f"{src.stem}.md"
        role_doc = generate_agent_doc(frontmatter, body, skill_names)
        write_text(role_doc_path, role_doc)
        entries.append(ManifestEntry(str(src), str(role_doc_path), "generated"))

        agent_config_path = agents_dest / f"{src.stem}.toml"
        role_doc_relpath = f"../docs/roles/{src.stem}.md"
        agent_config = generate_agent_config(frontmatter, role_doc_relpath)
        write_text(agent_config_path, agent_config)
        entries.append(ManifestEntry(str(src), str(agent_config_path), "generated"))

    return agent_frontmatters


def sync_skills(repo_root: Path, output_root: Path, skill_names: list[str], entries: list[ManifestEntry]) -> None:
    skills_src = repo_root / ".claude" / "skills"
    skills_dest = output_root / "skills"
    skills_dest.mkdir(parents=True, exist_ok=True)

    for skill_dir in sorted(path for path in skills_src.iterdir() if path.is_dir()):
        dest_dir = skills_dest / skill_dir.name
        dest_dir.mkdir(parents=True, exist_ok=True)

        for src in sorted(skill_dir.rglob("*")):
            if not src.is_file():
                continue
            rel = src.relative_to(skill_dir)
            dest = dest_dir / rel
            if src.name == "SKILL.md":
                frontmatter, body = parse_frontmatter(src.read_text(encoding="utf-8"))
                frontmatter.setdefault("name", skill_dir.name)
                skill_doc = generate_skill_doc(frontmatter, body, skill_names)
                write_text(dest, skill_doc)
                entries.append(ManifestEntry(str(src), str(dest), "generated"))
            else:
                copy_text_file(src, dest, skill_names, entries)


def prepare_output_root(output_root: Path) -> None:
    removable_paths = [
        output_root / "agents",
        output_root / "skills",
        output_root / "templates",
        output_root / "knowledge",
        output_root / "rules",
        output_root / "docs" / "roles",
        output_root / "docs" / "reference",
        output_root / "config.toml",
        output_root / "README.md",
        output_root / "migration-manifest.toml",
        output_root / "docs" / "project-instructions.md",
        output_root / "docs" / "usage.md",
        output_root / "docs" / "command-map.md",
        output_root / "docs" / "migration-map.md",
    ]
    for path in removable_paths:
        remove_path(path)

    output_root.mkdir(parents=True, exist_ok=True)
    (output_root / "docs").mkdir(parents=True, exist_ok=True)
    (output_root / "scripts").mkdir(parents=True, exist_ok=True)


def generate_codex_layer(repo_root: Path, output_root: Path) -> None:
    repo_root = repo_root.resolve()
    output_root = output_root.resolve()

    skill_names = list_source_skill_names(repo_root)
    prepare_output_root(output_root)

    entries: list[ManifestEntry] = []

    sync_scripts(repo_root, output_root, skill_names, entries)
    sync_reference_docs(repo_root, output_root, skill_names, entries)
    sync_templates(repo_root, output_root, skill_names, entries)
    sync_knowledge(repo_root, output_root, skill_names, entries)
    agent_frontmatters = sync_agents(repo_root, output_root, skill_names, entries)
    sync_skills(repo_root, output_root, skill_names, entries)

    generated_files = {
        output_root / "config.toml": generate_config(agent_frontmatters, skill_names),
        output_root / "README.md": generate_readme(skill_names),
        output_root / "migration-manifest.toml": "",
        output_root / "docs" / "project-instructions.md": generate_project_instructions(),
        output_root / "docs" / "usage.md": generate_usage(skill_names),
        output_root / "docs" / "command-map.md": generate_command_map(skill_names),
        output_root / "docs" / "migration-map.md": generate_migration_map(),
        output_root / "rules" / "default.rules": generate_rules(),
    }

    for path, content in generated_files.items():
        if path.name == "migration-manifest.toml":
            continue
        write_text(path, content)
        entries.append(ManifestEntry("generated", str(path), "generated"))

    manifest_path = output_root / "migration-manifest.toml"
    write_text(manifest_path, generate_manifest(entries))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate the self-contained Codex compatibility layer.")
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[2],
        help="Repository root containing .claude/ and docs/ source material.",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Output .codex directory to generate.",
    )
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    generate_codex_layer(args.repo_root, args.output_root)


if __name__ == "__main__":
    main()

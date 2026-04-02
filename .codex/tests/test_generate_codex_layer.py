import importlib.util
import re
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
GENERATOR_PATH = REPO_ROOT / ".codex" / "scripts" / "generate_codex_layer.py"


def load_generator_module():
    if not GENERATOR_PATH.exists():
        raise FileNotFoundError(f"Generator script is missing: {GENERATOR_PATH}")

    spec = importlib.util.spec_from_file_location("generate_codex_layer", GENERATOR_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class GenerateCodexLayerTest(unittest.TestCase):
    maxDiff = None

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.output_root = Path(self.temp_dir.name) / ".codex"
        self.module = load_generator_module()
        self.module.generate_codex_layer(REPO_ROOT, self.output_root)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_generates_expected_top_level_files(self):
        expected_paths = [
            self.output_root / "config.toml",
            self.output_root / "README.md",
            self.output_root / "migration-manifest.toml",
            self.output_root / "rules" / "default.rules",
            self.output_root / "docs" / "project-instructions.md",
            self.output_root / "docs" / "usage.md",
            self.output_root / "docs" / "command-map.md",
            self.output_root / "scripts" / "generate_codex_layer.py",
        ]

        for path in expected_paths:
            with self.subTest(path=path):
                self.assertTrue(path.exists(), f"Expected generated path: {path}")

    def test_registers_all_agents_and_skills(self):
        source_agents = sorted((REPO_ROOT / ".claude" / "agents").glob("*.md"))
        source_skills = sorted(
            path for path in (REPO_ROOT / ".claude" / "skills").iterdir() if path.is_dir()
        )

        generated_agent_configs = sorted((self.output_root / "agents").glob("*.toml"))
        generated_role_docs = sorted((self.output_root / "docs" / "roles").glob("*.md"))
        generated_skill_dirs = sorted(
            path for path in (self.output_root / "skills").iterdir() if path.is_dir()
        )

        self.assertEqual(len(source_agents), len(generated_agent_configs))
        self.assertEqual(len(source_agents), len(generated_role_docs))
        self.assertEqual(len(source_skills), len(generated_skill_dirs))

        config_text = (self.output_root / "config.toml").read_text(encoding="utf-8")
        for agent in source_agents:
            self.assertIn(f"[agents.{agent.stem}]", config_text)
        for skill in source_skills:
            self.assertIn(f'path = ".codex/skills/{skill.name}"', config_text)

    def test_copies_templates_and_knowledge_assets(self):
        source_template_files = sorted((REPO_ROOT / ".claude" / "docs" / "templates").rglob("*"))
        source_template_files = [path for path in source_template_files if path.is_file()]
        generated_template_files = sorted((self.output_root / "templates").rglob("*"))
        generated_template_files = [path for path in generated_template_files if path.is_file()]

        self.assertEqual(len(source_template_files), len(generated_template_files))
        self.assertTrue((self.output_root / "knowledge" / "engine-reference" / "README.md").exists())
        self.assertTrue((self.output_root / "knowledge" / "examples" / "README.md").exists())

    def test_runtime_content_does_not_reference_claude_paths(self):
        allowed_paths = {
            self.output_root / "migration-manifest.toml",
            self.output_root / "docs" / "migration-map.md",
            self.output_root / "scripts" / "generate_codex_layer.py",
        }

        disallowed_hits = []
        for path in self.output_root.rglob("*"):
            if not path.is_file() or path in allowed_paths:
                continue
            try:
                content = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            if ".claude/" in content:
                disallowed_hits.append(path)

        self.assertEqual([], disallowed_hits)

    def test_generates_expected_rules(self):
        rules_text = (self.output_root / "rules" / "default.rules").read_text(encoding="utf-8")
        self.assertIn('pattern = ["git", "push", "--force"]', rules_text)
        self.assertIn('pattern = ["git", "status"]', rules_text)
        self.assertIsNotNone(re.search(r'pattern = \["rm", "-rf"\].*decision = "forbidden"', rules_text, re.S))

    def test_embeds_required_config_defaults(self):
        config_text = (self.output_root / "config.toml").read_text(encoding="utf-8")
        required_settings = [
            'model = "gpt-5.4"',
            'model_reasoning_effort = "xhigh"',
            'plan_mode_reasoning_effort = "xhigh"',
            'personality = "pragmatic"',
            'approval_policy = "on-request"',
            'sandbox_mode = "workspace-write"',
            'model_instructions_file = ".codex/docs/project-instructions.md"',
            'tui.status_line = ["model", "context", "limits", "git", "tokens", "session"]',
        ]

        for setting in required_settings:
            with self.subTest(setting=setting):
                self.assertIn(setting, config_text)

    def test_generates_unified_agent_model_settings(self):
        for path in (self.output_root / "agents").glob("*.toml"):
            text = path.read_text(encoding="utf-8")
            lines = [line.strip() for line in text.splitlines() if line.strip()]
            self.assertGreaterEqual(len(lines), 3)
            self.assertEqual('model = "gpt-5.4"', lines[0])
            self.assertEqual('model_reasoning_effort = "xhigh"', lines[1])


if __name__ == "__main__":
    unittest.main()

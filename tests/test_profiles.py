"""Regression tests for the Sol High / Luna Max topology (Python 3.11+)."""
from pathlib import Path
import re
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROFILES = {"pro": 4, "plus": 4, "pro-max-2-subagents": 2, "plus-max-2-subagents": 2}
SANDBOXES = {"explorer": "read-only", "researcher": "read-only", "reviewer": "read-only",
             "worker": "workspace-write", "tester": "workspace-write"}


def read_toml(path):
    return tomllib.loads(path.read_text(encoding="utf-8"))


class ProfileTests(unittest.TestCase):
    def test_root_uses_sol_high(self):
        for profile in PROFILES:
            with self.subTest(profile=profile):
                config = read_toml(ROOT / "profiles" / profile / "codex/config.toml")
                self.assertEqual((config["model"], config["model_reasoning_effort"]),
                                 ("gpt-5.6-sol", "high"))

    def test_reviewer_uses_luna_max(self):
        for profile in PROFILES:
            with self.subTest(profile=profile):
                config = read_toml(ROOT / "profiles" / profile / "codex/agents/reviewer.toml")
                self.assertEqual((config["model"], config["model_reasoning_effort"]),
                                 ("gpt-5.6-luna", "max"))

    def test_defaults_limits_and_approvals(self):
        for profile, limit in PROFILES.items():
            with self.subTest(profile=profile):
                config = read_toml(ROOT / "profiles" / profile / "codex/config.toml")
                self.assertEqual(config["approval_policy"], "on-request")
                self.assertEqual(config["sandbox_mode"], "workspace-write")
                self.assertEqual(config["agents"], {
                    "enabled": True, "max_concurrent_threads_per_session": limit,
                    "default_subagent_model": "gpt-5.6-luna",
                    "default_subagent_reasoning_effort": "max",
                })

    def test_all_five_named_roles_are_pinned_and_scoped(self):
        for profile in PROFILES:
            directory = ROOT / "profiles" / profile / "codex/agents"
            self.assertEqual({p.stem for p in directory.glob("*.toml")}, set(SANDBOXES))
            for role, sandbox in SANDBOXES.items():
                with self.subTest(profile=profile, role=role):
                    config = read_toml(directory / (role + ".toml"))
                    self.assertEqual(config["name"], role)
                    self.assertEqual(config["model"], "gpt-5.6-luna")
                    self.assertEqual(config["model_reasoning_effort"], "max")
                    self.assertEqual(config["sandbox_mode"], sandbox)
                    self.assertTrue(config["description"].strip())
                    self.assertTrue(config["developer_instructions"].strip())

    def test_skill_name_and_model_policy_match_every_profile(self):
        for profile in PROFILES:
            with self.subTest(profile=profile):
                skills = ROOT / "profiles" / profile / "agents/skills"
                self.assertEqual({p.name for p in skills.iterdir()}, {"sol-orchestrator"})
                content = (skills / "sol-orchestrator/SKILL.md").read_text(encoding="utf-8")
                self.assertTrue(content.startswith("---\nname: sol-orchestrator\n"))
                self.assertIn("description: Use when", content)
                self.assertIn("gpt-5.6-sol", content)
                self.assertIn("gpt-5.6-luna", content)
                self.assertNotIn("gpt-6-astra", content)
                self.assertNotIn("astra-orchestrator", content)

    def test_compatibility_aliases_are_identical(self):
        def files(profile):
            base = ROOT / "profiles" / profile
            return {p.relative_to(base).as_posix(): p.read_bytes()
                    for p in base.rglob("*") if p.is_file()}
        self.assertEqual(files("plus"), files("pro"))
        self.assertEqual(files("plus-max-2-subagents"), files("pro-max-2-subagents"))
        four, two = files("pro"), files("pro-max-2-subagents")
        self.assertEqual(set(four), set(two))
        for path in four:
            with self.subTest(path=path):
                if path == "codex/config.toml":
                    a, b = tomllib.loads(four[path].decode()), tomllib.loads(two[path].decode())
                    a["agents"]["max_concurrent_threads_per_session"] = 2
                    self.assertEqual(a, b)
                else:
                    self.assertEqual(four[path], two[path])

    def test_instructions_and_documentation_are_consistent(self):
        instructions = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("`sol-orchestrator`", instructions)
        self.assertNotIn("astra-orchestrator", instructions)
        self.assertIn("Do not commit or push unless explicitly authorized", instructions)
        paths = [ROOT / "README.md", *sorted((ROOT / "guides").glob("*.md"))]
        self.assertEqual(len(paths), 8)
        for path in paths:
            with self.subTest(path=path.name):
                content = path.read_text(encoding="utf-8")
                for match in re.finditer(r"```toml\n(.*?)```", content, re.S):
                    config = tomllib.loads(match.group(1))
                    self.assertNotEqual(config.get("model"), "gpt-6-astra")
                    if "model" in config:
                        self.assertEqual((config["model"], config["model_reasoning_effort"]),
                                         ("gpt-5.6-sol", "high"))
                for link in re.findall(r"\]\(([^)#]+)(?:#[^)]*)?\)", content):
                    if "://" not in link and link != "LICENSE":
                        self.assertTrue((path.parent / link).exists(), (path.name, link))
        readme = paths[0].read_text(encoding="utf-8")
        self.assertIn("git clone https://github.com/LSthemagic/codex-orchestrator.git", readme)
        self.assertIn("not a semantic TOML merge", readme)
        self.assertIn("donvito/codex-astra-luna-orchestrator", readme)


if __name__ == "__main__":
    unittest.main()

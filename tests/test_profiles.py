"""Validate the installed GPT-6 role contract; no live model calls (Python 3.11+)."""
from pathlib import Path
import re
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROFILES = {"pro": 4, "plus": 4, "pro-max-2-subagents": 2, "plus-max-2-subagents": 2}
ROLES = {
    "explorer": ("gpt-6-luna", "medium", "read-only"),
    "researcher": ("gpt-6-luna", "max", "read-only"),
    "implementer": ("gpt-6-luna", "max", "workspace-write"),
    "worker": ("gpt-6-luna", "max", "workspace-write"),
    "tester": ("gpt-6-luna", "high", "workspace-write"),
    "debugger": ("gpt-6-sol", "high", "workspace-write"),
    "reviewer": ("gpt-6-sol", "high", "read-only"),
    "architect": ("gpt-6-sol", "xhigh", "read-only"),
    "escalation": ("gpt-6-astra", "high", "read-only"),
}


def read_toml(path):
    return tomllib.loads(path.read_text(encoding="utf-8"))


class ProfileTests(unittest.TestCase):
    def test_root_uses_sol_high(self):
        for profile in PROFILES:
            with self.subTest(profile=profile):
                config = read_toml(ROOT / "profiles" / profile / "codex/config.toml")
                self.assertEqual((config["model"], config["model_reasoning_effort"]),
                                 ("gpt-6-sol", "high"))

    def test_defaults_limits_and_approvals(self):
        for profile, limit in PROFILES.items():
            with self.subTest(profile=profile):
                config = read_toml(ROOT / "profiles" / profile / "codex/config.toml")
                self.assertEqual(config["approval_policy"], "on-request")
                self.assertEqual(config["sandbox_mode"], "workspace-write")
                self.assertEqual(config["agents"], {
                    "enabled": True, "max_concurrent_threads_per_session": limit,
                    "default_subagent_model": "gpt-6-luna",
                    "default_subagent_reasoning_effort": "max",
                })

    def test_named_roles_use_approved_models_efforts_and_sandboxes(self):
        for profile in PROFILES:
            directory = ROOT / "profiles" / profile / "codex/agents"
            with self.subTest(profile=profile):
                self.assertEqual({p.stem for p in directory.glob("*.toml")}, set(ROLES))
            for role, (model, effort, sandbox) in ROLES.items():
                with self.subTest(profile=profile, role=role):
                    path = directory / (role + ".toml")
                    self.assertTrue(path.is_file(), str(path))
                    config = read_toml(path)
                    self.assertEqual(config["name"], role)
                    self.assertEqual((config["model"], config["model_reasoning_effort"],
                                      config["sandbox_mode"]), (model, effort, sandbox))
                    self.assertEqual(config["agents"], {"enabled": False},
                                     "Only the root may dispatch agents; no recursive swarms.")
                    self.assertTrue(config["description"].strip())
                    self.assertTrue(config["developer_instructions"].strip())

    def test_worker_remains_an_implementation_compatibility_alias(self):
        for profile in PROFILES:
            directory = ROOT / "profiles" / profile / "codex/agents"
            with self.subTest(profile=profile):
                worker = read_toml(directory / "worker.toml")
                implementer = read_toml(directory / "implementer.toml")
                for key in ("model", "model_reasoning_effort", "sandbox_mode",
                            "developer_instructions", "agents"):
                    self.assertEqual(worker[key], implementer[key])

    def test_skill_name_model_matrix_and_routing_policy(self):
        for profile in PROFILES:
            with self.subTest(profile=profile):
                skills = ROOT / "profiles" / profile / "agents/skills"
                self.assertEqual({p.name for p in skills.iterdir()}, {"sol-orchestrator"})
                content = (skills / "sol-orchestrator/SKILL.md").read_text(encoding="utf-8")
                self.assertTrue(content.startswith("---\nname: sol-orchestrator\n"))
                self.assertIn("description: Use when", content)
                for role, (model, effort, sandbox) in ROLES.items():
                    self.assertIn(f"| {role} | `{model}` | `{effort}` | {sandbox} |", content)
                # Contract checks, not claims that a model obeyed these instructions.
                for phrase in ("one corrective retry", "two total attempts",
                               "at most one Astra consultation", "separate context",
                               "not a programmatic scheduler", "authentication",
                               "Do not invent tool parameters"):
                    self.assertIn(phrase, content)
                self.assertNotIn("gpt-5.6-", content)
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

    def test_managed_instructions_and_documentation_are_consistent(self):
        instructions = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
        self.assertEqual(instructions.count("<!-- codex-orchestrator:begin -->"), 1)
        self.assertEqual(instructions.count("<!-- codex-orchestrator:end -->"), 1)
        self.assertIn("`sol-orchestrator`", instructions)
        self.assertIn("Do not commit or push unless explicitly authorized", instructions)
        self.assertNotIn("GPT-5.6", instructions)
        for installer in ("setup.sh", "setup.ps1"):
            self.assertNotIn("gpt-5.6-", (ROOT / installer).read_text(encoding="utf-8"))
        paths = [ROOT / "README.md", *sorted((ROOT / "guides").glob("*.md"))]
        self.assertEqual(len(paths), 8)
        for path in paths:
            with self.subTest(path=path.name):
                content = path.read_text(encoding="utf-8")
                for match in re.finditer(r"```toml\n(.*?)```", content, re.S):
                    config = tomllib.loads(match.group(1))
                    if "model" in config:
                        self.assertEqual((config["model"], config["model_reasoning_effort"]),
                                         ("gpt-6-sol", "high"))
                for link in re.findall(r"\]\(([^)#]+)(?:#[^)]*)?\)", content):
                    if "://" not in link and link != "LICENSE":
                        self.assertTrue((path.parent / link).exists(), (path.name, link))
        readme = paths[0].read_text(encoding="utf-8")
        self.assertIn("git clone https://github.com/LSthemagic/codex-orchestrator.git", readme)
        self.assertIn("not a semantic TOML merge", readme)
        self.assertIn("donvito/codex-astra-luna-orchestrator", readme)


if __name__ == "__main__":
    unittest.main()

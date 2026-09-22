"""Exercise the real installers in disposable directories, never a user project."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]
POWERSHELL = shutil.which("powershell") or shutil.which("pwsh")
SH = shutil.which("sh") if os.name != "nt" else None


LEGACY_RULES = '# Codex project instructions\n\nFor complex coding tasks, use the `sol-orchestrator` skill when its trigger conditions match.\n\nThe root runs on GPT-5.6 Sol with high reasoning and owns architecture, decomposition,\nintegration and final verification. All named subagents, including reviewer, use\nGPT-5.6 Luna with max reasoning. Start the reviewer in a separate context from the worker.\n\nPrefer bounded exploration, implementation, testing, review and technical research.\nDo not delegate trivial work merely for parallelism. Respect the configured concurrent\nchild-thread limit and do not let implementation agents edit overlapping files.\nDo not commit or push unless explicitly authorized by the user.\nUser instructions always take precedence over this orchestration policy.\n'


class InstallerCases:
    command = []

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="sol installer ")
        self.addCleanup(self.temp.cleanup)
        self.target = Path(self.temp.name) / "target project"
        self.target.mkdir()

    def run_setup(self, answers, target=None):
        target = target or self.target
        result = subprocess.run(
            self.command,
            input="\n".join(["2", answers[0] if answers else "1", str(target), *answers[1:]]) + "\n",
            text=True, capture_output=True, cwd=ROOT, timeout=40,
        )
        return result

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def run_global(self, answers, existing_config=None):
        home = Path(self.temp.name) / "home"
        codex_home = home / ".codex"
        codex_home.mkdir(parents=True, exist_ok=True)
        if existing_config is not None:
            (codex_home / "config.toml").write_text(existing_config, encoding="utf-8")
        env = os.environ.copy()
        env["HOME"] = str(home)
        env["USERPROFILE"] = str(home)
        env["CODEX_HOME"] = str(codex_home)
        result = subprocess.run(
            self.command,
            input="\n".join(["1", *answers]) + "\n",
            text=True, capture_output=True, cwd=ROOT, timeout=40, env=env,
        )
        return result, home, codex_home

    def test_global_fresh_install_is_default_scope(self):
        result, home, codex_home = self.run_global(["1", ""])
        self.assert_success(result)
        config = tomllib.loads((codex_home / "config.toml").read_text(encoding="utf-8"))
        self.assertEqual(config["model"], "gpt-6-sol")
        self.assertEqual(config["model_reasoning_effort"], "high")
        self.assertEqual(config["agents"]["default_subagent_model"], "gpt-6-luna")
        self.assertEqual(config["agents"]["default_subagent_reasoning_effort"], "max")
        self.assertTrue((codex_home / "agents/reviewer.toml").is_file())
        self.assertTrue((home / ".agents/skills/sol-orchestrator/SKILL.md").is_file())
        self.assertTrue((codex_home / "AGENTS.md").is_file())

    def test_global_merge_preserves_unrelated_config_and_creates_backup(self):
        original = 'model = "old"\ncustom_setting = "keep"\n[mcp_servers.demo]\ncommand = "demo"\n'
        result, home, codex_home = self.run_global(["3", ""], original)
        self.assert_success(result)
        merged_text = (codex_home / "config.toml").read_text(encoding="utf-8")
        merged = tomllib.loads(merged_text)
        self.assertEqual(merged["model"], "gpt-6-sol")
        self.assertEqual(merged["model_reasoning_effort"], "high")
        self.assertEqual(merged["custom_setting"], "keep")
        self.assertEqual(merged["mcp_servers"]["demo"]["command"], "demo")
        self.assertEqual(merged["agents"]["max_concurrent_threads_per_session"], 2)
        self.assertEqual((codex_home / "config.toml.bak").read_text(encoding="utf-8"), original)


    def test_fresh_install_all_profiles(self):
        cases = [("", "pro", 4), ("1", "pro", 4), ("2", "plus", 4),
                 ("3", "pro-max-2-subagents", 2), ("4", "plus-max-2-subagents", 2)]
        for selection, profile, limit in cases:
            with self.subTest(selection=selection):
                target = self.target / (selection or "default")
                target.mkdir()
                result = self.run_setup([selection, "", "", ""], target)
                self.assert_success(result)
                self.assertIn("GPT-6 Sol (high)", result.stdout)
                self.assertNotIn("GPT-6 Astra", result.stdout)
                for component, source in [(".codex", "codex"), (".agents", "agents")]:
                    for path in (ROOT / "profiles" / profile / source).rglob("*"):
                        if path.is_file():
                            installed = target / component / path.relative_to(ROOT / "profiles" / profile / source)
                            self.assertEqual(installed.read_bytes(), path.read_bytes())
                config = tomllib.loads((target / ".codex/config.toml").read_text(encoding="utf-8"))
                self.assertEqual(config["agents"]["max_concurrent_threads_per_session"], limit)
                self.assertEqual((target / "AGENTS.md").read_bytes(), (ROOT / "AGENTS.md").read_bytes())

    def test_named_profiles_remain_accepted(self):
        for profile in ("pro", "plus", "pro-max-2-subagents", "plus-max-2-subagents"):
            with self.subTest(profile=profile):
                result = self.run_setup([profile, "n", "n", "n"])
                self.assert_success(result)
                self.assertIn("plan: " + profile, result.stdout)

    def test_existing_config_is_preserved_when_update_declined(self):
        config = self.target / ".codex/config.toml"
        config.parent.mkdir()
        original = 'model = "custom-model"\n[mcp_servers.keep]\ncommand = "keep-me"\n'
        config.write_text(original, encoding="utf-8")
        result = self.run_setup(["1", "y", "", "n", "n"])
        self.assert_success(result)
        self.assertEqual(config.read_text(encoding="utf-8"), original)
        self.assertIn("existing target left unchanged", result.stdout)
        self.assertFalse((config.parent / "agents").exists())

    def test_approved_update_preserves_unrelated_files(self):
        config = self.target / ".codex/config.toml"
        config.parent.mkdir()
        config.write_text('model = "old-model"\n', encoding="utf-8")
        extra = self.target / ".codex/custom-note.txt"
        extra.write_text("keep this", encoding="utf-8")
        result = self.run_setup(["1", "y", "y", "n", "n"])
        self.assert_success(result)
        self.assertEqual(extra.read_text(encoding="utf-8"), "keep this")
        self.assertEqual(tomllib.loads(config.read_text(encoding="utf-8"))["model"], "gpt-6-sol")

    def test_agents_append_is_idempotent(self):
        path = self.target / "AGENTS.md"
        path.write_text("# Project rules\nPreserve this rule.\n", encoding="utf-8")
        self.assert_success(self.run_setup(["1", "n", "n", "y"]))
        first = path.read_bytes()
        self.assert_success(self.run_setup(["1", "n", "n", "y"]))
        self.assertEqual(path.read_bytes(), first)
        self.assertIn(b"Preserve this rule.", first)
        self.assertEqual(first.count(b"For complex coding tasks"), 1)


    def test_global_upgrade_replaces_old_rules_and_is_idempotent(self):
        home = Path(self.temp.name) / "home"
        codex_home = home / ".codex"
        codex_home.mkdir(parents=True)
        path = codex_home / "AGENTS.md"
        original = "# Personal rules\nKeep my rules.\n\n" + LEGACY_RULES + "\nKeep trailing rules.\n"
        path.write_text(original, encoding="utf-8")
        result, _, _ = self.run_global(["1", ""])
        self.assert_success(result)
        actual = path.read_text(encoding="utf-8")
        self.assertIn("Keep my rules.", actual)
        self.assertIn("Keep trailing rules.", actual)
        self.assertNotIn("GPT-5.6", actual)
        self.assertEqual(actual.count("<!-- codex-orchestrator:begin -->"), 1)
        self.assertEqual(path.with_name("AGENTS.md.bak").read_text(encoding="utf-8"), original)
        before = path.read_bytes()
        result, _, _ = self.run_global(["1", ""])
        self.assert_success(result)
        self.assertEqual(path.read_bytes(), before)
        self.assertEqual(path.with_name("AGENTS.md.bak").read_text(encoding="utf-8"), original)
        for role, model, effort in (
            ("explorer", "gpt-6-luna", "medium"), ("researcher", "gpt-6-luna", "max"),
            ("implementer", "gpt-6-luna", "max"), ("worker", "gpt-6-luna", "max"),
            ("tester", "gpt-6-luna", "high"), ("debugger", "gpt-6-sol", "high"),
            ("reviewer", "gpt-6-sol", "high"), ("architect", "gpt-6-sol", "xhigh"),
            ("escalation", "gpt-6-astra", "high"),
        ):
            with self.subTest(role=role):
                config = tomllib.loads((codex_home / "agents" / (role + ".toml")).read_text(encoding="utf-8"))
                self.assertEqual((config["model"], config["model_reasoning_effort"]), (model, effort))
                self.assertFalse(config["agents"]["enabled"])

    def test_project_upgrade_replaces_old_rules_and_preserves_crlf_text(self):
        path = self.target / "AGENTS.md"
        original = "# Project rules\nKeep this first.\n\n" + LEGACY_RULES + "\nKeep this last.\n"
        path.write_bytes(original.replace("\n", "\r\n").encode())
        self.assert_success(self.run_setup(["1", "n", "n", "y"]))
        actual = path.read_text(encoding="utf-8")
        self.assertNotIn("GPT-5.6", actual)
        self.assertIn("Keep this first.", actual)
        self.assertIn("Keep this last.", actual)
        self.assertEqual(actual.count("<!-- codex-orchestrator:begin -->"), 1)
        self.assertEqual(path.with_name("AGENTS.md.bak").read_bytes(), original.replace("\n", "\r\n").encode())

    def test_managed_block_is_replaced_without_touching_outside_rules(self):
        path = self.target / "AGENTS.md"
        original = ("# Custom\nKeep before.\n\n<!-- codex-orchestrator:begin -->\n"
                    "Old managed policy.\n<!-- codex-orchestrator:end -->\n\nKeep after.\n")
        path.write_text(original, encoding="utf-8")
        self.assert_success(self.run_setup(["1", "n", "n", "y"]))
        actual = path.read_text(encoding="utf-8")
        self.assertNotIn("Old managed policy.", actual)
        self.assertIn("Keep before.", actual)
        self.assertIn("Keep after.", actual)
        self.assertEqual(actual.count("<!-- codex-orchestrator:begin -->"), 1)

    def test_customized_legacy_rules_require_manual_migration_before_writes(self):
        path = self.target / "AGENTS.md"
        original = LEGACY_RULES.replace("high reasoning", "medium reasoning")
        path.write_text(original, encoding="utf-8")
        result = self.run_setup(["1", "y", "y", "y"])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("guides/migration.md", result.stdout + result.stderr)
        self.assertEqual(path.read_text(encoding="utf-8"), original)
        self.assertFalse((self.target / ".codex").exists())

    def test_invalid_managed_markers_abort_before_config_changes(self):
        for original in (
            "<!-- codex-orchestrator:begin -->\nUnclosed policy.\n",
            "<!-- codex-orchestrator:end -->\nOrphan end.\n",
            ("<!-- codex-orchestrator:begin -->\n<!-- codex-orchestrator:end -->\n" * 2),
        ):
            with self.subTest(original=original):
                path = self.target / "AGENTS.md"
                path.write_text(original, encoding="utf-8")
                result = self.run_setup(["1", "y", "y", "y"])
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(path.read_text(encoding="utf-8"), original)
                self.assertFalse((self.target / ".codex").exists())

    def test_global_customized_legacy_rules_abort_before_config_changes(self):
        codex_home = Path(self.temp.name) / "home/.codex"
        codex_home.mkdir(parents=True)
        original = 'model = "custom-model"\n'
        (codex_home / "config.toml").write_text(original, encoding="utf-8")
        (codex_home / "AGENTS.md").write_text(LEGACY_RULES.replace("high reasoning", "medium reasoning"), encoding="utf-8")
        result, _, _ = self.run_global(["1", ""])
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((codex_home / "config.toml").read_text(encoding="utf-8"), original)
        self.assertFalse((codex_home / "agents").exists())

    def test_global_missing_root_values_are_not_confused_with_nested_values(self):
        original = ('[profiles.custom]\nmodel = "keep-model"\nmodel_reasoning_effort = "low"\n'
                    'sandbox_mode = "read-only"\napproval_policy = "never"\n'
                    '[agents]\nenabled = false\nmax_concurrent_threads_per_session = 8\n'
                    'default_subagent_model = "old"\ndefault_subagent_reasoning_effort = "low"\n'
                    '[mcp_servers.demo]\ncommand = "keep-command"\n')
        result, _, codex_home = self.run_global(["3", ""], original)
        self.assert_success(result)
        merged = tomllib.loads((codex_home / "config.toml").read_text(encoding="utf-8"))
        self.assertEqual(merged.get("model"), "gpt-6-sol")
        self.assertEqual(merged.get("model_reasoning_effort"), "high")
        self.assertEqual(merged.get("sandbox_mode"), "workspace-write")
        self.assertEqual(merged["profiles"]["custom"]["model"], "keep-model")
        self.assertEqual(merged["profiles"]["custom"]["sandbox_mode"], "read-only")
        self.assertEqual(merged["mcp_servers"]["demo"]["command"], "keep-command")
        self.assertEqual(merged["agents"]["max_concurrent_threads_per_session"], 2)
        self.assertEqual(merged["agents"]["default_subagent_model"], "gpt-6-luna")

    def test_can_skip_every_component(self):
        result = self.run_setup(["1", "n", "n", "n"])
        self.assert_success(result)
        self.assertEqual(list(self.target.iterdir()), [])
        self.assertIn("0 component(s)", result.stdout)

    def test_missing_target_is_rejected(self):
        result = self.run_setup([], self.target / "missing")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.target.iterdir()), [])

    def test_source_directory_is_rejected(self):
        result = self.run_setup([], ROOT)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("different from the setup source", result.stdout + result.stderr)

    def test_end_of_input_cancels_before_writes(self):
        result = self.run_setup([])
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.target.iterdir()), [])

    def test_conflicting_component_type_is_not_overwritten(self):
        path = self.target / ".codex"
        path.write_text("keep", encoding="utf-8")
        result = self.run_setup(["1", "y", "n", "n"])
        self.assert_success(result)
        self.assertEqual(path.read_text(encoding="utf-8"), "keep")

    def test_legacy_skill_blocks_install_without_mutations(self):
        path = self.target / ".agents/skills/astra-orchestrator/SKILL.md"
        path.parent.mkdir(parents=True)
        path.write_text("legacy instructions", encoding="utf-8")
        result = self.run_setup(["1", "y", "y", "y"])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("guides/migration.md", result.stdout + result.stderr)
        self.assertEqual(path.read_text(encoding="utf-8"), "legacy instructions")
        self.assertFalse((self.target / ".codex").exists())

    def test_legacy_agents_reference_blocks_install(self):
        path = self.target / "AGENTS.md"
        path.write_text("Use the `astra-orchestrator` skill.\n", encoding="utf-8")
        original = path.read_bytes()
        result = self.run_setup(["1", "y", "y", "y"])
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(path.read_bytes(), original)
        self.assertFalse((self.target / ".codex").exists())

    def test_nested_symlink_is_not_followed(self):
        codex = self.target / ".codex"
        codex.mkdir()
        outside = Path(self.temp.name) / "outside"
        outside.mkdir()
        try:
            (codex / "agents").symlink_to(outside, target_is_directory=True)
        except (OSError, NotImplementedError):
            self.skipTest("Symlink creation is not permitted on this runner")
        result = self.run_setup(["1", "y", "n", "n"])
        self.assert_success(result)
        self.assertEqual(list(outside.iterdir()), [])
        self.assertFalse((codex / "config.toml").exists())


@unittest.skipUnless(SH, "POSIX shell unavailable")
class ShellInstallerTests(InstallerCases, unittest.TestCase):
    command = [SH or "sh", str(ROOT / "setup.sh")]


@unittest.skipUnless(POWERSHELL, "PowerShell unavailable")
class PowerShellInstallerTests(InstallerCases, unittest.TestCase):
    command = [POWERSHELL or "pwsh", "-NoLogo", "-NoProfile", "-NonInteractive",
               "-ExecutionPolicy", "Bypass", "-File", str(ROOT / "setup.ps1")]


if __name__ == "__main__":
    unittest.main()

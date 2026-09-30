"""Regression tests for the catalog consumer audit.

Each case builds a throwaway workspace out of real git repositories (the
audit reads tracked files through git) and runs the audit's own entry point
as a subprocess; nothing is mocked.
"""

from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import unittest

from audit_catalog_consumers import dependency_literals

SCRIPT = Path(__file__).resolve().with_name("audit_catalog_consumers.py")


def git(repo, *args):
    subprocess.run(["git", "-C", str(repo), *args], check=True,
                   capture_output=True)


class DependencyLiteralTests(unittest.TestCase):
    def test_block_inline_nested_and_ended(self):
        source = textwrap.dedent('''\
            package consumer:
              uses:
                "sqlite3 >=3"
                # "commented >=1"
                when not defined(windows):
                  "llvm-config >=0"
              nativeBuildDeps: "make >=4"
              executable consumer:
                "not-a-dependency"
            ''')
        self.assertEqual(dependency_literals(source), [
            (3, "sqlite3 >=3"), (6, "llvm-config >=0"), (7, "make >=4")])

    def test_a_recipe_written_as_a_test_string_is_scanned(self):
        source = 'const Recipe = """\npackage p:\n  uses:\n    "sqlite3"\n"""\n'
        self.assertEqual(dependency_literals(source), [(4, "sqlite3")])


class AuditTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="catalog audit ")
        self.addCleanup(self.temp.cleanup)
        self.workspace = Path(self.temp.name)
        catalog = self.workspace / "reprobuild-packages"
        for name in ["sqlite3", "patchelf"]:
            interface = catalog / "packages" / "interfaces" / name
            interface.mkdir(parents=True)
            (interface / "repro.nim").write_text(f"package {name}:\n  discard\n")
        self.catalog = catalog
        dsl = self.workspace / "reprobuild" / "libs" / "repro_project_dsl" / "src" / "repro_project_dsl"
        dsl.mkdir(parents=True)
        (dsl / "macros_a.nim").write_text(textwrap.dedent('''\
            proc usesImportCode(pkg: PackageDef): string =
              proc isBundledStdlibSelector(selector: string): bool =
                selector in [
                  "gcc",
                  # "patchelf" is not bundled
                  "nim"
                ]
            '''))
        (dsl / "reprobuild_packages_catalog.nim").write_text(
            'const MovedToReprobuildPackages*: seq[string] = @["sqlite3"]\n')

    def repo(self, name, files):
        repo = self.workspace / name
        repo.mkdir()
        git(repo, "init", "-q")
        for relative, text in files.items():
            path = repo / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
        git(repo, "add", ".")
        return repo

    def audit(self, *repos):
        args = [sys.executable, str(SCRIPT), "--catalog", str(self.catalog),
                "--workspace", str(self.workspace)]
        for repo in repos:
            args += ["--repo", str(repo)]
        return subprocess.run(args, capture_output=True, text=True)

    recipe = 'package c:\n  uses:\n    "sqlite3 >=3"\n    "gcc >=12"\n'
    workflow = {".github/workflows/ci.yml": "on: push\n"}

    def test_consumer_without_a_channel_fails_and_is_named(self):
        repo = self.repo("consumer", {"repro.nim": self.recipe, **self.workflow})
        result = self.audit(repo)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("uses 'sqlite3 >=3' [moved]  repro.nim:3", result.stdout)
        self.assertIn("NO CHANNEL", result.stdout)
        self.assertIn("declare no way for CI to reach the catalog: consumer",
                      result.stderr)

    def test_sibling_repos_entry_is_a_channel(self):
        repo = self.repo("consumer", {
            "repro.nim": self.recipe, **self.workflow,
            ".github/sibling-repos": "# catalog\nreprobuild-packages=dev\n"})
        result = self.audit(repo)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(".github/sibling-repos:2: reprobuild-packages=dev", result.stdout)

    def test_nix_export_is_a_channel(self):
        repo = self.repo("consumer", {
            "repro.nim": self.recipe, **self.workflow,
            "nix/shell.nix": "export REPROBUILD_PACKAGES_ROOT=${inputs.catalog}\n"})
        result = self.audit(repo)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("nix/shell.nix:1: REPROBUILD_PACKAGES_ROOT", result.stdout)

    def test_a_commented_channel_is_not_a_channel(self):
        repo = self.repo("consumer", {
            "repro.nim": self.recipe, **self.workflow,
            ".github/sibling-repos": "# reprobuild-packages=dev\n"})
        self.assertEqual(self.audit(repo).returncode, 1)

    def test_a_repository_without_ci_is_reported_not_failed(self):
        repo = self.repo("consumer", {"repro.nim": self.recipe})
        result = self.audit(repo)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("no CI workflows", result.stdout)

    def test_bundled_names_and_non_consumers_are_ignored(self):
        repo = self.repo("other", {"repro.nim": 'package o:\n  uses:\n    "gcc >=12"\n',
                                   **self.workflow})
        result = self.audit(repo)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("catalog-only names: patchelf, sqlite3", result.stdout)
        self.assertIn("0 consume the catalog", result.stdout)


if __name__ == "__main__":
    unittest.main()

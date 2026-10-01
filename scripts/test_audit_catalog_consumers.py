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

from audit_catalog_consumers import dependency_literals, stdlib_package_imports

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


class StdlibPackageImportTests(unittest.TestCase):
    def test_every_import_spelling_is_found(self):
        source = textwrap.dedent('''\
            import repro_dsl_stdlib/packages/prek
            import std/os, repro_dsl_stdlib/packages/shfmt as shfmt_module
            from repro_dsl_stdlib/packages/sqlite3 import nil
            import "repro_dsl_stdlib/packages/pkg_config"
            import repro_dsl_stdlib/packages/[gcc, nim except package]
            import repro_dsl_stdlib/packages/[
              make,
              ninja]
            ''')
        self.assertEqual([(line, name) for line, name, _ in stdlib_package_imports(source)], [
            (1, "prek"), (2, "shfmt"), (3, "sqlite3"), (4, "pkg_config"),
            (5, "gcc"), (5, "nim"), (6, "make"), (6, "ninja")])

    def test_comments_and_non_imports_are_not_imports(self):
        source = textwrap.dedent('''\
            # import repro_dsl_stdlib/packages/prek
            import std/os  # was: repro_dsl_stdlib/packages/shfmt
            const path = "repro_dsl_stdlib/packages/prek.nim"
            ''')
        self.assertEqual(stdlib_package_imports(source), [])


class AuditTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="catalog audit ")
        self.addCleanup(self.temp.cleanup)
        self.workspace = Path(self.temp.name)
        catalog = self.workspace / "reprobuild-packages"
        for name in ["sqlite3", "patchelf", "prek", "shfmt"]:
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
                  "nim",
                  "shfmt"
                ]
            '''))
        (dsl / "reprobuild_packages_catalog.nim").write_text(
            'const MovedToReprobuildPackages*: seq[string] =\n'
            '  @["sqlite3", "prek"]\n')

    def repo(self, name, files, parent=None):
        repo = (parent or self.workspace) / name
        repo.mkdir()
        git(repo, "init", "-q")
        for relative, text in files.items():
            path = repo / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
        git(repo, "add", ".")
        return repo

    def audit(self, *repos, also=()):
        args = [sys.executable, str(SCRIPT), "--catalog", str(self.catalog),
                "--workspace", str(self.workspace)]
        for repo in repos:
            args += ["--repo", str(repo)]
        for repo in also:
            args += ["--also", str(repo)]
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
        self.assertIn("catalog-only names: patchelf, prek, sqlite3", result.stdout)
        self.assertIn("0 consume the catalog", result.stdout)

    importing_recipe = textwrap.dedent('''\
        import repro_dsl_stdlib/packages/[prek, shfmt]

        package c:
          uses:
            "prek"
            "shfmt"
        ''')
    sibling = {".github/sibling-repos": "reprobuild-packages=dev\n"}

    def test_a_direct_import_of_a_moved_module_fails_and_is_named(self):
        repo = self.repo("consumer", {"repro.nim": self.importing_recipe,
                                      **self.workflow, **self.sibling})
        result = self.audit(repo)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("imports repro_dsl_stdlib/packages/prek "
                      "[MOVED: no longer in the stdlib]  repro.nim:1", result.stdout)
        self.assertIn("imports repro_dsl_stdlib/packages/shfmt "
                      "[still in the stdlib; breaks when it moves]  repro.nim:1",
                      result.stdout)
        self.assertIn("1 direct import(s) of a stdlib module that moved", result.stderr)
        self.assertIn("consumer: repro.nim:1: repro_dsl_stdlib/packages/prek",
                      result.stderr)
        self.assertIn("rely on the package's `uses:` line", result.stderr)

    def test_a_direct_import_still_in_the_stdlib_is_a_hazard_not_a_failure(self):
        repo = self.repo("consumer", {
            "repro.nim": "import repro_dsl_stdlib/packages/shfmt\n", **self.workflow})
        result = self.audit(repo)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("imports repro_dsl_stdlib/packages/shfmt "
                      "[still in the stdlib; breaks when it moves]  repro.nim:1",
                      result.stdout)

    def test_imports_of_modules_the_catalog_does_not_define_are_ignored(self):
        repo = self.repo("consumer", {
            "repro.nim": "import repro_dsl_stdlib/packages/gcc\n", **self.workflow})
        result = self.audit(repo)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("0 consume the catalog", result.stdout)

    def test_a_checkout_outside_the_workspace_is_audited_with_also(self):
        outside = tempfile.TemporaryDirectory(prefix="outside workspace ")
        self.addCleanup(outside.cleanup)
        repo = self.repo("agent-harbor", {"repro.nim": self.importing_recipe,
                                          **self.workflow, **self.sibling},
                         parent=Path(outside.name))
        self.repo("bystander", {"repro.nim": "package b:\n  discard\n"})
        without = self.audit()
        self.assertEqual(without.returncode, 0, without.stdout + without.stderr)
        self.assertNotIn("agent-harbor", without.stdout + without.stderr)
        result = self.audit(also=[repo])
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("agent-harbor: repro.nim:1: repro_dsl_stdlib/packages/prek",
                      result.stderr)

    def test_also_refuses_a_path_that_is_not_a_checkout(self):
        result = self.audit(also=[self.workspace / "no-such-checkout"])
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("not a git checkout", result.stderr)


if __name__ == "__main__":
    unittest.main()

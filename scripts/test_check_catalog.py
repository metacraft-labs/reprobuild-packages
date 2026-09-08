"""Portable regression tests for the catalog's structural checks."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from check_catalog import check_catalog


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="catalog checks ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def recipe(self, name, source):
        directory = self.root / name
        directory.mkdir()
        (directory / "repro.nim").write_text(source, encoding="utf-8")

    def test_valid_recipes_and_support_directory(self):
        self.recipe("bash", 'package bashSource:\n  buildDeps:\n    "pkg-config"\n')
        self.recipe("create-dmg", "package `create-dmg`:\n  discard\n")
        (self.root / "scripts").mkdir()
        self.assertEqual(check_catalog(self.root), (2, []))

    def test_missing_or_empty_root_fails(self):
        self.assertTrue(check_catalog(self.root / "absent")[1])
        self.assertTrue(check_catalog(self.root)[1])

    def test_missing_recipe_file_fails(self):
        (self.root / "bash").mkdir()
        self.assertEqual(check_catalog(self.root)[1], ["bash: missing repro.nim"])

    def test_missing_package_declaration_fails(self):
        self.recipe("bash", "# package bashSource:\n")
        self.assertEqual(
            check_catalog(self.root)[1], ["bash: missing package declaration"]
        )

    def test_provider_dependency_rejected_but_capability_accepted(self):
        for selector in ('"pkgconf"', '"pkgconf >=1.0"'):
            with self.subTest(selector=selector):
                path = self.root / "pkg"
                path.mkdir(exist_ok=True)
                (path / "repro.nim").write_text(
                    f"package pkgSource:\n  buildDeps:\n    {selector}\n",
                    encoding="utf-8",
                )
                self.assertIn("pkg-config capability", check_catalog(self.root)[1][0])

    def test_identity_rules_fail_independently(self):
        self.recipe("bash", "package bash:\n")
        self.recipe("create-dmg", "package createDmgSource:\n")
        failures = check_catalog(self.root)[1]
        self.assertEqual(len(failures), 2)
        self.assertIn("must end in Source", failures[0])
        self.assertIn("expected package identity create-dmg", failures[1])

    def test_cli_exit_status_and_diagnostics(self):
        script = Path(__file__).with_name("check_catalog.py")
        command = [sys.executable, str(script), "--root", str(self.root)]
        failed = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(failed.returncode, 1)
        self.assertIn("no source recipes", failed.stderr)
        self.recipe("bash", "package bashSource:\n")
        passed = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(passed.returncode, 0, passed.stderr)
        self.assertIn("Validated 1 source recipes", passed.stdout)


if __name__ == "__main__":
    unittest.main()

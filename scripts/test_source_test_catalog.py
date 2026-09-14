import contextlib
import io
from pathlib import Path
import tempfile
import unittest

from source_test_catalog import discover, main, render


class SourceTestCatalogTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def add_test(self, relative):
        path = self.root / "packages" / "source" / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("discard\n", encoding="utf-8")
        return path

    def run_catalog(self, *arguments):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return main(["--root", str(self.root), *arguments])

    def test_stable_sorted_inventory_includes_shared_tests(self):
        self.add_test("zlib/test_zlib_source.nim")
        self.add_test("test_source_recipe_paths.nim")
        self.add_test("bash/test_bash_source.nim")
        self.assertEqual(discover(self.root), [
            "packages/source/bash/test_bash_source.nim",
            "packages/source/test_source_recipe_paths.nim",
            "packages/source/zlib/test_zlib_source.nim",
        ])

    def test_build_outputs_are_not_discovered(self):
        self.add_test("pcre2/test_pcre2_source.nim")
        self.add_test("pcre2/build/test_generated.nim")
        self.assertEqual(len(discover(self.root)), 1)

    def test_empty_catalog_is_rejected(self):
        self.assertEqual(self.run_catalog("--write"), 1)
        self.assertFalse((self.root / "source_tests.nim").exists())

    def test_target_collisions_are_rejected(self):
        self.add_test("a/test_same_name.nim")
        self.add_test("b/test_same-name.nim")
        with self.assertRaisesRegex(ValueError, "duplicate source-test target"):
            discover(self.root)

    def test_write_then_check_is_stable(self):
        self.add_test("pcre2/test_pcre2_source.nim")
        self.assertEqual(self.run_catalog("--write"), 0)
        self.assertEqual(self.run_catalog(), 0)
        self.assertEqual((self.root / "source_tests.nim").read_text(encoding="utf-8"),
                         render(discover(self.root)))

    def test_added_test_invalidates_inventory(self):
        self.add_test("pcre2/test_pcre2_source.nim")
        self.assertEqual(self.run_catalog("--write"), 0)
        self.add_test("bash/test_bash_source.nim")
        self.assertEqual(self.run_catalog(), 1)

    def test_removed_test_invalidates_inventory(self):
        path = self.add_test("pcre2/test_pcre2_source.nim")
        self.add_test("bash/test_bash_source.nim")
        self.assertEqual(self.run_catalog("--write"), 0)
        path.unlink()
        self.assertEqual(self.run_catalog(), 1)


if __name__ == "__main__":
    unittest.main()

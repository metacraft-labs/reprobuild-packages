import std/[os, strutils, unittest]

import ./source_recipe_paths

suite "source recipe catalog paths":
  test "explicit catalog root controls package install paths":
    let hadSourceRoot = existsEnv("REPRO_FROM_SOURCE_ROOT")
    let oldSourceRoot = getEnv("REPRO_FROM_SOURCE_ROOT")
    defer:
      if hadSourceRoot:
        putEnv("REPRO_FROM_SOURCE_ROOT", oldSourceRoot)
      else:
        delEnv("REPRO_FROM_SOURCE_ROOT")

    let catalogRoot = getTempDir() / "repro-package-catalog"
    putEnv("REPRO_FROM_SOURCE_ROOT", catalogRoot)

    check sourceRecipeRoot() == catalogRoot
    check sourcePackageRoot("glib2") == catalogRoot / "glib2"
    check sourcePackagePath("glib2", "build", "gir") ==
      catalogRoot / "glib2" / "build" / "gir"
    check sourcePackageInstallRoot("glib2").replace('\\', '/') ==
      (catalogRoot / "glib2" / ".repro" / "output" / "install").replace(
        '\\', '/')
    check sourcePackageInstallPath(
      "glib2", "usr", "include").replace('\\', '/') ==
      (catalogRoot / "glib2" / ".repro" / "output" / "install" /
        "usr" / "include").replace('\\', '/')

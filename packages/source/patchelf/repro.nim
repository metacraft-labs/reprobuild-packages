## Source-built patchelf for ELF runtime normalization.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package patchelfSource:
  versions:
    "0.15.2":
      sourceRevision = "0.15.2"
      sourceUrl = "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2"
      sourceRepository = "https://github.com/NixOS/patchelf.git"

  fetch:
    url: "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2"
    sha256: "17745f564159c8e228fc412da65a2048b846c4b6b4220b77cbf22416e02f2d7c"
    extractStrip: 1

  nativeBuildDeps:
    "make"
    "gcc >=11"

  buildDeps:
    discard

  config:
    discard

  executable patchelf:
    discard

  build:
    setCurrentOwningPackageOverride("patchelfSource")
    try:
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = @["--disable-dependency-tracking"],
      )
      discard pkg.executable("patchelf")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

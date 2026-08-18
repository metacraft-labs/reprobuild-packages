## GNU xorriso source recipe for deterministic ISO authoring.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package xorrisoSource:
  versions:
    "1.5.8.pl02":
      sourceRevision = "1.5.8.pl02"
      sourceUrl = "https://ftp.gnu.org/gnu/xorriso/xorriso-1.5.8.pl02.tar.gz"
      sourceRepository = "https://dev.lovelyhq.com/libburnia/libisoburn.git"

  fetch:
    url: "https://ftp.gnu.org/gnu/xorriso/xorriso-1.5.8.pl02.tar.gz"
    sha256: "b1455ecafbf0692ddafe1d71002a96f2ce2d77f4deae602678261ce033f97bc8"
    extractStrip: 1

  nativeBuildDeps:
    "make"
    "gcc >=11"
    "pkg-config"
    "patchelf"

  buildDeps:
    "zlib"

  config:
    discard

  executable xorriso:
    discard

  build:
    setCurrentOwningPackageOverride("xorrisoSource")
    try:
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = @["--disable-libreadline"],
      )
      discard pkg.executable("xorriso")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    "zlib"

## GNU mtools source recipe for creating and populating FAT images.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package mtoolsSource:
  versions:
    "4.0.49":
      sourceRevision = "v4.0.49"
      sourceUrl = "https://ftp.gnu.org/gnu/mtools/mtools-4.0.49.tar.gz"
      sourceRepository = "https://git.savannah.gnu.org/git/mtools.git"

  fetch:
    url: "https://ftp.gnu.org/gnu/mtools/mtools-4.0.49.tar.gz"
    sha256: "10cd1111da87bf2400a380c1639a6cba8bfb937a24f9c51f5f88d393ae5f6f76"
    extractStrip: 1

  nativeBuildDeps:
    "make"
    "gcc >=11"

  config:
    discard

  executable mtools:
    discard

  build:
    setCurrentOwningPackageOverride("mtoolsSource")
    try:
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = @["--disable-floppyd", "--disable-xdf"],
      )
      discard pkg.executable("mtools")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

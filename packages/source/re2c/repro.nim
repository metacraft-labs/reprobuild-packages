## re2c 3.1 source build for packages that generate C/C++ lexers.
##
## Clingo 5.8.0 requires the pre-4.3 grammar behavior. Keeping this recipe on
## the compatible 3.1 release avoids downstream source patches while making
## the lexer generator available through normal Reprobuild tool provisioning.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package re2cSource:
  versions:
    "3.1":
      sourceRevision = "3.1"
      sourceUrl = "https://github.com/skvadrik/re2c/releases/download/3.1/re2c-3.1.tar.xz"
      sourceRepository = "https://github.com/skvadrik/re2c"

  fetch:
    # Use the upstream release tarball: it contains the generated bootstrap
    # sources and therefore does not require an existing re2c executable.
    url: "https://github.com/skvadrik/re2c/releases/download/3.1/re2c-3.1.tar.xz"
    sha256: "0ac299ad359e3f512b06a99397d025cfff81d3be34464ded0656f8a96676c029"
    extractStrip: 1

  nativeBuildDeps:
    "make"
    "gcc >=11"
    "python3 >=3.7"

  executable re2c:
    discard

  build:
    setCurrentOwningPackageOverride("re2cSource")
    try:
      let pkg = autotools_package(
        srcDir = "./src",
        # The release includes its generated manual. Documentation
        # regeneration would add a docutils dependency to the bootstrap.
        configureOptions = @["--disable-docs"])
      discard pkg.executable("re2c")
      pkg.installTreeMirror()
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package zstdSource:
  versions:
    "1.5.7":
      sourceRevision = "v1.5.7"
      sourceUrl = "https://github.com/facebook/zstd/archive/v1.5.7.tar.gz"
      sourceRepository = "https://github.com/facebook/zstd"
  fetch:
    url: "https://github.com/facebook/zstd/archive/v1.5.7.tar.gz"
    sha256: "37d7284556b20954e56e1ca85b80226768902e2edabd3b649e9e72c0c9012ee3"
    extractStrip: 1
  nativeBuildDeps:
    "make"
    "gcc >=11"
    ## zig is the C toolchain of a cross build: `autotools_package` threads a
    ## zig `--target` with CC/AR/RANLIB naming its wrappers. Declared
    ## unconditionally, because dependency blocks are resolved at compile
    ## time; a native build never runs it. The Nim fork links this library
    ## when it is built for a target (the `nim-fork` recipe).
    "zig >=0.13 <0.14"
  buildDeps:
    "zlib"
  config:
    discard
  library libzstd:
    discard
  build:
    setCurrentOwningPackageOverride("zstdSource")
    try:
      let pkg = autotools_package(srcDir = "./src", configureOptions = @[
        "PREFIX=/usr",
        # Keep optional formats independent of libraries in the caller's shell.
        "HAVE_ZLIB=1",
        "HAVE_LZMA=0",
        "HAVE_LZ4=0",
      ], skipConfigure = true)
      discard pkg.library("libzstd")
    finally:
      clearCurrentOwningPackageOverride()
  runtimeDeps:
    "zlib"

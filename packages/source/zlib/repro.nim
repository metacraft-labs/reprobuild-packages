import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  ZlibVersion* = "1.3.1"
  ZlibSourceUrl* =
    "https://github.com/madler/zlib/releases/download/v1.3.1/" &
    "zlib-1.3.1.tar.gz"
  ZlibSourceHash* =
    "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23"
  ZlibBuildDir* = ".repro/build/zlib-native"
  ZlibNativeBuildDeps* = [
    "make",
    "gcc >=11",
  ]
  ZlibWindowsMakeOptions* = [
    "-f",
    "win32/Makefile.gcc",
    "CFLAGS=-O3 -Wall -MMD -MP",
    "SHARED_MODE=1",
    "BINARY_PATH=/usr/bin",
    "INCLUDE_PATH=/usr/include",
    "LIBRARY_PATH=/usr/lib",
  ]
  ZlibWindowsMakeDepfiles* = [
    "adler32.d",
    "compress.d",
    "crc32.d",
    "deflate.d",
    "gzclose.d",
    "gzlib.d",
    "gzread.d",
    "gzwrite.d",
    "infback.d",
    "inffast.d",
    "inflate.d",
    "inftrees.d",
    "trees.d",
    "uncompr.d",
    "zutil.d",
    "example.d",
    "minigzip.d",
  ]

package zlibSource:
  versions:
    "1.3.1":
      sourceRevision = "v" & ZlibVersion
      sourceUrl = ZlibSourceUrl
      sourceRepository = "https://github.com/madler/zlib"

  fetch:
    url: ZlibSourceUrl
    sha256: ZlibSourceHash
    extractStrip: 1

  nativeBuildDeps:
    "make"
    "gcc >=11"

  config:
    discard

  library libZ:
    discard

  build:
    setCurrentOwningPackageOverride("zlibSource")
    try:
      when defined(windows):
        # Upstream's configure script recommends this Makefile for MinGW.
        let pkg = autotools_package(
          srcDir = "./src",
          buildDir = ZlibBuildDir,
          configureOptions = @ZlibWindowsMakeOptions,
          makeDependencyPolicy = makeDepfilePolicy(
            depfiles = ZlibWindowsMakeDepfiles),
          skipConfigure = true)
        discard pkg.libraryAlias("libZ", "zlib1")
      else:
        let pkg = autotools_package(
          srcDir = "./src",
          buildDir = ZlibBuildDir,
          configureOptions = @["--shared"])
        discard pkg.library("libZ")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

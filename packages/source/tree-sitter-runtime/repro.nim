## Build the Tree-sitter C runtime and public headers from upstream source.
## The CLI interface and its provisioning contributions remain independent.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  TreeSitterVersion* = "0.25.10"
  TreeSitterSourceUrl* =
    "https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v0.25.10.tar.gz"
  TreeSitterSourceHash* =
    "ad5040537537012b16ef6e1210a572b927c7cdc2b99d1ee88d44a7dcdc3ff44c"
  TreeSitterBuildDir* = ".repro/build/tree-sitter-runtime"
  TreeSitterCmakeOptions* = [
    "BUILD_SHARED_LIBS=OFF",
    "AMALGAMATED=ON",
    "CMAKE_INSTALL_LIBDIR=lib",
    "TREE_SITTER_FEATURE_WASM=OFF",
  ]

package treeSitterRuntimeSource:
  versions:
    "0.25.10":
      sourceRevision = "v" & TreeSitterVersion
      sourceUrl = TreeSitterSourceUrl
      sourceRepository = "https://github.com/tree-sitter/tree-sitter"

  fetch:
    url: TreeSitterSourceUrl
    sha256: TreeSitterSourceHash
    extractStrip: 1

  nativeBuildDeps:
    "cmake >=3.13"
    "ninja"
    "gcc >=12"

  library `tree-sitter`:
    ## The runtime archive; upstream installs tree_sitter/api.h alongside it.
    kind static


  build:
    setCurrentOwningPackageOverride("treeSitterRuntimeSource")
    try:
      # Upstream's library CMake project supports Windows as well as POSIX.
      # Its amalgamated C target and install rules own the source list,
      # compiler flags, archive and public-header installation.
      let pkg = cmake_package(
        srcDir = "./src/lib",
        buildDir = TreeSitterBuildDir,
        generator = "Ninja",
        cacheVars = @TreeSitterCmakeOptions)
      discard pkg.library("tree-sitter")
    finally:
      clearCurrentOwningPackageOverride()

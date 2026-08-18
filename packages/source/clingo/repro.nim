## Clingo 5.8.0 source build for the repro CLI's ASP solver runtime.
## The CLI loads libclingo.so by soname at process startup, so the
## bootable image must provide the library independently of the build
## environment used to compile the CLI.

import std/os
import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package clingoSource:
  versions:
    "5.8.0":
      sourceRevision = "v5.8.0"
      sourceUrl = "https://github.com/potassco/clingo/archive/refs/tags/v5.8.0.tar.gz"
      sourceRepository = "https://github.com/potassco/clingo"

  fetch:
    url: "https://github.com/potassco/clingo/archive/refs/tags/v5.8.0.tar.gz"
    sha256: "4ddd5975e79d7a0f8d126039f1b923a371b1a43e0e0687e1537a37d6d6d5cc7c"
    extractStrip: 1

  nativeBuildDeps:
    "cmake >=3.16"
    "ninja >=1.10"
    "gcc >=11"
    "bison >=3.0"
    # Clingo 5.8.0's vendored grammars require re2c's pre-4.3 behavior.
    "re2c >=3.0"

  config:
    discard

  library libclingo:
    discard

  build:
    setCurrentOwningPackageOverride("clingoSource")
    try:
      let providerRoot = activeProviderProjectRoot()
      var opts = @[
        "CMAKE_BUILD_TYPE=Release",
        "CMAKE_INSTALL_LIBDIR=lib",
        "CLINGO_BUILD_TESTS=OFF",
        "CLINGO_BUILD_EXAMPLES=OFF",
        "CLINGO_BUILD_APPS=OFF",
        "CLINGO_BUILD_SHARED=ON",
        "CLINGO_BUILD_WITH_PYTHON=OFF",
        "CLINGO_BUILD_WITH_LUA=OFF",
      ]
      var patches: seq[string] = @[]
      if providerRoot.len > 0:
        let re2cWrapper = providerRoot / "src" / "repro-re2c"
        opts.add("RE2C_EXECUTABLE=" & re2cWrapper)
        patches.add(
          "printf '%s\\n' '#!/bin/sh' 'unset LD_LIBRARY_PATH' " &
          "'exec re2c \"$@\"' > src/repro-re2c && " &
          "chmod +x src/repro-re2c")
      let pkg = cmake_package(
        srcDir = "./src",
        generator = "Ninja",
        cacheVars = opts,
        # Clingo generates libclingo/clingo.h below its source tree.
        allowSourceWrites = true,
        # Tool provisioning also exposes the source GCC runtime through
        # LD_LIBRARY_PATH. re2c must retain its own glibc/libstdc++ pair.
        extraEnv = @[("LD_LIBRARY_PATH", "")],
        srcPatches = patches)
      discard pkg.library("libclingo")
      pkg.installTreeMirror()
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

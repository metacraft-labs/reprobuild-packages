## Minimal source-built LLVM runtime and configuration tool for llvmpipe.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package llvmSource:
  versions:
    "21.1.8":
      sourceRevision = "llvmorg-21.1.8"
      sourceUrl = "https://github.com/llvm/llvm-project/archive/llvmorg-21.1.8.tar.gz"
      sourceRepository = "https://github.com/llvm/llvm-project.git"

  fetch:
    url: "https://github.com/llvm/llvm-project/archive/llvmorg-21.1.8.tar.gz"
    sha256: "7ba3f2a8d8fda88be18a31d011e8195d3b7f87f9fa92b20c94cba2d7f65b0e3f"
    extractStrip: 1

  nativeBuildDeps:
    "cmake >=3.20"
    "ninja >=1.10"
    "gcc >=11"
    "binutils >=2.39"
    "python3 >=3.8"

  config:
    discard

  executable "llvm-config":
    discard

  library libLLVM:
    discard

  build:
    setCurrentOwningPackageOverride("llvmSource")
    try:
      let opts = @[
        "CMAKE_BUILD_TYPE=Release",
        "CMAKE_INSTALL_LIBDIR=lib",
        "CMAKE_C_COMPILER=gcc",
        "CMAKE_CXX_COMPILER=g++",
        "BUILD_SHARED_LIBS=OFF",
        "LLVM_BUILD_LLVM_DYLIB=ON",
        "LLVM_LINK_LLVM_DYLIB=ON",
        "LLVM_ENABLE_RTTI=ON",
        "LLVM_TARGETS_TO_BUILD=X86",
        "LLVM_INCLUDE_TESTS=OFF",
        "LLVM_INCLUDE_EXAMPLES=OFF",
        "LLVM_INCLUDE_BENCHMARKS=OFF",
        "LLVM_INCLUDE_DOCS=OFF",
        "LLVM_ENABLE_BINDINGS=OFF",
        "LLVM_ENABLE_TERMINFO=OFF",
        "LLVM_ENABLE_ZLIB=OFF",
        "LLVM_ENABLE_ZSTD=OFF",
        "LLVM_ENABLE_LIBXML2=OFF",
        "LLVM_ENABLE_LIBEDIT=OFF",
        "LLVM_ENABLE_LIBPFM=OFF",
      ]
      let pkg = cmake_package(srcDir = "./src/llvm", generator = "Ninja",
        cacheVars = opts,
        extraEnv = @[("CMAKE_BUILD_PARALLEL_LEVEL", "8")],
        allowSourceWrites = true)
      discard pkg.executable("llvm-config")
      discard pkg.library("libLLVM")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

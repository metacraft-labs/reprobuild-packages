## ``libblake3`` -- the BLAKE3 C library, built from the upstream release for
## the platform being built FOR.
##
## Why it is here: reprobuild links ``libblake3`` in its system-hash mode, and
## under ``--target`` the library must be the target's, not the build host's
## (ReproOS-Add-On-Mode A15, the full armv7 prefix). reprobuild declares
## ``uses: "libblake3"``; natively that is the prefix ``BLAKE3_PREFIX`` names
## (the stdlib's ``environmentPrefix`` arm, Package-Model.md §"Environment-
## provided library prefixes", approved by Zahary Karadjov, 2026-11-02), and
## under ``--target`` it is THIS recipe built for the target.
##
## The recipe name is ``libblake3``, the selector the stdlib package uses --
## not ``blake3``, which is the Nim binding module's name.
##
## SIMD: ``BLAKE3_SIMD_TYPE=none``. The portable implementation runs on every
## target, including Debian's armhf baseline (ARMv7-A, VFPv3-D16, no NEON),
## where the NEON path would not assemble. It costs speed on x86-64, where
## this recipe is not what reprobuild links (the environment prefix is).
##
## The source archive is GitHub's tag archive, hashed when this recipe was
## written (2026-11-02); upstream publishes no signature for it.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package libblake3Source:
  versions:
    "1.8.5":
      sourceRevision = "1.8.5"
      sourceUrl = "https://github.com/BLAKE3-team/BLAKE3/archive/refs/tags/1.8.5.tar.gz"
      sourceRepository = "https://github.com/BLAKE3-team/BLAKE3"
  fetch:
    url: "https://github.com/BLAKE3-team/BLAKE3/archive/refs/tags/1.8.5.tar.gz"
    sha256: "220bd81286e2a0585beac66d41ac3f4c2c33ae8a4e339fc88cf22d5e00514fe9"
    extractStrip: 1
  nativeBuildDeps:
    "cmake >=3.16"
    "ninja >=1.10"
    "gcc >=11"
    ## zig is the C toolchain of a cross build: `cmake_package` threads a zig
    ## `--target` through a toolchain file naming its wrappers. Declared
    ## unconditionally, because dependency blocks are resolved at compile
    ## time; a native build never runs it.
    "zig >=0.13 <0.14"
  config:
    discard
  library libblake3:
    discard
  build:
    setCurrentOwningPackageOverride("libblake3Source")
    try:
      let pkg = cmake_package(
        srcDir = "./src/c",
        generator = "Ninja",
        cacheVars = @[
          "CMAKE_BUILD_TYPE=Release",
          "CMAKE_INSTALL_LIBDIR=lib",
          "BUILD_SHARED_LIBS=ON",
          "BLAKE3_SIMD_TYPE=none",
          "BLAKE3_USE_TBB=OFF",
          "BLAKE3_EXAMPLES=OFF",
        ])
      discard pkg.library("libblake3")
      pkg.installTreeMirror()
    finally:
      clearCurrentOwningPackageOverride()
  runtimeDeps:
    discard

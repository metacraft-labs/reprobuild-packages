## ``xxhash`` -- the xxHash C library, built from the upstream release for the
## platform being built FOR.
##
## Why it is here: reprobuild links ``libxxhash`` in its system-hash mode, and
## under ``--target`` the library must be the target's, not the build host's
## (ReproOS-Add-On-Mode A15, the full armv7 prefix). reprobuild declares
## ``uses: "xxhash"``; natively that is the prefix ``XXHASH_PREFIX`` names
## (the stdlib's ``environmentPrefix`` arm, Package-Model.md §"Environment-
## provided library prefixes", approved by Zahary Karadjov, 2026-11-02), and
## under ``--target`` it is THIS recipe built for the target.
##
## Built through the release's ``cmake_unofficial`` project (the official
## build is a Makefile with no configure step): shared library only, no
## ``xxhsum`` command-line tool.
##
## The source archive is GitHub's tag archive, hashed when this recipe was
## written (2026-11-02); upstream publishes no signature for it.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package xxhashSource:
  versions:
    "0.8.3":
      sourceRevision = "v0.8.3"
      sourceUrl = "https://github.com/Cyan4973/xxHash/archive/refs/tags/v0.8.3.tar.gz"
      sourceRepository = "https://github.com/Cyan4973/xxHash"
  fetch:
    url: "https://github.com/Cyan4973/xxHash/archive/refs/tags/v0.8.3.tar.gz"
    sha256: "aae608dfe8213dfd05d909a57718ef82f30722c392344583d3f39050c7f29a80"
    extractStrip: 1
  nativeBuildDeps:
    "cmake >=3.16"
    "ninja >=1.10"
    "gcc >=11"
    ## See libblake3: the C toolchain of a cross build.
    "zig >=0.13 <0.14"
  config:
    discard
  library libxxhash:
    discard
  build:
    setCurrentOwningPackageOverride("xxhashSource")
    try:
      let pkg = cmake_package(
        srcDir = "./src/cmake_unofficial",
        generator = "Ninja",
        cacheVars = @[
          "CMAKE_BUILD_TYPE=Release",
          "CMAKE_INSTALL_LIBDIR=lib",
          "BUILD_SHARED_LIBS=ON",
          "XXHASH_BUILD_XXHSUM=OFF",
        ])
      discard pkg.library("libxxhash")
      pkg.installTreeMirror()
    finally:
      clearCurrentOwningPackageOverride()
  runtimeDeps:
    discard

## ``pcre`` -- PCRE1 8.45, the library the Nim compiler loads at run time,
## built from the upstream release for the platform being built FOR.
##
## Why it is here: the fork compiler (the ``nim-fork`` recipe) ``dlopen``s
## ``libpcre.so.1`` when it starts, and an installed reprobuild prefix
## carries its own runtime libraries (reprobuild-pm
## Distribution-And-Packaging.md §5.3, decision C). Where the target
## distribution ships the library, the prefix bundles that package; Debian
## trixie no longer ships PCRE1 (``libpcre3`` was removed in favour of
## PCRE2), so for an armhf prefix the library comes from this recipe. This is
## the library nixpkgs builds the fork against (``pcre``, 8.45).
##
## Shared only: what the compiler loads is ``libpcre.so.1``. UTF-8 and
## Unicode properties on, as Nim's ``std/re`` expects; no C++ wrapper and no
## command-line tools, which nothing here uses.
##
## The archive is the upstream release on SourceForge, PCRE1's only
## remaining home since ``ftp.pcre.org`` closed. It was hashed when this
## recipe was written (2026-11-03); 8.45 is the final PCRE1 release.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  PcreVersion* = "8.45"
  PcreSourceUrl* =
    "https://downloads.sourceforge.net/project/pcre/pcre/8.45/pcre-8.45.tar.gz"
  PcreSourceHash* =
    "4e6ce03e0336e8b4a3d6c2b70b1c5e18590a5673a98186da90d4f33c23defc09"

package pcreSource:
  versions:
    "8.45":
      sourceRevision = PcreVersion
      sourceUrl = PcreSourceUrl
      sourceRepository = "https://sourceforge.net/projects/pcre"
  fetch:
    url: PcreSourceUrl
    sha256: PcreSourceHash
    extractStrip: 1
  nativeBuildDeps:
    "make"
    "gcc >=11"
    ## zig is the C toolchain of a cross build: `autotools_package` threads a
    ## zig `--target` with CC/AR/RANLIB naming its wrappers. Declared
    ## unconditionally, because dependency blocks are resolved at compile
    ## time; a native build never runs it.
    "zig >=0.13 <0.14"
  config:
    discard
  library libpcre:
    discard
  build:
    setCurrentOwningPackageOverride("pcreSource")
    try:
      let pkg = autotools_package(
        srcDir = "./src",
        buildDir = ".repro/build/pcre",
        configureOptions = @[
          "--enable-shared",
          "--disable-static",
          "--enable-utf",
          "--enable-unicode-properties",
          "--disable-cpp",
          "--disable-pcregrep-libz",
          "--disable-pcregrep-libbz2",
          "--disable-pcretest-libreadline",
        ])
      discard pkg.library("libpcre")
    finally:
      clearCurrentOwningPackageOverride()
  runtimeDeps:
    discard

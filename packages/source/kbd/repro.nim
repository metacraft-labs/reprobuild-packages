## From-source recipe for the Linux console keyboard tools and keymap data.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package kbdSource:
  versions:
    "2.10.0":
      sourceRevision = "v2.10.0"
      sourceUrl = "https://www.kernel.org/pub/linux/utils/kbd/kbd-2.10.0.tar.xz"
      sourceRepository = "https://git.kernel.org/pub/scm/linux/kernel/git/legion/kbd.git"

  fetch:
    url: "https://www.kernel.org/pub/linux/utils/kbd/kbd-2.10.0.tar.xz"
    sha256: "6e5ca4f8d76ee9e3a8db700b667f13e12aac9933828a64e1aaad93d26be9b479"
    extractStrip: 1

  nativeBuildDeps:
    "autoconf"
    "automake"
    "libtool"
    "make"
    "gcc >=11"
    "pkg-config"

  config:
    discard

  executable loadkeys:
    discard

  build:
    setCurrentOwningPackageOverride("kbdSource")
    try:
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = @[
          "--disable-vlock",
          "--disable-tests",
          "--disable-nls",
          "--disable-xkb",
          "--disable-compress",
          "--without-zlib",
          "--without-bzip2",
          "--without-lzma",
          "--without-zstd",
        ],
      )
      discard pkg.executable("loadkeys")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

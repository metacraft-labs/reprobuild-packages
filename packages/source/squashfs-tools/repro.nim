## Squashfs userspace tools source recipe for live filesystem images.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package squashfsToolsSource:
  versions:
    "4.7.5":
      sourceRevision = "4.7.5"
      sourceUrl = "https://github.com/plougher/squashfs-tools/releases/download/4.7.5/squashfs-tools-4.7.5.tar.gz"
      sourceRepository = "https://github.com/plougher/squashfs-tools.git"

  fetch:
    url: "https://github.com/plougher/squashfs-tools/releases/download/4.7.5/squashfs-tools-4.7.5.tar.gz"
    sha256: "547b7b7f4d2e44bf91b6fc554664850c69563701deab9fd9cd7e21f694c88ea6"
    extractStrip: 1

  nativeBuildDeps:
    "make"
    "gcc >=11"
    "patchelf"

  buildDeps:
    "zlib"
    "xz"

  config:
    discard

  executable mksquashfs:
    discard

  build:
    setCurrentOwningPackageOverride("squashfsToolsSource")
    try:
      let patches = @[
        "printf '\n.PHONY: repro_install\n" &
          "repro_install:\n" &
          "\tmkdir -p $(DESTDIR)/usr/bin\n" &
          "\tcp -a mksquashfs unsquashfs sqfstar sqfscat " &
            "$(DESTDIR)/usr/bin/\n' >> ./src/squashfs-tools/Makefile",
      ]
      let pkg = autotools_package(
        srcDir = "./src/squashfs-tools",
        configureOptions = @[
          "CONFIG=1",
          "GZIP_SUPPORT=1",
          "XZ_SUPPORT=1",
          "LZO_SUPPORT=0",
          "LZ4_SUPPORT=0",
          "ZSTD_SUPPORT=0",
          "XATTR_SUPPORT=0",
          "COMP_DEFAULT=xz",
        ],
        skipConfigure = true,
        installTarget = "repro_install",
        srcPatches = patches,
      )
      discard pkg.executable("mksquashfs")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    "zlib"
    "xz"

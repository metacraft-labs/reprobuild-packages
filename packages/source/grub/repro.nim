## GNU GRUB built for the BIOS and x86_64 UEFI platforms used by ReproOS.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/packages/sh
import repro_dsl_stdlib/types/package_result

const
  GrubCommonConfigureOptions* = @[
    "--disable-werror",
    "--disable-nls",
    "--disable-device-mapper",
    "CFLAGS=-fno-PIE",
    "LDFLAGS=-no-pie",
    "TARGET_LDFLAGS=-Wl,--no-dynamic-linker",
  ]
  GrubBiosConfigureOptions* = GrubCommonConfigureOptions & @[
    "--target=i386",
    "--with-platform=pc",
  ]
  GrubEfiConfigureOptions* = GrubCommonConfigureOptions & @[
    "--target=x86_64",
    "--with-platform=efi",
  ]

package grubSource:
  versions:
    "2.12":
      sourceRevision = "grub-2.12"
      sourceUrl = "https://ftp.gnu.org/gnu/grub/grub-2.12.tar.xz"
      sourceRepository = "https://git.savannah.gnu.org/git/grub.git"

  fetch:
    url: "https://ftp.gnu.org/gnu/grub/grub-2.12.tar.xz"
    sha256: "f3c97391f7c4eaa677a78e090c7e97e6dc47b16f655f04683ebd37bef7fe0faa"
    extractStrip: 1

  uses:
    "sh"

  nativeBuildDeps:
    "autoconf"
    "automake"
    "make"
    "gcc >=11"
    "bison"
    "flex"
    "gettext"
    "pkg-config"
    "python3"

  buildDeps:
    "freetype >=2.10"

  config:
    discard

  build:
    setCurrentOwningPackageOverride("grubSource")
    try:
      let patches = @[
        "touch ./src/grub-core/extra_deps.lst",
      ]
      let bios = autotools_package(
        srcDir = "./src",
        buildDir = "build-grub-bios",
        destdir = "out-bios",
        configureOptions = GrubBiosConfigureOptions,
        srcPatches = patches,
      )
      let efi = autotools_package(
        srcDir = "./src",
        buildDir = "build-grub-efi",
        destdir = "out-efi",
        configureOptions = GrubEfiConfigureOptions,
        srcPatches = patches,
      )

      # The platform builds install the same host utilities but disjoint GRUB
      # module directories. Merge BIOS first and EFI second so the published
      # utilities come from the native x86_64 build while retaining both
      # platform trees in one package interface.
      let merge = shell(
        command =
          "set -e; " &
          "rm -rf build-grub-merged/out; " &
          "mkdir -p build-grub-merged/out; " &
          "cp -a build-grub-bios/out-bios/. build-grub-merged/out/; " &
          "cp -a build-grub-efi/out-efi/. build-grub-merged/out/; " &
          "test -f build-grub-merged/out/usr/lib/grub/i386-pc/modinfo.sh; " &
          "test -f build-grub-merged/out/usr/lib/grub/x86_64-efi/modinfo.sh; " &
          "test -x build-grub-merged/out/usr/bin/grub-mkrescue; " &
          "test -x build-grub-merged/out/usr/bin/grub-mkimage",
        actionId = "grubSource.merge_platforms",
        deps = @[bios.installEdge.id, efi.installEdge.id],
        extraInputs = @[
          "build-grub-bios/out-bios/usr/lib/grub/i386-pc",
          "build-grub-efi/out-efi/usr/lib/grub/x86_64-efi",
        ],
        extraOutputs = @["build-grub-merged/out"],
      )
      emitInstallTreeMirror(
        merge,
        "build-grub-merged",
        "out",
        "grubSource",
        "autotools-multiplatform",
      )
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    "freetype >=2.10"

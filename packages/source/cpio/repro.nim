## GNU cpio built from the published upstream release source distribution.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  CpioVersion* = "2.15"
  CpioSourceUrl* = "https://mirrors.kernel.org/gnu/cpio/cpio-2.15.tar.bz2"
  CpioSourceSha256* =
    "937610b97c329a1ec9268553fb780037bcfff0dcffe9725ebc4fd9c1aa9075db"

package cpioSource:
  versions:
    "2.15":
      sourceRevision = "v" & CpioVersion
      sourceUrl = CpioSourceUrl
      sourceRepository = "https://git.savannah.gnu.org/git/cpio.git"

  fetch:
    url: CpioSourceUrl
    sha256: CpioSourceSha256
    extractStrip: 1

  nativeBuildDeps:
    "gcc >=11"
    "make >=4"
    "sh"
    "rm"
    "mkdir"
    "curl"
    "mv"
    "sha256sum"
    "tar"
    "bzip2"
    "find"
    "sed"
    "grep"
    "cmp"
    "diff"
    "awk"
    "cp"
    "chmod"
    "patchelf"

  config:
    discard

  executable cpio:
    discard

  build:
    setCurrentOwningPackageOverride("cpioSource")
    try:
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = @[
          "--disable-dependency-tracking",
          "--disable-nls",
        ])
      discard pkg.executable("cpio")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

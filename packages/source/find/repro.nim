## GNU find built from the published upstream findutils source distribution.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  FindVersion* = "4.10.0"
  FindSourceUrl* =
    "https://mirrors.kernel.org/gnu/findutils/findutils-4.10.0.tar.xz"
  FindSourceSha256* =
    "1387e0b67ff247d2abde998f90dfbf70c1491391a59ddfecb8ae698789f0a4f5"

package findSource:
  versions:
    "4.10.0":
      sourceRevision = "v" & FindVersion
      sourceUrl = FindSourceUrl
      sourceRepository = "https://git.savannah.gnu.org/git/findutils.git"

  fetch:
    url: FindSourceUrl
    sha256: FindSourceSha256
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
    "xz"
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

  executable find:
    discard

  build:
    setCurrentOwningPackageOverride("findSource")
    try:
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = @[
          "--disable-dependency-tracking",
          "--disable-nls",
          "--without-selinux",
        ])
      discard pkg.executable("find")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

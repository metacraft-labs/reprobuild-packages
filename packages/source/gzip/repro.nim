## GNU gzip built from the signed upstream release source distribution.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  GzipVersion* = "1.14"
  GzipSourceUrl* = "https://ftp.gnu.org/gnu/gzip/gzip-1.14.tar.xz"
  GzipSourceSha256* =
    "01a7b881bd220bfdf615f97b8718f80bdfd3f6add385b993dcf6efd14e8c0ac6"

package gzipSource:
  versions:
    "1.14":
      sourceRevision = "v" & GzipVersion
      sourceUrl = GzipSourceUrl
      sourceRepository = "https://git.savannah.gnu.org/git/gzip.git"

  fetch:
    url: GzipSourceUrl
    sha256: GzipSourceSha256
    extractStrip: 1

  nativeBuildDeps:
    # Compiler and release-tarball build driver.
    "gcc >=11"
    "make >=4"
    # Fetch and archive extraction commands.
    "sh"
    "rm"
    "mkdir"
    "curl"
    "mv"
    "sha256sum"
    "tar"
    "xz"
    # Configure probes and generated-file transforms.
    "find"
    "sed"
    "grep"
    "cmp"
    "diff"
    "awk"
    # Artifact staging and runtime-path normalization.
    "cp"
    "chmod"
    "patchelf"

  config:
    discard

  executable gzip:
    discard

  build:
    setCurrentOwningPackageOverride("gzipSource")
    try:
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = @[
          "--disable-dependency-tracking",
          "--disable-nls",
        ])
      discard pkg.executable("gzip")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

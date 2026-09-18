## `jq` built from the upstream 1.7.1 release source distribution.
##
## The eighth and last entry in Agent Harbor's cargo/go tool tier, and the
## only one of the eight that is neither: jq is C with an autotools build,
## so it needs no new convention — `from-source-autotools` already covers
## it, and this recipe is what proves the tier does not depend on the two
## new shapes for its coverage.
##
## ## Why the release tarball and not the git tag
##
## jqlang's release tarball carries a generated `configure`, `Makefile.in`
## and `config.h.in`, and it BUNDLES oniguruma under `modules/oniguruma`.
## The git tag carries neither: building from it needs `autoreconf` plus a
## submodule checkout, which is a network fetch this recipe is not allowed
## to make after its own. `--with-oniguruma=builtin` is what points the
## configure at the bundled copy, so the regex support jq's `test`/`match`
## builtins need comes from the same pinned archive as the rest.
##
## ## What the version pins
##
## 1.7.1, the same version `repro_dsl_stdlib/packages/jq.nim` fetches as a
## release binary — an alternative realization of one package, not a second
## package. That binary package's Windows slice is a bare `jq-win64.exe`
## with `archiveType = "raw"`; this one is the source it was built from.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  JqVersion* = "1.7.1"
  JqSourceUrl* =
    "https://github.com/jqlang/jq/releases/download/jq-" & JqVersion &
    "/jq-" & JqVersion & ".tar.gz"
  JqSourceSha256* =
    "478c9ca129fd2e3443fe27314b455e211e0d8c60bc8ff7df703873deeee580c2"

package jqSource:
  versions:
    "1.7.1":
      sourceRevision = "jq-" & JqVersion
      sourceUrl = JqSourceUrl
      sourceRepository = "https://github.com/jqlang/jq.git"

  fetch:
    url: JqSourceUrl
    sha256: JqSourceSha256
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

  executable jq:
    discard

  build:
    setCurrentOwningPackageOverride("jqSource")
    try:
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = @[
          # The bundled copy under `modules/oniguruma`, not a system one:
          # a system oniguruma is a dependency this recipe has not pinned,
          # and `--without-oniguruma` would silently drop `test`, `match`,
          # `capture`, `split/2`, `sub` and `gsub`.
          "--with-oniguruma=builtin",
          # The generated files are already in the tarball. Without this,
          # a timestamp skew after extraction makes the build try to
          # re-run `autoreconf`, which is not declared above and would be
          # a network fetch besides.
          "--disable-maintainer-mode",
          "--disable-dependency-tracking",
          # jq's default build puts the interpreter in a shared `libjq`
          # and links the command against it, which makes the artifact two
          # files that have to stay together — and on Windows a `jq.exe`
          # that will not start without `libjq-1.dll` beside it. A static
          # `libjq` folded into the command is one file with no load-time
          # search, which is what a CLI package should be.
          "--disable-shared",
          "--enable-static",
          # jq's own test suite needs `valgrind` and a shell harness this
          # recipe does not declare; the artifact is verified by running
          # it, not by `make check`.
          "--disable-valgrind",
          "--disable-docs",
        ])
      discard pkg.executable("jq")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

## `addlicense` from source — the second package through the
## `from-source-go` shape.
##
## One of the eight CLIs Agent Harbor's dev environment pins as release
## binaries today (see
## `agent-harbor/specs/Public/Reprobuild-Dev-Environment.milestones.org`
## M2), and the one that exercises the other common Go layout: the main
## package lives at the module ROOT rather than under `cmd/`, so
## `mainPackage` is `"."`.
##
## ## What the version pins
##
## 1.2.0, the same version `repro_dsl_stdlib/packages/addlicense.nim`
## fetches as a release binary. Deliberately the same — an alternative
## realization of one package, not a second package.
##
## The source comes from the GitHub tag archive rather than the release
## asset. Upstream's Windows release assets are named
## `addlicense_v1.2.0_Windows_x86_64.zip`, with an inconsistency in the
## naming that the binary-side recipe documents; the tag archive has no
## such ambiguity and is what `go build` wants anyway.
##
## ## How the dependency closure is pinned
##
## By the `go.sum` inside this tarball, verified by `go mod download`. See
## `go_package`'s docstring for why the Go shape reaches the guarantee
## through the toolchain instead of through a manifest committed here, as
## the cargo shape does.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  AddlicenseVersion = "1.2.0"
  AddlicenseSourceSha256 =
    "d2e05668e6f3da9b119931c2fdadfa6dd19a8fc441218eb3f2aec4aa24ae3f90"

package addlicenseSource:
  versions:
    "1.2.0":
      sourceRevision = "v" & AddlicenseVersion
      sourceUrl =
        "https://github.com/google/addlicense/archive/refs/tags/v" &
        AddlicenseVersion & ".tar.gz"
      sourceRepository = "https://github.com/google/addlicense.git"

  fetch:
    url: "https://github.com/google/addlicense/archive/refs/tags/v1.2.0.tar.gz"
    sha256: "d2e05668e6f3da9b119931c2fdadfa6dd19a8fc441218eb3f2aec4aa24ae3f90"
    extractStrip: 1

  nativeBuildDeps:
    # `go.mod` declares `go 1.13`, but that is a language-version floor
    # rather than a toolchain pin, and building with the catalog's current
    # Go is what keeps one toolchain across every Go package here.
    "go >=1.23"

  config:
    discard

  executable addlicense:
    discard

  build:
    setCurrentOwningPackageOverride("addlicenseSource")
    try:
      let pkg = go_package(
        binaryName = "addlicense",
        # The main package is at the module root — the other common Go
        # layout, and the reason this package is worth having beside
        # `shfmt` rather than being a copy of it.
        mainPackage = ".",
      )
      discard pkg.executable("addlicense")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

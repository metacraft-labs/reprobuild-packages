## `shfmt` from source — the catalog's first Go-built package.
##
## `shfmt` is one of the eight small Rust and Go CLIs Agent Harbor's dev
## environment pins as release binaries today (see
## `agent-harbor/specs/Public/Reprobuild-Dev-Environment.milestones.org`
## M2). It is the first through the `from-source-go` shape for the same
## reason `just` was first through the cargo one: a single command, a plain
## `go build`, no cgo, and a small enough module graph that a failure is
## legible.
##
## ## What the version pins
##
## 3.12.0, the same version `repro_dsl_stdlib/packages/shfmt.nim` fetches as
## a release binary. Deliberately the same: this is an alternative
## REALIZATION of one package, not a second package.
##
## ## The module path is not the repository name
##
## Upstream is `github.com/mvdan/sh`, the Go module is `mvdan.cc/sh/v3`,
## and the command lives at `./cmd/shfmt`. All three appear below because
## all three are load-bearing and none can be derived from another: the
## tarball comes from the GitHub tag, the module identity comes from
## `go.mod`, and `go build` needs the package path.
##
## ## How the dependency closure is pinned
##
## By the `go.sum` inside this tarball, verified by `go mod download` —
## not by a manifest committed here, the way the cargo shape pins its
## crates. `go.sum` records `h1:` dirhashes (SHA-256 over a sorted file
## listing, not over the module archive), so verifying one outside the
## toolchain would mean reimplementing Go's `dirhash`. The asymmetry is
## real: the Go closure is not visible in this repository the way the cargo
## one is. What is pinned here is the source digest; what pins the closure
## is the `go.sum` inside it. See `go_package`'s docstring.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  ShfmtVersion = "3.12.0"
  ShfmtSourceSha256 =
    "ac15f42feeba55af29bd07698a881deebed1cd07e937effe140d9300e79d5ceb"

package shfmtSource:
  versions:
    "3.12.0":
      sourceRevision = "v" & ShfmtVersion
      sourceUrl = "https://github.com/mvdan/sh/archive/refs/tags/v" &
        ShfmtVersion & ".tar.gz"
      sourceRepository = "https://github.com/mvdan/sh.git"

  fetch:
    url: "https://github.com/mvdan/sh/archive/refs/tags/v3.12.0.tar.gz"
    sha256: "ac15f42feeba55af29bd07698a881deebed1cd07e937effe140d9300e79d5ceb"
    # A GitHub tag archive wraps its tree in one `<repo>-<version>`
    # directory, so one component of strip lands `go.mod` at `src/`.
    extractStrip: 1

  nativeBuildDeps:
    # `go` is the discriminator the `from-source-go` convention recognises,
    # and the whole toolchain this package needs: `cgo` is off, so no C
    # compiler is involved.
    "go >=1.23"

  config:
    discard

  executable shfmt:
    discard

  build:
    setCurrentOwningPackageOverride("shfmtSource")
    try:
      let pkg = go_package(
        binaryName = "shfmt",
        # The module's main packages live under `cmd/`; `gosh` is the
        # other one and is not what this package publishes.
        mainPackage = "./cmd/shfmt",
        # Upstream stamps its own version through this variable; without
        # it `shfmt --version` reports the module's zero value rather than
        # the release this recipe pins.
        ldflags = "-X main.version=v" & ShfmtVersion,
      )
      discard pkg.executable("shfmt")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

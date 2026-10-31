## `geth` from source: the go-ethereum execution client, statically linked.
##
## go-ethereum's `geth` command, built as one static, pure-Go executable
## that runs unchanged on stock Debian 12/13 and Ubuntu 24.04 hosts from
## its store prefix: with cgo off, the Go toolchain links no C library at
## all, so the binary depends neither on the build host's libc nor on the
## one where it runs.
##
## ## What the version pins
##
## go-ethereum v1.17.10, upstream's tag archive. Its `go.mod` declares
## `go 1.25.0`, which the catalog's `go` satisfies. Upstream's own
## `go run build/ci.go install` stamps the git commit into the version
## string through `-X github.com/ethereum/go-ethereum/internal/version.gitCommit`;
## a tag archive has no git metadata, so this recipe passes no stamp and
## `geth version` reports `1.17.10-stable`, which is what the release
## version itself is (`version/version.go`).
##
## ## Why cgo is off
##
## `geth` builds and runs without cgo: its secp256k1 signing has a pure-Go
## implementation selected when `CGO_ENABLED=0` (`crypto/signature_nocgo.go`),
## and the USB hardware-wallet support, which a server node does not use,
## is compiled out. Turning cgo off is what makes the executable static
## without a C toolchain in the build.
##
## ## How the dependency closure is pinned
##
## By the `go.sum` inside this tarball, verified by `go mod download`; see
## `go_package`'s docstring and `packages/source/shfmt`.
##
## `GethBinarySha256` is what two builds from two checkouts at different
## paths both produced; see its comment.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  GethVersion* = "1.17.10"
  GethSourceSha256* =
    "d947e1e82eef5ffb46900d1047f207ed5e6f6d2049970cf3f1442669a175fd27"
  GethBinarySha256* =
    "a6c3713b1af8e45a0f25d8c732b4f98cfe130f36d3b89733ab5a64207bf893cc"
    ## sha256 of `bin/geth` as this recipe builds it, from ANY checkout.
    ## Measured 2026-10-31 on x86-64 NixOS with reprobuild `agents`
    ## `f509c61743` (`--tool-provisioning=nix`, nixpkgs go 1.25.4), from two
    ## checkouts of this repository at different paths, both clean: the two
    ## binaries were byte-identical (87 MB, static, no absolute path of
    ## either checkout in them). `-trimpath` alone did not get there:
    ## gnark-crypto's `#include`d assembly kept the module cache's absolute
    ## path until reprobuild's `go_package` completed the rewrite. The test
    ## beside the recipe holds a present build output to this value.

package gethSource:
  versions:
    "1.17.10":
      sourceRevision = "v" & GethVersion
      sourceUrl = "https://github.com/ethereum/go-ethereum/archive/refs/tags/v" &
        GethVersion & ".tar.gz"
      sourceRepository = "https://github.com/ethereum/go-ethereum.git"

  fetch:
    url: "https://github.com/ethereum/go-ethereum/archive/refs/tags/v1.17.10.tar.gz"
    sha256: "d947e1e82eef5ffb46900d1047f207ed5e6f6d2049970cf3f1442669a175fd27"
    # A GitHub tag archive wraps its tree in one `<repo>-<version>`
    # directory, so one component of strip lands `go.mod` at `src/`.
    extractStrip: 1

  nativeBuildDeps:
    # The whole toolchain: cgo is off, so no C compiler is involved.
    "go >=1.25"

  config:
    discard

  executable geth:
    discard

  build:
    setCurrentOwningPackageOverride("gethSource")
    try:
      let pkg = go_package(
        binaryName = "geth",
        mainPackage = "./cmd/geth",
        cgo = false)
      discard pkg.executable("geth")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

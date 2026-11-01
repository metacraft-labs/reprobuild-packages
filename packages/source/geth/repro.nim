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
## `go 1.25.0`; the recipe builds with exactly Go 1.25.4 in every
## provisioning mode (see `nativeBuildDeps`). Upstream's own
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
    "e9993434472679c5cc92ca1cc5a6b4a991897cda7086bd5989e43a08eabd934e"
    ## sha256 of `bin/geth` as this recipe builds it, from ANY checkout and
    ## in either provisioning mode. Measured 2026-11-01 on x86-64 NixOS with
    ## an engine built from reprobuild `agents` `26b2a206f8` plus the
    ## decision-36 Go change (`go ==1.25.4` realised from go.dev's release
    ## archive through Nix; the commit that carries it is named in this
    ## file's history):
    ## - `repro build --tool-provisioning=nix` in two checkouts of this
    ##   repository at different paths gave this value, with no `/nix/store`
    ##   path in the binary;
    ## - the recipe's build command run with the Nix-realised GOROOT and with
    ##   go.dev's archive extracted elsewhere (what the tarball mode
    ##   realises) gave this value too: the two toolchain trees are
    ##   identical, and with `-trimpath` their location does not reach the
    ##   binary.
    ## The value it replaces, a6c3713b..., was built with nixpkgs' patched Go
    ## and embedded its tzdata, iana-etc and mailcap store paths (ReproOS
    ## Add-On Mode decision 36). `-trimpath` alone did not make the binary
    ## path-free: gnark-crypto's `#include`d assembly kept the module cache's
    ## absolute path until reprobuild's `go_package` completed the rewrite.
    ## The test beside the recipe holds a present build output to this value.

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
    # The whole toolchain: cgo is off, so no C compiler is involved. One
    # exact Go release, so the Nix and the tarball provisioning build the
    # same compiler's output (`GethBinarySha256`): 1.25.4 is the pinned
    # nixpkgs' `go`, and the catalog's `go` carries go.dev's 1.25.4 Linux
    # archives for the tarball mode (A12 review finding 12). A range would
    # take nixpkgs' 1.25.4 in one mode and the newest archive (1.26) in the
    # other.
    "go ==1.25.4"

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

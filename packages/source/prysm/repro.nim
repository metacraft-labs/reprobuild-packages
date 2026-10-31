## `prysm` from source: the Prysm Ethereum consensus client, statically
## linked.
##
## Four commands from one module, each one static executable that runs
## unchanged on stock Debian 12/13 and Ubuntu 24.04 hosts from its store
## prefix:
##
## * `beacon-chain` (`./cmd/beacon-chain`), the beacon node;
## * `validator` (`./cmd/validator`), the validator client;
## * `prysmctl` (`./cmd/prysmctl`), the operator tool (genesis, deposits,
##   checkpoint sync, ...);
## * `prysm-keystores` (`./tools/keystores`), upstream's EIP-2335 keystore
##   encryptor/decryptor (https://eips.ethereum.org/EIPS/eip-2335). Upstream
##   builds it as `keystores`; it is installed under a prefixed name so it
##   does not claim a generic word in `bin/`.
##
## All four come from one `go.sum`, so they are one download and one
## verified closure: `go_package`'s `extraBinaries` builds the three after
## the first in the same edge. The network preset is mainnet's (upstream's
## default; the `minimal` build tag selects the test preset and is not set).
##
## ## What the version pins
##
## Prysm v7.3.1, upstream's tag archive (commit `PrysmCommit`). Its
## `go.mod` declares `go 1.26.5`, a minimum toolchain
## (https://go.dev/doc/toolchain), so `nativeBuildDeps` asks for that; the
## catalog serves it from go.dev's release archive.
##
## Upstream's Bazel release build stamps the tag, the commit and the build
## date into `runtime/version` through `-X`. A tag archive has no git
## metadata, so the recipe stamps the pinned tag and commit itself, and the
## commit's own date as the build date: a wall-clock date would make every
## build a different binary.
##
## ## Why cgo, and how the result is still static
##
## The BLS signatures (`supranational/blst`) and the KZG commitments
## (`ethereum/c-kzg-4844`) are C libraries bound through cgo; neither has a
## pure-Go implementation in this tree. `go_package(staticCgo = true)` makes
## zig the C compiler and linker for the host CPU's musl, adds the
## `netgo`/`osusergo` tags and links with `-extldflags -static`, so the
## executables carry their own libc and resolve names with Go's own
## resolver. `-s -w` asks the Go linker to leave out its symbol table and
## DWARF, as upstream's release builds do; with the external link, the C
## objects zig contributes keep theirs, which `file` reports as
## "with debug_info". None of it names the checkout (see
## `PrysmBinarySha256`).
##
## ## How the dependency closure is pinned
##
## By the `go.sum` inside this tarball, verified by `go mod download`; see
## `go_package`'s docstring and `packages/source/shfmt`.
##
## `PrysmBinarySha256` records what two builds from two checkouts at
## different paths both produced; see its comment.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  PrysmVersion* = "7.3.1"
  PrysmCommit* = "96d418cd964b083e37519a9df274030a1beac7db"
    ## The commit `refs/tags/v7.3.1` names.
  PrysmCommitDate* = "2026-10-22T18:49:20Z"
  PrysmCommitDateUnix* = "1792694960"
  PrysmSourceSha256* =
    "77341f5ed257efb0b9040cd2dbf08d12d413fbd4d14be49681b284843d899ca3"
  PrysmVersionPackage = "github.com/OffchainLabs/prysm/v7/runtime/version"
  PrysmMainBinary* = ("beacon-chain", "./cmd/beacon-chain")
  PrysmExtraBinaries* = @[
    ("validator", "./cmd/validator"),
    ("prysmctl", "./cmd/prysmctl"),
    ("prysm-keystores", "./tools/keystores"),
  ]
  PrysmLdflags* =
    "-s -w" &
    " -X " & PrysmVersionPackage & ".gitTag=v" & PrysmVersion &
    " -X " & PrysmVersionPackage & ".gitCommit=" & PrysmCommit &
    " -X " & PrysmVersionPackage & ".buildDate=" & PrysmCommitDate &
    " -X " & PrysmVersionPackage & ".buildDateUnix=" & PrysmCommitDateUnix
  PrysmBinarySha256* = [
    ("beacon-chain",
     "8f993e1cbed3b4484c96ea76e3c5e2992659b8c9801815f7341538ea88aa1667"),
    ("validator",
     "5706088d02657c9bf069f4e6a76fb0010f50b19e0833e291acd5939d5a497449"),
    ("prysmctl",
     "0c96e95fb9b3c9f19dcdcc3aadef2b11d7a257acc02c284f30e43ceeca8a1e17"),
    ("prysm-keystores",
     "d7290be3bd6c11f09d9bd6cf9392444e42fbe424879d193a056e2a72418148e4"),
  ]
    ## sha256 of each executable as this recipe builds it, from ANY
    ## checkout. Measured 2026-11-01 on x86-64 NixOS with reprobuild
    ## `agents` `c470b18067` (`--tool-provisioning=nix`: go 1.26.10 and
    ## zig 0.13.0 from the catalog's release archives), from two clean
    ## checkouts of this repository at different paths: all four were
    ## byte-identical, static and stripped. Getting there took three
    ## `go_package` fixes, each of which put the checkout's path into the
    ## bytes: `#include`d assembly kept its module-cache path, zig's DWARF
    ## named the scratch tree, and the Go build ID hashed the path of the C
    ## compiler wrapper. The test beside the recipe holds present build
    ## outputs to these values.

package prysmSource:
  versions:
    "7.3.1":
      sourceRevision = "v" & PrysmVersion
      sourceUrl = "https://github.com/OffchainLabs/prysm/archive/refs/tags/v" &
        PrysmVersion & ".tar.gz"
      sourceRepository = "https://github.com/OffchainLabs/prysm.git"

  fetch:
    url: "https://github.com/OffchainLabs/prysm/archive/refs/tags/v7.3.1.tar.gz"
    sha256: "77341f5ed257efb0b9040cd2dbf08d12d413fbd4d14be49681b284843d899ca3"
    # A GitHub tag archive wraps its tree in one `<repo>-<version>`
    # directory, so one component of strip lands `go.mod` at `src/`.
    extractStrip: 1

  nativeBuildDeps:
    # `go.mod` says `go 1.26.5`: a minimum, not a preference.
    "go >=1.26.5"
    # The C compiler and linker of the static cgo build.
    "zig >=0.13 <0.14"

  config:
    discard

  executable `beacon-chain`:
    discard
  executable validator:
    discard
  executable prysmctl:
    discard
  executable `prysm-keystores`:
    discard

  build:
    setCurrentOwningPackageOverride("prysmSource")
    try:
      let pkg = go_package(
        binaryName = PrysmMainBinary[0],
        mainPackage = PrysmMainBinary[1],
        extraBinaries = PrysmExtraBinaries,
        ldflags = PrysmLdflags,
        staticCgo = true)
      discard pkg.executable(PrysmMainBinary[0])
      for (name, _) in PrysmExtraBinaries:
        discard pkg.executable(name)
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

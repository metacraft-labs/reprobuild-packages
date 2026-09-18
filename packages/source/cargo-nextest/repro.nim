## `cargo-nextest` from source.
##
## The first of the three tier entries whose closure is not pure Rust, and
## the reason the other three recipes could not simply be copied from
## `cargo-sort`: 470 vendored crates, two of which run a build script
## against a C compiler.
##
## ## What the C toolchain is, and where it comes from
##
## `zstd-sys` compiles the zstd C sources it vendors, and `ring` compiles
## its own C plus the assembly it ships pregenerated. Both go through the
## `cc` crate, which for the `x86_64-pc-windows-msvc` target resolves
## `cl.exe` — so on Windows the compiler is the MSVC installation the dev
## environment activates through `repro_platform`, not a catalog package,
## and `nativeBuildDeps:` below names no compiler on that platform because
## naming one would install a toolchain `cc` then declines to use. On
## every other platform the target is gnu or darwin and `cc` resolves the
## declared `gcc`.
##
## Verified by building it: 470 crates vendored from the manifest beside
## this file, `cargo build --release --locked --offline` with no network
## access, `zstd.lib` produced from the vendored C, and the resulting
## binary reporting `cargo-nextest 0.9.124`. `openssl-sys` is in the
## closure but does not build on Windows — it is gated behind a target
## `cfg` the msvc triple does not satisfy.
##
## ## What the version pins
##
## 0.9.124, the same version `repro_dsl_stdlib/packages/cargo_nextest.nim`
## fetches as a release binary — an alternative realization of one package,
## not a second package.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  CargoNextestVersion* = "0.9.124"
  CargoNextestCrateUrl* =
    "https://static.crates.io/crates/cargo-nextest/cargo-nextest-" &
    CargoNextestVersion & ".crate"
  CargoNextestCrateSha256* =
    "e784a4a760367b6fd169df022dbdaeb5e758ee58d5d45aadd3b503f9697c6913"

package cargoNextestSource:
  versions:
    "0.9.124":
      sourceRevision = "cargo-nextest-" & CargoNextestVersion
      sourceUrl = CargoNextestCrateUrl
      sourceRepository = "https://github.com/nextest-rs/nextest.git"

  fetch:
    url: CargoNextestCrateUrl
    sha256: CargoNextestCrateSha256
    extractStrip: 1

  nativeBuildDeps:
    # The Rust half of the toolchain.
    "cargo >=1.92"
    "rustc >=1.92"
    when not defined(windows):
      # `zstd-sys` and `ring` compile C through the `cc` crate. On the msvc
      # target `cc` resolves `cl.exe` from the ambient MSVC environment, so
      # this entry would be an unused install there; on gnu and darwin
      # targets it is the compiler `cc` actually runs.
      "gcc >=11"

  config:
    discard

  # Backticks because the name carries a hyphen: `executable cargo-nextest:`
  # parses as the infix expression `cargo - nextest` and registers nothing.
  executable `cargo-nextest`:
    discard

  build:
    setCurrentOwningPackageOverride("cargoNextestSource")
    try:
      let pkg = cargo_package()
      discard pkg.executable("cargo-nextest")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

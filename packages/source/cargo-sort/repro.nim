## `cargo-sort` from source.
##
## One of the eight CLIs Agent Harbor's dev environment pins as release
## binaries today, and the one whose from-source build has been exercised
## end to end: 59 crates vendored from the manifest beside this file,
## `cargo build --release --locked --offline` compiling all of them with no
## network access, and the resulting binary reporting `cargo-sort 2.0.2`.
##
## ## Why this one is the proof
##
## Its closure is pure Rust. `cargo-nextest`, `taplo-cli` and `prek` pull
## `ring`, `zstd-sys` or `openssl-sys`, each of which runs a build script
## against a C toolchain — a dependency those recipes have to declare and
## whose availability is a separate question from whether the vendoring
## works. `cargo-sort` isolates the vendoring, so a failure here is about
## the shape and nothing else.
##
## ## What the version pins
##
## 2.0.2, the same version `repro_dsl_stdlib/packages/cargo_sort.nim`
## fetches as a release binary — an alternative realization of one package,
## not a second package.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  CargoSortVersion = "2.0.2"
  CargoSortCrateSha256 =
    "0bfbbaa65c2026a4102c28b016b72e38834ce78ed35740f96770b84642014780"

package cargoSortSource:
  versions:
    "2.0.2":
      sourceRevision = "v" & CargoSortVersion
      sourceUrl = "https://static.crates.io/crates/cargo-sort/cargo-sort-" &
        CargoSortVersion & ".crate"
      sourceRepository = "https://github.com/DevinR528/cargo-sort.git"

  fetch:
    url: "https://static.crates.io/crates/cargo-sort/cargo-sort-2.0.2.crate"
    sha256: "0bfbbaa65c2026a4102c28b016b72e38834ce78ed35740f96770b84642014780"
    extractStrip: 1

  nativeBuildDeps:
    # The whole toolchain this package needs. Its closure is pure Rust —
    # verified by building it — so no C compiler appears here.
    "cargo >=1.92"
    "rustc >=1.92"

  config:
    discard

  # Backticks because the name carries a hyphen: `executable cargo-sort:`
  # parses as the infix expression `cargo - sort` and registers nothing,
  # which surfaces as an empty artifact list rather than as a syntax error.
  executable `cargo-sort`:
    discard

  build:
    setCurrentOwningPackageOverride("cargoSortSource")
    try:
      let pkg = cargo_package()
      discard pkg.executable("cargo-sort")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

## `taplo` from source.
##
## The crate is `taplo-cli` and the command is `taplo`; the package this
## recipe realizes is `taplo`, matching
## `repro_dsl_stdlib/packages/taplo.nim`. The crate name appears only in
## the fetch URL, because that is the name crates.io publishes under.
##
## ## What the closure needs
##
## 274 crates, and like `cargo-nextest` it carries `ring`, which compiles C
## through the `cc` crate. On the `x86_64-pc-windows-msvc` target `cc`
## resolves `cl.exe` from the MSVC installation the dev environment
## activates through `repro_platform`, which is why `nativeBuildDeps:`
## names no compiler there. `openssl-sys` is in the closure but is gated
## behind a target `cfg` the msvc triple does not satisfy, so it never
## builds on Windows.
##
## Verified by building it: 274 crates vendored from the manifest beside
## this file, `cargo build --release --locked --offline` with no network
## access, and the resulting binary reporting `taplo 0.10.0`.
##
## ## What the version pins
##
## 0.10.0, the same version the binary package fetches — an alternative
## realization of one package, not a second package.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  TaploVersion* = "0.10.0"
  TaploCrateUrl* =
    "https://static.crates.io/crates/taplo-cli/taplo-cli-" & TaploVersion &
    ".crate"
  TaploCrateSha256* =
    "105c88e872aef8af352663aaf71b9d5311372fef237bed8de0a6d04857c7983f"

package taploSource:
  versions:
    "0.10.0":
      sourceRevision = TaploVersion
      sourceUrl = TaploCrateUrl
      sourceRepository = "https://github.com/tamasfe/taplo.git"

  fetch:
    url: TaploCrateUrl
    sha256: TaploCrateSha256
    extractStrip: 1

  nativeBuildDeps:
    # The Rust half of the toolchain.
    "cargo >=1.92"
    "rustc >=1.92"
    when not defined(windows):
      # `ring` compiles C through the `cc` crate. On the msvc target `cc`
      # resolves `cl.exe` from the ambient MSVC environment, so this entry
      # would be an unused install there; on gnu and darwin targets it is
      # the compiler `cc` actually runs.
      "gcc >=11"

  config:
    discard

  executable taplo:
    discard

  build:
    setCurrentOwningPackageOverride("taploSource")
    try:
      let pkg = cargo_package()
      discard pkg.executable("taplo")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

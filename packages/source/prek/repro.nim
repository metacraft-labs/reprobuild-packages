## `prek` from source.
##
## Agent Harbor's pre-commit driver, and the largest of the tier's Rust
## closures at 395 crates. Two of them compile C through the `cc` crate:
## `ring`, and `liblzma-sys`, which vendors the xz sources.
##
## ## The nasm question, answered by building it
##
## `ring` on `x86_64` needs its assembly, and building that assembly from
## the perlasm sources needs `nasm` on Windows — a package this catalog
## does not carry. It turns out not to need it: ring 0.17 ships the
## generated objects, so the build script compiles C and consumes the
## pregenerated assembly, which is what `ring_core_0_17_14_.lib` in the
## build output is. On the `x86_64-pc-windows-msvc` target the `cc` crate
## resolves `cl.exe` from the MSVC installation the dev environment
## activates through `repro_platform`, so `nativeBuildDeps:` names no
## compiler on Windows; on gnu and darwin targets it names the `gcc` that
## `cc` actually runs.
##
## Verified by building it: 395 crates vendored from the manifest beside
## this file, `cargo build --release --locked --offline` with no network
## access, and the resulting binary reporting `prek 0.3.2`.
##
## ## What the version pins
##
## 0.3.2, the same version `repro_dsl_stdlib/packages/prek.nim` fetches as
## a release binary — an alternative realization of one package, not a
## second package.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  PrekVersion* = "0.3.2"
  PrekCrateUrl* =
    "https://static.crates.io/crates/prek/prek-" & PrekVersion & ".crate"
  PrekCrateSha256* =
    "2cde665a5b368863e828a0c326aacaa2e183b1a9b97371df834ca5fa90bac0e8"

package prekSource:
  versions:
    "0.3.2":
      sourceRevision = "v" & PrekVersion
      sourceUrl = PrekCrateUrl
      sourceRepository = "https://github.com/j178/prek.git"

  fetch:
    url: PrekCrateUrl
    sha256: PrekCrateSha256
    extractStrip: 1

  nativeBuildDeps:
    # The Rust half of the toolchain.
    "cargo >=1.92"
    "rustc >=1.92"
    when not defined(windows):
      # `ring` and `liblzma-sys` compile C through the `cc` crate. On the
      # msvc target `cc` resolves `cl.exe` from the ambient MSVC
      # environment, so this entry would be an unused install there; on gnu
      # and darwin targets it is the compiler `cc` actually runs.
      "gcc >=11"

  config:
    discard

  executable prek:
    discard

  build:
    setCurrentOwningPackageOverride("prekSource")
    try:
      let pkg = cargo_package()
      discard pkg.executable("prek")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

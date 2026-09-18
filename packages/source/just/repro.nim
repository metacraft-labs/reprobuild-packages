## `just` from source — the catalog's first cargo-built package.
##
## `just` is one of the eight small Rust and Go CLIs Agent Harbor's dev
## environment pins as release binaries today (see
## `agent-harbor/specs/Public/Reprobuild-Dev-Environment.milestones.org`
## M2). It is the first through the `from-source-cargo` shape because it is
## the simplest honest test of it: a single binary, a plain `cargo build`,
## no build script that shells out, and a 172-crate dependency closure —
## large enough that the vendoring is doing real work, small enough that a
## failure is legible.
##
## ## What the version pins
##
## 1.51.0, the same version `repro_dsl_stdlib/packages/just.nim` fetches as
## a release binary. Deliberately the same: this recipe is an alternative
## REALIZATION of one package, not a second package, so a consumer that
## selects either path gets the same `just --version`.
##
## The source is the crates.io `.crate` rather than the GitHub release
## tarball. Both contain the same tree, but the `.crate` is what the
## lockfile's own checksums are computed against, so pinning it keeps one
## notion of "this version's source" across the recipe and its closure.
##
## ## The dependency closure
##
## `cargo-vendor.manifest` beside this file pins all 172 transitive crates
## by URL and SHA-256, generated from the upstream `Cargo.lock` by
## `tools/cargo_vendor_manifest.nim`. It is committed rather than derived at
## build time because the closure has to be readable at graph-emission
## time, and the lockfile it comes from does not exist then — it arrives
## with the source the fetch action has not run yet.
##
## Refreshing it on a version bump is one command, and its diff is exactly
## the set of dependencies that moved:
##
##     nim r tools/cargo_vendor_manifest.nim <extracted>/Cargo.lock \
##       packages/source/just/cargo-vendor.manifest

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  JustVersion = "1.51.0"
  JustCrateSha256 =
    "15a50b98e53d838090b26dd0f5181a8e03c32c4734d6bb7261fde60406e91cb8"

package justSource:
  versions:
    "1.51.0":
      sourceRevision = JustVersion
      sourceUrl = "https://static.crates.io/crates/just/just-" &
        JustVersion & ".crate"
      sourceRepository = "https://github.com/casey/just.git"

  fetch:
    url: "https://static.crates.io/crates/just/just-1.51.0.crate"
    sha256: "15a50b98e53d838090b26dd0f5181a8e03c32c4734d6bb7261fde60406e91cb8"
    # A `.crate` is a gzipped tar whose single top-level directory is
    # `<name>-<version>`, so one component of strip lands the tree at
    # `src/` with `Cargo.toml` at its root.
    extractStrip: 1

  nativeBuildDeps:
    # `cargo` is the discriminator the `from-source-cargo` convention
    # recognises; `rustc` is what cargo drives. Both are already catalog
    # packages, so this recipe does not pin a toolchain of its own.
    "cargo >=1.92"
    "rustc >=1.92"

  config:
    discard

  executable just:
    discard

  build:
    setCurrentOwningPackageOverride("justSource")
    try:
      let pkg = cargo_package()
      discard pkg.executable("just")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

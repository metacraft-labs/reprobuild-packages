## `vaultwarden` from source: one static musl executable.
##
## Vaultwarden is a Bitwarden-compatible password-manager server. This
## recipe builds the server alone, as a single statically linked
## `x86_64-unknown-linux-musl` executable that runs unchanged on stock
## Debian 12/13 and Ubuntu 24.04 hosts from its store prefix: it links no
## library from the build host, and none from the machine it runs on.
##
## ## What the version pins, and why not the newest release
##
## Vaultwarden 1.36.0, upstream's tag archive. 1.37.0 and later declare
## `rust-version = "1.95"` in `Cargo.toml`, while the catalog's `rustc` and
## `cargo` are 1.94; 1.36.0 declares 1.93, which they satisfy. Moving to
## 1.37 waits on the catalog's Rust toolchain, not on this recipe.
##
## Upstream's `build.rs` stamps the version from `git describe` unless
## `VW_VERSION` is set. The fetched tarball carries no `.git`, and the
## directory above it is this catalog's own checkout, so without the
## variable the stamp would be this repository's tag, and would change
## with every commit here. The recipe sets it to the pinned version.
##
## ## Features: SQLite only
##
## Cargo features `sqlite` and nothing else. `sqlite` is upstream's
## "statically linked SQLite" feature (`libsqlite3-sys/bundled`): the
## amalgamation is compiled into the executable, so there is no
## `libsqlite3` to find at run time, and the MySQL and PostgreSQL client
## libraries are never linked. The web vault (the browser UI, a separate
## upstream project) is not built: the service runs with
## `WEB_VAULT_ENABLED=false`, and clients talk to the API.
##
## ## The dependency closure
##
## `cargo-vendor.manifest` beside this file pins every crate of the
## upstream `Cargo.lock` (643), generated with
## `nim r tools/cargo_vendor_manifest.nim <Cargo.lock>`. The build is
## `--locked --offline`.
##
## ## Building for musl, and OpenSSL
##
## The recipe names no target; it is built with
## `repro build --target=x86_64-unknown-linux-musl`, which makes zig the C
## toolchain of every `*-sys` crate (reprobuild's `cross_zig` adapter) and
## the target's standard library the catalog's `rust-std` component, the
## same route `packages/source/llm-api-proxy` takes. The C-bearing crates
## in the closure are `openssl-sys`, `libsqlite3-sys` (bundled) and `ring`.
##
## OpenSSL comes from the sibling `packages/source/openssl` recipe, built
## for the same target, rather than from upstream's `vendored_openssl`
## feature (`openssl-src`). Both would give a static OpenSSL; the sibling
## is chosen because it is the one OpenSSL realization the catalog already
## reviews and pins, and its build is already shown to embed no path of
## the machine that ran it (`--prefix=/usr`, `--openssldir=/etc/ssl`), so
## the executable's bytes do not depend on the checkout. `openssl-src`
## would be a second OpenSSL build, driven by a crate's build script, whose
## reproducibility nothing here has measured.
##
## ## The recorded digest
##
## `VaultwardenBinarySha256` is what two builds from two checkouts at
## different paths both produced; see its comment. The Rust toolchain is
## the catalog's `rustc`/`cargo` 1.94.0, rust-lang's own release build, so
## that it can load rust-lang's prebuilt `rust-std` for the target. On a
## NixOS host without nix-ld reprobuild realizes that release through its
## Nix channel, with the ELF loader pointed at the pinned glibc, because
## the generic-Linux archive cannot start there.

import repro_project_dsl
import repro_dsl_stdlib/active_context
import repro_dsl_stdlib/adapters/cross_zig
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

import ../source_recipe_paths

const
  VaultwardenVersion* = "1.36.0"
  VaultwardenSourceSha256* =
    "8d506379fa19f21323c401b525ab5c6ca74de71509df81a9591ad5d5a4da2737"
  VaultwardenBinarySha256* =
    "08005cef7e04eef31cd5a917287294e978bc47131bff41d15afae167f896549e"
    ## sha256 of `usr/bin/vaultwarden` as this recipe builds it with
    ## `--target=x86_64-unknown-linux-musl`, from ANY checkout. Measured
    ## 2026-11-01 on x86-64 NixOS without nix-ld with an engine built from
    ## reprobuild `ff76c98ad0` (landed on `agents` rebased, unchanged, as
    ## `adf363bcf2`), `--tool-provisioning=path`, rustc/cargo 1.94.0
    ## through the catalog's Nix channel, from two checkouts of this
    ## repository at different paths: the two executables were
    ## byte-identical (36 MB,
    ## static, no absolute path of either checkout or of the Nix store in
    ## them), and `vaultwarden --version` answers `Vaultwarden 1.36.0`.
    ## The test beside the recipe holds a present build output to this
    ## value.
  VaultwardenFeatures* = @["sqlite"]
  OpensslRecipe = "openssl"
    ## The sibling recipe `openssl-sys` links; built for the active target.

proc opensslSysEnv*(ct: CrossTarget; opensslPrefix: string):
    seq[(string, string)] =
  ## The environment that points `openssl-sys` at `opensslPrefix` for `ct`:
  ## the crate reads `<TRIPLE>_OPENSSL_DIR` / `<TRIPLE>_OPENSSL_STATIC` when
  ## cargo builds for a target and `OPENSSL_DIR` otherwise.
  result = @[("OPENSSL_NO_VENDOR", "1")]
  let triple = ct.tripleOrEmpty()
  if triple.len > 0:
    let key = cargoTripleEnvKey(triple)
    result.add((key & "_OPENSSL_DIR", opensslPrefix))
    result.add((key & "_OPENSSL_STATIC", "1"))
  else:
    result.add(("OPENSSL_DIR", opensslPrefix))

proc vaultwardenEnv*(ct: CrossTarget; opensslPrefix: string):
    seq[(string, string)] =
  ## OpenSSL's location, and the version stamp `build.rs` would otherwise
  ## read from whatever git repository encloses the build.
  result = opensslSysEnv(ct, opensslPrefix)
  result.add(("VW_VERSION", VaultwardenVersion))

package vaultwardenSource:
  versions:
    "1.36.0":
      sourceRevision = VaultwardenVersion
      sourceUrl = "https://github.com/dani-garcia/vaultwarden/archive/refs/tags/" &
        VaultwardenVersion & ".tar.gz"
      sourceRepository = "https://github.com/dani-garcia/vaultwarden.git"

  fetch:
    url: "https://github.com/dani-garcia/vaultwarden/archive/refs/tags/1.36.0.tar.gz"
    sha256: "8d506379fa19f21323c401b525ab5c6ca74de71509df81a9591ad5d5a4da2737"
    # A GitHub tag archive wraps its tree in one `<repo>-<version>`
    # directory.
    extractStrip: 1

  nativeBuildDeps:
    "cargo >=1.94 <1.95"
    "rustc >=1.94 <1.95"
    # The target C toolchain of the `*-sys` crates.
    "zig >=0.13 <0.14"
    "perl >=5.32"
    "make"
    # The vendor step unpacks the `.crate` gzip tarballs (tar execs gzip);
    # the rust-std sysroot merge checks `rustc --print sysroot` with grep.
    "tar"
    "gzip"
    "grep"

  buildDeps:
    # What the executable LINKS: OpenSSL, built for the same target by the
    # sibling recipe.
    "openssl >=3.0"

  config:
    discard

  executable vaultwarden:
    discard

  build:
    setCurrentOwningPackageOverride("vaultwardenSource")
    try:
      let openssl = sourcePackageInstallPath(OpensslRecipe, "usr")
      let pkg = cargo_package(
        features = VaultwardenFeatures,
        extraEnv = vaultwardenEnv(activeCrossTarget(), openssl))
      discard pkg.executable("vaultwarden")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

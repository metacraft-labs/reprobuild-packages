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
## ## Not yet built: the toolchain gap
##
## This recipe has not been built. On an x86-64 NixOS host without nix-ld,
## measured 2026-10-31 with reprobuild `agents` `f509c61743`, no Rust 1.94
## toolchain can build for the musl target:
##
## * the catalog's `rustc`/`cargo` 1.94 tarball arm is the generic-Linux
##   release build, which needs `/lib64/ld-linux-x86-64.so.2`; reprobuild
##   refuses it on such a host (`TarballHostLoaderMissing`);
## * the `nixPackage` arm is the pinned nixpkgs' rustc 1.91, outside the
##   `>=1.94 <1.95` range below;
## * a nixpkgs rustc 1.94.0 put on PATH instead cannot load the catalog's
##   official `rust-std` 1.94.0 for `x86_64-unknown-linux-musl` ("found
##   crate `core` compiled by an incompatible version of rustc"): a
##   from-source nixpkgs rustc and rust-lang's prebuilt standard library do
##   not mix.
##
## So no binary digest is recorded here. Build it where the release
## toolchain runs (a host with a glibc loader or nix-ld), and record the
## executable's sha256 from two checkouts at different paths, as
## `packages/source/llm-api-proxy` does.

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

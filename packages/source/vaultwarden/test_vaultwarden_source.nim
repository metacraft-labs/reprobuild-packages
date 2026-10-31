## The `vaultwarden` from-source recipe: one static musl executable,
## SQLite only, OpenSSL from the sibling recipe.

import std/[os, strutils, unittest]

import repro_project_dsl
import repro_project_dsl/cargo_vendor
import repro_dsl_stdlib/adapters/cross_zig
import repro_dsl_stdlib/adapters/native_cross_target
import ./repro

suite "vaultwarden source recipe":
  test "pins 1.36.0, the last release the catalog's Rust 1.94 can build":
    let spec = registeredFetchSpec("vaultwardenSource")
    check spec.url ==
      "https://github.com/dani-garcia/vaultwarden/archive/refs/tags/1.36.0.tar.gz"
    check spec.hashHex == VaultwardenSourceSha256
    check spec.extractStrip == 1
    # 1.37.0+ declares rust-version 1.95; the toolchain range below is 1.94.
    var cargo = false
    for dep in registeredNativeBuildDeps("vaultwardenSource"):
      if dep.startsWith("cargo"):
        cargo = true
        check dep.contains("<1.95")
    check cargo

  test "SQLite only: no MySQL or PostgreSQL client":
    check VaultwardenFeatures == @["sqlite"]
    var code = ""
    for line in readFile(currentSourcePath.parentDir / "repro.nim").splitLines:
      if not line.strip().startsWith("#"): code.add(line & "\n")
    check "mysql" notin code
    check "postgres" notin code
    # OpenSSL is the sibling recipe, not `openssl-src`.
    check "vendored_openssl" notin code
    check "target =" notin code

  test "links the sibling OpenSSL and builds with zig":
    var openssl = false
    for dep in registeredBuildDeps("vaultwardenSource"):
      if dep.startsWith("openssl"): openssl = true
    check openssl
    var zig = false
    for dep in registeredNativeBuildDeps("vaultwardenSource"):
      if dep.startsWith("zig"): zig = true
      check not dep.startsWith("gcc")
    check zig

  test "publishes the single command":
    let artifacts = registeredArtifacts("vaultwardenSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "vaultwarden"
    check artifacts[0].kind == dakExecutable

  test "the version stamp never comes from an enclosing git repository":
    let cross = vaultwardenEnv(
      crossZigTarget("x86_64-unknown-linux-musl"), "/p/usr")
    check ("VW_VERSION", VaultwardenVersion) in cross
    check ("X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_DIR", "/p/usr") in cross
    check ("X86_64_UNKNOWN_LINUX_MUSL_OPENSSL_STATIC", "1") in cross
    check ("OPENSSL_NO_VENDOR", "1") in cross
    let native = vaultwardenEnv(nativeCrossTarget(), "/p/usr")
    check ("OPENSSL_DIR", "/p/usr") in native
    check ("VW_VERSION", VaultwardenVersion) in native

suite "vaultwarden vendored closure":
  let manifestPath = currentSourcePath.parentDir / "cargo-vendor.manifest"

  test "every line parses and the count is the generated one":
    let plan = parseVendorManifest(readFile(manifestPath))
    check plan.len == 643

  test "every crate is a crates.io archive with a digest":
    for entry in parseVendorManifest(readFile(manifestPath)):
      check not entry.isGit
      check entry.url.startsWith("https://static.crates.io/crates/")
      check entry.sha256.len == 64
      # The workspace's own members are not vendored.
      check entry.name != "vaultwarden"
      check entry.name != "macros"

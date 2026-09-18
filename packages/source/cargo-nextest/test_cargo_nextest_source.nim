## The `cargo-nextest` from-source recipe.
##
## What separates this recipe from `cargo-sort` is that its closure is not
## pure Rust: `zstd-sys` and `ring` compile C. So the cases below pin the
## closure's size and shape, and they pin the C-toolchain declaration,
## which is the part that differs per platform and therefore the part a
## copy-paste from another recipe would get wrong.

import std/[os, sequtils, strutils, unittest]

import repro_project_dsl
import repro_project_dsl/cargo_vendor
import ./repro

suite "cargo-nextest source recipe":
  test "pins the crates.io release":
    let spec = registeredFetchSpec("cargoNextestSource")
    check spec.url == CargoNextestCrateUrl
    check spec.hashHex == CargoNextestCrateSha256
    check spec.extractStrip == 1

  test "publishes the single command":
    let artifacts = registeredArtifacts("cargoNextestSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "cargo-nextest"
    check artifacts[0].kind == dakExecutable

  test "realizes the same version the binary package fetches":
    check CargoNextestVersion == "0.9.124"
    check CargoNextestCrateUrl.contains("cargo-nextest-0.9.124.crate")

  test "declares the C toolchain only where cc would use it":
    # `zstd-sys` and `ring` go through the `cc` crate. For the
    # `x86_64-pc-windows-msvc` target `cc` resolves `cl.exe` from the
    # ambient MSVC environment, so a declared `gcc` there is a toolchain
    # that gets installed and never invoked; on gnu and darwin targets it
    # is the compiler that actually runs.
    let deps = registeredNativeBuildDeps("cargoNextestSource")
    check deps.anyIt(it.startsWith("cargo"))
    check deps.anyIt(it.startsWith("rustc"))
    when defined(windows):
      check not deps.anyIt(it.startsWith("gcc"))
    else:
      check deps.anyIt(it.startsWith("gcc"))

  test "does not claim nasm":
    # ring 0.17 ships its generated assembly, so the build script consumes
    # the pregenerated objects rather than assembling from perlasm. A
    # `nasm` here would be a package this catalog does not carry.
    let deps = registeredNativeBuildDeps("cargoNextestSource")
    for absent in ["nasm", "perl", "cmake", "clang"]:
      check not deps.anyIt(it.startsWith(absent))

suite "cargo-nextest vendored closure":
  let manifestPath = currentSourcePath.parentDir / "cargo-vendor.manifest"

  test "every line parses and the count is the built one":
    # 470 is the number that was vendored and compiled offline. A manifest
    # that grew or shrank without the recipe's version moving would mean
    # the pin and the closure had come apart.
    let plan = parseVendorManifest(readFile(manifestPath))
    check plan.len == 470

  test "every entry is a full crates.io pin":
    let plan = parseVendorManifest(readFile(manifestPath))
    for entry in plan:
      check entry.url.startsWith("https://static.crates.io/crates/")
      check entry.sha256.len == 64
      check entry.directoryName == entry.name & "-" & entry.version

  test "the package being built is not in its own closure":
    let plan = parseVendorManifest(readFile(manifestPath))
    for entry in plan:
      check entry.name != "cargo-nextest"

  test "no crate appears twice":
    let plan = parseVendorManifest(readFile(manifestPath))
    var seen: seq[string] = @[]
    for entry in plan:
      check entry.directoryName notin seen
      seen.add(entry.directoryName)

  test "the crates that need a C compiler are the ones documented":
    # The recipe's C-toolchain declaration is justified by exactly these
    # entries. If the closure grows another `*-sys` crate that vendors C,
    # this case is where the justification has to be revisited.
    let plan = parseVendorManifest(readFile(manifestPath))
    let names = plan.mapIt(it.name)
    check "zstd-sys" in names
    check "ring" in names
    # In the closure, but gated behind a target `cfg` the msvc triple does
    # not satisfy: it never builds on Windows, which is why the recipe does
    # not declare pkg-config or an openssl.
    check "openssl-sys" in names

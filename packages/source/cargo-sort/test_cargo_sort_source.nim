## The `cargo-sort` from-source recipe — the one whose build is proven.
##
## Its closure is pure Rust, which is why this package rather than one of
## the other three carries the evidence: `cargo-nextest`, `taplo-cli` and
## `prek` each pull a `*-sys` crate whose build script needs a C toolchain,
## so a failure in one of those could be about the toolchain rather than
## about the vendoring. Here a failure can only be about the shape.

import std/[os, strutils, unittest]

import repro_project_dsl
import repro_project_dsl/cargo_vendor
import ./repro

suite "cargo-sort source recipe":
  test "pins the crates.io release":
    let spec = registeredFetchSpec("cargoSortSource")
    check spec.url ==
      "https://static.crates.io/crates/cargo-sort/cargo-sort-2.0.2.crate"
    check spec.hashHex ==
      "0bfbbaa65c2026a4102c28b016b72e38834ce78ed35740f96770b84642014780"
    check spec.extractStrip == 1

  test "publishes the single command":
    let artifacts = registeredArtifacts("cargoSortSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "cargo-sort"
    check artifacts[0].kind == dakExecutable

  test "needs no C toolchain":
    # The property that makes this package the proof of the shape. A `cc`
    # or `clang` appearing here would mean the closure had grown a
    # `*-sys` crate, and a build failure would stop being attributable to
    # the vendoring alone.
    let deps = registeredNativeBuildDeps("cargoSortSource")
    for dep in deps:
      check not dep.startsWith("clang")
      check not dep.startsWith("gcc")
      check not dep.startsWith("mingw")
      check not dep.startsWith("nasm")

  test "realizes the same version the binary package fetches":
    check registeredFetchSpec("cargoSortSource").url.contains("2.0.2")

suite "cargo-sort vendored closure":
  let manifestPath = currentSourcePath.parentDir / "cargo-vendor.manifest"

  test "every line parses and the count is the built one":
    # 59 is the number that was vendored and compiled offline. A manifest
    # that grew or shrank without the recipe's version moving would mean
    # the pin and the closure had come apart.
    let plan = parseVendorManifest(readFile(manifestPath))
    check plan.len == 59

  test "every entry is a full crates.io pin":
    let plan = parseVendorManifest(readFile(manifestPath))
    for entry in plan:
      check entry.url.startsWith("https://static.crates.io/crates/")
      check entry.sha256.len == 64
      check entry.directoryName == entry.name & "-" & entry.version

  test "the package being built is not in its own closure":
    let plan = parseVendorManifest(readFile(manifestPath))
    for entry in plan:
      check entry.name != "cargo-sort"

  test "no crate appears twice":
    let plan = parseVendorManifest(readFile(manifestPath))
    var seen: seq[string] = @[]
    for entry in plan:
      check entry.directoryName notin seen
      seen.add(entry.directoryName)

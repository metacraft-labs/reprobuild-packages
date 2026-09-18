## The `taplo` from-source recipe.
##
## The one entry in the tier where the crate name and the package name
## differ — crates.io publishes `taplo-cli`, the command is `taplo`, and
## the package interface this realizes is `taplo`. The first case pins that
## so a rename on either side cannot pass silently.

import std/[os, sequtils, strutils, unittest]

import repro_project_dsl
import repro_project_dsl/cargo_vendor
import ./repro

suite "taplo source recipe":
  test "fetches the taplo-cli crate and publishes the taplo command":
    let spec = registeredFetchSpec("taploSource")
    check spec.url.contains("/crates/taplo-cli/taplo-cli-0.10.0.crate")
    check spec.hashHex == TaploCrateSha256
    check spec.extractStrip == 1

    let artifacts = registeredArtifacts("taploSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "taplo"
    check artifacts[0].kind == dakExecutable

  test "realizes the same version the binary package fetches":
    check TaploVersion == "0.10.0"

  test "declares the C toolchain only where cc would use it":
    let deps = registeredNativeBuildDeps("taploSource")
    check deps.anyIt(it.startsWith("cargo"))
    check deps.anyIt(it.startsWith("rustc"))
    when defined(windows):
      check not deps.anyIt(it.startsWith("gcc"))
    else:
      check deps.anyIt(it.startsWith("gcc"))

  test "does not claim nasm":
    let deps = registeredNativeBuildDeps("taploSource")
    for absent in ["nasm", "perl", "cmake", "clang"]:
      check not deps.anyIt(it.startsWith(absent))

suite "taplo vendored closure":
  let manifestPath = currentSourcePath.parentDir / "cargo-vendor.manifest"

  test "every line parses and the count is the built one":
    # 274 is the number that was vendored and compiled offline.
    let plan = parseVendorManifest(readFile(manifestPath))
    check plan.len == 274

  test "every entry is a full crates.io pin":
    let plan = parseVendorManifest(readFile(manifestPath))
    for entry in plan:
      check entry.url.startsWith("https://static.crates.io/crates/")
      check entry.sha256.len == 64
      check entry.directoryName == entry.name & "-" & entry.version

  test "neither the crate nor the command is in its own closure":
    let plan = parseVendorManifest(readFile(manifestPath))
    for entry in plan:
      check entry.name != "taplo-cli"

  test "no crate appears twice":
    let plan = parseVendorManifest(readFile(manifestPath))
    var seen: seq[string] = @[]
    for entry in plan:
      check entry.directoryName notin seen
      seen.add(entry.directoryName)

  test "the crate that needs a C compiler is the one documented":
    let plan = parseVendorManifest(readFile(manifestPath))
    let names = plan.mapIt(it.name)
    check "ring" in names
    # Present but gated behind a target `cfg` the msvc triple does not
    # satisfy, so it never builds on Windows.
    check "openssl-sys" in names

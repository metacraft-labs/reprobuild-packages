## The `prek` from-source recipe.
##
## The largest closure in the tier, and the one that answered the nasm
## question: ring 0.17 ships its generated assembly, so no assembler is
## needed. The cases below pin that answer, because a `ring` bump that
## stopped shipping the pregenerated objects would turn a green build into
## one that needs a package this catalog does not carry.

import std/[os, sequtils, strutils, unittest]

import repro_project_dsl
import repro_project_dsl/cargo_vendor
import ./repro

suite "prek source recipe":
  test "pins the crates.io release":
    let spec = registeredFetchSpec("prekSource")
    check spec.url == PrekCrateUrl
    check spec.hashHex == PrekCrateSha256
    check spec.extractStrip == 1

  test "publishes the single command":
    let artifacts = registeredArtifacts("prekSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "prek"
    check artifacts[0].kind == dakExecutable

  test "realizes the same version the binary package fetches":
    check PrekVersion == "0.3.2"
    check PrekCrateUrl.contains("prek-0.3.2.crate")

  test "declares the C toolchain only where cc would use it":
    let deps = registeredNativeBuildDeps("prekSource")
    check deps.anyIt(it.startsWith("cargo"))
    check deps.anyIt(it.startsWith("rustc"))
    when defined(windows):
      check not deps.anyIt(it.startsWith("gcc"))
    else:
      check deps.anyIt(it.startsWith("gcc"))

  test "does not claim nasm":
    # The finding this recipe records. ring 0.17's build script consumes
    # the assembly the crate ships rather than assembling it, so the
    # closure needs a C compiler and nothing else.
    let deps = registeredNativeBuildDeps("prekSource")
    for absent in ["nasm", "perl", "cmake", "clang"]:
      check not deps.anyIt(it.startsWith(absent))

  test "prek is a Rust build, not a Python one":
    # prek reimplements pre-commit; it does not embed or shell out to a
    # Python at BUILD time. A `python3` here would mean the recipe had
    # picked up pre-commit's own runtime as a build dependency.
    let deps = registeredNativeBuildDeps("prekSource")
    for absent in ["python", "python3", "uv"]:
      check not deps.anyIt(it.startsWith(absent))

suite "prek vendored closure":
  let manifestPath = currentSourcePath.parentDir / "cargo-vendor.manifest"

  test "every line parses and the count is the built one":
    # 395 is the number that was vendored and compiled offline — the
    # largest closure in the tier.
    let plan = parseVendorManifest(readFile(manifestPath))
    check plan.len == 395

  test "every entry is a full crates.io pin":
    let plan = parseVendorManifest(readFile(manifestPath))
    for entry in plan:
      check entry.url.startsWith("https://static.crates.io/crates/")
      check entry.sha256.len == 64
      check entry.directoryName == entry.name & "-" & entry.version

  test "the package being built is not in its own closure":
    let plan = parseVendorManifest(readFile(manifestPath))
    for entry in plan:
      check entry.name != "prek"

  test "no crate appears twice":
    let plan = parseVendorManifest(readFile(manifestPath))
    var seen: seq[string] = @[]
    for entry in plan:
      check entry.directoryName notin seen
      seen.add(entry.directoryName)

  test "the crates that need a C compiler are the ones documented":
    let plan = parseVendorManifest(readFile(manifestPath))
    let names = plan.mapIt(it.name)
    check "ring" in names
    check "liblzma-sys" in names
    # Unlike `cargo-nextest` and `taplo`, prek's closure carries no
    # openssl-sys at all: it uses rustls, which is what `ring` is there
    # for.
    check "openssl-sys" notin names

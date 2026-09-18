## The `just` from-source recipe, and the cargo shape it is the first user
## of.
##
## Two things are worth pinning here, and they are different in kind.
##
## The recipe's own declarations — the version, the digest, the members —
## are a statement about what this package IS, and a test that reads them
## back is what catches a bump that edited one and not another.
##
## The vendored closure is different: it is 172 lines of pinned URLs and
## digests that nobody reviews line by line. What can be asserted about it
## is its SHAPE and its INTERNAL CONSISTENCY — that every line parses, that
## every crate is a crates.io download with a full-length digest, and that
## the package being built is not in its own closure. A manifest that
## satisfies those and is still wrong fails loudly at the first build,
## because every entry is checked against its digest as it is fetched.

import std/unittest

import repro_project_dsl
import repro_project_dsl/cargo_vendor
import ./repro

import std/[os, strutils]

suite "just source recipe":
  test "pins the crates.io release, not the GitHub tarball":
    # Both carry the same tree, but the `.crate` is what the lockfile's
    # own checksums are computed against — so pinning it keeps one notion
    # of "this version's source" across the recipe and its closure.
    let spec = registeredFetchSpec("justSource")
    check spec.url ==
      "https://static.crates.io/crates/just/just-1.51.0.crate"
    check spec.hashHex ==
      "15a50b98e53d838090b26dd0f5181a8e03c32c4734d6bb7261fde60406e91cb8"
    # A `.crate` wraps its tree in one `<name>-<version>` directory.
    check spec.extractStrip == 1

  test "publishes the single command":
    let artifacts = registeredArtifacts("justSource")
    check artifacts.len == 1
    check artifacts[0].packageName == "justSource"
    check artifacts[0].artifactName == "just"
    check artifacts[0].kind == dakExecutable

  test "declares cargo, which is what the convention recognises":
    let deps = registeredNativeBuildDeps("justSource")
    var sawCargo = false
    var sawRustc = false
    for dep in deps:
      if dep.startsWith("cargo"): sawCargo = true
      if dep.startsWith("rustc"): sawRustc = true
    check sawCargo
    check sawRustc

  test "the recipe realizes the same version the binary package fetches":
    # This is an alternative REALIZATION of one package, not a second
    # package: a consumer selecting either path must get the same
    # `just --version`. The binary side pins 1.51.0 in
    # `repro_dsl_stdlib/packages/just.nim`.
    check registeredFetchSpec("justSource").url.contains("just-1.51.0")

suite "just vendored closure":
  let manifestPath = currentSourcePath.parentDir / "cargo-vendor.manifest"

  test "the closure is committed beside the recipe":
    # Not derived at build time: it has to be readable at graph-emission
    # time, and the lockfile it comes from arrives with the source the
    # fetch action has not run yet.
    check fileExists(manifestPath)

  test "every line parses":
    # `parseVendorManifest` refuses what it cannot read exactly, so this
    # is also the assertion that no line was hand-edited into a shape the
    # build would reject.
    let plan = parseVendorManifest(readFile(manifestPath))
    check plan.len == 172

  test "every entry is a full crates.io pin":
    let plan = parseVendorManifest(readFile(manifestPath))
    for entry in plan:
      check entry.url.startsWith("https://static.crates.io/crates/")
      check entry.sha256.len == 64
      check entry.name.len > 0
      check entry.version.len > 0
      # The directory name is what the fetch step creates and what cargo
      # looks for; it has to agree with the name and version derived from
      # it, or the vendored tree is one cargo cannot read.
      check entry.directoryName == entry.name & "-" & entry.version

  test "the package being built is not in its own closure":
    # `just` has no `source` line in its own lockfile entry, so a plan
    # that included it would be asking crates.io for the thing the fetch
    # step already produced.
    let plan = parseVendorManifest(readFile(manifestPath))
    for entry in plan:
      check entry.name != "just"

  test "no crate appears twice":
    # Two entries for one directory name would have the second unpack over
    # the first, and which digest the tree ended up matching would depend
    # on manifest order.
    let plan = parseVendorManifest(readFile(manifestPath))
    var seen: seq[string] = @[]
    for entry in plan:
      check entry.directoryName notin seen
      seen.add(entry.directoryName)

## The `llm-api-proxy` recipe: agent-harbor at the commit infra pins,
## cross-compiled for the Raspberry Pi add-on host.

import std/[os, strutils, unittest]

import repro_project_dsl
import repro_project_dsl/cargo_vendor
import ./repro

suite "llm-api-proxy source recipe":
  test "pins the agent-harbor commit infra pins, as a git archive":
    let spec = registeredFetchSpec("llmApiProxySource")
    check spec.kind == dfkGitArchive
    check spec.gitRevision == "23960db5e22b46357ffb93c71db141e3414bbd63"
    check spec.hashHex ==
      "f36aacc95d23cd8cd8205ed200901aec82e730c1a552d74d1b6d8961f1a5fdb1"
    # A git archive has no top-level directory to strip.
    check spec.extractStrip == 0

  test "declares the cross toolchain and the target-side OpenSSL":
    let deps = registeredNativeBuildDeps("llmApiProxySource")
    check "rust-sysroot-armv7-unknown-linux-musleabihf" in deps
    check "openssl-static-armv7-unknown-linux-musleabihf" in deps
    var zig, cmake = false
    for dep in deps:
      if dep.startsWith("zig"): zig = true
      if dep.startsWith("cmake"): cmake = true
      # zig is the target C toolchain; a host gcc here would be the wrong
      # compiler for every `*-sys` crate.
      check not dep.startsWith("gcc")
    check zig and cmake

  test "publishes the single command":
    let artifacts = registeredArtifacts("llmApiProxySource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "llm-api-proxy"
    check artifacts[0].kind == dakExecutable

suite "llm-api-proxy vendored closure":
  let manifestPath = currentSourcePath.parentDir / "cargo-vendor.manifest"

  test "every line parses and the count is the generated one":
    let plan = parseVendorManifest(readFile(manifestPath))
    check plan.len == 1496

  test "the six git sources are pinned to commits":
    # Five are agent-harbor's forks under blocksense-network, one is
    # SnowflakePowered/winfsp-rs; what matters is that each names a commit,
    # the content address the vendor step verifies by.
    let plan = parseVendorManifest(readFile(manifestPath))
    var gits = 0
    for entry in plan:
      if entry.isGit:
        inc gits
        check entry.gitCommit.len == 40
        check entry.gitUrl.startsWith("https://github.com/")
      else:
        check entry.url.startsWith("https://static.crates.io/crates/")
        check entry.sha256.len == 64
    check gits == 6

  test "no workspace member is vendored, and no crate twice":
    let plan = parseVendorManifest(readFile(manifestPath))
    var seen: seq[string] = @[]
    for entry in plan:
      check not entry.name.startsWith("ah-")
      check entry.name != "llm-api-proxy"
      check entry.directoryName notin seen
      seen.add(entry.directoryName)

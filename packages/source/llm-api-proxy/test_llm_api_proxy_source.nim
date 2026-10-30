## The `llm-api-proxy` recipe: agent-harbor at the commit infra pins,
## cross-compiled for the Raspberry Pi add-on host.

import std/[os, strutils, unittest]

import repro_core/ambient_execution
import repro_test_support/reasoned_skip

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
    # The tree id is git-version independent; the archive hash is not.
    check AgentHarborTreeId.len == 40

  test "declares the cross toolchain and the target-side OpenSSL":
    let deps = registeredNativeBuildDeps("llmApiProxySource")
    check "openssl-static-armv7-unknown-linux-musleabihf" in deps
    # The target standard library is the catalog's `rust-std` component,
    # merged by `cargo_package`: no sysroot recipe is named.
    for dep in deps:
      check not dep.startsWith("rust-sysroot")
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

suite "llm-api-proxy build output is path-independent":
  test "a present build output has the recorded sha256":
    # The recipe's output must not depend on the checkout path: the cross
    # adapter remaps the project root out of the binary. This checks the
    # output of `repro build packages/source/llm-api-proxy` in THIS
    # checkout against the sha256 recorded from another; a divergence means
    # a path (or a toolchain change) reached the bytes and the constant must
    # move in review. Without a build output there is nothing to check.
    let built = currentSourcePath.parentDir / ".repro" / "output" / "install" /
      "usr" / "bin" / "llm-api-proxy"
    if LlmApiProxyBinarySha256.len == 0:
      skip("no recorded sha256 yet: the two-checkout build is blocked on reprobuild-pm issue 2026-10-30-io-mon-shim-kills-upstream-rustc-1.94.0-on-crates-with-macro-rules")
    elif not fileExists(built):
      skip("no build output in this checkout; run `repro build packages/source/llm-api-proxy` first")
    else:
      let execution = uncontrolledExecCmdEx("sha256sum " & quoteShell(built))
      check execution.exitCode == 0
      check execution.output.split(' ')[0] == LlmApiProxyBinarySha256

## The `llm-api-proxy` recipe: agent-harbor at the commit infra pins,
## cross-compiled for the Raspberry Pi add-on host.

import std/[os, strutils, unittest]

import repro_core/ambient_execution
import repro_test_support/reasoned_skip

import repro_project_dsl
import repro_project_dsl/cargo_vendor
import repro_dsl_stdlib/adapters/cross_zig
import repro_dsl_stdlib/adapters/native_cross_target
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

  test "declares the cross toolchain and the OpenSSL it links":
    let deps = registeredNativeBuildDeps("llmApiProxySource")
    # The library the binary links is a buildDeps: entry, and it is the
    # catalog's own openssl recipe: no target-suffixed package.
    var openssl = false
    for dep in registeredBuildDeps("llmApiProxySource"):
      if dep.startsWith("openssl"):
        openssl = true
        check not dep.contains("armv7")
    check openssl
    for dep in deps:
      check not dep.startsWith("rust-sysroot")
      check not dep.startsWith("openssl")
    var zig, cmake, hostCc = false
    for dep in deps:
      if dep.startsWith("zig"): zig = true
      if dep.startsWith("cmake"): cmake = true
      # zig is the target C toolchain of the `*-sys` crates; gcc is only the
      # host `cc` rustc links the build scripts with, which a nix-provisioned
      # action has no other way to find.
      if dep.startsWith("gcc"): hostCc = true
    check zig and cmake and hostCc

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
  test "the current build output has the recorded sha256":
    # The recipe's output must not depend on the checkout path: the cross
    # adapter remaps the project root out of the binary. This checks THIS
    # checkout's armv7 build against the sha256 recorded from another; a
    # divergence means a path (or a toolchain change) reached the bytes and
    # the constant must move in review.
    #
    # A mirror left on disk proves nothing about the sources now checked
    # out, so the test builds first and checks what that build wrote. It
    # runs only when asked, with an engine NAMED rather than whatever
    # `repro` is on PATH: `REPRO_PACKAGE_TESTS_REPRO=<path to repro>` (an
    # engine that carries A15's cross support; the workspace pin does not
    # yet) runs `repro build --target=...` here, and the case prints the
    # engine and rustc it used beside the result.
    #
    # Why no gate runs it yet: the catalog's own test edges (`repro.nim`)
    # run under the pinned `repro`, which predates `--target` for cargo, and
    # the catalog's rustc 1.94 arm is not runnable on a NixOS builder in nix
    # mode (reprobuild-pm issue 2026-10-30-path-mode-realizes-a-nix-rustc-
    # outside-the-declared-version-range). Until the pin moves, the pin's
    # measurements are recorded with their commits beside the constant.
    check LlmApiProxyBinarySha256.len == 64
    const Triple = "armv7-unknown-linux-musleabihf"
    let recipeDir = currentSourcePath.parentDir
    let built = recipeDir / ".repro" / "output" / ("install@" & Triple) /
      "usr" / "bin" / "llm-api-proxy"
    let repro = getEnv("REPRO_PACKAGE_TESTS_REPRO")
    if repro.len == 0:
      skip("set REPRO_PACKAGE_TESTS_REPRO to a repro engine with A15's " &
        "cross support to build llm-api-proxy for " & Triple & " and check " &
        "its sha256 (needs zig 0.13 and rustc 1.94 on PATH, and its zlib " &
        "and openssl siblings built for the target)")
    else:
      require fileExists(repro)
      let rustc = uncontrolledExecCmdEx("rustc --version")
      echo "    engine: ", repro, "; ", rustc.output.strip()
      let build = uncontrolledExecCmdEx("cd " & quoteShell(recipeDir) &
        " && " & quoteShell(repro) & " build --daemon=off --progress=quiet " &
        "--tool-provisioning=path --target=" & Triple)
      checkpoint(build.output)
      require build.exitCode == 0
      require fileExists(built)
      let execution = uncontrolledExecCmdEx("sha256sum " & quoteShell(built))
      check execution.exitCode == 0
      check execution.output.split(' ')[0] == LlmApiProxyBinarySha256

suite "llm-api-proxy names no target":
  test "openssl-sys is pointed at the prefix in the target's spelling":
    let cross = opensslSysEnv(
      crossZigTarget("armv7-unknown-linux-musleabihf"), "/p/usr")
    check ("ARMV7_UNKNOWN_LINUX_MUSLEABIHF_OPENSSL_DIR", "/p/usr") in cross
    check ("ARMV7_UNKNOWN_LINUX_MUSLEABIHF_OPENSSL_STATIC", "1") in cross
    check ("OPENSSL_NO_VENDOR", "1") in cross
    let native = opensslSysEnv(nativeCrossTarget(), "/p/usr")
    check ("OPENSSL_DIR", "/p/usr") in native
    for (k, _) in native:
      check not k.startsWith("ARMV7")

  test "the recipe code spells no triple":
    # Code only: the prose may name the Pi; the recipe must not.
    var code = ""
    for line in readFile(currentSourcePath.parentDir / "repro.nim").splitLines:
      if not line.strip().startsWith("#"): code.add(line & "\n")
    check "armv7" notin code
    check "zigCross" notin code
    check "target =" notin code

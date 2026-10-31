## The `prysm` from-source recipe: four static executables from one Go
## module, with cgo through zig.
##
## What the recipe pins (tag archive, commit, the four command paths, the
## mainnet preset, static cgo) is read back below; the last suite holds a
## present build output to the sha256s recorded in the recipe.

import std/[os, strutils, unittest]

import repro_core/ambient_execution
import repro_test_support/reasoned_skip

import repro_project_dsl
import ./repro

suite "prysm source recipe":
  test "pins the upstream tag archive":
    let spec = registeredFetchSpec("prysmSource")
    check spec.url ==
      "https://github.com/OffchainLabs/prysm/archive/refs/tags/v7.3.1.tar.gz"
    check spec.hashHex == PrysmSourceSha256
    check spec.extractStrip == 1
    check PrysmCommit.len == 40

  test "publishes the four commands":
    var names: seq[string] = @[]
    for a in registeredArtifacts("prysmSource"):
      check a.kind == dakExecutable
      names.add(a.artifactName)
    check names.len == 4
    for name in ["beacon-chain", "validator", "prysmctl", "prysm-keystores"]:
      check name in names

  test "the commands are the upstream main packages":
    check PrysmMainBinary == ("beacon-chain", "./cmd/beacon-chain")
    check ("validator", "./cmd/validator") in PrysmExtraBinaries
    check ("prysmctl", "./cmd/prysmctl") in PrysmExtraBinaries
    # The EIP-2335 keystore tool lives under tools/, not cmd/.
    check ("prysm-keystores", "./tools/keystores") in PrysmExtraBinaries
    check PrysmBinarySha256.len == 1 + PrysmExtraBinaries.len

  test "go is new enough for go.mod and zig is the C toolchain":
    var go, zig = false
    for dep in registeredNativeBuildDeps("prysmSource"):
      if dep.startsWith("go"):
        go = true
        # go.mod says `go 1.26.5`, a minimum toolchain.
        check dep.contains("1.26.5")
      if dep.startsWith("zig"): zig = true
      check not dep.startsWith("gcc")
      check not dep.startsWith("clang")
    check go and zig

  test "the build is static cgo, mainnet, stamped with the pinned tag":
    var code = ""
    for line in readFile(currentSourcePath.parentDir / "repro.nim").splitLines:
      if not line.strip().startsWith("#"): code.add(line & "\n")
    check "staticCgo = true" in code
    # `minimal` selects the test preset; mainnet is the default.
    check "minimal" notin code
    check ("gitTag=v" & PrysmVersion) in PrysmLdflags
    check ("gitCommit=" & PrysmCommit) in PrysmLdflags
    # A wall-clock build date would make every build different bytes.
    check ("buildDate=" & PrysmCommitDate) in PrysmLdflags
    check PrysmLdflags.startsWith("-s -w ")

suite "prysm build output":
  test "present build outputs are static and have the recorded sha256s":
    let binDir = currentSourcePath.parentDir / ".repro" / "output" /
      "install" / "usr" / "bin"
    if not fileExists(binDir / "beacon-chain"):
      skip("no build output in this checkout; run `repro build packages/source/prysm` first")
    else:
      for (name, sha) in PrysmBinarySha256:
        check sha.len == 64
        let built = binDir / name
        check fileExists(built)
        let sum = uncontrolledExecCmdEx("sha256sum " & quoteShell(built))
        check sum.exitCode == 0
        check sum.output.split(' ')[0] == sha
        let kind = uncontrolledExecCmdEx("file -b " & quoteShell(built))
        check "statically linked" in kind.output

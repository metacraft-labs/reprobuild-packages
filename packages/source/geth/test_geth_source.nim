## The `geth` from-source recipe: go-ethereum's execution client as one
## static, pure-Go executable.
##
## The tag archive, the command's package path and the cgo setting cannot
## be derived from one another; each is read back below. The last suite
## holds a present build output to the sha256 recorded in the recipe.

import std/[os, strutils, unittest]

import repro_core/ambient_execution
import repro_test_support/reasoned_skip

import repro_project_dsl
import ./repro

suite "geth source recipe":
  test "pins the upstream tag archive":
    let spec = registeredFetchSpec("gethSource")
    check spec.url ==
      "https://github.com/ethereum/go-ethereum/archive/refs/tags/v1.17.10.tar.gz"
    check spec.hashHex == GethSourceSha256
    # A GitHub tag archive wraps its tree in one `<repo>-<version>`
    # directory; the strip lands `go.mod` at `src/`.
    check spec.extractStrip == 1
    check spec.url.contains("v" & GethVersion)

  test "publishes the single command":
    let artifacts = registeredArtifacts("gethSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "geth"
    check artifacts[0].kind == dakExecutable

  test "declares go and nothing else":
    # cgo is off: a C compiler here would mean the recipe acquired a
    # dependency it does not declare, and zig would mean it went static
    # the hard way.
    var sawGo = false
    for dep in registeredNativeBuildDeps("gethSource"):
      if dep.startsWith("go"): sawGo = true
      check not dep.startsWith("zig")
      check not dep.startsWith("gcc")
      check not dep.startsWith("clang")
    check sawGo

  test "the recipe code builds ./cmd/geth with cgo off":
    var code = ""
    for line in readFile(currentSourcePath.parentDir / "repro.nim").splitLines:
      if not line.strip().startsWith("#"): code.add(line & "\n")
    check "mainPackage = \"./cmd/geth\"" in code
    check "cgo = false" in code
    check "staticCgo" notin code

suite "geth build output":
  test "a present build output is static and has the recorded sha256":
    # The bytes must not depend on the checkout path (`-trimpath`) or on
    # the day: two checkouts produced `GethBinarySha256`. Without a build
    # output there is nothing to check.
    let built = currentSourcePath.parentDir / ".repro" / "output" /
      "install" / "usr" / "bin" / "geth"
    check GethBinarySha256.len == 64
    if not fileExists(built):
      skip("no build output in this checkout; run `repro build packages/source/geth` first")
    else:
      let sum = uncontrolledExecCmdEx("sha256sum " & quoteShell(built))
      check sum.exitCode == 0
      check sum.output.split(' ')[0] == GethBinarySha256
      let kind = uncontrolledExecCmdEx("file -b " & quoteShell(built))
      check kind.exitCode == 0
      check "statically linked" in kind.output

## The `nixfmt` from-source recipe: what it pins, and that its Hackage
## closure and its patch are the ones its build was measured with.
##
## No mocks: the recipe module is imported, so the registries hold exactly
## what the recipe declares, and the committed manifest is parsed by the
## reader the build itself uses (`repro_core/hackage_closure`).

import std/[os, sequtils, sets, strutils, unittest]

import repro_project_dsl
import repro_core/hackage_closure
import ./repro

let recipeDir = currentSourcePath.parentDir

suite "nixfmt source recipe":
  test "pins upstream's 1.2.0 tag tarball":
    let spec = registeredFetchSpec("nixfmtSource")
    check spec.url ==
      "https://github.com/NixOS/nixfmt/archive/refs/tags/v1.2.0.tar.gz"
    check spec.hashHex ==
      "2b148abdf3c2ae9fca2b5898709cde5e4474e09cb32b892da51651c479f1f73a"
    check spec.extractStrip == 1

  test "publishes the single command":
    let artifacts = registeredArtifacts("nixfmtSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "nixfmt"
    check artifacts[0].kind == dakExecutable

  test "drives cabal, which is what the from-source-cabal convention keys on":
    let heads = registeredNativeBuildDeps("nixfmtSource").mapIt(
      it.splitWhitespace()[0])
    check "cabal" in heads
    check "ghc" in heads
    check "git" in heads

suite "nixfmt Hackage closure":
  let plan = parseHackageVendorManifest(
    readFile(hackageVendorManifestPath(recipeDir)))

  test "the 17 packages of the measured plan, four of them revised":
    # The plan cabal 3.16.1.0 solved with GHC 9.12.1 for windows-x86_64 at
    # index-state 2026-09-30T00:00:00Z. A count that moved without the
    # version or the compiler moving means the closure and the build came
    # apart.
    check plan.countIt(it.isSdist) == 17
    check plan.countIt(not it.isSdist) == 4

  test "nothing GHC ships, and nothing the recipe builds, is in it":
    let ids = plan.mapIt(it.packageId).toHashSet()
    for id in ids:
      let name = id[0 ..< id.rfind('-')]
      checkpoint(id)
      check name notin ["base", "text", "directory", "filepath", "process",
        "bytestring", "containers", "mtl", "transformers", "time", "unix",
        "Win32", "nixfmt"]

  test "every file comes from Hackage":
    for entry in plan:
      checkpoint(entry.fileName)
      check entry.url.startsWith(HackageDownloadBase & entry.packageId & "/")

suite "nixfmt Windows patch":
  let patch = readFile(recipeDir / "patches" / "nixfmt-1.2.0-windows.patch")

  test "touches only the executable's files and the package description":
    var files: seq[string] = @[]
    for line in patch.splitLines():
      if line.startsWith("+++ b/"):
        files.add(line["+++ b/".len .. ^1])
    check files.toHashSet() == ["nixfmt.cabal", "main/Main.hs",
      "main/System/Interrupt.hs", "main/System/IO/Atomic.hs",
      "main/System/IO/Utf8.hs"].toHashSet()

  test "keeps the C preprocessor out of Main":
    # CPP in Main.hs breaks the string gaps of its help texts (measured:
    # GHC-21231 "lexical error at character 's'").
    var inMain = false
    for line in patch.splitLines():
      if line.startsWith("+++ b/"):
        inMain = line == "+++ b/main/Main.hs"
      elif inMain and line.startsWith("+"):
        check "CPP" notin line
        check not line.startsWith("+#")

  test "keeps unix off Windows only, rather than dropping it":
    check "  if !os(windows)" in patch
    check "unix           >= 2.7.2 && < 2.9" in patch
    check "-    , unix             >= 2.7.2 && < 2.9" in patch

  test "has LF line endings, as the fetched sources do":
    check "\r\n" notin patch

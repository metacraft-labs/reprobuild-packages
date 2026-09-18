## The pinned CLI tool tier: one interface, two realizations that agree.
##
## Agent Harbor pins eight small CLIs. Each has a canonical interface in
## `repro_dsl_stdlib` that realizes it from an upstream release archive, and
## a recipe under `packages/source/` that realizes the same interface by
## building it. The promise those two make together is that selecting either
## one leaves the consuming `repro.nim` unchanged — so what has to hold is
## that they publish the SAME command, under the same name.
##
## Nothing enforces that structurally. A canonical interface names its
## command through `executablePath` inside a `provisioning:` block; a source
## recipe names it as an `executable` member. Those are different spellings
## in different repositories, and a rename on either side is invisible to
## the other until a consumer's `repro.nim` stops resolving. That is what
## these cases are for.
##
## The Scoop realizations live in `reprobuild-scoop-packages` and are
## checked there against the same canonical interfaces, which is why they do
## not appear here: a contribution pins its target interface's fingerprint,
## so it cannot change the declared command without failing to load. Each
## repository tests the half it owns, and the agreement is transitive
## through the canonical interface.

import std/[algorithm, os, sequtils, strutils, unittest]

import repro_project_dsl

# The canonical interfaces — the release-archive realizations.
import repro_dsl_stdlib/packages/just
import repro_dsl_stdlib/packages/jq
import repro_dsl_stdlib/packages/shfmt
import repro_dsl_stdlib/packages/taplo
import repro_dsl_stdlib/packages/prek
import repro_dsl_stdlib/packages/cargo_sort
import repro_dsl_stdlib/packages/cargo_nextest
import repro_dsl_stdlib/packages/addlicense

# The from-source realizations.
import ../packages/source/just/repro as justSource
import ../packages/source/jq/repro as jqSource
import ../packages/source/shfmt/repro as shfmtSource
import ../packages/source/taplo/repro as taploSource
import ../packages/source/prek/repro as prekSource
import "../packages/source/cargo-sort/repro" as cargoSortSource
import "../packages/source/cargo-nextest/repro" as cargoNextestSource
import ../packages/source/addlicense/repro as addlicenseSource

type TierEntry = object
  interfaceName: string
  sourcePackage: string
  command: string

const Tier = [
  TierEntry(interfaceName: "just", sourcePackage: "justSource",
    command: "just"),
  TierEntry(interfaceName: "jq", sourcePackage: "jqSource", command: "jq"),
  TierEntry(interfaceName: "shfmt", sourcePackage: "shfmtSource",
    command: "shfmt"),
  TierEntry(interfaceName: "taplo", sourcePackage: "taploSource",
    command: "taplo"),
  TierEntry(interfaceName: "prek", sourcePackage: "prekSource",
    command: "prek"),
  TierEntry(interfaceName: "cargo-sort", sourcePackage: "cargoSortSource",
    command: "cargo-sort"),
  TierEntry(interfaceName: "cargo-nextest",
    sourcePackage: "cargoNextestSource", command: "cargo-nextest"),
  TierEntry(interfaceName: "addlicense", sourcePackage: "addlicenseSource",
    command: "addlicense"),
]

proc canonical(name: string): PackageDef =
  let hits = registeredPackages().filterIt(it.packageName == name)
  doAssert hits.len == 1, "expected exactly one interface named " & name &
    ", found " & $hits.len
  hits[0]

proc commandsFrom(pkg: PackageDef): seq[string] =
  ## Every command name the canonical interface publishes, across all its
  ## provisioning slices.
  ##
  ## The name is the `executablePath` basename with any extension dropped,
  ## which is what a consumer resolves by: the Windows slice says
  ## `just.exe`, the nix slice says `bin/just`, and both are the command
  ## `just`.
  for slice in pkg.tarballProvisioning:
    if slice.executablePath.len > 0:
      result.add(slice.executablePath.extractFilename.changeFileExt(""))
    for alias in slice.executableAlias.split(','):
      if alias.strip().len > 0:
        result.add(alias.strip().changeFileExt(""))
  for slice in pkg.nixProvisioning:
    if slice.executablePath.len > 0:
      result.add(slice.executablePath.extractFilename.changeFileExt(""))
  result = result.deduplicate()
  result.sort()

suite "the tool tier's two realizations publish the same command":
  test "every entry has both a canonical interface and a source recipe":
    # The list itself is the claim. An entry that lost either half would
    # leave a consumer with one realization and no alternative, which is
    # the state this tier exists to get out of.
    for entry in Tier:
      check registeredPackages().anyIt(it.packageName == entry.interfaceName)
      check registeredArtifacts(entry.sourcePackage).len > 0

  test "the source recipe publishes exactly the canonical command":
    for entry in Tier:
      let artifacts = registeredArtifacts(entry.sourcePackage)
      check artifacts.len == 1
      check artifacts[0].artifactName == entry.command
      check artifacts[0].kind == dakExecutable

  test "the canonical interface publishes exactly the same command":
    for entry in Tier:
      let commands = commandsFrom(canonical(entry.interfaceName))
      check commands.len == 1
      check commands[0] == entry.command

  test "the source recipe realizes the version the interface pins":
    # Two realizations of ONE package, not two packages. A version that
    # drifted apart would make which realization a developer selected
    # observable in the tool's own `--version` output.
    let pins = {
      "just": "1.51.0",
      "jq": "1.7.1",
      "shfmt": "3.12.0",
      "taplo": "0.10.0",
      "prek": "0.3.2",
      "cargo-sort": "2.0.2",
      "cargo-nextest": "0.9.124",
      "addlicense": "1.2.0",
    }
    for entry in Tier:
      var expected = ""
      for (name, version) in pins:
        if name == entry.interfaceName:
          expected = version
      check expected.len > 0

      # The canonical side states it as `packageId = "<name>@<version>"`.
      let pkg = canonical(entry.interfaceName)
      var canonicalVersions: seq[string] = @[]
      for slice in pkg.tarballProvisioning:
        let parts = slice.packageId.split('@')
        if parts.len == 2 and parts[1].len > 0:
          canonicalVersions.add(parts[1])
      for version in canonicalVersions:
        check version == expected

      # The source side states it in its `versions:` block.
      let versions = registeredVersions(entry.sourcePackage)
      check versions.len == 1
      check versions[0].version == expected

  test "every source recipe fetches from a pinned digest, never a branch":
    # What the source realization is FOR. A recipe that fetched a moving
    # ref would be a third behaviour rather than a second realization of
    # the same thing.
    for entry in Tier:
      let fetch = registeredFetchSpec(entry.sourcePackage)
      check fetch.hashAlg == dshaSha256
      check fetch.hashHex.len == 64
      check fetch.hashHex.allIt(it in HexDigits)
      check fetch.url.startsWith("https://")

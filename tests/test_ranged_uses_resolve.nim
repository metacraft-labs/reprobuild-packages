## A ranged `uses:` resolves against every platform arm of the interfaces
## RunQuota and other consumers reach with a version range.
##
## Since the engine checks `uses "<pkg> <range>"` against the acquired
## realization, a `tarball` arm with no `version` is eligible only for an
## unranged request. RunQuota's `uses "sqlite3 >=3"` was refused on Windows
## with "no tarball realization satisfies range '>=3' for x86_64-windows
## (offered: unversioned)". This case resolves that use on every arm, with
## the production acquisition planner and nothing downloaded.
##
## Falsifiable: delete `version` from any sqlite3 arm and the case names it.

import std/[sets, strutils, unittest]

import repro_project_dsl
import repro_interface_artifacts
import repro_tool_profiles

import ../packages/interfaces/sqlite3/repro as sqlite3Interface

const RangedUses = [("sqlite3", ">=3")]

proc packageNamed(name: string): PackageDef =
  for pkg in registeredPackages():
    if pkg.packageName == name:
      return pkg
  raise newException(KeyError, "no registered package " & name)

proc rangedToolUse(pkg: PackageDef; range: string): InterfaceToolUse =
  let iface = toProjectInterface(PackageDef(
    packageName: "rangedUseConsumer",
    toolUses: @[PackageUseDef(
      rawConstraint: pkg.packageName & " " & range,
      packageSelector: pkg.packageName,
      executableName: pkg.packageName)]),
    [pkg])
  doAssert iface.toolUses.len == 1
  iface.toolUses[0]

suite "ranged uses resolve on every arm":
  test "every arm of a ranged-use package declares a version and resolves":
    var refused: seq[string] = @[]
    var targets = 0
    for (selector, range) in RangedUses:
      let pkg = packageNamed(selector)
      let useDef = rangedToolUse(pkg, range)
      var seen = initHashSet[string]()
      for arm in pkg.tarballProvisioning:
        if arm.detail.version.len == 0:
          refused.add(selector & " " & arm.cpu & "-" & arm.os &
            ": arm declares no version")
        if seen.containsOrIncl(arm.cpu & "-" & arm.os):
          continue
        inc targets
        let cpu = parseEnum[PlatformCpu](arm.cpu)
        let target = realizationTargetFor(cpu, parseEnum[PlatformOs](arm.os),
          baselineMicroarchLevel(cpu))
        try:
          discard tarballAcquisitionPlan(useDef, target = target)
        except ValueError as err:
          refused.add(err.msg)
    # A package that registered no arms would pass vacuously.
    check targets >= 5
    if refused.len > 0:
      checkpoint(refused.join("\n"))
    check refused.len == 0

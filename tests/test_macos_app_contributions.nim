## The macOS application definitions: every one of the sixteen pins a real
## vendor artifact and the identity of the bundle it delivers, and resolves
## the way a home profile resolves it.
##
## The facts pinned in each `packages/interfaces/<name>/repro.nim` (sha256,
## bundle identifier, version, team) were read off the downloaded artifacts;
## this test cannot re-download them, so it holds the definitions to the
## SHAPE those facts must have and to the resolution they must produce:
##
## * every macOS record carries an https URL, a sha256, a 10-character team
##   id, a bundle identifier, a version and the bundle's path, and its
##   `executablePath` lies inside the bundle;
## * each package resolves for aarch64-darwin (and for x86_64-darwin, which
##   every one of them offers) through `resolveProfilePackage` -- the
##   selection a home profile makes, `selectRealization` with the
##   `[tarball]` policy -- to the home archive realizer's `app-bundle` shape;
## * the two packages upstream ships only as installers that must RUN
##   (Karabiner-Elements' root package, OpenWebStart's installer
##   application) select their record, and resolution then refuses them
##   naming the realizer they lack, instead of
##   pretending to install them.
##
## The packages are linked into THIS process by importing their modules,
## which registers the same definitions a home profile reaches through the
## catalog lookup (reprobuild's `catalog_projection`; that route is covered
## end to end by reprobuild's `e2e_home_profile_reaches_catalog_apps`). No
## mocks: the real definitions, the real projection and selection code.

import std/[strutils, unittest]

import repro_project_dsl
import repro_home_apply/package_catalog

import ../packages/interfaces/ghostty/repro as ghosttyInterface
import ../packages/interfaces/iterm2/repro as iterm2Interface
import "../packages/interfaces/karabiner-elements/repro" as karabinerInterface
import ../packages/interfaces/hammerspoon/repro as hammerspoonInterface
import ../packages/interfaces/inkscape/repro as inkscapeInterface
import ../packages/interfaces/figma/repro as figmaInterface
import ../packages/interfaces/neovide/repro as neovideInterface
import ../packages/interfaces/vscode/repro as vscodeInterface
import "../packages/interfaces/claude-desktop/repro" as claudeDesktopInterface
import "../packages/interfaces/codex-desktop/repro" as codexDesktopInterface
import "../packages/interfaces/windows-app/repro" as windowsAppInterface
import ../packages/interfaces/tigervnc/repro as tigervncInterface
import ../packages/interfaces/turbovnc/repro as turbovncInterface
import ../packages/interfaces/utm/repro as utmInterface
import ../packages/interfaces/openwebstart/repro as openwebstartInterface
import ../packages/interfaces/sqlitebrowser/repro as sqlitebrowserInterface

const
  Realizable = ["ghostty", "iterm2", "hammerspoon", "inkscape", "figma",
    "neovide", "vscode", "claude-desktop", "codex-desktop", "windows-app",
    "tigervnc", "turbovnc", "utm", "sqlitebrowser"]
  InstallerOnly = [
    ("karabiner-elements", MacosPkgInstallRefusal),
    ("openwebstart", MacosInstallerAppRefusal)]

proc definition(name: string): PackageDef =
  var hits = 0
  for pkg in registeredPackages():
    if pkg.packageName == name:
      result = pkg
      inc hits
  doAssert hits == 1, "expected exactly one definition of " & name &
    ", found " & $hits

proc isLowerHex(text: string; length: int): bool =
  if text.len != length:
    return false
  for ch in text:
    if ch notin {'0'..'9', 'a'..'f'}:
      return false
  true

proc isTeamId(text: string): bool =
  if text.len != 10:
    return false
  for ch in text:
    if ch notin {'A'..'Z', '0'..'9'}:
      return false
  true

proc allNames(): seq[string] =
  for name in Realizable:
    result.add(name)
  for (name, _) in InstallerOnly:
    result.add(name)

proc macosTarget(arch: string): RealizationTarget =
  profileRealizationTarget("macos", arch, isHost = false)

suite "macOS application definitions":

  test "the sixteen applications are each defined exactly once":
    check allNames().len == 16
    for name in allNames():
      discard definition(name)

  test "every macOS record pins url, sha256, team id, bundle id, version " &
      "and the bundle":
    for name in allNames():
      let pkg = definition(name)
      var macRecords = 0
      for record in pkg.tarballProvisioning:
        if record.os != "macos":
          continue
        inc macRecords
        checkpoint name & ": " & record.url
        check record.url.startsWith("https://")
        check isLowerHex(record.sha256, 64)
        check record.sha256 in record.lockIdentity
        check isTeamId(record.detail.teamId)
        check record.detail.bundleId.len > 0
        check '.' in record.detail.bundleId
        check record.detail.version.len > 0
        check record.detail.appBundle.endsWith(".app")
        let leaf = record.detail.appBundle.split('/')[^1]
        check record.executablePath.startsWith(leaf & "/Contents/MacOS/")
        check record.archiveType in ["dmg", "pkg", "zip"]
        check record.cpu in ["any", "aarch64", "x86_64"]
      check macRecords > 0

  test "each realizable application resolves for aarch64- and " &
      "x86_64-darwin to the app-bundle realizer":
    for name in Realizable:
      for arch in ["arm64", "x86_64"]:
        checkpoint name & " " & arch
        let resolution = resolveProfilePackage(name, macosTarget(arch),
          @[rkTarball])
        check resolution.selection.kind == rkTarball
        check resolution.selection.tarball.os == "macos"
        check resolution.selection.tarball.cpu in
          [(if arch == "arm64": "aarch64" else: "x86_64"), "any"]
        check resolution.archiveRoute == arInstaller
        check resolution.archive.installMethod == imAppBundle
        check resolution.archive.archiveFormat in {afDmg, afPkg, afZip}
        check resolution.archive.bundleId ==
          resolution.selection.tarball.detail.bundleId
        check resolution.archive.teamId.len == 10
        check resolution.archive.builtinVersion ==
          resolution.selection.version
        check resolution.archive.digestAlgorithm == "sha256"

  test "installer-only applications select their record and are refused " &
      "naming the realizer they lack":
    for (name, reason) in InstallerOnly:
      for arch in ["arm64", "x86_64"]:
        checkpoint name & " " & arch
        # Selection itself succeeds: the record is the vendor's artifact.
        let projected = profileToolUse(name)
        check projected.known
        let selection = selectRealization(projected.useDef, SelectionRequest(
          packageName: name, target: macosTarget(arch), policy: @[rkTarball],
          availability: packageAvailability(name), probeNames: @[name],
          definitionKnown: true))
        check selection.kind == rkTarball
        # Resolution refuses it, before anything is downloaded.
        try:
          discard resolveProfilePackage(name, macosTarget(arch), @[rkTarball])
          check false
        except ValueError as err:
          check reason in err.msg

  test "no definition offers a realization for Linux or Windows":
    # These are macOS applications; a Linux or Windows profile naming one
    # reports a missing realization rather than selecting a macOS archive.
    for name in allNames():
      for (os, arch) in [("linux", "x86_64"), ("windows", "x86_64")]:
        expect EMissingRealization:
          discard resolveProfilePackage(name,
            profileRealizationTarget(os, arch, isHost = false), @[rkTarball])

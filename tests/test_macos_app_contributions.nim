## The macOS application definitions: every one of the twenty-four pins a real
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
##   `[tarball]` policy -- to the home archive realizer: the `app-bundle`
##   shape, or for OpenWebStart, which ships only an installer application,
##   the installer-application shape (`installer-silent` with
##   `installerApp`, run confined; Store-And-Installation-Layout.md
##   § Installer applications);
## * the one package upstream ships only as an installer package that must
##   RUN as root (Karabiner-Elements) selects its record, and resolution
##   then refuses it naming the realizer it lacks, instead of pretending to
##   install it.
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
import ../packages/interfaces/slack/repro as slackInterface
import ../packages/interfaces/discord/repro as discordInterface
import ../packages/interfaces/signal/repro as signalInterface
import ../packages/interfaces/telegram/repro as telegramInterface
import ../packages/interfaces/cursor/repro as cursorInterface
import "../packages/interfaces/ledger-wallet/repro" as ledgerWalletInterface
import "../packages/interfaces/google-antigravity/repro" as googleAntigravityInterface
import "../packages/interfaces/google-antigravity-ide/repro" as googleAntigravityIdeInterface

const
  Realizable = ["ghostty", "iterm2", "hammerspoon", "inkscape", "figma",
    "neovide", "vscode", "claude-desktop", "codex-desktop", "windows-app",
    "tigervnc", "turbovnc", "utm", "sqlitebrowser", "openwebstart",
    "slack", "discord", "signal", "telegram", "cursor", "ledger-wallet",
    "google-antigravity", "google-antigravity-ide"]
    ## Twenty-three. OpenWebStart is an installer application; the rest
    ## are app bundles.
  InstallerApplications = ["openwebstart"]
  InstallerOnly = [
    ("karabiner-elements", MacosPkgInstallRefusal)]

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

  test "the twenty-four applications are each defined exactly once":
    check Realizable.len == 23
    check allNames().len == 24
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
        if record.detail.installMethod == "installer-silent":
          # An installer application: the installer's path in the archive,
          # and the product bundle's path in the installed prefix.
          check record.detail.installerApp.endsWith(".app")
          check record.detail.installerArgs.len > 0
          check record.executablePath.startsWith(record.detail.appBundle &
            "/Contents/MacOS/")
        else:
          check record.detail.installerApp.len == 0
          let leaf = record.detail.appBundle.split('/')[^1]
          check record.executablePath.startsWith(leaf & "/Contents/MacOS/")
        check record.archiveType in ["dmg", "pkg", "zip"]
        check record.cpu in ["any", "aarch64", "x86_64"]
      check macRecords > 0

  test "each realizable application resolves for aarch64- and " &
      "x86_64-darwin to the home archive realizer's application shapes":
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
        if name in InstallerApplications:
          check resolution.archive.installMethod == imInstallerSilent
          check resolution.archive.installerApp.len > 0
          check resolution.archive.archiveFormat in {afDmg, afZip}
        else:
          check resolution.archive.installMethod == imAppBundle
          check resolution.archive.installerApp.len == 0
          check resolution.archive.archiveFormat in {afDmg, afPkg, afZip}
        check resolution.archive.bundleId ==
          resolution.selection.tarball.detail.bundleId
        check resolution.archive.teamId.len == 10
        check resolution.archive.builtinVersion ==
          resolution.selection.version
        check resolution.archive.digestAlgorithm == "sha256"

  test "the applications whose casks link commands declare them, inside " &
      "the bundle, and resolution exports them":
    # The commands the Homebrew casks link into /opt/homebrew/bin, declared
    # with `extraExecutable` so the home profile exports them from the
    # placed bundle (Store-And-Installation-Layout.md § macOS Application
    # Bundles, "Command line"). The paths were read off the extracted
    # bundles of every record on 2026-10-16.
    const Commands = [
      ("vscode", @["Visual Studio Code.app/Contents/Resources/app/bin/code",
        "Visual Studio Code.app/Contents/Resources/app/bin/code-tunnel"]),
      ("cursor", @["Cursor.app/Contents/Resources/app/bin/cursor"]),
      ("utm", @["UTM.app/Contents/MacOS/utmctl"]),
      ("hammerspoon", @["Hammerspoon.app/Contents/Frameworks/hs/hs"]),
      ("google-antigravity-ide",
        @["Antigravity IDE.app/Contents/Resources/app/bin/antigravity-ide"])]
    for (name, commands) in Commands:
      for record in definition(name).tarballProvisioning:
        checkpoint name & ": " & record.url
        check record.detail.extraExecutables == commands
      for arch in ["arm64", "x86_64"]:
        let resolution = resolveProfilePackage(name, macosTarget(arch),
          @[rkTarball])
        check resolution.archive.binRelpath ==
          @[resolution.selection.tarball.executablePath] & commands

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

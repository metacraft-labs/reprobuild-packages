## Realize and place every macOS application definition for real, into a
## scratch store and a scratch `~/Applications`.
##
## For each package named on the command line (default: every realizable
## application) and the host's CPU (or `--arch=`), this runs the two halves of what
## `repro home apply` does for an application, with the engine's own code
## linked in and the STRICT trust policy:
##
## 1. resolution and realization -- `resolveProfilePackage` (the selection
##    a home profile makes, `[tarball]` policy) and the home archive
##    realizer (`realizeBuiltinPackage`): the vendor artifact is downloaded
##    from its pinned URL, its sha256 checked, the bundle copied out (disk
##    image attached and detached, package expanded, zip expanded with
##    ditto) and refused unless its identifier, version, signature,
##    Developer ID team and Gatekeeper notarization verdict check out. An
##    installer application (OpenWebStart) is instead copied out, verified,
##    and RUN confined under `sandbox-exec` into the staging prefix, and the
##    product it installed is verified (Store-And-Installation-Layout.md
##    § Installer applications);
## 2. activation -- the `macos.appBundle` driver (`placeAppBundle`) copies the
##    realized bundle (or, for an installer application, the folder holding
##    it) into `<scratch>/home/Applications`, verifies the STAGED copy again
##    (the same checks, plus the realized item's identity) and renames it
##    into place; it is then read back, compared with the definition, every
##    bundle in it re-verified, and removed (`removeAppBundle`).
##
## The resource lifecycle around activation (recording, no-op detection,
## rollback) is covered by reprobuild's
## `e2e_dmg_app_bundle_install_and_rollback`; linking the apply pipeline here
## would pull the whole build engine into this tool.
##
## It downloads every artifact it is given (about 4 GB for the full set),
## so it is a tool rather than a test: run it when an application definition
## is added or bumped (`just verify-macos-apps [names...]`). It never touches
## the real `~/Applications`. macOS only.

import std/[os, osproc, strutils, tempfiles, times]

import repro_project_dsl
import repro_local_store
import repro_home_apply/package_catalog
import repro_home_apply/builtin_adapter
import repro_home_resources/drivers/app_bundle

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

const Realizable = ["ghostty", "iterm2", "hammerspoon", "inkscape", "figma",
  "neovide", "vscode", "claude-desktop", "codex-desktop", "windows-app",
  "tigervnc", "turbovnc", "utm", "sqlitebrowser", "openwebstart",
  "slack", "discord", "signal", "telegram", "cursor", "ledger-wallet",
  "google-antigravity", "google-antigravity-ide"]

proc bundlesIn(item: string): seq[string] =
  ## Every bundle in a placed item, at any depth, not inside another bundle
  ## (the item itself when it is a bundle).
  if item.endsWith(".app"):
    return @[item]
  for kind, path in walkDir(item):
    if kind != pcDir: continue
    if path.endsWith(".app"): result.add(path)
    else: result.add(bundlesIn(path))

proc plist(app, key: string): string =
  let (output, code) = execCmdEx("/usr/bin/plutil -extract " &
    quoteShell(key) & " raw -o - " & quoteShell(app / "Contents" /
    "Info.plist"))
  if code == 0: output.strip() else: ""

when isMainModule:
  when not defined(macosx):
    quit("verify_macos_apps runs on macOS only", 2)
  # `--arch=x86_64` (or `--arch=arm64`) verifies the records of that CPU
  # instead of the host's: realization and every trust check work on either
  # CPU's bundle; only launching them would not.
  var names: seq[string] = @[]
  var arch = if hostCPU == "arm64": "arm64" else: "x86_64"
  for arg in commandLineParams():
    if arg.startsWith("--arch="):
      arch = arg["--arch=".len .. ^1]
    else:
      names.add(arg)
  if names.len == 0:
    names = @Realizable
  let target = profileRealizationTarget("macos", arch, isHost = false)
  let root = createTempDir("verify-macos-apps-", "")
  let applications = applicationsDir(apsHome, root / "home")
  echo "scratch root: ", root, " (", arch, ")"
  var store = openStore(root / "store")
  var failures = 0
  for name in names:
    let started = epochTime()
    try:
      let resolution = resolveProfilePackage(name, target, @[rkTarball])
      let archive = resolution.archive
      let realized = realizeBuiltinPackage(store, archive)
      let itemName = extractFilename(realized.appBundlePath)
      let placed = placeAppBundle(realized.appBundlePath, applications,
        itemName, appBundleExpectationOf(archive), {},
        pinned = realized.appBundleIdentity,
        mainBundle = realized.appBundleMainPath)
      let item = applications / itemName
      let app =
        if realized.appBundleMainPath.len > 0:
          item / realized.appBundleMainPath
        else: item
      let id = plist(app, "CFBundleIdentifier")
      let version = plist(app, "CFBundleShortVersionString")
      var ok = dirExists(app) and id == archive.bundleId and
        version == archive.builtinVersion and placed.teamId == archive.teamId
      # Every bundle placed passes the strict trust checks against the team
      # (for an installer application: the ones its installer produced).
      for bundle in bundlesIn(item):
        try:
          discard verifyAppBundleTeam(bundle, archive.teamId, {})
          echo "     ", name, " bundle verified: ",
            bundle.relativePath(applications)
        except EAppBundleRefused as err:
          ok = false
          echo "FAIL ", name, ": ", err.msg
      echo (if ok: "OK   " else: "FAIL "), name, " ", archive.builtinVersion,
        " ", itemName,
        (if realized.appBundleMainPath.len > 0:
           "/" & realized.appBundleMainPath else: ""),
        " archive=", archive.archiveFormat,
        " id=", id, " team=", placed.teamId, " cdhash=", placed.cdhash,
        " url=", archive.urlUsed,
        " seconds=", formatFloat(epochTime() - started, ffDecimal, 1)
      if not ok:
        inc failures
      removeAppBundle(item)
      if dirExists(item):
        echo "FAIL ", name, ": removal left ", item
        inc failures
    except CatchableError as err:
      inc failures
      echo "FAIL ", name, ": ", err.msg
  store.close()
  if failures > 0:
    quit("verify_macos_apps: " & $failures & " failure(s); scratch root " &
      root & " kept", 1)
  removeDir(root)
  echo "verify_macos_apps: all ", names.len, " realized, verified, placed " &
    "and removed"

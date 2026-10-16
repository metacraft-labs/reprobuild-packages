## hammerspoon — Hammerspoon, the Lua automation tool (macOS application).
##
## Upstream's notarized universal zip from its GitHub release (versioned
## tag and file name). `hs` is
## `Hammerspoon.app/Contents/Frameworks/hs/hs`.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: Hammerspoon.app, signed "Developer ID Application: Chris Jones (VQCYSNZB89)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.
##
## `hs` is declared with `extraExecutable`: the home profile gets a
## launcher for it, running it from the placed bundle (§ macOS Application
## Bundles, "Command line"). The path was read off the extracted bundle
## of every record on 2026-10-16.

import repro_project_dsl

const
  HammerspoonVersion = "1.1.1"

package hammerspoon:
  provisioning:
    tarball url = "https://github.com/Hammerspoon/hammerspoon/releases/download/" & HammerspoonVersion & "/Hammerspoon-" & HammerspoonVersion & ".zip",
      sha256 = "11bb1c90faf5427f37c7bd4fe7eab9774ae43e1d5cb020c5b3088dac32849efa",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Hammerspoon.app",
      bundleId = "org.hammerspoon.Hammerspoon",
      teamId = "VQCYSNZB89",
      version = HammerspoonVersion,
      executablePath = "Hammerspoon.app/Contents/MacOS/Hammerspoon",
      extraExecutable = "Hammerspoon.app/Contents/Frameworks/hs/hs",
      packageId = "hammerspoon@" & HammerspoonVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:hammerspoon@" & HammerspoonVersion &
        ":macos-any:sha256:11bb1c90faf5427f37c7bd4fe7eab9774ae43e1d5cb020c5b3088dac32849efa"

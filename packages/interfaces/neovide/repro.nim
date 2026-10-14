## neovide — Neovide, the graphical Neovim client (macOS application).
##
## Upstream publishes one notarized disk image per CPU on its GitHub release.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: Neovide.app, signed "Developer ID Application: ALEXSANDE FALCUCCI DOS SANTOS (X8CNW77992)".
## * x86_64: Neovide.app, signed "Developer ID Application: ALEXSANDE FALCUCCI DOS SANTOS (X8CNW77992)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  NeovideVersion = "0.16.2"

package neovide:
  provisioning:
    tarball url = "https://github.com/neovide/neovide/releases/download/" & NeovideVersion & "/Neovide-aarch64-apple-darwin.dmg",
      sha256 = "5eb745ea7f20cf00491a8ffd8d793c6169ef1c6e1a0f75ae8be40571e65c6b26",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Neovide.app",
      bundleId = "com.neovide.neovide",
      teamId = "X8CNW77992",
      version = NeovideVersion,
      executablePath = "Neovide.app/Contents/MacOS/neovide",
      packageId = "neovide@" & NeovideVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:neovide@" & NeovideVersion &
        ":macos-aarch64:sha256:5eb745ea7f20cf00491a8ffd8d793c6169ef1c6e1a0f75ae8be40571e65c6b26"

    tarball url = "https://github.com/neovide/neovide/releases/download/" & NeovideVersion & "/Neovide-x86_64-apple-darwin.dmg",
      sha256 = "e84f7e585a688ac29073927fedeb1ff40419a558fffd9c021cb14a29db10bb41",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Neovide.app",
      bundleId = "com.neovide.neovide",
      teamId = "X8CNW77992",
      version = NeovideVersion,
      executablePath = "Neovide.app/Contents/MacOS/neovide",
      packageId = "neovide@" & NeovideVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:neovide@" & NeovideVersion &
        ":macos-x86_64:sha256:e84f7e585a688ac29073927fedeb1ff40419a558fffd9c021cb14a29db10bb41"

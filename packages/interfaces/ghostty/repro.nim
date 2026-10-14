## ghostty — Ghostty, the GPU-accelerated terminal emulator (macOS application).
##
## Upstream's notarized universal disk image (arm64 + x86_64 in one bundle), so
## one record serves both macOS CPUs. The URL is versioned by its directory.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: Ghostty.app, signed "Developer ID Application: Mitchell Hashimoto (24VZTF6M5V)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  GhosttyVersion = "1.3.1"

package ghostty:
  provisioning:
    tarball url = "https://release.files.ghostty.org/" & GhosttyVersion & "/Ghostty.dmg",
      sha256 = "18cff2b0a6cee90eead9c7d3064e808a252a40baf214aa752c1ecb793b8f5f69",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Ghostty.app",
      bundleId = "com.mitchellh.ghostty",
      teamId = "24VZTF6M5V",
      version = GhosttyVersion,
      executablePath = "Ghostty.app/Contents/MacOS/ghostty",
      packageId = "ghostty@" & GhosttyVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:ghostty@" & GhosttyVersion &
        ":macos-any:sha256:18cff2b0a6cee90eead9c7d3064e808a252a40baf214aa752c1ecb793b8f5f69"

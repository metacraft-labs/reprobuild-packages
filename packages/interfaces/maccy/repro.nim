## maccy — Maccy, the clipboard manager (macOS application).
##
## Upstream's notarized universal zip from its GitHub release (versioned
## tag; the file name is `Maccy.app.zip` in every release). Requires
## macOS 14 or later (`LSMinimumSystemVersion` 14.0).
##
## Each record was read off the downloaded artifact on m1-mini
## (aarch64-darwin), 2026-11-11: `sha256` with `shasum -a 256`, the bundle
## identifier and version from its `Info.plist`, the team with `codesign -dv`.
## Every bundle passed `codesign --verify --deep --strict` and Gatekeeper
## assessed it as `source=Notarized Developer ID`:
##
## * any: Maccy.app, signed "Developer ID Application: Alexey Rodionov (MN3X4648SC)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  MaccyVersion = "2.8.0"

package maccy:
  provisioning:
    tarball url = "https://github.com/p0deje/Maccy/releases/download/" & MaccyVersion & "/Maccy.app.zip",
      sha256 = "e684e1ce0c60d7cffd3a2b182dc37bd7e88c29967a64a431a2c71be65b1d27e0",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Maccy.app",
      bundleId = "org.p0deje.Maccy",
      teamId = "MN3X4648SC",
      version = MaccyVersion,
      executablePath = "Maccy.app/Contents/MacOS/Maccy",
      packageId = "maccy@" & MaccyVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:maccy@" & MaccyVersion &
        ":macos-any:sha256:e684e1ce0c60d7cffd3a2b182dc37bd7e88c29967a64a431a2c71be65b1d27e0"

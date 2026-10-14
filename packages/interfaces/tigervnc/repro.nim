## tigervnc — TigerVNC Viewer (macOS application).
##
## TigerVNC publishes its macOS binaries on SourceForge only (its GitHub
## releases link there); `downloads.sourceforge.net/tigervnc/TigerVNC-<version>.dmg`
## is versioned and redirects to a mirror. Notarized universal bundle; the disk
## image also carries the licence and README beside it.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: TigerVNC.app, signed "Developer ID Application: Brian Hinz (S5LX88A9BW)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  TigervncVersion = "1.16.2"

package tigervnc:
  provisioning:
    tarball url = "https://downloads.sourceforge.net/tigervnc/TigerVNC-" & TigervncVersion & ".dmg",
      sha256 = "aa0ef07e4ebe4f068cbf1118273459b5b616177cb6abf15a538af018ebfb5933",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "TigerVNC.app",
      bundleId = "com.tigervnc.tigervnc",
      teamId = "S5LX88A9BW",
      version = TigervncVersion,
      executablePath = "TigerVNC.app/Contents/MacOS/vncviewer",
      packageId = "tigervnc@" & TigervncVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:tigervnc@" & TigervncVersion &
        ":macos-any:sha256:aa0ef07e4ebe4f068cbf1118273459b5b616177cb6abf15a538af018ebfb5933"

## cursor — Cursor, Anysphere's AI code editor (macOS application).
##
## Cursor's notarized zips, one per CPU, from its commit-addressed release
## directory (`production/<commit>/darwin/<arm64|x64>/Cursor-darwin-<cpu>.zip`;
## the commit identifies the release, the file name does not). The zip also
## holds a top-level `resources/` directory beside the bundle, which is not
## used. The `cursor` command-line launcher is
## `Cursor.app/Contents/Resources/app/bin/cursor`. The bundle is signed by the
## Developer ID of ToDesktop's signer (team VDXQ22DGB9), as its identifier
## `com.todesktop.230313mzl4w4u92` reflects.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: Cursor.app, signed "Developer ID Application: Hilary Stout (VDXQ22DGB9)".
## * x86_64: Cursor.app, signed "Developer ID Application: Hilary Stout (VDXQ22DGB9)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.
##
## `cursor` is declared with `extraExecutable`: the home profile gets a
## launcher for it, running it from the placed bundle (§ macOS Application
## Bundles, "Command line"). The path was read off the extracted bundle
## of every record on 2026-10-16.

import repro_project_dsl

const
  CursorVersion = "3.25.6"
  CursorCommit = "f0df777c412b670d09e3eaf214967d779e67c088"

package cursor:
  provisioning:
    tarball url = "https://downloads.cursor.com/production/" & CursorCommit & "/darwin/arm64/Cursor-darwin-arm64.zip",
      sha256 = "823f2747547b72a93eac85ec3ab1e69e7c794fb03025c5c0cbec063ef5a2d8b0",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Cursor.app",
      bundleId = "com.todesktop.230313mzl4w4u92",
      teamId = "VDXQ22DGB9",
      version = CursorVersion,
      executablePath = "Cursor.app/Contents/MacOS/Cursor",
      extraExecutable = "Cursor.app/Contents/Resources/app/bin/cursor",
      packageId = "cursor@" & CursorVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:cursor@" & CursorVersion &
        ":macos-aarch64:sha256:823f2747547b72a93eac85ec3ab1e69e7c794fb03025c5c0cbec063ef5a2d8b0"

    tarball url = "https://downloads.cursor.com/production/" & CursorCommit & "/darwin/x64/Cursor-darwin-x64.zip",
      sha256 = "5f3ffb21d2671afb4c5a72985a95cba5fb2ce2e45e6a75c5f7dcb35f8d0f6ff5",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Cursor.app",
      bundleId = "com.todesktop.230313mzl4w4u92",
      teamId = "VDXQ22DGB9",
      version = CursorVersion,
      executablePath = "Cursor.app/Contents/MacOS/Cursor",
      extraExecutable = "Cursor.app/Contents/Resources/app/bin/cursor",
      packageId = "cursor@" & CursorVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:cursor@" & CursorVersion &
        ":macos-x86_64:sha256:5f3ffb21d2671afb4c5a72985a95cba5fb2ce2e45e6a75c5f7dcb35f8d0f6ff5"

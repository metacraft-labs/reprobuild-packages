## google-antigravity-ide — Google Antigravity IDE, the editor of Google
## Antigravity (macOS application).
##
## Google's notarized disk images, one per CPU (`darwin-arm`, `darwin-x64`),
## from the release directory named by the version and its build id
## (`antigravity/stable/<version>-<build id>/<platform>/Antigravity IDE.dmg`).
## The bundle's main executable is `Contents/MacOS/Electron`. The
## `antigravity-ide` command-line launcher is
## `Antigravity IDE.app/Contents/Resources/app/bin/antigravity-ide`.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: Antigravity IDE.app, signed "Developer ID Application: Google LLC (EQHXZ8M8AV)".
## * x86_64: Antigravity IDE.app, signed "Developer ID Application: Google LLC (EQHXZ8M8AV)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.
##
## `antigravity-ide` is declared with `extraExecutable`: the home profile gets a
## launcher for it, running it from the placed bundle (§ macOS Application
## Bundles, "Command line"). The path was read off the extracted bundle
## of every record on 2026-10-16.

import repro_project_dsl

const
  GoogleAntigravityIdeVersion = "2.5.5"
  GoogleAntigravityIdeBuild = "4923483625488384"

package `google-antigravity-ide`:
  provisioning:
    tarball url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/" & GoogleAntigravityIdeVersion & "-" & GoogleAntigravityIdeBuild & "/darwin-arm/Antigravity%20IDE.dmg",
      sha256 = "cad67d6d30a537fcb3bb9a6100330040ec6bcb686e38069f1ff16fe42306a33e",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Antigravity IDE.app",
      bundleId = "com.google.antigravity-ide",
      teamId = "EQHXZ8M8AV",
      version = GoogleAntigravityIdeVersion,
      executablePath = "Antigravity IDE.app/Contents/MacOS/Electron",
      extraExecutable = "Antigravity IDE.app/Contents/Resources/app/bin/antigravity-ide",
      packageId = "google-antigravity-ide@" & GoogleAntigravityIdeVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:google-antigravity-ide@" & GoogleAntigravityIdeVersion &
        ":macos-aarch64:sha256:cad67d6d30a537fcb3bb9a6100330040ec6bcb686e38069f1ff16fe42306a33e"

    tarball url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/" & GoogleAntigravityIdeVersion & "-" & GoogleAntigravityIdeBuild & "/darwin-x64/Antigravity%20IDE.dmg",
      sha256 = "a6434e157a549d1553bd19f99a233fcb03f1d7f66eee30ea16683559dd112120",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Antigravity IDE.app",
      bundleId = "com.google.antigravity-ide",
      teamId = "EQHXZ8M8AV",
      version = GoogleAntigravityIdeVersion,
      executablePath = "Antigravity IDE.app/Contents/MacOS/Electron",
      extraExecutable = "Antigravity IDE.app/Contents/Resources/app/bin/antigravity-ide",
      packageId = "google-antigravity-ide@" & GoogleAntigravityIdeVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:google-antigravity-ide@" & GoogleAntigravityIdeVersion &
        ":macos-x86_64:sha256:a6434e157a549d1553bd19f99a233fcb03f1d7f66eee30ea16683559dd112120"

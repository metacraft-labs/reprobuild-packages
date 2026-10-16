## google-antigravity — Google Antigravity, Google's agentic development
## application (the base app) (macOS application).
##
## Google's notarized disk images, one per CPU (`darwin-arm`, `darwin-x64`),
## from the release directory named by the version and its build id
## (`antigravity-hub/<version>-<build id>/<platform>/Antigravity.dmg`).
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: Antigravity.app, signed "Developer ID Application: Google LLC (EQHXZ8M8AV)".
## * x86_64: Antigravity.app, signed "Developer ID Application: Google LLC (EQHXZ8M8AV)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  GoogleAntigravityVersion = "2.23.1"
  GoogleAntigravityBuild = "6348059836284928"

package `google-antigravity`:
  provisioning:
    tarball url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/" & GoogleAntigravityVersion & "-" & GoogleAntigravityBuild & "/darwin-arm/Antigravity.dmg",
      sha256 = "c61a8746cc6dc5f754985f395d598368b80140652b0150f66b49b747d35acc87",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Antigravity.app",
      bundleId = "com.google.antigravity",
      teamId = "EQHXZ8M8AV",
      version = GoogleAntigravityVersion,
      executablePath = "Antigravity.app/Contents/MacOS/Antigravity",
      packageId = "google-antigravity@" & GoogleAntigravityVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:google-antigravity@" & GoogleAntigravityVersion &
        ":macos-aarch64:sha256:c61a8746cc6dc5f754985f395d598368b80140652b0150f66b49b747d35acc87"

    tarball url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/" & GoogleAntigravityVersion & "-" & GoogleAntigravityBuild & "/darwin-x64/Antigravity.dmg",
      sha256 = "51a29acf8eeccb6b7bb7702d9814bc1ecd3d10cb6b89c67f7a1fc419925a90c6",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Antigravity.app",
      bundleId = "com.google.antigravity",
      teamId = "EQHXZ8M8AV",
      version = GoogleAntigravityVersion,
      executablePath = "Antigravity.app/Contents/MacOS/Antigravity",
      packageId = "google-antigravity@" & GoogleAntigravityVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:google-antigravity@" & GoogleAntigravityVersion &
        ":macos-x86_64:sha256:51a29acf8eeccb6b7bb7702d9814bc1ecd3d10cb6b89c67f7a1fc419925a90c6"

## figma — Figma, the design tool (desktop app) (macOS application).
##
## Figma publishes one notarized zip per CPU (`mac-arm/` and `mac/`); the file
## name carries the version.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: Figma.app, signed "Developer ID Application: Figma, Inc. (T8RA8NE3B7)".
## * x86_64: Figma.app, signed "Developer ID Application: Figma, Inc. (T8RA8NE3B7)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  FigmaVersion = "126.9.13"

package figma:
  provisioning:
    tarball url = "https://desktop.figma.com/mac-arm/Figma-" & FigmaVersion & ".zip",
      sha256 = "8772e2f4188e823a9e8f92e34bcaf8d9489fae119be7beb22fdb8b8947b2d7f7",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Figma.app",
      bundleId = "com.figma.Desktop",
      teamId = "T8RA8NE3B7",
      version = FigmaVersion,
      executablePath = "Figma.app/Contents/MacOS/Figma",
      packageId = "figma@" & FigmaVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:figma@" & FigmaVersion &
        ":macos-aarch64:sha256:8772e2f4188e823a9e8f92e34bcaf8d9489fae119be7beb22fdb8b8947b2d7f7"

    tarball url = "https://desktop.figma.com/mac/Figma-" & FigmaVersion & ".zip",
      sha256 = "8ef8586d4f3b76f34a3ba44dd464b971bafe2a85973387df2a9f46c5b7c453ca",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Figma.app",
      bundleId = "com.figma.Desktop",
      teamId = "T8RA8NE3B7",
      version = FigmaVersion,
      executablePath = "Figma.app/Contents/MacOS/Figma",
      packageId = "figma@" & FigmaVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:figma@" & FigmaVersion &
        ":macos-x86_64:sha256:8ef8586d4f3b76f34a3ba44dd464b971bafe2a85973387df2a9f46c5b7c453ca"

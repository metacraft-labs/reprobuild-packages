## windows-app — Windows App (formerly Microsoft Remote Desktop) (macOS application).
##
## Microsoft distributes Windows App through the Mac App Store AND as a
## direct download: the versioned installer package on its MacAutoupdate CDN,
## the artifact Homebrew's `windows-app` cask also pins. The package is a
## product archive of three components:
##
## * `com.microsoft.rdc.macos.pkg` -- the payload `Windows App.app`. It carries
##   NO scripts.
## * `com.microsoft.rdc.installer.scripts.pkg` -- an empty payload and a
##   `postinstall` that renames a leftover `Microsoft Remote Desktop.app` and,
##   only for a GUI install, registers the app with Microsoft AutoUpdate.
## * `Office16_autoupdate_updater.pkg` -- Microsoft AutoUpdate itself.
##
## None of that is needed by the application (Reprobuild, not MAU, updates
## it), so the bundle is copied out of the first component's payload and no
## script runs. Universal (arm64 + x86_64).
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: Windows App.app, signed "Developer ID Application: Microsoft Corporation (UBF8T346G9)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  WindowsAppVersion = "11.4.4"

package `windows-app`:
  provisioning:
    tarball url = "https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/Windows_App_" & WindowsAppVersion & "_installer.pkg",
      sha256 = "70041210ec1c40cbcc1913010fb9a7de7e2b0c8d9f336777775789ae65bc9cab",
      archiveType = "pkg",
      installMethod = "app-bundle",
      appBundle = "com.microsoft.rdc.macos.pkg/Payload/Windows App.app",
      bundleId = "com.microsoft.rdc.macos",
      teamId = "UBF8T346G9",
      version = WindowsAppVersion,
      executablePath = "Windows App.app/Contents/MacOS/Windows App",
      packageId = "windows-app@" & WindowsAppVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:windows-app@" & WindowsAppVersion &
        ":macos-any:sha256:70041210ec1c40cbcc1913010fb9a7de7e2b0c8d9f336777775789ae65bc9cab"

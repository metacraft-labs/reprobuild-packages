## utm — UTM, the virtual machine host (macOS application).
##
## Upstream's notarized universal disk image from its GitHub release (the
## tag carries the version; the asset name `UTM.dmg` does not). `utmctl` is
## `UTM.app/Contents/MacOS/utmctl`.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: UTM.app, signed "Developer ID Application: Turing Software, LLC (WDNLXAD4W8)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  UtmVersion = "4.7.5"

package utm:
  provisioning:
    tarball url = "https://github.com/utmapp/UTM/releases/download/v" & UtmVersion & "/UTM.dmg",
      sha256 = "a8435c93cfb5f8bbfeea4b134cfad1ac66b67632b75e438c63b1a8ae043bef0e",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "UTM.app",
      bundleId = "com.utmapp.UTM",
      teamId = "WDNLXAD4W8",
      version = UtmVersion,
      executablePath = "UTM.app/Contents/MacOS/UTM",
      packageId = "utm@" & UtmVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:utm@" & UtmVersion &
        ":macos-any:sha256:a8435c93cfb5f8bbfeea4b134cfad1ac66b67632b75e438c63b1a8ae043bef0e"

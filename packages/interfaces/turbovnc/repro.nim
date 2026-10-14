## turbovnc — TurboVNC Viewer (macOS application).
##
## Upstream ships a disk image per CPU holding a notarized installer package
## (`TurboVNC.pkg`, one component, NO scripts) whose payload installs
## `/Applications/TurboVNC/TurboVNC Viewer.app` (with its own bundled JRE),
## a Listen Mode launcher, an uninstaller and `/opt/TurboVNC`. Only the viewer
## bundle is realized, copied out of the payload: it is self-contained (it
## references nothing under `/opt`). The Listen Mode app and the `/opt`
## command-line wrapper are not placed.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: TurboVNC Viewer.app, signed "Developer ID Application: Darrell Commander (LG36Y2V34X)".
## * x86_64: TurboVNC Viewer.app, signed "Developer ID Application: Darrell Commander (LG36Y2V34X)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  TurbovncVersion = "3.3.1"

package turbovnc:
  provisioning:
    tarball url = "https://github.com/TurboVNC/turbovnc/releases/download/" & TurbovncVersion & "/TurboVNC-" & TurbovncVersion & "-arm64.dmg",
      sha256 = "8d285f7bc00d30c0ace104b1d71b5ba4eb8bc2a561c71d8b7a26f2798f7d5db3",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "TurboVNC.pkg/TurboVNC.pkg/Payload/Applications/TurboVNC/TurboVNC Viewer.app",
      bundleId = "com.turbovnc.vncviewer.VncViewer",
      teamId = "LG36Y2V34X",
      version = TurbovncVersion,
      executablePath = "TurboVNC Viewer.app/Contents/MacOS/TurboVNC Viewer",
      packageId = "turbovnc@" & TurbovncVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:turbovnc@" & TurbovncVersion &
        ":macos-aarch64:sha256:8d285f7bc00d30c0ace104b1d71b5ba4eb8bc2a561c71d8b7a26f2798f7d5db3"

    tarball url = "https://github.com/TurboVNC/turbovnc/releases/download/" & TurbovncVersion & "/TurboVNC-" & TurbovncVersion & "-x86_64.dmg",
      sha256 = "7fc670c9110e05661c7be14438c919f44cb1515124f7daa47f5d7166b53f666d",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "TurboVNC.pkg/TurboVNC.pkg/Payload/Applications/TurboVNC/TurboVNC Viewer.app",
      bundleId = "com.turbovnc.vncviewer.VncViewer",
      teamId = "LG36Y2V34X",
      version = TurbovncVersion,
      executablePath = "TurboVNC Viewer.app/Contents/MacOS/TurboVNC Viewer",
      packageId = "turbovnc@" & TurbovncVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:turbovnc@" & TurbovncVersion &
        ":macos-x86_64:sha256:7fc670c9110e05661c7be14438c919f44cb1515124f7daa47f5d7166b53f666d"

## signal — Signal, the Signal Messenger desktop client (Signal Desktop) (macOS application).
##
## Signal's notarized zips from its update server, one per CPU
## (`signal-desktop-mac-<arm64|x64>-<version>.zip`); no universal build is
## published. Signal Desktop requires macOS 13 or later.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: Signal.app, signed "Developer ID Application: Signal Messenger, LLC (U68MSDN6DR)".
## * x86_64: Signal.app, signed "Developer ID Application: Signal Messenger, LLC (U68MSDN6DR)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  SignalVersion = "8.31.0"

package signal:
  provisioning:
    tarball url = "https://updates.signal.org/desktop/signal-desktop-mac-arm64-" & SignalVersion & ".zip",
      sha256 = "1bba76ba19125e936044bb43d79f979671d2947470502a0c213e001182fa5f6c",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Signal.app",
      bundleId = "org.whispersystems.signal-desktop",
      teamId = "U68MSDN6DR",
      version = SignalVersion,
      executablePath = "Signal.app/Contents/MacOS/Signal",
      packageId = "signal@" & SignalVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:signal@" & SignalVersion &
        ":macos-aarch64:sha256:1bba76ba19125e936044bb43d79f979671d2947470502a0c213e001182fa5f6c"

    tarball url = "https://updates.signal.org/desktop/signal-desktop-mac-x64-" & SignalVersion & ".zip",
      sha256 = "1458b5fbfab36b2191831959e7aa95a4b4bf60db75b55af41a0dd0977023f84b",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Signal.app",
      bundleId = "org.whispersystems.signal-desktop",
      teamId = "U68MSDN6DR",
      version = SignalVersion,
      executablePath = "Signal.app/Contents/MacOS/Signal",
      packageId = "signal@" & SignalVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:signal@" & SignalVersion &
        ":macos-x86_64:sha256:1458b5fbfab36b2191831959e7aa95a4b4bf60db75b55af41a0dd0977023f84b"

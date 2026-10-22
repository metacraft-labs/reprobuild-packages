## slack — Slack, the Slack Technologies desktop client (macOS application).
##
## Slack's notarized disk images from its versioned release directory
## (`desktop-releases/mac/<cpu>/<version>/Slack-<version>-macOS.dmg`), one per
## CPU (`arm64`, `x64`); a universal image is also published, at nearly twice
## the size of either.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: Slack.app, signed "Developer ID Application: SLACK TECHNOLOGIES L.L.C. (BQR82RBBHL)".
## * x86_64: Slack.app, signed "Developer ID Application: SLACK TECHNOLOGIES L.L.C. (BQR82RBBHL)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  SlackVersion = "4.52.178"

package slack:
  provisioning:
    tarball url = "https://downloads.slack-edge.com/desktop-releases/mac/arm64/" & SlackVersion & "/Slack-" & SlackVersion & "-macOS.dmg",
      sha256 = "8a5bd759b91478c19f23deef1f21b870a5c3c55b631e3341be32f1c297260331",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Slack.app",
      bundleId = "com.tinyspeck.slackmacgap",
      teamId = "BQR82RBBHL",
      version = SlackVersion,
      executablePath = "Slack.app/Contents/MacOS/Slack",
      packageId = "slack@" & SlackVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:slack@" & SlackVersion &
        ":macos-aarch64:sha256:8a5bd759b91478c19f23deef1f21b870a5c3c55b631e3341be32f1c297260331"

    tarball url = "https://downloads.slack-edge.com/desktop-releases/mac/x64/" & SlackVersion & "/Slack-" & SlackVersion & "-macOS.dmg",
      sha256 = "3d68c32bbb0b279c8481060017d0069bf2c6231b91c5199aa71e6c2a4132d2c1",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Slack.app",
      bundleId = "com.tinyspeck.slackmacgap",
      teamId = "BQR82RBBHL",
      version = SlackVersion,
      executablePath = "Slack.app/Contents/MacOS/Slack",
      packageId = "slack@" & SlackVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:slack@" & SlackVersion &
        ":macos-x86_64:sha256:3d68c32bbb0b279c8481060017d0069bf2c6231b91c5199aa71e6c2a4132d2c1"

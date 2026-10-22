## claude-desktop — Claude Desktop, Anthropic's desktop app (macOS application).
##
## Anthropic's notarized universal zip; its path carries the version and the
## build's commit (`releases/darwin/universal/<version>/Claude-<commit>.zip`).
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: Claude.app, signed "Developer ID Application: Anthropic PBC (Q6L2SF6YDW)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  ClaudeDesktopVersion = "2.42304.0"

package `claude-desktop`:
  provisioning:
    tarball url = "https://downloads.claude.ai/releases/darwin/universal/" & ClaudeDesktopVersion & "/Claude-e7f60e658f15cfece9efa384a78a39aec3c12845.zip",
      sha256 = "3d63d7180ead976ab268529c693a584df72e06824d5770937c79d6d8bc100cb4",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Claude.app",
      bundleId = "com.anthropic.claudefordesktop",
      teamId = "Q6L2SF6YDW",
      version = ClaudeDesktopVersion,
      executablePath = "Claude.app/Contents/MacOS/Claude",
      packageId = "claude-desktop@" & ClaudeDesktopVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:claude-desktop@" & ClaudeDesktopVersion &
        ":macos-any:sha256:3d63d7180ead976ab268529c693a584df72e06824d5770937c79d6d8bc100cb4"

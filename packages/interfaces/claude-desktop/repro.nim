## claude-desktop — Claude Desktop, Anthropic's desktop app (macOS application).
##
## Anthropic's notarized universal zip; its path carries the version and the
## build's commit (`releases/darwin/universal/<version>/Claude-<commit>.zip`).
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
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
  ClaudeDesktopVersion = "2.37337.1"

package `claude-desktop`:
  provisioning:
    tarball url = "https://downloads.claude.ai/releases/darwin/universal/" & ClaudeDesktopVersion & "/Claude-ba51ab579cc4029765083ec9f9f0bd23d37a32ee.zip",
      sha256 = "06185e36552dad5fa80f6fbdddc0cc9784d8f82cc8d3ec94d31a8140fea990a4",
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
        ":macos-any:sha256:06185e36552dad5fa80f6fbdddc0cc9784d8f82cc8d3ec94d31a8140fea990a4"

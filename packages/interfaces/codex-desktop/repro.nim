## codex-desktop — the Codex desktop app (OpenAI) (macOS application).
##
## The app's own Sparkle feed
## (https://persistent.oaistatic.com/codex-app-prod/appcast.xml, title "Codex")
## is the source of truth for its releases. Since 26.10 its head enclosure is
## `ChatGPT-darwin-arm64-<version>.zip`, whose bundle is `ChatGPT.app` with the
## Codex bundle identifier `com.openai.codex`: the Codex app now ships under
## that name. The feed's items are arm64-only, but the same directory carries
## the matching x86_64 build, `ChatGPT-darwin-x64-<version>.zip` (also
## `ChatGPT.app`), so both CPUs pin the same version. Both are notarized and
## signed by OpenAI (2DC432GLL2).
##
## Not the Homebrew cask `codex`, which is the codex CLI (package `codex`);
## the desktop app's cask is `codex-app`.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: ChatGPT.app, signed "Developer ID Application: OpenAI OpCo, LLC (2DC432GLL2)".
## * x86_64: ChatGPT.app, signed "Developer ID Application: OpenAI OpCo, LLC (2DC432GLL2)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  CodexDesktopVersion = "26.1013.31256"

package `codex-desktop`:
  provisioning:
    tarball url = "https://persistent.oaistatic.com/codex-app-prod/ChatGPT-darwin-arm64-" & CodexDesktopVersion & ".zip",
      sha256 = "5c75de21199a2637a2f1f648086cf1105565eecae89ac0e58cf151a1b16c703c",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "ChatGPT.app",
      bundleId = "com.openai.codex",
      teamId = "2DC432GLL2",
      version = CodexDesktopVersion,
      executablePath = "ChatGPT.app/Contents/MacOS/ChatGPT",
      packageId = "codex-desktop@" & CodexDesktopVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:codex-desktop@" & CodexDesktopVersion &
        ":macos-aarch64:sha256:5c75de21199a2637a2f1f648086cf1105565eecae89ac0e58cf151a1b16c703c"

    tarball url = "https://persistent.oaistatic.com/codex-app-prod/ChatGPT-darwin-x64-" & CodexDesktopVersion & ".zip",
      sha256 = "8091769e0e521e0bb1cc9b58b85c0d7dc79bd998d70c398a49c170e1fa33d9a4",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "ChatGPT.app",
      bundleId = "com.openai.codex",
      teamId = "2DC432GLL2",
      version = CodexDesktopVersion,
      executablePath = "ChatGPT.app/Contents/MacOS/ChatGPT",
      packageId = "codex-desktop@" & CodexDesktopVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:codex-desktop@" & CodexDesktopVersion &
        ":macos-x86_64:sha256:8091769e0e521e0bb1cc9b58b85c0d7dc79bd998d70c398a49c170e1fa33d9a4"

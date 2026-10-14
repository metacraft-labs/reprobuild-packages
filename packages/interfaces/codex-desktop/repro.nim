## codex-desktop — the Codex desktop app (OpenAI) (macOS application).
##
## The app's own Sparkle feed
## (https://persistent.oaistatic.com/codex-app-prod/appcast.xml, title "Codex")
## is the source of truth for its releases. Since 26.10 its head enclosure is
## `ChatGPT-darwin-arm64-<version>.zip`, whose bundle is `ChatGPT.app` with the
## Codex bundle identifier `com.openai.codex`: the Codex app now ships under
## that name. The feed's items are arm64-only; the newest x86_64 build found
## is the earlier `Codex-darwin-x64-26.623.141536.zip` (bundle `Codex.app`), so
## the two CPUs carry different versions and bundle names. Both are
## notarized and signed by OpenAI (2DC432GLL2).
##
## Note for the dotfiles migration: the Homebrew cask `codex` that
## `modules/mac-casks.nix` labels "Codex Desktop" is the codex CLI; the desktop
## app is the `codex-app` cask.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: ChatGPT.app, signed "Developer ID Application: OpenAI OpCo, LLC (2DC432GLL2)".
## * x86_64: Codex.app, signed "Developer ID Application: OpenAI OpCo, LLC (2DC432GLL2)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  CodexDesktopVersion = "26.1007.41230"

package `codex-desktop`:
  provisioning:
    tarball url = "https://persistent.oaistatic.com/codex-app-prod/ChatGPT-darwin-arm64-" & CodexDesktopVersion & ".zip",
      sha256 = "c542b9eb977a2f4d6598a951e3775edd129407ee9c92644e16b3153816f3f56b",
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
        ":macos-aarch64:sha256:c542b9eb977a2f4d6598a951e3775edd129407ee9c92644e16b3153816f3f56b"

    tarball url = "https://persistent.oaistatic.com/codex-app-prod/Codex-darwin-x64-26.623.141536.zip",
      sha256 = "5a8eb9bca0c021b994e56c93ef3502bdbc105975bcb83f99aef40f2ae56d48cc",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Codex.app",
      bundleId = "com.openai.codex",
      teamId = "2DC432GLL2",
      version = "26.623.141536",
      executablePath = "Codex.app/Contents/MacOS/Codex",
      packageId = "codex-desktop@" & "26.623.141536",
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:codex-desktop@" & "26.623.141536" &
        ":macos-x86_64:sha256:5a8eb9bca0c021b994e56c93ef3502bdbc105975bcb83f99aef40f2ae56d48cc"

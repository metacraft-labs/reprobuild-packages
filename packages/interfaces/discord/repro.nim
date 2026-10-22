## discord — Discord, the Discord Inc. desktop client (macOS application).
##
## Discord's notarized universal disk image (arm64 + x86_64 in one bundle), so
## one record serves both macOS CPUs. The URL is versioned by its directory
## (`apps/osx/<version>/Discord.dmg`).
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: Discord.app, signed "Developer ID Application: Discord, Inc. (53Q6R32WPB)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  DiscordVersion = "0.0.416"

package discord:
  provisioning:
    tarball url = "https://dl.discordapp.net/apps/osx/" & DiscordVersion & "/Discord.dmg",
      sha256 = "9bcada2ac203337ec523930de5ace261c1839250bfd4e648999af93f5be9a646",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Discord.app",
      bundleId = "com.hnc.Discord",
      teamId = "53Q6R32WPB",
      version = DiscordVersion,
      executablePath = "Discord.app/Contents/MacOS/Discord",
      packageId = "discord@" & DiscordVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:discord@" & DiscordVersion &
        ":macos-any:sha256:9bcada2ac203337ec523930de5ace261c1839250bfd4e648999af93f5be9a646"

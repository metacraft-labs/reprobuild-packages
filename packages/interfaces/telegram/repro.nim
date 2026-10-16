## telegram — Telegram, the Telegram messenger desktop client (macOS application).
##
## Telegram's notarized universal zip from its update server (arm64 + x86_64
## in one bundle). The file name carries the version and the build
## (`Telegram-<version>.<build>.app.zip`); the bundle's
## CFBundleShortVersionString is the version alone (`13.0`), its
## CFBundleVersion the build (`283305`).
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: Telegram.app, signed "Developer ID Application: TELEGRAM MESSENGER LLP (6N38VWS5BX)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  TelegramVersion = "13.0"
  TelegramBuild = "283305"

package telegram:
  provisioning:
    tarball url = "https://osx.telegram.org/updates/Telegram-" & TelegramVersion & "." & TelegramBuild & ".app.zip",
      sha256 = "eae378083774b6d379c328c71989b764fa960e5e4265236e0fc58b8a08014a64",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Telegram.app",
      bundleId = "ru.keepcoder.Telegram",
      teamId = "6N38VWS5BX",
      version = TelegramVersion,
      executablePath = "Telegram.app/Contents/MacOS/Telegram",
      packageId = "telegram@" & TelegramVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:telegram@" & TelegramVersion &
        ":macos-any:sha256:eae378083774b6d379c328c71989b764fa960e5e4265236e0fc58b8a08014a64"

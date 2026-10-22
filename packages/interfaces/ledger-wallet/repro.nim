## ledger-wallet — Ledger Wallet (formerly Ledger Live), the companion
## application for Ledger hardware wallets (macOS application).
##
## Ledger's notarized universal disk image (arm64 + x86_64 in one bundle),
## versioned by its file name (`ledger-live-desktop-<version>-mac.dmg`). The
## bundle keeps the Ledger Live identifier `com.ledger.live`.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: Ledger Wallet.app, signed "Developer ID Application: Ledger SAS (X6LFS5BQKN)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  LedgerWalletVersion = "4.24.0"

package `ledger-wallet`:
  provisioning:
    tarball url = "https://download.live.ledger.com/ledger-live-desktop-" & LedgerWalletVersion & "-mac.dmg",
      sha256 = "a515c0a179b8e49baf54f9c9c87b796879fd6ee3b50c9a07e9a60d42a4ba0948",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Ledger Wallet.app",
      bundleId = "com.ledger.live",
      teamId = "X6LFS5BQKN",
      version = LedgerWalletVersion,
      executablePath = "Ledger Wallet.app/Contents/MacOS/Ledger Wallet",
      packageId = "ledger-wallet@" & LedgerWalletVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:ledger-wallet@" & LedgerWalletVersion &
        ":macos-any:sha256:a515c0a179b8e49baf54f9c9c87b796879fd6ee3b50c9a07e9a60d42a4ba0948"

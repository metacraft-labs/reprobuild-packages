## sqlitebrowser — DB Browser for SQLite (macOS application).
##
## Upstream's notarized universal disk image from its GitHub release. The
## bundle's `CFBundleExecutable` is empty; macOS falls back to the bundle name,
## which is the executable below.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: DB Browser for SQLite.app, signed "Developer ID Application: Justin Clift (C34AV33YLK)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  SqlitebrowserVersion = "3.13.1"

package sqlitebrowser:
  provisioning:
    tarball url = "https://github.com/sqlitebrowser/sqlitebrowser/releases/download/v" & SqlitebrowserVersion & "/DB.Browser.for.SQLite-v" & SqlitebrowserVersion & ".dmg",
      sha256 = "a641cfbfcc2ce609f07de44a35134dab53485ecc18e6d9afa297b514d74bd75e",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "DB Browser for SQLite.app",
      bundleId = "net.sourceforge.sqlitebrowser",
      teamId = "C34AV33YLK",
      version = SqlitebrowserVersion,
      executablePath = "DB Browser for SQLite.app/Contents/MacOS/DB Browser for SQLite",
      packageId = "sqlitebrowser@" & SqlitebrowserVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:sqlitebrowser@" & SqlitebrowserVersion &
        ":macos-any:sha256:a641cfbfcc2ce609f07de44a35134dab53485ecc18e6d9afa297b514d74bd75e"

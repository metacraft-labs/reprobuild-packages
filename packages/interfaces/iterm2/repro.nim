## iterm2 — iTerm2, the terminal emulator (macOS application).
##
## Upstream's notarized universal zip; the file name carries the version
## (`iTerm2-3_7_4.zip`).
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: iTerm.app, signed "Developer ID Application: GEORGE NACHMAN (H7V7XYVQ7D)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import std/strutils

import repro_project_dsl

const
  Iterm2Version = "3.7.4"

package iterm2:
  provisioning:
    tarball url = "https://iterm2.com/downloads/stable/iTerm2-" & Iterm2Version.replace('.', '_') & ".zip",
      sha256 = "4bf02ae616752600cd195ca504e55392afb21741cda7314199e375ed8a46f90c",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "iTerm.app",
      bundleId = "com.googlecode.iterm2",
      teamId = "H7V7XYVQ7D",
      version = Iterm2Version,
      executablePath = "iTerm.app/Contents/MacOS/iTerm2",
      packageId = "iterm2@" & Iterm2Version,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:iterm2@" & Iterm2Version &
        ":macos-any:sha256:4bf02ae616752600cd195ca504e55392afb21741cda7314199e375ed8a46f90c"

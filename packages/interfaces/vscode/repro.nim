## vscode — Visual Studio Code (macOS application).
##
## Microsoft's versioned update endpoint
## (`update.code.visualstudio.com/<version>/<platform>/stable`) redirects to the
## commit-addressed zip on its CDN; the content is pinned by sha256 either way.
## One notarized zip per CPU (`darwin-arm64`, `darwin`). The `code` command-line
## launcher is `Visual Studio Code.app/Contents/Resources/app/bin/code`.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-16: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: Visual Studio Code.app, signed "Developer ID Application: Microsoft Corporation (UBF8T346G9)".
## * x86_64: Visual Studio Code.app, signed "Developer ID Application: Microsoft Corporation (UBF8T346G9)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.
##
## `code` and `code-tunnel` are declared with `extraExecutable`: the home
## profile gets a launcher for each, running it from the placed bundle (§ macOS
## Application Bundles, "Command line"). The paths were read off the
## extracted bundles of every record on 2026-10-16.

import repro_project_dsl

const
  VscodeVersion = "1.142.0"

package vscode:
  provisioning:
    tarball url = "https://update.code.visualstudio.com/" & VscodeVersion & "/darwin-arm64/stable",
      sha256 = "099d3514fda308822a150d65ea36d4c4bfc565ee1b7fbc5a3fff97700f7af408",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Visual Studio Code.app",
      bundleId = "com.microsoft.VSCode",
      teamId = "UBF8T346G9",
      version = VscodeVersion,
      executablePath = "Visual Studio Code.app/Contents/MacOS/Code",
      extraExecutable = "Visual Studio Code.app/Contents/Resources/app/bin/code",
      extraExecutable = "Visual Studio Code.app/Contents/Resources/app/bin/code-tunnel",
      packageId = "vscode@" & VscodeVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:vscode@" & VscodeVersion &
        ":macos-aarch64:sha256:099d3514fda308822a150d65ea36d4c4bfc565ee1b7fbc5a3fff97700f7af408"

    tarball url = "https://update.code.visualstudio.com/" & VscodeVersion & "/darwin/stable",
      sha256 = "cbe7bfbfe576f4315ffd5d4ac67c8dd550972659b7f1785999ed96505f25a31a",
      archiveType = "zip",
      installMethod = "app-bundle",
      appBundle = "Visual Studio Code.app",
      bundleId = "com.microsoft.VSCode",
      teamId = "UBF8T346G9",
      version = VscodeVersion,
      executablePath = "Visual Studio Code.app/Contents/MacOS/Code",
      extraExecutable = "Visual Studio Code.app/Contents/Resources/app/bin/code",
      extraExecutable = "Visual Studio Code.app/Contents/Resources/app/bin/code-tunnel",
      packageId = "vscode@" & VscodeVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:vscode@" & VscodeVersion &
        ":macos-x86_64:sha256:cbe7bfbfe576f4315ffd5d4ac67c8dd550972659b7f1785999ed96505f25a31a"

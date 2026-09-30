## shfmt — the shell-script formatter from mvdan/sh.
##
## Moved here from reprobuild's bundled stdlib
## (`repro_dsl_stdlib/packages/shfmt.nim`), which realized it from a release
## binary on Windows x86_64 only and was not on the stdlib's list of names a
## plain `uses:` line reaches. A plain `uses: "shfmt"` now reaches this module
## through the engine's catalog lookup. A recipe that imported the stdlib
## module directly must drop that import; the `uses:` line alone registers
## this package.
##
## Upstream ships bare executables with no archive around them, so every slice
## is `archiveType = "raw"` and the realize step renames the download to the
## declared `executablePath` -- which is what makes the program callable as
## `shfmt` despite the versioned upstream file name. The Linux builds are
## static.
##
## Version 3.12.0, the version the pinned nixpkgs carries and the one the
## from-source recipe `packages/source/shfmt` builds. Each SHA-256 below was
## computed over the downloaded file and matches both upstream's
## `sha256sums.txt` for the release and GitHub's asset digest (2026-09-30).
## Upstream publishes no arm64 Windows build of this release (see
## `tools/platform-coverage.tsv`).

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

const
  ShfmtVersion = "3.12.0"
  ShfmtBase = "https://github.com/mvdan/sh/releases/download/v" &
    ShfmtVersion & "/shfmt_v" & ShfmtVersion & "_"

package shfmt:
  provisioning:
    nixPackage "nixpkgs#shfmt", executablePath = "bin/shfmt",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

    tarball url = ShfmtBase & "windows_amd64.exe",
      sha256 = "c8bda517ba1c640ce4a715c0fa665439ddbe4357ba5e9b77b0e51e70e2b9c94b",
      archiveType = "raw",
      executablePath = "shfmt.exe",
      packageId = "shfmt@" & ShfmtVersion,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:shfmt@" & ShfmtVersion &
        ":windows-x86_64:sha256:c8bda517ba1c640ce4a715c0fa665439ddbe4357ba5e9b77b0e51e70e2b9c94b"

    tarball url = ShfmtBase & "linux_amd64",
      sha256 = "d9fbb2a9c33d13f47e7618cf362a914d029d02a6df124064fff04fd688a745ea",
      archiveType = "raw",
      executablePath = "shfmt",
      packageId = "shfmt@" & ShfmtVersion,
      cpu = "x86_64",
      os = "linux",
      lockIdentity = "tarball:shfmt@" & ShfmtVersion &
        ":linux-x86_64:sha256:d9fbb2a9c33d13f47e7618cf362a914d029d02a6df124064fff04fd688a745ea"

    tarball url = ShfmtBase & "linux_arm64",
      sha256 = "5f3fe3fa6a9f766e6a182ba79a94bef8afedafc57db0b1ad32b0f67fae971ba4",
      archiveType = "raw",
      executablePath = "shfmt",
      packageId = "shfmt@" & ShfmtVersion,
      cpu = "aarch64",
      os = "linux",
      lockIdentity = "tarball:shfmt@" & ShfmtVersion &
        ":linux-aarch64:sha256:5f3fe3fa6a9f766e6a182ba79a94bef8afedafc57db0b1ad32b0f67fae971ba4"

    tarball url = ShfmtBase & "darwin_amd64",
      sha256 = "c31548693de6584e6164b7ed5fbb7b4a083f2d937ca94b4e0ddf59aa461a85e4",
      archiveType = "raw",
      executablePath = "shfmt",
      packageId = "shfmt@" & ShfmtVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:shfmt@" & ShfmtVersion &
        ":macos-x86_64:sha256:c31548693de6584e6164b7ed5fbb7b4a083f2d937ca94b4e0ddf59aa461a85e4"

    tarball url = ShfmtBase & "darwin_arm64",
      sha256 = "d903802e0ce3ecbc82b98512f55ba370b0d37a93f3f78de394f5b657052b33dd",
      archiveType = "raw",
      executablePath = "shfmt",
      packageId = "shfmt@" & ShfmtVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:shfmt@" & ShfmtVersion &
        ":macos-aarch64:sha256:d903802e0ce3ecbc82b98512f55ba370b0d37a93f3f78de394f5b657052b33dd"

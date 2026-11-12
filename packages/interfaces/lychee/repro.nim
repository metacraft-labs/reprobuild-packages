## lychee — the link checker (lycheeverse/lychee).
##
## The release assets are upstream's own for 0.23.0, as its
## `release-binary.yml` workflow names them:
##
## * Windows x86_64: `lychee-x86_64-windows.exe`, a bare executable with no
##   archive around it, so the slice is `archiveType = "raw"` and realize
##   renames the download to `lychee.exe`. Upstream builds no Windows arm64
##   binary (see `tools/platform-coverage.tsv`).
## * Linux x86_64 and aarch64: the static `-unknown-linux-musl` builds.
## * macOS aarch64: `lychee-arm64-macos.tar.gz`. Upstream builds macOS on an
##   arm64 runner only, so there is no macOS x86_64 asset.
##
## Every tar.gz holds `./lychee` at its root beside a `docs/` directory, so
## nothing is stripped.
##
## Version 0.23.0, the version the pinned nixpkgs of the repositories that
## run lychee as a lint gate carries. The Nix realization below follows the
## catalog's shared nixpkgs pin.
##
## Each SHA-256 below was computed over the downloaded asset (2026-11-12).
## Upstream publishes no checksum file of its own. The Linux x86_64 binary
## was run and reports `lychee 0.23.0`.

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

const
  LycheeVersion = "0.23.0"
  LycheeBase = "https://github.com/lycheeverse/lychee/releases/download/lychee-v" &
    LycheeVersion & "/lychee-"

package lychee:
  provisioning:
    nixPackage "nixpkgs#lychee", executablePath = "bin/lychee",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

    tarball url = LycheeBase & "x86_64-windows.exe",
      sha256 = "0fda7ff0a60c0250939fc25361c2d4e6e7853c31c996733fdd5a1dd760bcb824",
      archiveType = "raw",
      executablePath = "lychee.exe",
      packageId = "lychee@" & LycheeVersion,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:lychee@" & LycheeVersion &
        ":windows-x86_64:sha256:0fda7ff0a60c0250939fc25361c2d4e6e7853c31c996733fdd5a1dd760bcb824"

    tarball url = LycheeBase & "x86_64-unknown-linux-musl.tar.gz",
      sha256 = "5538440d2c69a45a0a09983271e5dee0c2fe7137d8035d25b2632e10a66a090a",
      archiveType = "tar.gz",
      executablePath = "lychee",
      packageId = "lychee@" & LycheeVersion,
      cpu = "x86_64",
      os = "linux",
      lockIdentity = "tarball:lychee@" & LycheeVersion &
        ":linux-x86_64:sha256:5538440d2c69a45a0a09983271e5dee0c2fe7137d8035d25b2632e10a66a090a"

    tarball url = LycheeBase & "aarch64-unknown-linux-musl.tar.gz",
      sha256 = "4eb6ff3ccd40dbb71843c41429683d3c60fe3b33b2042ffbbff9bb21cedacb39",
      archiveType = "tar.gz",
      executablePath = "lychee",
      packageId = "lychee@" & LycheeVersion,
      cpu = "aarch64",
      os = "linux",
      lockIdentity = "tarball:lychee@" & LycheeVersion &
        ":linux-aarch64:sha256:4eb6ff3ccd40dbb71843c41429683d3c60fe3b33b2042ffbbff9bb21cedacb39"

    tarball url = LycheeBase & "arm64-macos.tar.gz",
      sha256 = "1953bb425486e1b887757201e54e8fdf866c9cada6c270d8f6ed21ffbed4145a",
      archiveType = "tar.gz",
      executablePath = "lychee",
      packageId = "lychee@" & LycheeVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:lychee@" & LycheeVersion &
        ":macos-aarch64:sha256:1953bb425486e1b887757201e54e8fdf866c9cada6c270d8f6ed21ffbed4145a"

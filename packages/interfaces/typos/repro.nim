## typos — the source-code spell checker (crate-ci/typos).
##
## The release archives are upstream's own for 1.45.0:
##
## * Windows x86_64: `typos-v1.45.0-x86_64-pc-windows-msvc.zip`, with
##   `typos.exe` at its root beside the licences and a `doc/` directory.
##   Upstream publishes no Windows arm64 build (see
##   `tools/platform-coverage.tsv`).
## * Linux x86_64 and aarch64: the static `-unknown-linux-musl` builds, which
##   are the only Linux builds upstream publishes.
## * macOS x86_64 and aarch64: the `-apple-darwin` builds.
##
## Every tar.gz holds `./typos` at its root, so nothing is stripped.
##
## WHY 1.45.0 AND NOT THE PINNED NIXPKGS' 1.40.0. The Windows zip of 1.40.0
## (sha256 f13426420749fae31136e15a245c8eb144d6d3d681b3300d54d1a129999a140d)
## is quarantined on download by Microsoft Defender as
## `Trojan:Win32/Suschil!rfn`, a heuristic detection, so a Windows host with
## Defender on cannot realize it at all. 1.45.0's zip is not flagged, and it is
## the version RunQuota's flake dev shell (nixpkgs-unstable) already carries.
## The Nix realization below follows the catalog's shared nixpkgs pin and so
## still resolves 1.40.0; the two differ by release only, not by the command
## they provide.
##
## Each SHA-256 below was computed over the downloaded archive and matches the
## digest GitHub's release API reports for the asset (2026-09-30). Upstream
## publishes no checksum file of its own.

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

const
  TyposVersion = "1.45.0"
  TyposBase = "https://github.com/crate-ci/typos/releases/download/v" &
    TyposVersion & "/typos-v" & TyposVersion & "-"

package typos:
  provisioning:
    nixPackage "nixpkgs#typos", executablePath = "bin/typos",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

    tarball url = TyposBase & "x86_64-pc-windows-msvc.zip",
      sha256 = "dc89f5f175ee1a389e1f5cc5173353d9db3751e2cddedf34339d8ec45cd38aa0",
      archiveType = "zip",
      executablePath = "typos.exe",
      packageId = "typos@" & TyposVersion,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:typos@" & TyposVersion &
        ":windows-x86_64:sha256:dc89f5f175ee1a389e1f5cc5173353d9db3751e2cddedf34339d8ec45cd38aa0"

    tarball url = TyposBase & "x86_64-unknown-linux-musl.tar.gz",
      sha256 = "fa10c3c77c61bdf03f2f6f8245eb6fb89d92115450272a4eabe326b3967ac375",
      archiveType = "tar.gz",
      executablePath = "typos",
      packageId = "typos@" & TyposVersion,
      cpu = "x86_64",
      os = "linux",
      lockIdentity = "tarball:typos@" & TyposVersion &
        ":linux-x86_64:sha256:fa10c3c77c61bdf03f2f6f8245eb6fb89d92115450272a4eabe326b3967ac375"

    tarball url = TyposBase & "aarch64-unknown-linux-musl.tar.gz",
      sha256 = "dde3b5c5bd5d0ab6ff76a1465658dc6485e7d420cf8eccfdfbdea37809bed793",
      archiveType = "tar.gz",
      executablePath = "typos",
      packageId = "typos@" & TyposVersion,
      cpu = "aarch64",
      os = "linux",
      lockIdentity = "tarball:typos@" & TyposVersion &
        ":linux-aarch64:sha256:dde3b5c5bd5d0ab6ff76a1465658dc6485e7d420cf8eccfdfbdea37809bed793"

    tarball url = TyposBase & "x86_64-apple-darwin.tar.gz",
      sha256 = "4a4c1060b248c13ce7bc6c1ffe5cb75120885e8ecb62e7ba2b40f5567680f9ba",
      archiveType = "tar.gz",
      executablePath = "typos",
      packageId = "typos@" & TyposVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:typos@" & TyposVersion &
        ":macos-x86_64:sha256:4a4c1060b248c13ce7bc6c1ffe5cb75120885e8ecb62e7ba2b40f5567680f9ba"

    tarball url = TyposBase & "aarch64-apple-darwin.tar.gz",
      sha256 = "c42f8d8af49bff559f0bf0a45d1fb704f9e13446cc8faebfb30a3f669b89c802",
      archiveType = "tar.gz",
      executablePath = "typos",
      packageId = "typos@" & TyposVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:typos@" & TyposVersion &
        ":macos-aarch64:sha256:c42f8d8af49bff559f0bf0a45d1fb704f9e13446cc8faebfb30a3f669b89c802"

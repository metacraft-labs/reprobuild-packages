## prek — a fast, Rust reimplementation of the pre-commit hook runner
## (j178/prek).
##
## Moved here from reprobuild's bundled stdlib
## (`repro_dsl_stdlib/packages/prek.nim`), which realized it from release
## archives on Windows only and was not on the stdlib's list of names a plain
## `uses:` line reaches. A plain `uses: "prek"` now reaches this module
## through the engine's catalog lookup. A recipe that imported the stdlib
## module directly must drop that import; the `uses:` line alone registers
## this package.
##
## prek reads the same `.pre-commit-config.yaml` as pre-commit, plus its own
## `prek.toml`, and needs no Python environment of its own -- which is why a
## Windows dev environment takes it where a Nix one would take pre-commit.
##
## Version 0.3.2, the version the from-source recipe `packages/source/prek`
## builds:
##
## * Windows x86_64 and aarch64: `prek-<target>-pc-windows-msvc.zip`, with
##   `prek.exe` at the root.
## * Linux x86_64 and aarch64: the static `-unknown-linux-musl` builds rather
##   than the glibc ones, so the binary runs whatever the host's libc.
## * macOS x86_64 and aarch64: the `-apple-darwin` builds.
##
## Each tar.gz holds `prek` under a `prek-<target>/` directory, which
## `stripComponents = 1` removes. Each SHA-256 below was computed over the
## downloaded archive and matches the digest GitHub's release API reports for
## the asset (2026-09-30); the two Windows digests are also the ones the stdlib
## copy carried.

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

const
  PrekVersion = "0.3.2"
  PrekBase = "https://github.com/j178/prek/releases/download/v" &
    PrekVersion & "/prek-"

package prek:
  provisioning:
    nixPackage "nixpkgs#prek", executablePath = "bin/prek",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

    tarball url = PrekBase & "x86_64-pc-windows-msvc.zip",
      sha256 = "4aaf87523d3588090a6f547a5eca379264ddb287e3a424a1fab73aca6cd9c0c0",
      archiveType = "zip",
      executablePath = "prek.exe",
      packageId = "prek@" & PrekVersion,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:prek@" & PrekVersion &
        ":windows-x86_64:sha256:4aaf87523d3588090a6f547a5eca379264ddb287e3a424a1fab73aca6cd9c0c0"

    tarball url = PrekBase & "aarch64-pc-windows-msvc.zip",
      sha256 = "14694b2623fffa38402dbdc1c2208c91400557fd44f7083160853e6027b125d7",
      archiveType = "zip",
      executablePath = "prek.exe",
      packageId = "prek@" & PrekVersion,
      cpu = "aarch64",
      os = "windows",
      lockIdentity = "tarball:prek@" & PrekVersion &
        ":windows-aarch64:sha256:14694b2623fffa38402dbdc1c2208c91400557fd44f7083160853e6027b125d7"

    tarball url = PrekBase & "x86_64-unknown-linux-musl.tar.gz",
      sha256 = "7960379beca845367258ce4080a0ce1754d88846d9cfe273106f272442729eff",
      archiveType = "tar.gz",
      stripComponents = 1,
      executablePath = "prek",
      packageId = "prek@" & PrekVersion,
      cpu = "x86_64",
      os = "linux",
      lockIdentity = "tarball:prek@" & PrekVersion &
        ":linux-x86_64:sha256:7960379beca845367258ce4080a0ce1754d88846d9cfe273106f272442729eff"

    tarball url = PrekBase & "aarch64-unknown-linux-musl.tar.gz",
      sha256 = "fce387f0c31e87ceebb1ae84ad5fe3502931b248c89cfe5ee8208dcfa0656260",
      archiveType = "tar.gz",
      stripComponents = 1,
      executablePath = "prek",
      packageId = "prek@" & PrekVersion,
      cpu = "aarch64",
      os = "linux",
      lockIdentity = "tarball:prek@" & PrekVersion &
        ":linux-aarch64:sha256:fce387f0c31e87ceebb1ae84ad5fe3502931b248c89cfe5ee8208dcfa0656260"

    tarball url = PrekBase & "x86_64-apple-darwin.tar.gz",
      sha256 = "4bdf9b59530b7593a3f5d8dcce43c67e442a79af730cbd1b73c223ef30b5c1b5",
      archiveType = "tar.gz",
      stripComponents = 1,
      executablePath = "prek",
      packageId = "prek@" & PrekVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:prek@" & PrekVersion &
        ":macos-x86_64:sha256:4bdf9b59530b7593a3f5d8dcce43c67e442a79af730cbd1b73c223ef30b5c1b5"

    tarball url = PrekBase & "aarch64-apple-darwin.tar.gz",
      sha256 = "9705b3e3df6db7f1128058fb4f5198736553e6c3957afe0810fa7e974679c88c",
      archiveType = "tar.gz",
      stripComponents = 1,
      executablePath = "prek",
      packageId = "prek@" & PrekVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:prek@" & PrekVersion &
        ":macos-aarch64:sha256:9705b3e3df6db7f1128058fb4f5198736553e6c3957afe0810fa7e974679c88c"

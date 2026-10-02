## actionlint — the static checker for GitHub Actions workflow files
## (rhysd/actionlint).
##
## reprobuild's `just lint` runs it over `.github/workflows` through
## `scripts/check_workflows.sh`. Its flake dev shell carries it on Linux and
## macOS; this interface is what lets a plain `uses: "actionlint"` provide it
## where there is no flake shell, which is Windows.
##
## Version 1.7.9, the version the pinned nixpkgs carries, so the Nix and the
## release-archive realizations provide the same release. Upstream's own
## archives for it:
##
## * Windows x86_64 and aarch64: `actionlint_1.7.9_windows_<arch>.zip`, with
##   `actionlint.exe` at its root beside the licence and `docs/`.
## * Linux and macOS x86_64 and aarch64: `actionlint_1.7.9_<os>_<arch>.tar.gz`,
##   with `actionlint` at its root, so nothing is stripped. The binaries are
##   statically linked Go programs.
##
## Each SHA-256 below was computed over the downloaded archive and matches
## both upstream's `actionlint_1.7.9_checksums.txt` for the release and the
## digest GitHub's release API reports for the asset (2026-10-02). The
## Windows x86_64 binary was run once after extraction and reported `1.7.9`.

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

const
  ActionlintVersion = "1.7.9"
  ActionlintBase = "https://github.com/rhysd/actionlint/releases/download/v" &
    ActionlintVersion & "/actionlint_" & ActionlintVersion & "_"

package actionlint:
  provisioning:
    nixPackage "nixpkgs#actionlint", executablePath = "bin/actionlint",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

    tarball url = ActionlintBase & "windows_amd64.zip",
      sha256 = "7c8b10a93723838bc3533f6e1886d868fdbb109b81606ebe6d1a533d11d8e978",
      archiveType = "zip",
      executablePath = "actionlint.exe",
      packageId = "actionlint@" & ActionlintVersion,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:actionlint@" & ActionlintVersion &
        ":windows-x86_64:sha256:7c8b10a93723838bc3533f6e1886d868fdbb109b81606ebe6d1a533d11d8e978"

    tarball url = ActionlintBase & "windows_arm64.zip",
      sha256 = "7aca9bf09eedf0a743e08c7cb9f1712467a7324a9342a029ae4536fb4be95c25",
      archiveType = "zip",
      executablePath = "actionlint.exe",
      packageId = "actionlint@" & ActionlintVersion,
      cpu = "aarch64",
      os = "windows",
      lockIdentity = "tarball:actionlint@" & ActionlintVersion &
        ":windows-aarch64:sha256:7aca9bf09eedf0a743e08c7cb9f1712467a7324a9342a029ae4536fb4be95c25"

    tarball url = ActionlintBase & "linux_amd64.tar.gz",
      sha256 = "233b280d05e100837f4af1433c7b40a5dcb306e3aa68fb4f17f8a7f45a7df7b4",
      archiveType = "tar.gz",
      executablePath = "actionlint",
      packageId = "actionlint@" & ActionlintVersion,
      cpu = "x86_64",
      os = "linux",
      lockIdentity = "tarball:actionlint@" & ActionlintVersion &
        ":linux-x86_64:sha256:233b280d05e100837f4af1433c7b40a5dcb306e3aa68fb4f17f8a7f45a7df7b4"

    tarball url = ActionlintBase & "linux_arm64.tar.gz",
      sha256 = "6b82a3b8c808bf1bcd39a95aced22fc1a026eef08ede410f81e274af8deadbbc",
      archiveType = "tar.gz",
      executablePath = "actionlint",
      packageId = "actionlint@" & ActionlintVersion,
      cpu = "aarch64",
      os = "linux",
      lockIdentity = "tarball:actionlint@" & ActionlintVersion &
        ":linux-aarch64:sha256:6b82a3b8c808bf1bcd39a95aced22fc1a026eef08ede410f81e274af8deadbbc"

    tarball url = ActionlintBase & "darwin_amd64.tar.gz",
      sha256 = "f89a910e90e536f60df7c504160247db01dd67cab6f08c064c1c397b76c91a79",
      archiveType = "tar.gz",
      executablePath = "actionlint",
      packageId = "actionlint@" & ActionlintVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:actionlint@" & ActionlintVersion &
        ":macos-x86_64:sha256:f89a910e90e536f60df7c504160247db01dd67cab6f08c064c1c397b76c91a79"

    tarball url = ActionlintBase & "darwin_arm64.tar.gz",
      sha256 = "855e49e823fc68c6371fd6967e359cde11912d8d44fed343283c8e6e943bd789",
      archiveType = "tar.gz",
      executablePath = "actionlint",
      packageId = "actionlint@" & ActionlintVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:actionlint@" & ActionlintVersion &
        ":macos-aarch64:sha256:855e49e823fc68c6371fd6967e359cde11912d8d44fed343283c8e6e943bd789"

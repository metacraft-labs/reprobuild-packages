## shellcheck — the static analyser for shell scripts (koalaman/shellcheck).
##
## Moved here from reprobuild's bundled stdlib
## (`repro_dsl_stdlib/packages/shellcheck.nim`), which declared only a Nix
## realization, so tarball provisioning could not supply it on Windows even
## though upstream publishes a Windows build. A plain `uses: "shellcheck"`
## still reaches this module: the engine looks a name up in this catalog when
## its stdlib does not bundle it.
##
## The release archives are upstream's own for 0.11.0, the version the pinned
## nixpkgs also carries, so both realizations run the same checker:
##
## * Windows x86_64: `shellcheck-v0.11.0.zip`, which holds `shellcheck.exe`,
##   `LICENSE.txt` and `README.txt` at its root. Upstream publishes no Windows
##   arm64 build (see `tools/platform-coverage.tsv`).
## * Linux and macOS, x86_64 and aarch64: `shellcheck-v0.11.0.<os>.<cpu>.tar.xz`,
##   each holding the same three files under `shellcheck-v0.11.0/`, which
##   `stripComponents = 1` removes. The Linux builds are static.
##
## Each SHA-256 below was computed over the downloaded archive and matches the
## digest GitHub's release API reports for the asset (2026-09-30). Upstream
## publishes no checksum file of its own for this release.

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

const
  ShellcheckVersion = "0.11.0"
  ShellcheckBase = "https://github.com/koalaman/shellcheck/releases/download/v" &
    ShellcheckVersion & "/shellcheck-v" & ShellcheckVersion

package shellcheck:
  provisioning:
    nixPackage "nixpkgs#shellcheck", executablePath = "bin/shellcheck",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

    tarball url = ShellcheckBase & ".zip",
      sha256 = "8a4e35ab0b331c85d73567b12f2a444df187f483e5079ceffa6bda1faa2e740e",
      archiveType = "zip",
      executablePath = "shellcheck.exe",
      packageId = "shellcheck@" & ShellcheckVersion,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:shellcheck@" & ShellcheckVersion &
        ":windows-x86_64:sha256:8a4e35ab0b331c85d73567b12f2a444df187f483e5079ceffa6bda1faa2e740e"

    tarball url = ShellcheckBase & ".linux.x86_64.tar.xz",
      sha256 = "8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198",
      archiveType = "tar.xz",
      stripComponents = 1,
      executablePath = "shellcheck",
      packageId = "shellcheck@" & ShellcheckVersion,
      cpu = "x86_64",
      os = "linux",
      lockIdentity = "tarball:shellcheck@" & ShellcheckVersion &
        ":linux-x86_64:sha256:8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198"

    tarball url = ShellcheckBase & ".linux.aarch64.tar.xz",
      sha256 = "12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588",
      archiveType = "tar.xz",
      stripComponents = 1,
      executablePath = "shellcheck",
      packageId = "shellcheck@" & ShellcheckVersion,
      cpu = "aarch64",
      os = "linux",
      lockIdentity = "tarball:shellcheck@" & ShellcheckVersion &
        ":linux-aarch64:sha256:12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588"

    tarball url = ShellcheckBase & ".darwin.x86_64.tar.xz",
      sha256 = "3c89db4edcab7cf1c27bff178882e0f6f27f7afdf54e859fa041fca10febe4c6",
      archiveType = "tar.xz",
      stripComponents = 1,
      executablePath = "shellcheck",
      packageId = "shellcheck@" & ShellcheckVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:shellcheck@" & ShellcheckVersion &
        ":macos-x86_64:sha256:3c89db4edcab7cf1c27bff178882e0f6f27f7afdf54e859fa041fca10febe4c6"

    tarball url = ShellcheckBase & ".darwin.aarch64.tar.xz",
      sha256 = "56affdd8de5527894dca6dc3d7e0a99a873b0f004d7aabc30ae407d3f48b0a79",
      archiveType = "tar.xz",
      stripComponents = 1,
      executablePath = "shellcheck",
      packageId = "shellcheck@" & ShellcheckVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:shellcheck@" & ShellcheckVersion &
        ":macos-aarch64:sha256:56affdd8de5527894dca6dc3d7e0a99a873b0f004d7aabc30ae407d3f48b0a79"

## nixfmt — the official formatter for Nix code (NixOS/nixfmt), in the RFC 166
## style nixpkgs formats with.
##
## Realizations:
##
## * Linux x86_64: upstream's release binary for 1.2.0, a single statically
##   linked x86_64 ELF named `nixfmt` with no archive around it
##   (`archiveType = "raw"`). It is the only binary upstream attaches to a
##   release: there is no aarch64 Linux, macOS or Windows build.
## * Linux and macOS, both architectures: the pinned nixpkgs' `nixfmt`, built
##   by Hydra. The x86_64 Linux release binary above is preferred over it
##   where a host runs tarball provisioning.
## * Windows x86_64: built from source by `packages/source/nixfmt`, from
##   upstream's 1.2.0 tag with a small patch that makes the executable
##   portable (it depends on the POSIX-only `unix` package), against a pinned
##   Hackage closure. Nothing publishes a Windows binary -- not upstream, not
##   nixpkgs (which does not target Windows), not Scoop, MSYS2 or conda-forge
##   (checked 2026-09-30) -- so this interface declares no Windows slice.
##   A dev environment in tarball mode reaches the recipe once reprobuild
##   falls through to a source recipe for a package with no tarball for the
##   host (reprobuild-specs spec/Dependency-Provisioning-In-Build-Graph.md,
##   section 4.3, approved and not yet on `agents`); until then it is reached
##   with `--tool-provisioning=from-source` or a `repro build` of the recipe.
##   The recipe records the patch, the closure and how to refresh both.
## * Windows arm64: nothing. GHC publishes no Windows arm64 build, so the
##   recipe cannot run there either (`tools/platform-coverage.tsv`).
##
## The SHA-256 below was computed over the downloaded file and matches the
## digest GitHub's release API reports for the asset (2026-09-30). The pinned
## nixpkgs carries 1.1.0, a release upstream attached no binary to; 1.2.0 is
## also the version RunQuota's flake dev shell carries.

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

const
  NixfmtVersion = "1.2.0"

package nixfmt:
  provisioning:
    nixPackage "nixpkgs#nixfmt", executablePath = "bin/nixfmt",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

    tarball url = "https://github.com/NixOS/nixfmt/releases/download/v" &
        NixfmtVersion & "/nixfmt",
      sha256 = "aa43e06e2e98d07f9393a8dc73978e0df79bad15d7f84fcd838e15557eb056ee",
      archiveType = "raw",
      executablePath = "nixfmt",
      packageId = "nixfmt@" & NixfmtVersion,
      cpu = "x86_64",
      os = "linux",
      lockIdentity = "tarball:nixfmt@" & NixfmtVersion &
        ":linux-x86_64:sha256:aa43e06e2e98d07f9393a8dc73978e0df79bad15d7f84fcd838e15557eb056ee"

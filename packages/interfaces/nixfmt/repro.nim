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
##
## The SHA-256 below was computed over the downloaded file and matches the
## digest GitHub's release API reports for the asset (2026-09-30). The pinned
## nixpkgs carries 1.1.0, a release upstream attached no binary to; 1.2.0 is
## also the version RunQuota's flake dev shell carries.
##
## ## Windows: no realization, and why
##
## Nothing publishes a Windows nixfmt: not upstream, not nixpkgs (which does
## not target Windows), not Scoop, MSYS2 or conda-forge (checked 2026-09-30).
##
## Building it from source for Windows is not just a missing recipe. The
## `nixfmt` library is portable Haskell, but the `nixfmt` EXECUTABLE depends on
## the `unix` package (`build-depends: unix` in `nixfmt.cabal`): `main/Main.hs`
## imports `System.Posix.Process` and `System.Posix.Signals` for its Ctrl-C
## handler, and `main/System/IO/Atomic.hs` imports `System.Posix.Files` to
## carry a file's mode and owner across its atomic rewrite. `unix` declares
## itself unbuildable on Windows (`if os(windows) buildable: False` in
## `unix.cabal`), so cabal cannot produce the executable there as upstream
## wrote it. A Windows build therefore needs two things this catalog does not
## have: a patch to upstream's executable that replaces those three POSIX uses,
## and a way to pin a Hackage dependency closure for an offline cabal build
## (the cargo, npm and Go shapes each have one; Haskell has none yet). The gap
## is recorded in `tools/platform-coverage.tsv`.

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

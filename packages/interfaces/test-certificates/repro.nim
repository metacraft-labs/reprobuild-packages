## test-certificates — the reference helper tool of the test-certificate
## standard (metacraft-labs/test-certificates-tools): the local certificate
## store (`store-root`, `put`, `find`, `prune`), its git-notes carrier
## (`notes publish|import|push|fetch`) and a `pre-push` hook body
## (`hook pre-push`), as one statically self-contained Nim executable with no
## dependency beyond the Nim standard library.
##
## A project whose `pre-push` dispatcher calls `test-certificates hook
## pre-push "$@"`, or whose test framework pipes certificates into
## `test-certificates put -`, declares `uses: "test-certificates"`.
##
## ## Realizations
##
## * Linux and macOS: the tool's own flake, `packages.default`, at a pinned
##   revision of the public repository. The flake builds the executable from
##   source with nixpkgs' Nim; nothing else is fetched.
##
## Release archives (`test-certificates-<version>-<os>-<arch>.tar.gz` /
## `.zip`, published by the repository's release workflow on a `v<version>`
## tag) are not pinned yet: no release has been published. When 0.1.0 is,
## add one `tarball` channel per asset (Linux x86_64, macOS aarch64, Windows
## x86_64), with the SHA-256 from the release's signed checksum manifest, and
## move the flake revision to the tagged commit.
##
## The revision below is the commit that landed `hook pre-push`
## (2026-10-29), ahead of the first release.

import repro_project_dsl

package `test-certificates`:
  provisioning:
    # The selector must be one string literal (the macro derives the lock
    # identity from it), so the revision is written out here.
    nixPackage "github:metacraft-labs/test-certificates-tools/9b279dbf6f551b798f54aaab5653a0377594db6b#default",
      executablePath = "bin/test-certificates"

  executable `test-certificates`:
    discard

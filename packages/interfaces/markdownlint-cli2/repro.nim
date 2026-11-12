## markdownlint-cli2 — the Markdown linter's command-line front end
## (DavidAnson/markdownlint-cli2).
##
## Realizations:
##
## * Every platform: upstream's npm package, 0.21.0, with its runtime
##   dependency closure, run by `node`. This is how Windows gets it, and it
##   is what a Linux or macOS host running tarball provisioning gets too.
## * Linux and macOS, both architectures: the pinned nixpkgs'
##   `markdownlint-cli2`.
##
## ## The npm realization
##
## Upstream publishes markdownlint-cli2 only as an npm package. It is not a
## bundle: `markdownlint-cli2-bin.mjs` imports `markdownlint`, `globby`,
## `micromatch` and the rest from `node_modules`. So the realization is the
## registry archive plus `closures/markdownlint-cli2.manifest`, the 84
## archives `npm install --omit=dev` puts under `node_modules`, each pinned
## by URL and SHA-256. Realize unpacks them beside the package exactly where
## npm would. Nothing resolves a version range, and no member declares an
## install script.
##
## ## Why the lock is committed here
##
## Upstream commits no lock file: its `.npmrc` sets `package-lock=false`, and
## `package.json` pins only the direct dependencies. So
## `closures/markdownlint-cli2.package-lock.json` is generated here, from the
## `package.json` inside the 0.21.0 registry archive with its
## `devDependencies` and `scripts` removed, resolved as of the release:
##
##     npm install --package-lock-only --ignore-scripts \
##       --before=2026-02-15T23:17:04.216Z
##
## The timestamp is the registry's publish time for 0.21.0, so the tree is
## the one an install on release day resolved, and regenerating it gives the
## same lock. The manifest is GENERATED from that lock by
## `tools/npm_closure_manifest.nim`, which checks every archive against the
## lock's sha512 `integrity` before it records the sha256. Refresh both with
## the version: regenerate the lock the same way from the new `package.json`
## and publish time, then
##
##     nim r tools/npm_closure_manifest.nim \
##       --lock=packages/interfaces/markdownlint-cli2/closures/markdownlint-cli2.package-lock.json \
##       --expect=markdownlint-cli2@<ver> \
##       --lock-source=packages/interfaces/markdownlint-cli2/closures/markdownlint-cli2.package-lock.json \
##       --out=packages/interfaces/markdownlint-cli2/closures/markdownlint-cli2.manifest
##
## The closure is platform-neutral JavaScript (no member carries npm
## `os`/`cpu` constraints), so one arm with no `cpu`/`os` serves every host.
##
## `launcher = "node"` writes `markdownlint-cli2` and `markdownlint-cli2.cmd`
## beside the script, each running `node` on it. The interpreter is resolved
## from the consumer's PATH, so a project that uses markdownlint-cli2 through
## this realization declares `node` too. 0.21.0 needs node >= 20, and the
## stdlib `node` is 24.
##
## The root archive's SHA-256 was computed over the downloaded file, whose
## sha512 matches the `integrity` the npm registry publishes for 0.21.0
## (2026-11-12).

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

const
  MarkdownlintCli2Version = "0.21.0"
  MarkdownlintCli2Sha256 =
    "3ff893617ece08d5fffea2451d758cfad7cee1b96e64d5d4585e06ffb97091c3"

package `markdownlint-cli2`:
  provisioning:
    nixPackage "nixpkgs#markdownlint-cli2",
      executablePath = "bin/markdownlint-cli2",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

    tarball url = "https://registry.npmjs.org/markdownlint-cli2/-/markdownlint-cli2-" &
        MarkdownlintCli2Version & ".tgz",
      sha256 = MarkdownlintCli2Sha256,
      archiveType = "tar.gz",
      stripComponents = 1,
      executablePath = "markdownlint-cli2-bin.mjs",
      executableAlias = "markdownlint-cli2",
      launcher = "node",
      closureManifest = "closures/markdownlint-cli2.manifest",
      packageId = "markdownlint-cli2@" & MarkdownlintCli2Version,
      lockIdentity = "tarball:markdownlint-cli2@" & MarkdownlintCli2Version &
        ":sha256:" & MarkdownlintCli2Sha256

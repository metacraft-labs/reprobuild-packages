## repomix — packs a repository into a single AI-friendly file
## (yamadashy/repomix).
##
## Realizations:
##
## * Every platform: upstream's npm package, 1.18.1, with its runtime
##   dependency closure, run by `node`. This is how Windows gets repomix, and
##   it is what a Linux or macOS host running tarball provisioning gets too.
## * Linux and macOS, both architectures: the pinned nixpkgs' `repomix`.
##
## ## The npm realization
##
## Upstream publishes repomix only as an npm package (its GitHub releases
## carry no assets), and that package is not a bundle: `bin/repomix.cjs`
## runs the TypeScript compiler's output in `lib/`, which loads 28 direct
## dependencies from `node_modules`, starts worker scripts by path
## (`lib/shared/processConcurrency.js`) and loads tree-sitter grammars from
## `.wasm` files by path. So the realization is the registry archive plus
## `closures/repomix.manifest`: the 170 archives `npm install --omit=dev`
## would put under `node_modules`, each pinned by URL and SHA-256, which
## realize unpacks into the prefix beside `bin/` and `lib/` exactly where npm
## would. Nothing resolves a version range and nothing runs an install
## script (none of the 170 declares one).
##
## The manifest is GENERATED from the `package-lock.json` upstream committed
## at the `v1.18.1` tag (commit 80b4280a), whose root entry is
## `repomix@1.18.1` with the same `dependencies` as the published
## `package.json`. `tools/npm_closure_manifest.nim` walks it the way npm
## resolves a `require`, checks every archive against the lock's sha512
## `integrity`, and records its sha256. Refresh it with the version:
##
##     curl -fsSLo /tmp/repomix-lock.json \
##       https://raw.githubusercontent.com/yamadashy/repomix/v<ver>/package-lock.json
##     nim r tools/npm_closure_manifest.nim --lock=/tmp/repomix-lock.json \
##       --expect=repomix@<ver> \
##       --lock-source=https://raw.githubusercontent.com/yamadashy/repomix/v<ver>/package-lock.json \
##       --out=packages/interfaces/repomix/closures/repomix.manifest
##
## The closure is platform-neutral JavaScript and WebAssembly (the tool
## refuses to write a neutral manifest if any member carries npm `os`/`cpu`
## constraints), so one arm with no `cpu`/`os` serves every host.
##
## `launcher = "node"` writes `bin/repomix` and `bin/repomix.cmd` beside the
## script, each running `node` on it. The interpreter is resolved from the
## consumer's PATH, so a project that uses repomix through this realization
## declares `node` too; repomix 1.18.1 needs node >= 22, and the stdlib
## `node` is 24.
##
## The root archive's SHA-256 was computed over the downloaded file, whose
## sha512 matches the `integrity` the npm registry publishes for 1.18.1
## (2026-10-01).

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

const
  RepomixVersion = "1.18.1"
  RepomixSha256 =
    "d4d278310b33f245d4abbc7f757cc3815ff362f6d69225692f837c7dcee83c8f"

package repomix:
  provisioning:
    nixPackage "nixpkgs#repomix", executablePath = "bin/repomix",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

    tarball url = "https://registry.npmjs.org/repomix/-/repomix-" &
        RepomixVersion & ".tgz",
      sha256 = RepomixSha256,
      archiveType = "tar.gz",
      stripComponents = 1,
      executablePath = "bin/repomix.cjs",
      executableAlias = "repomix",
      launcher = "node",
      closureManifest = "closures/repomix.manifest",
      packageId = "repomix@" & RepomixVersion,
      lockIdentity = "tarball:repomix@" & RepomixVersion & ":sha256:" &
        RepomixSha256

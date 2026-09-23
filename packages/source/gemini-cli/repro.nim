## `gemini-cli` from source — the catalog's first from-source npm agent.
##
## Google's Gemini CLI is a source-available (Apache-2.0) npm workspace
## monorepo. This recipe builds it from its own tree through the
## `from-source-npm` convention: fetch the tagged source, materialise its
## committed build closure into an offline `file:` mirror, `npm ci --offline`,
## run upstream's own `bundle` script, and install a node launcher.
##
## ## What the version pins
##
## 0.59.0 — the same version the agent catalog's vendor realization repacks
## from the npm registry, so a consumer that selects either path gets the
## same `gemini --version`. The source is GitHub's tag tarball rather than the
## npm bundle, because from-source means building the bundle, not repacking
## the published one.
##
## ## The dependency closure
##
## `npm-build-closure.manifest` beside this file pins every archive of the
## whole `npm ci` install — dev tools (esbuild, tsc) and every workspace's
## dependencies — by URL and SHA-256, generated from the corrected lock
## described below (NOT upstream's, which is not installable offline) by
## `reprobuild-llm-agent-packages/tools/npm_closure_manifest.nim
## --build-closure`. It is committed rather than derived at build time because
## the closure has to be readable at graph-emission time, and upstream's
## lockfile arrives inside the fetched source the fetch action has not run
## yet — the same reason `cargo-vendor.manifest` is committed.
##
## ## Why a corrected lock is committed too
##
## Upstream's `package-lock.json` at v0.59.0 is not installable as written,
## so `npm-build-closure.package-lock.json` beside this file replaces it
## before the offline rewrite (see `NpmBuildClosureLockName` in
## `repro_project_dsl/npm_vendor`). Two defects, both of which online
## `npm ci` papers over by re-resolving edges from the registry:
##
## * Six workspace edges are stale: the workspaces pin `tar@7.5.8`,
##   `vitest@3.2.4` (twice), `clipboardy@5.2.0` and `typescript@5.8.3`, but
##   the lock nests `7.5.11`, `3.1.1`, `5.2.1` and `5.9.3` under them.
## * One hoisted `ansi-styles` (and its `color-convert`) is shared between
##   the conflicting `overrides` scopes `cliui -> wrap-ansi 7.0.0` and
##   `wrap-ansi -> 9.0.2`; npm revalidates such a node by fetching its
##   packument. `wrap-ansi-cjs` gets its own nested copy instead.
##
## The corrected lock is exactly the tree upstream's own online `npm ci`
## installs (tar 7.5.8 and clipboardy 5.2.0 hoisted, the stale subtrees
## gone), and it passes `npm ci --dry-run --offline` against an EMPTY npm
## cache — i.e. it needs no registry metadata at all. Reproduce it from the
## pristine lock with the pinned npm: drop the stale nested entries,
## `npm install --package-lock-only`, then nest `ansi-styles` and
## `color-convert` under `node_modules/wrap-ansi-cjs`, re-checking with the
## empty-cache offline dry-run after each step.
##
## Refreshing the closure on a version bump is then one command, run
## against the CORRECTED lock:
##
##     nim r ../../reprobuild-llm-agent-packages/tools/npm_closure_manifest.nim \
##       --lock=packages/source/gemini-cli/npm-build-closure.package-lock.json \
##       --out=packages/source/gemini-cli/npm-build-closure.manifest \
##       --build-closure

import repro_project_dsl
import repro_dsl_stdlib/constructors

const
  GeminiVersion = "0.59.0"
  GeminiSourceUrl =
    "https://github.com/google-gemini/gemini-cli/archive/refs/tags/v" &
    GeminiVersion & ".tar.gz"
  GeminiSourceSha256 =
    "6e698510dcae4341f94efe93704447b2fe456062c138f64f95da1c30996d0f33"

package geminiCliSource:
  versions:
    "0.59.0":
      sourceRevision = GeminiVersion
      sourceUrl = GeminiSourceUrl
      sourceRepository = "https://github.com/google-gemini/gemini-cli.git"

  fetch:
    url: GeminiSourceUrl
    sha256: GeminiSourceSha256
    # The GitHub tag tarball's single top-level dir is
    # `gemini-cli-<version>/`; one component of strip lands the tree at `src/`
    # with `package.json` / `package-lock.json` at its root.
    extractStrip: 1

  nativeBuildDeps:
    # `node` is the discriminator the `from-source-npm` convention recognises;
    # `npm` ships inside it. Both are catalog packages, so this recipe pins no
    # runtime of its own.
    "node >=20"
    "npm >=10"

  config:
    discard

  executable gemini:
    discard

  build:
    setCurrentOwningPackageOverride("geminiCliSource")
    try:
      # Upstream's `bundle` script produces `bundle/gemini.js`; the installed
      # `gemini` launcher runs that under node.
      let pkg = node_package(bundleScript = "bundle",
                             entry = "bundle/gemini.js")
      discard pkg.executable("gemini")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    "node >=20"

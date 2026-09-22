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
## `npm-build-closure.manifest` beside this file pins all 1356 archives of the
## whole `npm ci` install — dev tools (esbuild, tsc) and every workspace's
## dependencies — by URL and SHA-256, generated from upstream's own
## `package-lock.json` by
## `reprobuild-llm-agent-packages/tools/npm_closure_manifest.nim
## --build-closure`. It is committed rather than derived at build time because
## the closure has to be readable at graph-emission time, and the lockfile it
## comes from arrives inside the fetched source the fetch action has not run
## yet — the same reason `cargo-vendor.manifest` is committed.
##
## Refreshing it on a version bump is one command:
##
##     nim r ../../reprobuild-llm-agent-packages/tools/npm_closure_manifest.nim \
##       --lock=<extracted>/package-lock.json \
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

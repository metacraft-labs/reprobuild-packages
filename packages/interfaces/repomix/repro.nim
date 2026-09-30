## repomix — packs a repository into a single AI-friendly file
## (yamadashy/repomix).
##
## Realized by the pinned nixpkgs' `repomix` on Linux and macOS, both
## architectures.
##
## ## Windows: no realization, and why
##
## Upstream publishes repomix only as an npm package (GitHub releases carry no
## assets), and that package is not self-contained: its `bin/repomix.cjs` runs
## the TypeScript compiler's output in `lib/`, which `require`s 26 runtime
## dependencies from `node_modules` -- among them tree-sitter grammars and a
## tokenizer shipped as WebAssembly files that repomix loads by path, and
## worker scripts it starts by path. So the two npm shapes this catalog has do
## not fit:
##
## * the registry tarball with `launcher = "node"` (how the agent catalog
##   realizes gemini-cli) works only for a package that is already a bundle
##   with no dependencies;
## * a from-source build through the `from-source-npm` convention installs
##   only the directory that holds the bundle's entry point
##   (`node_package` in reprobuild's stdlib), never `node_modules`, so the
##   built `lib/` would start and then fail on its first `require`.
##
## A Windows realization needs `node_package` to be able to install a
## package's production `node_modules` beside its entry point, and then a
## `packages/source/repomix` recipe with a committed build closure. The gap is
## recorded in `tools/platform-coverage.tsv`.

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

package repomix:
  provisioning:
    nixPackage "nixpkgs#repomix", executablePath = "bin/repomix",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

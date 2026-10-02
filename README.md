# reprobuild-packages

Reusable package interfaces and build-from-source recipes for reprobuild.

Each package is independently addressable under `packages/source/<selector>`.
For example:

```console
repro build packages/source/bash
repro build packages/source/curl
```

The directory selector is the public package name. Source recipes use a
private `<name>Source` package identity so they can coexist with the module
that owns the public interface. The from-source resolver maps the public
selector to the recipe directory and its exported artifacts.

Public interface modules live under `packages/interfaces`. Alternative
realization catalogs can contribute Nix, Scoop, or tarball provisioning only
when they target the public interface fingerprint; they do not redefine the
package. Interfaces already owned by reprobuild's standard library are
imported from there instead of being duplicated here.

Set `REPROBUILD_SRC` when the sibling `reprobuild` checkout is not available at
`../reprobuild`.

Run `nim c -r tools/package_interface_fingerprints.nim` to print the canonical
interface pins used by external provisioning catalogs.

## Consumers and how they reach the catalog

A `uses:` name reprobuild's stdlib does not bundle is looked up here, as
`packages/interfaces/<name>/repro.nim`, in `$REPROBUILD_PACKAGES_ROOT`, in a
`reprobuild-packages` checkout beside the consuming project or any directory
above it, or beside the reprobuild checkout. A package that moved here from
the stdlib (today `sqlite3`) is a compile error when none of those defines it,
and the error lists every place it looked.

So a repository that uses one of these packages must say how its CI provides
the catalog: a `reprobuild-packages` entry in its `.github/sibling-repos`
(cloned beside the checkout by `setup-dev-env`), or `REPROBUILD_PACKAGES_ROOT`
exported from the Nix dev shell that compiles the recipe, from a flake input.
`just audit-consumers` (or `repro run audit-consumers`) scans the workspace
beside this checkout, lists every consumer with the lines that use the
catalog, and fails when one declares neither. Run it whenever a package moves
here. The decision is recorded in reprobuild-specs
`Provisioning-Contributions.md`, "Catalog Lookup And Provisioning".

## Platform coverage

`just coverage` prints, for every package a cross-platform dev environment
provisions from this catalog and reprobuild's standard library, what the
catalog can do on each of six platforms. It exists to separate the two very
different reasons a cell can be empty:

- `upstream-none` — upstream publishes no asset for that platform, so there
  is nothing to realize until upstream ships one;
- `not-pinned` — upstream publishes one and nobody has pinned it. Work, and
  the reason says what the asset is.

A cell can also read `source`: no binary exists for that platform, and the
package is built from its recipe under `packages/source/` instead (nixfmt on
Windows). Those cells are listed in `SourceRealized` in
`tools/dev_env_platform_coverage.nim` only once the recipe has been built and
run there, because a recipe does not say which hosts it builds on.

The tool never decides which a gap is. Every gap has to be declared in
`tools/platform-coverage.tsv` with its state and a reason, and an undeclared
gap is `UNCLASSIFIED`. `just coverage-check` fails on exactly that, and on a
declaration for a cell the catalog has since covered. So the gate does not
forbid gaps; it forbids unexamined ones.

## Pinned dependency closures

A realization that needs more than one archive commits the extra archives as
a generated manifest, each by URL and SHA-256, so nothing resolves a version
range or reaches the network unpinned at build time. The generators:

| Tool | Writes | From |
| --- | --- | --- |
| `tools/cargo_vendor_manifest.nim` | `cargo-vendor.manifest` (from-source Rust) | a `Cargo.lock` |
| `tools/npm_closure_manifest.nim` | an npm tarball realization's `closureManifest` (repomix) | a `package-lock.json`; every archive is checked against the lock's sha512 `integrity` |
| `tools/hackage_closure_manifest.nim` | `hackage-vendor.manifest` (from-source Haskell, nixfmt) | the `plan.json` of a cabal plan solved at a pinned Hackage index state; every tarball and revised `.cabal` is checked against the plan's digests |

Each tool's header has its usage; each consuming recipe's header has the
exact command that refreshes its manifest.

## Contributor Checks

Run `repro lint` to validate the source catalog layout, package identity
policy, and test inventory. Run `repro test` for the recipe regression tests
and the catalog/inventory/graph checks. Each recipe test has its own compiled
binary and execution edge; the root graph does not import the recipe modules.

| Command | Scope |
| --- | --- |
| `repro build test-pcre2-source` | Compile and run the PCRE2 recipe regressions |
| `repro build test-bash-source test-gettext-source` | Run two selected recipe suites |
| `repro build build-test-pcre2-source` | Build the PCRE2 test binary without running it |
| `repro build test-source-recipes` | Run all recipe registry/graph tests |
| `repro build test-catalog test-source-inventory test-source-graph` | Run the lightweight catalog and graph checks |
| `repro build test-source-integration` | Run the real kernel configuration gate on x86-64 Linux |
| `repro run refresh-source-tests` | Update the tracked test inventory after adding or removing tests |
| `repro build test-tier-realizations` | Check that each pinned CLI tool's from-source recipe and its canonical release-archive interface publish the same command at the same version |
| `repro build test-platform-coverage` | Check that every (package, platform) cell is either realized or declared |
| `repro build test-consumer-audit` | Run the consumer audit's regression tests |

Source tests live beside their recipe as `packages/source/<selector>/test_*.nim`;
shared source tests may live directly under `packages/source`. The generated
`source_tests.nim` is a sorted list of paths, not an aggregate import. Lint
rejects an inventory that no longer matches the source tree.

Python checks require Python 3.10 or newer. Recipe tests also declare Nim 2.2
or newer (before 3.0), GCC, and any subprocess tools used by the test. Compiler
actions track imported modules and use separate scratch directories. Test
execution deliberately reruns; an unchanged compiled test binary can be reused.
These tests inspect recipe contracts, not the success of a complete source build.

The separate kernel integration gate executes real Kconfig tools and can download
the kernel archive. It checks the resolved configuration, not just requested
symbols. Checking a built kernel's packaged configuration additionally requires
that artifact to be present; its absence is reported as a skip. This gate does
not replace compiling and booting the kernel.

The pre-commit and pre-push hooks run `repro lint`. In an already provisioned
developer environment, `--tool-provisioning=path` uses its installed tools.

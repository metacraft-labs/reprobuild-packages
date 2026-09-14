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

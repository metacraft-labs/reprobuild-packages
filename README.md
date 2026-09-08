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

Run `repro lint` to validate the source catalog layout and package identity
policy. Run `repro test` for the catalog checker's regression tests. These
are build graph collections, also addressable as `repro build check-catalog`
and `repro build test-catalog`, without importing every package recipe.
Both commands require Python 3.10 or newer through the declared tool dependency.
The checks deliberately rerun, including when recipes are added or removed.

The pre-commit and pre-push hooks run `repro lint`. In an already provisioned
developer environment, `--tool-provisioning=path` uses its installed tools.

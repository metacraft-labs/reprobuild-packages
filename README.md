# reprobuild-packages

Reusable package interfaces and build-from-source recipes for reprobuild.

Each package is independently addressable under `packages/source/<selector>`.
For example:

```console
repro build packages/source/bash
repro build packages/source/curl
```

The package declaration owns the public interface. Alternative realization
catalogs can contribute Nix, Scoop, or tarball provisioning only when they
target that interface fingerprint; they do not redefine the package.

Set `REPROBUILD_SRC` when the sibling `reprobuild` checkout is not available at
`../reprobuild`.

Run `nim c -r tools/package_interface_fingerprints.nim` to print the canonical
interface pins used by external provisioning catalogs.

## msys2-root -- a pinned MSYS2 root: the MSYS runtime (`msys-2.0.dll`) and the
## MSYS programs a native-extension build drives (`make`, `sh`, coreutils),
## in MSYS2's own `usr/` layout, assembled from pinned package files.
##
## Why it exists: Ruby's `mkmf` on Windows writes MSYS-form paths into the
## Makefiles it generates, so a native gem is built with MSYS2's own `make`
## and `sh`, which need the MSYS runtime beside them. RubyInstaller looks for
## an MSYS2 installation through `MSYS2_PATH` first, and recognises one by
## `usr/bin/msys-2.0.dll`; a gem-closure step names this prefix there. It is
## never assembled by running `pacman`, and it ships no `pacman`, so nothing
## can install packages while it is in use.
##
## Realization (Windows x86_64): the primary archive is MSYS2's
## `msys2-runtime` package; every other package of the closure is unpacked
## over the same root (closure entries at `.`, which merge and never replace a
## file). The closure is generated, not resolved at build time:
##
##     nim r tools/msys2_root_closure_manifest.nim --db=<msys.db snapshot> \
##       --primary=msys2-runtime --root=make --root=bash --root=coreutils \
##       --out=packages/interfaces/msys2-root/closures/msys2-root.manifest
##
## The manifest header records the database snapshot's SHA-256; every digest
## is the one the database records for that package file. The pacman metadata
## each package carries at its top level (`.PKGINFO`, `.BUILDINFO`, `.MTREE`,
## `.INSTALL`) describes the package, not the root: the closure's entries do
## not place it, and the primary archive's copy is pruned here.
##
## `make-4.4.1-3` (sha256 af0bdba1...) is the build checked by hand against a
## download; MSYS2 keeps superseded package files on `repo.msys2.org`, so the
## pinned URLs stay fetchable after a rebuild.

import repro_project_dsl

const Msys2RuntimeVersion* = "3.6.12-1"

package `msys2-root`:
  provisioning:
    tarball url = "https://repo.msys2.org/msys/x86_64/msys2-runtime-" &
        Msys2RuntimeVersion & "-x86_64.pkg.tar.zst",
      sha256 = "c0dbaa624e29be6d08cf5c65609dca6c749431109e4572bf446a3ca9b4c4fd7c",
      archiveType = "tar.zst",
      closureManifest = "closures/msys2-root.manifest",
      prune = ".PKGINFO",
      prune = ".BUILDINFO",
      prune = ".MTREE",
      prune = ".INSTALL",
      executablePath = "usr/bin/make.exe",
      extraExecutable = "usr/bin/sh.exe",
      version = "3.6.12",
      packageId = "msys2-root@" & Msys2RuntimeVersion,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:msys2-root@" & Msys2RuntimeVersion &
        ":windows-x86_64:sha256:c0dbaa624e29be6d08cf5c65609dca6c749431109e4572bf446a3ca9b4c4fd7c"

## libyaml-dev -- libyaml's development channel: `yaml.h`, the static
## `libyaml.a` and `yaml-0.1.pc`.
##
## What Ruby's `psych` extension is compiled against on Windows
## (`--with-libyaml-dir`), at the version the Nix side uses, 0.2.5.
##
## Realization (Windows x86_64): MSYS2's UCRT64 package, pruned to the
## headers, the static archive and the `pkg-config` file -- the
## arrangement of reprobuild's `zstd-dev`: `bin` (the DLL and programs) and
## the import library are pruned, so that `-lyaml` can only bind the static
## archive and nothing built against it needs a DLL of this library at run
## time. The `.pc` file says `prefix=/ucrt64`, which pkgconf on Windows
## relocates from the file's own location. MSYS2 keeps superseded package
## files on `repo.msys2.org`, so the pinned URL stays fetchable after a
## rebuild.
##
## Why an archive and not a source recipe: a provisioned prefix BUILT
## against this library (a Ruby SDK whose native gems a post-extraction step
## compiles) is shared through the binary cache only when every input has a
## complete, content-keyed identity. An archive arm has one; a library built
## by a source recipe does not yet.

import repro_project_dsl

const LibyamlDevMsys2Version* = "0.2.5-2"
  ## MSYS2's `pkgver-pkgrel`; the record's `version` is the library's own.

package `libyaml-dev`:
  provisioning:
    tarball url = "https://repo.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-libyaml-" &
        LibyamlDevMsys2Version & "-any.pkg.tar.zst",
      sha256 = "bf4c28a3a92a46db3c809b0789aef731ae9a0c4283db368c7e8624550fed07f3",
      archiveType = "tar.zst",
      stripComponents = 1,
      prune = "bin",
      prune = "lib/libyaml.dll.a",
      prune = "share",
      executablePath = "include/yaml.h",
      version = "0.2.5",
      packageId = "libyaml-dev@" & LibyamlDevMsys2Version,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:libyaml-dev@" & LibyamlDevMsys2Version &
        ":windows-x86_64:sha256:bf4c28a3a92a46db3c809b0789aef731ae9a0c4283db368c7e8624550fed07f3"

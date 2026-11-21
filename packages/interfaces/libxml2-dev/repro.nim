## libxml2-dev -- libxml2's development channel: its headers under
## `include/libxml2/`, the static `libxml2.a` and `libxml-2.0.pc`.
##
## The library nokogiri is compiled against on Windows (`--use-system-libraries`),
## at the version the Nix side builds it against, 2.15.1, so that both
## platforms build nokogiri against the same libxml2. Its `.pc` file names
## `-DLIBXML_STATIC` and `-liconv -lbcrypt` / `zlib` as private flags, which a
## static link needs (`pkg-config --static`).
##
## Realization (Windows x86_64): MSYS2's UCRT64 package, pruned to the
## headers, the static archive and the `pkg-config` file -- the
## arrangement of reprobuild's `zstd-dev`: `bin` (the DLL and programs) and
## the import library are pruned, so that `-lxml2` can only bind the static
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

const Libxml2DevMsys2Version* = "2.15.1-4"
  ## MSYS2's `pkgver-pkgrel`; the record's `version` is the library's own.

package `libxml2-dev`:
  provisioning:
    tarball url = "https://repo.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-libxml2-" &
        Libxml2DevMsys2Version & "-any.pkg.tar.zst",
      sha256 = "71c112edab49a19292abdd5ba65f56c4f2dac27d0ef85e6df708b697219061a9",
      archiveType = "tar.zst",
      stripComponents = 1,
      prune = "bin",
      prune = "lib/libxml2.dll.a",
      prune = "lib/cmake",
      prune = "lib/python3.14",
      prune = "share",
      executablePath = "include/libxml2/libxml/parser.h",
      version = "2.15.1",
      packageId = "libxml2-dev@" & Libxml2DevMsys2Version,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:libxml2-dev@" & Libxml2DevMsys2Version &
        ":windows-x86_64:sha256:71c112edab49a19292abdd5ba65f56c4f2dac27d0ef85e6df708b697219061a9"

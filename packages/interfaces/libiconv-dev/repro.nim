## libiconv-dev -- GNU libiconv's development channel: `iconv.h`, the
## static `libiconv.a` and `libcharset.a`, and `iconv.pc`.
##
## libxml2's static archive needs it at link time (its `.pc` file's
## `Libs.private: -liconv`). 1.19 is the version of reprobuild-packages'
## `libiconv` source recipe.
##
## Realization (Windows x86_64): MSYS2's UCRT64 package, pruned to the
## headers, the static archives and the `pkg-config` file -- the
## arrangement of reprobuild's `zstd-dev`: `bin` (the DLLs and programs) and
## the import libraries are pruned, so that `-liconv` can only bind the static
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

const LibiconvDevMsys2Version* = "1.19-1"
  ## MSYS2's `pkgver-pkgrel`; the record's `version` is the library's own.

package `libiconv-dev`:
  provisioning:
    tarball url = "https://repo.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-libiconv-" &
        LibiconvDevMsys2Version & "-any.pkg.tar.zst",
      sha256 = "9a500f38c2b91808741c62fae746b3e9110b33a1ecf5c30fa0c66dbedddf7e16",
      archiveType = "tar.zst",
      stripComponents = 1,
      prune = "bin",
      prune = "lib/libiconv.dll.a",
      prune = "lib/libcharset.dll.a",
      prune = "share",
      executablePath = "include/iconv.h",
      version = "1.19",
      packageId = "libiconv-dev@" & LibiconvDevMsys2Version,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:libiconv-dev@" & LibiconvDevMsys2Version &
        ":windows-x86_64:sha256:9a500f38c2b91808741c62fae746b3e9110b33a1ecf5c30fa0c66dbedddf7e16"

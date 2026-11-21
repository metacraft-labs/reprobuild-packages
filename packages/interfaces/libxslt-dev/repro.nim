## libxslt-dev -- libxslt's and libexslt's development channel: their
## headers, the static `libxslt.a` and `libexslt.a`, and their `.pc` files.
##
## The second library nokogiri is compiled against on Windows, at the version
## the Nix side builds it against, 1.1.45.
##
## Realization (Windows x86_64): MSYS2's UCRT64 package, pruned to the
## headers, the static archives and the `pkg-config` files -- the
## arrangement of reprobuild's `zstd-dev`: `bin` (the DLLs and programs) and
## the import libraries are pruned, so that `-lxslt` can only bind the static
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

const LibxsltDevMsys2Version* = "1.1.45-1"
  ## MSYS2's `pkgver-pkgrel`; the record's `version` is the library's own.

package `libxslt-dev`:
  provisioning:
    tarball url = "https://repo.msys2.org/mingw/ucrt64/mingw-w64-ucrt-x86_64-libxslt-" &
        LibxsltDevMsys2Version & "-any.pkg.tar.zst",
      sha256 = "20fae8833681bf783b13df4db3bb3811cc0dc69311a8e5e10c26ba150a47826e",
      archiveType = "tar.zst",
      stripComponents = 1,
      prune = "bin",
      prune = "lib/libxslt.dll.a",
      prune = "lib/libexslt.dll.a",
      prune = "lib/cmake",
      prune = "share",
      executablePath = "include/libxslt/xslt.h",
      version = "1.1.45",
      packageId = "libxslt-dev@" & LibxsltDevMsys2Version,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:libxslt-dev@" & LibxsltDevMsys2Version &
        ":windows-x86_64:sha256:20fae8833681bf783b13df4db3bb3811cc0dc69311a8e5e10c26ba150a47826e"

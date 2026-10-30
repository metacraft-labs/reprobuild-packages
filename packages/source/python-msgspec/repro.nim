## msgspec for CPython 3.13 on 32-bit ARM (armv7l, hard-float), from piwheels.
##
## SearXNG declares its settings schema with `msgspec.Struct`, so the module
## must be importable wherever SearXNG runs. msgspec is a C extension, and for
## the Raspberry Pi add-on hosts (Raspberry Pi OS / Debian 13 trixie, `armhf`)
## no distribution package exists: Debian trixie ships `python3-msgspec`
## 0.19.0-2 for amd64, arm64, ppc64el and riscv64 only, Raspbian's trixie
## index has no build at all, and the `armhf` build in the Debian pool
## (0.22.0-2+b1) is sid's. Building the extension from source for that target
## needs the cross C toolchain plumbing the catalog does not have yet
## (reprobuild-pm issue 2026-10-30-cargo-package-cannot-cross-compile-a-workspace-member-for-armv7
## lists the same gap for Rust).
##
## So this realization takes the wheel the Raspberry Pi Foundation builds on
## Raspberry Pi OS for exactly this interpreter and ABI (`cp313-cp313-linux_armv7l`,
## https://www.piwheels.org/project/msgspec/), pinned by URL and SHA-256 and
## verified before it is unpacked. It is a binary realization, not a source
## build, and it is only correct on armv7l hosts running CPython 3.13: the
## module directory it installs contains `_core.cpython-313-arm-linux-gnueabihf.so`.
## A wheel is a zip archive, so the fetch keeps the file whole (`dataFile`)
## and the build unpacks it with the interpreter's own `zipfile` module.
##
## 0.21.1 is the version SearXNG pins in its `requirements.txt` at the
## revision `packages/source/searxng` builds.

import repro_project_dsl

package pythonMsgspecSource:
  versions:
    "0.21.1":
      sourceRevision = "0.21.1"
      sourceUrl = "https://www.piwheels.org/simple/msgspec/msgspec-0.21.1-cp313-cp313-linux_armv7l.whl"
      sourceRepository = "https://github.com/jcrist/msgspec"

  fetch:
    url: "https://www.piwheels.org/simple/msgspec/msgspec-0.21.1-cp313-cp313-linux_armv7l.whl"
    sha256: "b94c31c83b4d12951b84506a017d4ac63b97d7a06bbb92cf10b823415634a033"
    dataFile: true

  nativeBuildDeps:
    # Unpacks the wheel; the module itself is not imported here, because the
    # build host is usually not the armv7l host the extension is for.
    "python3 >=3.10"

  executable `python-msgspec`:
    build:
      shell "mkdir -p $out/bin $out/share/python-modules"
      shell "python3 -m zipfile -e $extracted/source $out/share/python-modules"
      shell "test -f $out/share/python-modules/msgspec/_core.cpython-313-arm-linux-gnueabihf.so"
      shell "printf '#!/bin/sh\nMODULE_ROOT=$(CDPATH= cd -- \"$(dirname -- \"$0\")/../share/python-modules\" && pwd)\necho \"$MODULE_ROOT\"\n' > $out/bin/python-msgspec"
      shell "chmod +x $out/bin/python-msgspec"

  runtimeDeps:
    discard

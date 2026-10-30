## SearXNG from source: the metasearch engine, as one Python module tree.
##
## SearXNG is pure Python. Its C-extension dependencies (lxml, PyYAML's
## accelerator, ...) and most of its pure-Python ones are distribution
## packages on the hosts it runs on, so they are NOT part of this prefix: a
## consuming system unit binds a `package(apt, ...)` closure of
## `python3 python3-lxml python3-flask python3-flask-babel python3-babel
## python3-httpx python3-h2 python3-socksio python3-python-socks
## python3-async-timeout python3-certifi python3-cloudscraper python3-isodate
## python3-jinja2 python3-markdown-it python3-pygments python3-dateutil
## python3-yaml python3-sniffio python3-typer python3-typing-extensions
## python3-whitenoise` over `/usr` and runs `/usr/bin/python3 -m searx.webapp`
## with this prefix's `lib/python3.13/site-packages` on `PYTHONPATH`
## (reprobuild-pm ReproOS-Add-On-Mode.md §8.3). Verified on a Raspberry Pi 2
## (Raspberry Pi OS trixie armhf) against Debian trixie's packages.
##
## What this prefix holds is what those distributions lack: the `searx`
## package itself (no distribution packages SearXNG), and the three
## `requirements.txt` entries that are not in Debian trixie — `httpx-socks`,
## `valkey` and `msgspec` — copied in from their own recipes. msgspec is a C
## extension for which only an armv7l build is realized
## (`packages/source/python-msgspec` says why), so the assembled prefix is
## for CPython 3.13 on armv7l hosts; the directory name records the
## interpreter.
##
## ## What the version pins
##
## Upstream has no releases. The commit is the one infra's nixpkgs
## resolves for high-mem-server (`pkgs.searxng.src.rev` = `dce3bb69`,
## 2026-05-16, measured at infra `b468867f`; its running unit's store path
## is `searxng-0-unstable-2026-05-16`), so the add-on host runs the same
## code as the NixOS host it takes the service over from. The build writes `searx/version_frozen.py` with the strings
## nixpkgs writes, because `searx.version` otherwise shells out to `git` at
## import time and this is a tarball. Bump the commit, the date and the
## tarball hash together.

import repro_project_dsl

const
  SearxngCommit = "dce3bb69bb45519bde01c610e09e45cd42fd896c"
  SearxngDate = "2026.05.16"
  SearxngSourceUrl =
    "https://github.com/searxng/searxng/archive/" & SearxngCommit & ".tar.gz"
  SearxngSourceSha256 =
    "bdf08984b48d9e6fd7e3eecf8a272aad7bd4ba911cee34e39b677c0ea1595154"
  SitePackages = "lib/python3.13/site-packages"

package searxngSource:
  versions:
    "2026.05.16":
      sourceRevision = SearxngCommit
      sourceUrl = SearxngSourceUrl
      sourceRepository = "https://github.com/searxng/searxng"

  fetch:
    url: SearxngSourceUrl
    sha256: SearxngSourceSha256
    extractStrip: 1

  nativeBuildDeps:
    # The three requirements no distribution supplies, each a catalog
    # package whose command prints its module root.
    "python-msgspec"
    "python-httpx-socks"
    "python-valkey"

  executable searxng:
    build:
      shell "mkdir -p $out/bin $out/" & SitePackages
      shell "cp -a $extracted/searx $out/" & SitePackages & "/"
      shell "printf '%s\\n' " &
        "'VERSION_STRING=\"" & SearxngDate & "+" & SearxngCommit[0 .. 7] & "\"' " &
        "'VERSION_TAG=\"" & SearxngDate & "+" & SearxngCommit[0 .. 7] & "\"' " &
        "'DOCKER_TAG=\"" & SearxngDate & "-" & SearxngCommit[0 .. 7] & "\"' " &
        "'GIT_URL=\"https://github.com/searxng/searxng\"' " &
        "'GIT_BRANCH=\"master\"' " &
        "> $out/" & SitePackages & "/searx/version_frozen.py"
      shell "for dep in python-msgspec python-httpx-socks python-valkey; do " &
        "root=$($dep); cp -a \"$root\"/. $out/" & SitePackages & "/; done"
      shell "test -f $out/" & SitePackages & "/msgspec/_core.cpython-313-arm-linux-gnueabihf.so"
      # The launcher runs the host's interpreter (inside an add-on unit that
      # is the bound closure's /usr/bin/python3) with this tree first on the
      # path. Arguments pass through to `searx.webapp`.
      shell "printf '#!/bin/sh\\nPREFIX=$(CDPATH= cd -- \"$(dirname -- \"$0\")/..\" && pwd)\\n" &
        "PYTHONPATH=\"$PREFIX/" & SitePackages & "${PYTHONPATH:+:$PYTHONPATH}\" " &
        "exec /usr/bin/python3 -m searx.webapp \"$@\"\\n' > $out/bin/searxng"
      shell "chmod +x $out/bin/searxng"

  runtimeDeps:
    # The runtime is the HOST's: CPython 3.13 and the C-extension packages
    # listed in the header come from the consuming unit's `package(apt)`
    # closure (Debian trixie), not from this catalog, and the prefix is
    # for CPython 3.13 on armv7l only (msgspec's `.so`). Nothing here can
    # name that closure, so the requirement is stated in the header and
    # enforced by the unit that binds the closure (ReproOS-Add-On-Mode §8.3).
    discard

## httpx-socks Python module sourced from the official PyPI release.
##
## SearXNG routes engine requests through SOCKS proxies with this package.
## It is pure Python; the SOCKS protocol layer underneath it (`python-socks`)
## is a separate module that the consuming host supplies. The sdist's module
## directory is copied as-is, without pip.
##
## 0.10.0 is the version SearXNG pins in its `requirements.txt` at the
## revision `packages/source/searxng` builds.

import repro_project_dsl

package pythonHttpxSocksSource:
  versions:
    "0.10.0":
      sourceRevision = "0.10.0"
      sourceUrl = "https://files.pythonhosted.org/packages/26/a4/b93909386d9bfc9d43fbb4a35bc33936ff5e6952d03aba8958af3b7dfada/httpx_socks-0.10.0.tar.gz"
      sourceRepository = "https://github.com/romis2012/httpx-socks"

  fetch:
    url: "https://files.pythonhosted.org/packages/26/a4/b93909386d9bfc9d43fbb4a35bc33936ff5e6952d03aba8958af3b7dfada/httpx_socks-0.10.0.tar.gz"
    sha256: "e232e31174de79cc79ca7174bbc159aabb4b95e0ff5cc2d894d33f6cbe1a1096"
    extractStrip: 1

  nativeBuildDeps:
    discard

  executable `python-httpx-socks`:
    build:
      shell "mkdir -p $out/bin $out/share/python-modules"
      shell "cp -a $extracted/httpx_socks $out/share/python-modules/"
      shell "printf '#!/bin/sh\nMODULE_ROOT=$(CDPATH= cd -- \"$(dirname -- \"$0\")/../share/python-modules\" && pwd)\necho \"$MODULE_ROOT\"\n' > $out/bin/python-httpx-socks"
      shell "chmod +x $out/bin/python-httpx-socks"

  runtimeDeps:
    discard

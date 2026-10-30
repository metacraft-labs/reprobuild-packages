## valkey Python client sourced from the official PyPI release.
##
## SearXNG's shared cache and bot-detection limiter talk to a Valkey server
## through this client. It is pure Python (it imports `async_timeout`, which
## the consuming host supplies). The sdist's module directory is copied
## as-is, without pip.
##
## 6.1.1 is the version SearXNG pins in its `requirements.txt` at the
## revision `packages/source/searxng` builds.

import repro_project_dsl

package pythonValkeySource:
  versions:
    "6.1.1":
      sourceRevision = "6.1.1"
      sourceUrl = "https://files.pythonhosted.org/packages/c3/ee/7fd930fc712275084722ddd464a0ea296abdb997d2da396320507968daeb/valkey-6.1.1.tar.gz"
      sourceRepository = "https://github.com/valkey-io/valkey-py"

  fetch:
    url: "https://files.pythonhosted.org/packages/c3/ee/7fd930fc712275084722ddd464a0ea296abdb997d2da396320507968daeb/valkey-6.1.1.tar.gz"
    sha256: "5880792990c6c2b5eb604a5ed5f98f300880b6dd92d123819b66ed54bb259731"
    extractStrip: 1

  nativeBuildDeps:
    discard

  executable `python-valkey`:
    build:
      shell "mkdir -p $out/bin $out/share/python-modules"
      shell "cp -a $extracted/valkey $out/share/python-modules/"
      shell "printf '#!/bin/sh\nMODULE_ROOT=$(CDPATH= cd -- \"$(dirname -- \"$0\")/../share/python-modules\" && pwd)\necho \"$MODULE_ROOT\"\n' > $out/bin/python-valkey"
      shell "chmod +x $out/bin/python-valkey"

  runtimeDeps:
    discard

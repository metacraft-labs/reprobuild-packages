## Meson 1.6.1 built from its upstream source tarball.
##
## Meson is a pure-Python build tool. Installation copies the upstream
## ``mesonbuild`` package into the output and writes a relocatable launcher;
## no native compiler or Python packaging frontend is required.

import repro_project_dsl
import repro_dsl_stdlib/types
import repro_dsl_stdlib/packages/system_tools

package mesonSource:
  versions:
    "1.6.1":
      sourceRevision = "1.6.1"
      sourceUrl = "https://github.com/mesonbuild/meson/releases/download/1.6.1/meson-1.6.1.tar.gz"
      sourceRepository = "https://github.com/mesonbuild/meson"

  fetch:
    url: "https://github.com/mesonbuild/meson/releases/download/1.6.1/meson-1.6.1.tar.gz"
    sha256: "1eca49eb6c26d58bbee67fd3337d8ef557c0804e30a6d16bfdf269db997464de"
    extractStrip: 1

  nativeBuildDeps:
    "python3 >=3.8"

  executable meson:
    build:
      shell "mkdir -p $out/share/meson $out/bin"
      shell "cp -r $extracted/mesonbuild $out/share/meson/"
      shell "printf '#!/bin/sh\\nMESON_ROOT=$(CDPATH= cd -- \"$(dirname -- \"$0\")/../share/meson\" && pwd)\\nPYTHONPATH=\"$MESON_ROOT${PYTHONPATH:+:$PYTHONPATH}\" exec python3 -m mesonbuild.mesonmain \"$@\"\\n' > $out/bin/meson"
      shell "chmod +x $out/bin/meson"

  runtimeDeps:
    "python3 >=3.8"

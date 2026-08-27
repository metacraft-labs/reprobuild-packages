import std/[strutils, unittest]

import repro_project_dsl
import ./repro

const
  ExpectedUrl =
    "https://github.com/mesonbuild/meson/releases/download/1.6.1/meson-1.6.1.tar.gz"
  ExpectedHash =
    "1eca49eb6c26d58bbee67fd3337d8ef557c0804e30a6d16bfdf269db997464de"

suite "mesonSource recipe":
  test "source metadata is pinned":
    let spec = registeredFetchSpec("mesonSource")
    check spec.packageName == "mesonSource"
    check spec.url == ExpectedUrl
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

    let versions = registeredVersions("mesonSource")
    check versions.len == 1
    check versions[0].version == "1.6.1"
    check versions[0].sourceRevision == "1.6.1"
    check versions[0].sourceUrl == ExpectedUrl
    check versions[0].sourceRepository ==
      "https://github.com/mesonbuild/meson"

  test "Python is available while building and running Meson":
    check registeredNativeBuildDeps("mesonSource") == @["python3 >=3.8"]
    check registeredRuntimeDeps("mesonSource") == @["python3 >=3.8"]

  test "the package exports one Meson executable":
    let artifacts = registeredArtifacts("mesonSource")
    check artifacts.len == 1
    check artifacts[0].packageName == "mesonSource"
    check artifacts[0].artifactName == "meson"
    check artifacts[0].kind == dakExecutable

  test "install actions copy the Python package and write a launcher":
    let rows = registeredShellActions("mesonSource")
    check rows.len == 4
    for index, row in rows:
      check row.packageName == "mesonSource"
      check row.artifactName == "meson"
      check row.id == "mesonSource-meson-" & $(index + 1)

    check rows[0].command == "mkdir -p $out/share/meson $out/bin"
    check rows[1].command ==
      "cp -r $extracted/mesonbuild $out/share/meson/"
    check rows[2].command.contains("MESON_BIN_DIR=${0%/*}")
    check not rows[2].command.contains("dirname")
    check rows[2].command.contains("PYTHONPATH=")
    check rows[2].command.contains("python3 -m mesonbuild.mesonmain")
    check rows[2].command.endsWith("> $out/bin/meson")
    check rows[3].command == "chmod +x $out/bin/meson"

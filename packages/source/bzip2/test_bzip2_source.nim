import std/unittest

import repro_project_dsl
import ./repro

suite "bzip2 source recipe":
  test "pins the official sourceware release":
    let spec = registeredFetchSpec("bzip2Source")
    check spec.url == "https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz"
    check spec.hashHex ==
      "ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269"
    check spec.extractStrip == 1

  test "publishes the command and shared ABI":
    let artifacts = registeredArtifacts("bzip2Source")
    check artifacts.len == 2
    check artifacts[0].packageName == "bzip2Source"
    check artifacts[0].artifactName == "bzip2"
    check artifacts[0].kind == dakExecutable
    check artifacts[1].artifactName == "libBz2"
    check artifacts[1].kind == dakLibrary

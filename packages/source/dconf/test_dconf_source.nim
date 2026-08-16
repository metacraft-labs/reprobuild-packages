import std/[algorithm, sequtils, strutils, unittest]

import repro_project_dsl

import ./repro

suite "dconfSource source recipe":
  test "pins the verified GNOME release tarball":
    let spec = registeredFetchSpec("dconfSource")
    check spec.url.endsWith("dconf-0.40.0.tar.xz")
    check spec.hashHex ==
      "cf7f22a4c9200421d8d3325c5c1b8b93a36843650c9f95d6451e20f0bcb24533"
    check spec.extractStrip == 1

  test "registers the command, client library, and source dependencies":
    let artifacts = registeredArtifacts("dconfSource")
    check artifacts.mapIt(it.artifactName).sorted() == @["dconf", "libDconf"]
    check "glib2 >=2.44" in registeredBuildDeps("dconfSource")
    check "dbus >=1.12" in registeredBuildDeps("dconfSource")
    check "glib2 >=2.44" in registeredRuntimeDeps("dconfSource")
    check "dbus >=1.12" in registeredRuntimeDeps("dconfSource")

import std/[sequtils, unittest]

import repro_project_dsl
import ./repro

suite "busyboxSource recipe":
  test "pins the canonical BusyBox 1.36.1 release":
    let spec = registeredFetchSpec("busyboxSource")
    check spec.url == "https://busybox.net/downloads/busybox-1.36.1.tar.bz2"
    check spec.hashHex ==
      "b8cc24c9574d809e7279c3be349795c5d5ceb6fdf19ca709f80cde50e47de314"
    check spec.hashAlg == dshaSha256
    check spec.extractStrip == 1

  test "exposes BusyBox and its required hostname applet":
    let artifacts = registeredArtifacts("busyboxSource")
    check artifacts.len == 2
    check artifacts.mapIt(it.artifactName) == @["busybox", "hostname"]
    check artifacts.allIt(it.kind == dakExecutable)

  test "records the upstream version metadata":
    let versions = registeredVersions("busyboxSource")
    check versions.len == 1
    check versions[0].version == "1.36.1"
    check versions[0].sourceRevision == "1_36_1"
    check versions[0].sourceRepository ==
      "https://git.busybox.net/busybox"

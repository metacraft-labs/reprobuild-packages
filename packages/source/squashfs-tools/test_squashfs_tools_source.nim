import std/unittest

import repro_project_dsl

import ./repro

const
  ExpectedUrl = "https://github.com/plougher/squashfs-tools/releases/download/4.7.5/squashfs-tools-4.7.5.tar.gz"
  ExpectedHash =
    "547b7b7f4d2e44bf91b6fc554664850c69563701deab9fd9cd7e21f694c88ea6"

suite "squashfsToolsSource from-source recipe":
  test "fetch metadata pins the upstream release":
    let spec = registeredFetchSpec("squashfsToolsSource")
    check spec.packageName == "squashfsToolsSource"
    check spec.url == ExpectedUrl
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "the package exposes mksquashfs and its compression libraries":
    check registeredBuildDeps("squashfsToolsSource") == @["zlib", "xz"]
    check registeredRuntimeDeps("squashfsToolsSource") == @["zlib", "xz"]
    let artifacts = registeredArtifacts("squashfsToolsSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "mksquashfs"
    check artifacts[0].kind == dakExecutable

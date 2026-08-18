import std/unittest

import repro_project_dsl

import ./repro

const
  ExpectedUrl = "https://ftp.gnu.org/gnu/mtools/mtools-4.0.49.tar.gz"
  ExpectedHash =
    "10cd1111da87bf2400a380c1639a6cba8bfb937a24f9c51f5f88d393ae5f6f76"

suite "mtoolsSource from-source recipe":
  test "fetch metadata pins the upstream release":
    let spec = registeredFetchSpec("mtoolsSource")
    check spec.packageName == "mtoolsSource"
    check spec.url == ExpectedUrl
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "the package exposes its command suite":
    let artifacts = registeredArtifacts("mtoolsSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "mtools"
    check artifacts[0].kind == dakExecutable

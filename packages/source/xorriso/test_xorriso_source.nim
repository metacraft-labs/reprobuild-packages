import std/unittest

import repro_project_dsl

import ./repro

const
  ExpectedUrl =
    "https://ftp.gnu.org/gnu/xorriso/xorriso-1.5.8.pl02.tar.gz"
  ExpectedHash =
    "b1455ecafbf0692ddafe1d71002a96f2ce2d77f4deae602678261ce033f97bc8"

suite "xorrisoSource from-source recipe":
  test "fetch metadata pins the upstream release":
    let spec = registeredFetchSpec("xorrisoSource")
    check spec.packageName == "xorrisoSource"
    check spec.url == ExpectedUrl
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "build and runtime interfaces are registered":
    check "zlib" in registeredBuildDeps("xorrisoSource")
    check "zlib" in registeredRuntimeDeps("xorrisoSource")
    let artifacts = registeredArtifacts("xorrisoSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "xorriso"
    check artifacts[0].kind == dakExecutable

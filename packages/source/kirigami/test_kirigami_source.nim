## Smoke test for the from-source ``kirigami`` recipe (M9.R.15p.3.1).

import std/[unittest]

import repro_project_dsl

import ./repro

const ExpectedUrl =
  "https://download.kde.org/stable/frameworks/6.10/kirigami-6.10.0.tar.xz"

const ExpectedHash =
  "2e245ffd79eca1fcfb591f43ff39e7c2f5160e868a36e20ebbe2d66c550da8d4"

suite "kirigami — from-source recipe smoke test":

  test "fetch spec carries the upstream URL verbatim":
    let spec = registeredFetchSpec("kirigami")
    check spec.url == ExpectedUrl

  test "fetch spec hash is the upstream sha256":
    let spec = registeredFetchSpec("kirigami")
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    let spec = registeredFetchSpec("kirigami")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "artifacts register the seven Kirigami library outputs":
    let arts = registeredArtifacts("kirigami")
    check arts.len == 7
    for a in arts:
      check a.packageName == "kirigami"
      check a.kind == dakLibrary
    let names = block:
      var s: seq[string]
      for a in arts: s.add(a.artifactName)
      s
    check "libKirigamiPlatform" in names
    check "libKirigamiPrimitives" in names
    check "libKirigamiPrivate" in names
    check "libKirigamiDelegates" in names
    check "libKirigamiDialogs" in names
    check "libKirigamiLayouts" in names
    check "libKirigami" in names

  test "versions block records the upstream tag + URL + repository":
    let vs = registeredVersions("kirigami")
    check vs.len == 1
    check vs[0].version == "6.10.0"
    check vs[0].sourceRevision == "v6.10.0"
    check vs[0].sourceUrl ==
      "https://download.kde.org/stable/frameworks/6.10/kirigami-6.10.0.tar.xz"
    check vs[0].sourceRepository ==
      "https://invent.kde.org/frameworks/kirigami"

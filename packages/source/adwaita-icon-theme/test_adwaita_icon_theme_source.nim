## Smoke test for the from-source ``adwaitaIconTheme`` recipe
## (M9.R.15b).

import std/[unittest]

import repro_project_dsl

import ./repro

const ExpectedUrl =
  "https://download.gnome.org/sources/adwaita-icon-theme/50/adwaita-icon-theme-50.0.tar.xz"

const ExpectedHash =
  "fac6e0401fca714780561a081b8f7e27c3bc1db34ebda4da175081f26b24d460"

suite "adwaitaIconTheme — from-source recipe smoke test":

  test "fetch spec carries the upstream URL verbatim":
    let spec = registeredFetchSpec("adwaitaIconTheme")
    check spec.packageName == "adwaitaIconTheme"
    check spec.url == ExpectedUrl

  test "fetch spec hash is a 64-char sha256 hex string":
    let spec = registeredFetchSpec("adwaitaIconTheme")
    check spec.hashHex.len == 64
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    let spec = registeredFetchSpec("adwaitaIconTheme")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "single files artifact iconAssets registered as dakFiles":
    let arts = registeredArtifacts("adwaitaIconTheme")
    check arts.len == 1
    check arts[0].packageName == "adwaitaIconTheme"
    check arts[0].artifactName == "iconAssets"
    check arts[0].kind == dakFiles

  test "versions block records the upstream tag + URL + repository":
    let vs = registeredVersions("adwaitaIconTheme")
    check vs.len == 1
    check vs[0].version == "50.0"
    check vs[0].sourceRevision == "50.0"
    check vs[0].sourceUrl == ExpectedUrl
    check vs[0].sourceRepository ==
      "https://gitlab.gnome.org/GNOME/adwaita-icon-theme"

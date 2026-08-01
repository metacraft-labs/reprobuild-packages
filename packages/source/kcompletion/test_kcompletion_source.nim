## Smoke test for the from-source ``kcompletion`` recipe (M9.R.15h.4).

import std/[unittest]

import repro_project_dsl

import ./repro

const ExpectedUrl =
  "https://download.kde.org/stable/frameworks/6.10/kcompletion-6.10.0.tar.xz"

const ExpectedHash =
  "b56e925bbe881c89fce9c80441e1565ad1adfcb16f1cac5bb08a281fb9334bc9"

suite "kcompletion — from-source recipe smoke test":

  test "fetch spec carries the upstream URL verbatim":
    let spec = registeredFetchSpec("kcompletion")
    check spec.url == ExpectedUrl

  test "fetch spec hash is the upstream sha256":
    let spec = registeredFetchSpec("kcompletion")
    check spec.hashHex == ExpectedHash

  test "artifacts register libKF6Completion":
    let arts = registeredArtifacts("kcompletion")
    check arts.len == 1
    check arts[0].artifactName == "libKF6Completion"
    check arts[0].kind == dakLibrary

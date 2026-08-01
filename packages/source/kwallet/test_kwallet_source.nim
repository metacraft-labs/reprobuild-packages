## Smoke test for the from-source ``kwallet`` recipe (M9.R.15q.10.3).

import std/[strutils, unittest]

import repro_project_dsl

import ./repro

suite "kwallet — from-source recipe smoke test":

  test "fetch spec is registered":
    let spec = registeredFetchSpec("kwallet")
    check spec.hashHex.len == 64
    check spec.url.endsWith("kwallet-6.10.0.tar.xz")

  test "artifact libKF6Wallet registered":
    let arts = registeredArtifacts("kwallet")
    check arts.len == 1
    check arts[0].artifactName == "libKF6Wallet"

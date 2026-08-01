## Smoke test for the from-source ``kunitconversion`` recipe (M9.R.15q.10.3).

import std/[strutils, unittest]

import repro_project_dsl

import ./repro

suite "kunitconversion — from-source recipe smoke test":

  test "fetch spec is registered":
    let spec = registeredFetchSpec("kunitconversion")
    check spec.hashHex.len == 64
    check spec.url.endsWith("kunitconversion-6.10.0.tar.xz")

  test "artifact libKF6UnitConversion registered":
    let arts = registeredArtifacts("kunitconversion")
    check arts.len == 1
    check arts[0].artifactName == "libKF6UnitConversion"

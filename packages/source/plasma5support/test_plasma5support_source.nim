## Smoke test for the from-source ``plasma5support`` recipe (M9.R.15q.10.8).

import std/[strutils, unittest]

import repro_project_dsl

import ./repro

suite "plasma5support — from-source recipe smoke test":

  test "fetch spec is registered":
    let spec = registeredFetchSpec("plasma5support")
    check spec.hashHex.len == 64
    check spec.url.endsWith("plasma5support-6.2.5.tar.xz")

  test "artifact libPlasma5Support registered":
    let arts = registeredArtifacts("plasma5support")
    check arts.len == 1
    check arts[0].artifactName == "libPlasma5Support"

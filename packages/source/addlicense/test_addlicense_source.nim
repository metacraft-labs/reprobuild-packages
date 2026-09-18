## The `addlicense` from-source recipe.
##
## Its reason for existing beside `shfmt` is the layout: `addlicense`'s main
## package is at the module root and `shfmt`'s is under `cmd/`. Two recipes
## that differed only in their pins would prove nothing the first already
## did; these two together prove the constructor handles both shapes.

import std/[strutils, unittest]

import repro_project_dsl
import ./repro

suite "addlicense source recipe":
  test "pins the upstream tag archive, not the release asset":
    # Upstream's Windows assets carry an inconsistency in their naming that
    # the binary-side recipe documents. The tag archive has no such
    # ambiguity, and is what `go build` wants regardless.
    let spec = registeredFetchSpec("addlicenseSource")
    check spec.url ==
      "https://github.com/google/addlicense/archive/refs/tags/v1.2.0.tar.gz"
    check spec.hashHex ==
      "d2e05668e6f3da9b119931c2fdadfa6dd19a8fc441218eb3f2aec4aa24ae3f90"
    check spec.extractStrip == 1

  test "publishes the single command":
    let artifacts = registeredArtifacts("addlicenseSource")
    check artifacts.len == 1
    check artifacts[0].packageName == "addlicenseSource"
    check artifacts[0].artifactName == "addlicense"
    check artifacts[0].kind == dakExecutable

  test "declares go and nothing else":
    let deps = registeredNativeBuildDeps("addlicenseSource")
    var sawGo = false
    for dep in deps:
      if dep.startsWith("go"):
        sawGo = true
      check not dep.startsWith("cargo")
      check not dep.startsWith("cmake")
      check not dep.startsWith("meson")
    check sawGo

  test "realizes the same version the binary package fetches":
    check registeredFetchSpec("addlicenseSource").url.contains("v1.2.0")

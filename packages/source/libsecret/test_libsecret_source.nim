import std/[strutils, unittest]
import repro_project_dsl
import ./repro

suite "libsecret source recipe":
  test "pins the verified GNOME release tarball":
    let spec = registeredFetchSpec("libsecret")
    check spec.url.endsWith("libsecret-0.21.6.tar.xz")
    check spec.hashHex == "747b8c175be108c880d3adfb9c3537ea66e520e4ad2dccf5dce58003aeeca090"
    check spec.extractStrip == 1

  test "registers the secret service library and crypto closure":
    let artifacts = registeredArtifacts("libsecret")
    check artifacts.len == 1
    check artifacts[0].artifactName == "libSecret"
    check "glib2 >=2.70" in registeredBuildDeps("libsecret")
    check "libgcrypt >=1.10" in registeredBuildDeps("libsecret")

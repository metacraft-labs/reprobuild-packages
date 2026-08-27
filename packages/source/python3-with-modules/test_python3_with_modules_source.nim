import std/unittest

import repro_project_dsl

import ./repro

suite "python3WithModulesSource recipe":
  test "custom install actions declare every shell helper":
    let nativeDeps = registeredNativeBuildDeps("python3WithModulesSource")
    for tool in ["sh", "mkdir", "find", "rm", "cp", "chmod", "ln"]:
      check tool in nativeDeps

  test "the package exports the augmented Python executable":
    let artifacts = registeredArtifacts("python3WithModulesSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "python3-with-modules"
    check artifacts[0].kind == dakExecutable

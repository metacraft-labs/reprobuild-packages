import std/unittest

import repro_project_dsl
import ./repro
import "../../interfaces/tree-sitter-runtime/repro" as runtimeInterface

suite "Tree-sitter runtime source recipe":
  test "canonical runtime interface declares no command-line executable":
    discard runtimeInterface.tree_sitter_runtime
    var found = false
    for pkg in registeredPackages():
      if pkg.packageName == "tree-sitter-runtime":
        found = true
        check pkg.executables.len == 0
        check pkg.libraries.len == 1
        check pkg.libraries[0].name == "tree-sitter"
        check pkg.libraries[0].kind == lkStatic
    check found

  test "pins the upstream runtime source independently of the CLI":
    let spec = registeredFetchSpec("treeSitterRuntimeSource")
    check spec.kind == dfkTarball
    check spec.url == TreeSitterSourceUrl
    check spec.hashAlg == dshaSha256
    check spec.hashHex == TreeSitterSourceHash
    check spec.extractStrip == 1
    let versions = registeredVersions("treeSitterRuntimeSource")
    check versions.len == 1
    check versions[0].version == TreeSitterVersion
    check versions[0].sourceRevision == "v" & TreeSitterVersion

  test "declares the real build toolchain":
    check registeredAuthoredNativeBuildDeps("treeSitterRuntimeSource") ==
      @["cmake >=3.13", "ninja", "gcc >=12"]

  test "exports the static runtime artifact":
    let artifacts = registeredArtifacts("treeSitterRuntimeSource")
    check artifacts.len == 1
    check artifacts[0].kind == dakLibrary
    check artifacts[0].artifactName == "tree-sitter"

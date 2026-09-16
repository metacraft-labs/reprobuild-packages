import std/unittest
import repro_project_dsl
import ./repro

when defined(reproProviderMode):
  import std/os
  import repro_core

  proc emittedActions(): seq[BuildActionDef] =
    let projectRoot = currentSourcePath.parentDir
    let package = PackageDef(
      packageName: "icuSource", sourceFile: projectRoot / "repro.nim",
      hasDevEnv: false, devEnvBodyHash: "", toolUses: @[])
    let request = ProviderGraphRequest(
      kind: prkGraphInvocation, providerArtifactId: "test-provider",
      entryPointId: "icuSource.root", entryPointBodyHash: "test-body",
      reason: girExplicitUserRequest, arguments: projectRoot,
      namespace: "project")
    let fragment = buildPackageFragment(package, request,
      proc() = buildIcuSourcePackage(), includeDefault = false)
    for node in fragment.nodes:
      if node.kind == gnkAction:
        result.add(decodeBuildActionPayload(toBytes(node.payload)))

suite "ICU source recipe":
  test "pins the official release archive":
    let spec = registeredFetchSpec("icuSource")
    check spec.kind == dfkTarball
    check spec.url == "https://github.com/unicode-org/icu/releases/download/release-76-1/icu4c-76_1-src.tgz"
    check spec.hashAlg == dshaSha256
    check spec.hashHex == "dfacb46bfe4747410472ce3e1144bf28a102feeaa4e3875bac9b4c6cf30f4f3e"
    check spec.extractStrip == 1

  test "declares awk for config.status on the build machine":
    check "awk" in registeredAuthoredNativeBuildDeps("icuSource")
    check "awk" notin registeredBuildDeps("icuSource")
    check "awk" notin registeredRuntimeDeps("icuSource")

  test "preserves all three shared library interfaces":
    let artifacts = registeredArtifacts("icuSource")
    require artifacts.len == 3
    for name in ["libIcuUc", "libIcuI18n", "libIcuData"]:
      var found = false
      for artifact in artifacts:
        if artifact.artifactName == name:
          check artifact.packageName == "icuSource"
          check artifact.kind == dakLibrary
          found = true
      check found

  when defined(reproProviderMode):
    test "configure make and install carry the native awk identity":
      var checked = 0
      for action in emittedActions():
        if action.commandStatsId == "autotools_package.configure" or
            action.id in ["autotools-make-build-icuSource-build",
              "autotools-make-install-icuSource-build"]:
          require action.toolIdentityRefKinds.len == action.toolIdentityRefs.len
          let index = action.toolIdentityRefs.find("awk")
          require index >= 0
          check action.toolIdentityRefKinds[index] == tirkNative
          inc checked
      check checked == 3

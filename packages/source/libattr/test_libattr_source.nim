import std/unittest
import repro_project_dsl
import ./repro

when defined(reproProviderMode):
  import std/os
  import repro_core

  proc configureAction(): BuildActionDef =
    let projectRoot = currentSourcePath.parentDir
    let package = PackageDef(
      packageName: "libattrSource", sourceFile: projectRoot / "repro.nim",
      hasDevEnv: false, devEnvBodyHash: "", toolUses: @[])
    let request = ProviderGraphRequest(
      kind: prkGraphInvocation, providerArtifactId: "test-provider",
      entryPointId: "libattrSource.root", entryPointBodyHash: "test-body",
      reason: girExplicitUserRequest, arguments: projectRoot,
      namespace: "project")
    let fragment = buildPackageFragment(package, request,
      proc() = buildLibattrSourcePackage(), includeDefault = false)
    for node in fragment.nodes:
      if node.kind == gnkAction:
        let action = decodeBuildActionPayload(toBytes(node.payload))
        if action.commandStatsId == "autotools_package.configure":
          return action
    raise newException(ValueError, "libattr configure action is missing")

suite "libattr source recipe":
  test "pins the official release archive":
    let spec = registeredFetchSpec("libattrSource")
    check spec.kind == dfkTarball
    check spec.url == "https://download.savannah.gnu.org/releases/attr/attr-2.5.2.tar.gz"
    check spec.hashAlg == dshaSha256
    check spec.hashHex == "39bf67452fa41d0948c2197601053f48b3d78a029389734332a6309a680c6c87"
    check spec.extractStrip == 1

  test "declares the tools used by configure and config.status":
    let dependencies = registeredAuthoredNativeBuildDeps("libattrSource")
    for tool in ["awk", "cmp", "diff"]:
      check tool in dependencies

  when defined(reproProviderMode):
    test "binds each text tool to the configure action":
      let action = configureAction()
      for tool in ["awk", "cmp", "diff"]:
        check tool in action.toolIdentityRefs

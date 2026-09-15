import std/unittest
import repro_project_dsl
import ./repro

when defined(reproProviderMode):
  import std/os
  import repro_core

  proc configureAction(): BuildActionDef =
    let projectRoot = currentSourcePath.parentDir
    let package = PackageDef(
      packageName: "libaclSource", sourceFile: projectRoot / "repro.nim",
      hasDevEnv: false, devEnvBodyHash: "", toolUses: @[])
    let request = ProviderGraphRequest(
      kind: prkGraphInvocation, providerArtifactId: "test-provider",
      entryPointId: "libaclSource.root", entryPointBodyHash: "test-body",
      reason: girExplicitUserRequest, arguments: projectRoot,
      namespace: "project")
    let fragment = buildPackageFragment(package, request,
      proc() = buildLibaclSourcePackage(), includeDefault = false)
    for node in fragment.nodes:
      if node.kind == gnkAction:
        let action = decodeBuildActionPayload(toBytes(node.payload))
        if action.commandStatsId == "autotools_package.configure":
          return action
    raise newException(ValueError, "libacl configure action is missing")

suite "libacl source recipe":
  test "pins the official release archive":
    let spec = registeredFetchSpec("libaclSource")
    check spec.kind == dfkTarball
    check spec.url == "https://download.savannah.gnu.org/releases/acl/acl-2.3.2.tar.gz"
    check spec.hashAlg == dshaSha256
    check spec.hashHex == "5f2bdbad629707aa7d85c623f994aa8a1d2dec55a73de5205bac0bf6058a2f7c"
    check spec.extractStrip == 1

  test "declares the tools used by configure and config.status":
    let dependencies = registeredAuthoredNativeBuildDeps("libaclSource")
    for tool in ["awk", "cmp", "diff"]:
      check tool in dependencies

  test "preserves the libattr build and runtime dependency":
    check registeredBuildDeps("libaclSource") == @["libattr"]
    check registeredRuntimeDeps("libaclSource") == @["libattr"]

  when defined(reproProviderMode):
    test "binds each text tool to the configure action":
      let action = configureAction()
      for tool in ["awk", "cmp", "diff"]:
        check tool in action.toolIdentityRefs

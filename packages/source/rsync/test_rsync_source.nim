import std/unittest

import repro_project_dsl

import ./repro

when defined(reproProviderMode):
  import std/os
  import repro_core

  proc configureAction(): BuildActionDef =
    let projectRoot = currentSourcePath.parentDir
    let package = PackageDef(
      packageName: "rsyncSource", sourceFile: projectRoot / "repro.nim",
      hasDevEnv: false, devEnvBodyHash: "", toolUses: @[])
    let request = ProviderGraphRequest(
      kind: prkGraphInvocation, providerArtifactId: "test-provider",
      entryPointId: "rsyncSource.root", entryPointBodyHash: "test-body",
      reason: girExplicitUserRequest, arguments: projectRoot,
      namespace: "project")
    let fragment = buildPackageFragment(package, request,
      proc() = buildRsyncSourcePackage(), includeDefault = false)
    for node in fragment.nodes:
      if node.kind == gnkAction:
        let action = decodeBuildActionPayload(toBytes(node.payload))
        if action.commandStatsId == "autotools_package.configure":
          return action
    raise newException(ValueError, "rsync configure action is missing")

const ExpectedUrl =
  "https://download.samba.org/pub/rsync/src/rsync-3.4.4.tar.gz"
const ExpectedHash =
  "bd88cf82fa653da32314fb229136407c5c90f80d1758d8f4b091767877d8fa96"

suite "rsyncSource from-source recipe":
  test "pins the official release tarball":
    let spec = registeredFetchSpec("rsyncSource")
    check spec.packageName == "rsyncSource"
    check spec.url == ExpectedUrl
    check spec.hashAlg == dshaSha256
    check spec.hashHex == ExpectedHash
    check spec.extractStrip == 1

  test "declares the text tools used by configure and config.status":
    let dependencies = registeredAuthoredNativeBuildDeps("rsyncSource")
    for tool in ["awk", "diff"]:
      check tool in dependencies

  when defined(reproProviderMode):
    test "binds configure text tools to their package identities":
      let action = configureAction()
      for tool in ["awk", "diff"]:
        check tool in action.toolIdentityRefs

import std/unittest

import repro_project_dsl
import ./repro

when defined(reproProviderMode):
  import std/[os, strutils]
  import repro_core

suite "patchelf source recipe":
  test "pins the upstream release archive":
    let spec = registeredFetchSpec("patchelfSource")
    check spec.url == "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2"
    check spec.hashHex == "17745f564159c8e228fc412da65a2048b846c4b6b4220b77cbf22416e02f2d7c"
    check spec.extractStrip == 1

  test "declares awk for the generated configure script":
    check "awk" in registeredNativeBuildDeps("patchelfSource")

  when defined(reproProviderMode):
    test "configure action receives the declared awk tool":
      let projectRoot = currentSourcePath.parentDir
      let request = ProviderGraphRequest(kind: prkGraphInvocation,
        providerArtifactId: "test-provider", entryPointId: "patchelfSource.root",
        entryPointBodyHash: "test-body", reason: girExplicitUserRequest,
        arguments: projectRoot, namespace: "project")
      let fragment = buildPackageFragment(PackageDef(packageName: "patchelfSource",
        sourceFile: projectRoot / "repro.nim"), request,
        proc() = buildPatchelfSourcePackage(), includeDefault = false)
      var configureCount = 0
      for node in fragment.nodes:
        if node.kind != gnkAction: continue
        let action = decodeBuildActionPayload(toBytes(node.payload))
        for argument in action.call.arguments:
          if argument.name == "argv" and "/configure" in argument.encodedValue:
            inc configureCount
            check "--disable-dependency-tracking" in argument.encodedValue
            check "awk" in action.toolIdentityRefs
      check configureCount == 1

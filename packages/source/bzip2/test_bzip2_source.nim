import std/unittest

import repro_project_dsl
import ./repro

when defined(reproProviderMode):
  import std/[os, strutils]
  import repro_core

suite "bzip2 source recipe":
  test "pins the official sourceware release":
    let spec = registeredFetchSpec("bzip2Source")
    check spec.url == "https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz"
    check spec.hashHex ==
      "ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269"
    check spec.extractStrip == 1

  test "publishes the command and shared ABI":
    let artifacts = registeredArtifacts("bzip2Source")
    check artifacts.len == 2
    check artifacts[0].packageName == "bzip2Source"
    check artifacts[0].artifactName == "bzip2"
    check artifacts[0].kind == dakExecutable
    check artifacts[1].artifactName == "libBz2"
    check artifacts[1].kind == dakLibrary

  test "declares the comparison tool used by upstream self-tests":
    check "cmp" in registeredNativeBuildDeps("bzip2Source")

  when defined(reproProviderMode):
    proc argValues(action: BuildActionDef; name: string): seq[string] =
      for arg in action.call.arguments:
        if arg.name == name:
          if arg.encodedValue.len > 0:
            return arg.encodedValue.split("\x1f")
          return @[]

    test "default make target retains self-tests and receives cmp":
      let projectRoot = currentSourcePath.parentDir
      let request = ProviderGraphRequest(kind: prkGraphInvocation,
        providerArtifactId: "test-provider", entryPointId: "bzip2Source.root",
        entryPointBodyHash: "test-body", reason: girExplicitUserRequest,
        arguments: projectRoot, namespace: "project")
      let fragment = buildPackageFragment(PackageDef(packageName: "bzip2Source",
        sourceFile: projectRoot / "repro.nim"), request,
        proc() = buildBzip2SourcePackage(), includeDefault = false)
      var builds, installs = 0
      for node in fragment.nodes:
        if node.kind != gnkAction: continue
        let action = decodeBuildActionPayload(toBytes(node.payload))
        if action.call.packageName != "make" or
            action.call.executableName != "makeBin": continue
        if action.id == "autotools-make-build-bzip2Source-build":
          inc builds
          check action.argValues("targets").len == 0
          check "cmp" in action.toolIdentityRefs
        if action.id == "autotools-make-install-bzip2Source-build":
          inc installs
          check action.argValues("targets") == @["repro_install"]
      check builds == 1
      check installs == 1

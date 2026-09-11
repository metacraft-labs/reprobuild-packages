import std/unittest
import repro_project_dsl
import ./repro

when defined(reproProviderMode):
  import std/[os, strutils]
  import repro_core

suite "zstd source format contract":
  test "declares gzip support as a link and runtime dependency":
    check "zlib" in registeredBuildDeps("zstdSource")
    check "zlib" in registeredRuntimeDeps("zstdSource")

  when defined(reproProviderMode):
    proc argValues(action: BuildActionDef; name: string): seq[string] =
      for arg in action.call.arguments:
        if arg.name == name:
          return arg.encodedValue.split("\x1f")

    test "make and install explicitly select formats without host detection":
      let projectRoot = currentSourcePath.parentDir
      let request = ProviderGraphRequest(kind: prkGraphInvocation,
        providerArtifactId: "test-provider", entryPointId: "zstdSource.root",
        entryPointBodyHash: "test-body", reason: girExplicitUserRequest,
        arguments: projectRoot, namespace: "project")
      let fragment = buildPackageFragment(PackageDef(packageName: "zstdSource",
        sourceFile: projectRoot / "repro.nim"), request,
        proc() = buildZstdSourcePackage(), includeDefault = false)
      var builds, installs, mirrors = 0
      for node in fragment.nodes:
        if node.kind != gnkAction: continue
        let action = decodeBuildActionPayload(toBytes(node.payload))
        if action.call.packageName == "make" and
            action.call.executableName == "makeBin":
          if "install" in action.argValues("targets"): inc installs
          else: inc builds
          for option in ["PREFIX=/usr", "HAVE_ZLIB=1", "HAVE_LZMA=0", "HAVE_LZ4=0"]:
            check option in action.argValues("vars")
          check "zlib" in action.toolIdentityRefs
        if action.id == "install-mirror-zstdSource":
          inc mirrors
          check "zlib" in action.toolIdentityRefs
      check builds == 1
      check installs == 1
      check mirrors == 1

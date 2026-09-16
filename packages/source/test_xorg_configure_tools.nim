import std/unittest
import repro_project_dsl
import ./libxau/repro
import ./libxdmcp/repro
import ./libxcb/repro

when defined(reproProviderMode):
  import std/os
  import repro_core

  proc emittedActions(name, selector: string,
                      body: proc() {.closure.}): seq[BuildActionDef] =
    let projectRoot = currentSourcePath.parentDir / selector
    let package = PackageDef(
      packageName: name, sourceFile: projectRoot / "repro.nim",
      hasDevEnv: false, devEnvBodyHash: "", toolUses: @[])
    let request = ProviderGraphRequest(
      kind: prkGraphInvocation, providerArtifactId: "test-provider",
      entryPointId: name & ".root", entryPointBodyHash: "test-body",
      reason: girExplicitUserRequest, arguments: projectRoot,
      namespace: "project")
    let fragment = buildPackageFragment(package, request, body,
      includeDefault = false)
    for node in fragment.nodes:
      if node.kind == gnkAction:
        result.add(decodeBuildActionPayload(toBytes(node.payload)))

template checkRecipe(selector, name: string, emit: untyped) =
  suite selector & " configure tools":
    test "configuration utilities are build-machine dependencies only":
      for tool in ["awk", "cmp", "diff"]:
        check tool in registeredAuthoredNativeBuildDeps(name)
        check tool notin registeredBuildDeps(name)
        check tool notin registeredRuntimeDeps(name)

    when defined(reproProviderMode):
      test "configure make and install carry native utility identities":
        var checked = 0
        for action in emittedActions(name, selector, proc() = emit):
          if action.commandStatsId == "autotools_package.configure" or
              action.id in ["autotools-make-build-" & name & "-build",
                "autotools-make-install-" & name & "-build"]:
            require action.toolIdentityRefKinds.len == action.toolIdentityRefs.len
            for tool in ["awk", "cmp", "diff"]:
              let index = action.toolIdentityRefs.find(tool)
              require index >= 0
              check action.toolIdentityRefKinds[index] == tirkNative
            inc checked
        check checked == 3

checkRecipe("libxau", "libxauSource", buildLibxauSourcePackage())
checkRecipe("libxdmcp", "libxdmcpSource", buildLibxdmcpSourcePackage())
checkRecipe("libxcb", "libxcbSource", buildLibxcbSourcePackage())

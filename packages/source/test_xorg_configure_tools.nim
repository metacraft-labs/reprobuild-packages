import std/unittest
import repro_project_dsl
import ./libxau/repro
import ./libxdmcp/repro
import ./libxcb/repro
import ./libx11/repro
import ./libxext/repro
import ./libxfixes/repro
import ./libxfont2/repro
import ./libxkbfile/repro
import ./libxrandr/repro
import ./libxrender/repro
import ./libxshmfence/repro
import ./libfontenc/repro
import "./xcb-proto/repro"
import ./xtrans/repro
import "./xcb-util/repro"
import "./xcb-util-image/repro"
import "./xcb-util-renderutil/repro"
import "./xcb-util-cursor/repro"
import "./xcb-util-keysyms/repro"
import "./xcb-util-wm/repro"
import ./xkbcomp/repro

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

template checkRecipe(selector, name: string, emit: untyped,
                     requiredTools: untyped = ["awk", "cmp", "diff"]) =
  suite selector & " configure tools":
    test "configuration utilities are build-machine dependencies only":
      for tool in requiredTools:
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
            for tool in requiredTools:
              let index = action.toolIdentityRefs.find(tool)
              require index >= 0
              check action.toolIdentityRefKinds[index] == tirkNative
            inc checked
        check checked == 3

checkRecipe("libxau", "libxauSource", buildLibxauSourcePackage())
checkRecipe("libxdmcp", "libxdmcpSource", buildLibxdmcpSourcePackage())
checkRecipe("libxcb", "libxcbSource", buildLibxcbSourcePackage())
checkRecipe("libx11", "libx11Source", buildLibx11SourcePackage())
checkRecipe("libxext", "libxextSource", buildLibxextSourcePackage())
checkRecipe("libxfixes", "libxfixesSource", buildLibxfixesSourcePackage())
checkRecipe("libxfont2", "libxfont2Source", buildLibxfont2SourcePackage())
checkRecipe("libxkbfile", "libxkbfileSource", buildLibxkbfileSourcePackage())
checkRecipe("libxrandr", "libxrandrSource", buildLibxrandrSourcePackage())
checkRecipe("libxrender", "libxrenderSource", buildLibxrenderSourcePackage())
checkRecipe("libxshmfence", "libxshmfenceSource", buildLibxshmfenceSourcePackage())
checkRecipe("libfontenc", "libfontencSource", buildLibfontencSourcePackage())
checkRecipe("xcb-proto", "xcbProtoSource", buildXcbProtoSourcePackage(), ["awk"])
checkRecipe("xtrans", "xtransSource", buildXtransSourcePackage(), ["awk", "diff"])
checkRecipe("xcb-util", "xcbUtilSource", buildXcbUtilSourcePackage())
checkRecipe("xcb-util-image", "xcbUtilImageSource", buildXcbUtilImageSourcePackage())
checkRecipe("xcb-util-renderutil", "xcbUtilRenderutilSource", buildXcbUtilRenderutilSourcePackage())
checkRecipe("xcb-util-cursor", "xcbUtilCursorSource", buildXcbUtilCursorSourcePackage())
checkRecipe("xcb-util-keysyms", "xcbUtilKeysymsSource", buildXcbUtilKeysymsSourcePackage())
checkRecipe("xcb-util-wm", "xcbUtilWmSource", buildXcbUtilWmSourcePackage())
checkRecipe("xkbcomp", "xkbcompSource", buildXkbcompSourcePackage(), ["awk", "diff"])

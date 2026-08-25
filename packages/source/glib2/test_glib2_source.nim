## Focused interface and graph-shape tests for the GLib source recipe.

import std/[sequtils, strutils, unittest]

when defined(reproProviderMode):
  import std/os
  import repro_core
import repro_project_dsl

import ./repro

proc argByName(action: BuildActionDef; name: string): PublicCliArg =
  for arg in action.call.arguments:
    if arg.name == name:
      return arg
  raise newException(ValueError, "no argument named '" & name & "'")

proc encodedValues(arg: PublicCliArg): seq[string] =
  if arg.encodedValue.len > 0:
    arg.encodedValue.split('\x1f')
  else:
    @[]

proc findMesonSetupAction(): BuildActionDef =
  for action in registeredBuildActions():
    if action.call.packageName == "meson" and
        action.call.executableName == "mesonBin" and
        action.call.subcommand == "setup":
      return action
  raise newException(ValueError, "meson setup action not found")

when defined(reproProviderMode):
  proc dummyRequest(projectRoot: string): ProviderGraphRequest =
    ProviderGraphRequest(
      kind: prkGraphInvocation,
      providerArtifactId: "test-provider",
      entryPointId: "glib2Source.root",
      entryPointBodyHash: "test-body",
      reason: girExplicitUserRequest,
      arguments: projectRoot,
      namespace: "project")

  proc extractActions(fragment: GraphFragment): seq[BuildActionDef] =
    for node in fragment.nodes:
      if node.kind == gnkAction:
        result.add(decodeBuildActionPayload(toBytes(node.payload)))

  proc findById(actions: seq[BuildActionDef]; id: string): BuildActionDef =
    for action in actions:
      if action.id == id:
        return action
    raise newException(ValueError, "action not found: " & id)

  proc inlineScriptOf(action: BuildActionDef): string =
    let argv = action.argByName("argv").encodedValues()
    if argv.len >= 3:
      argv[2]
    else:
      ""

suite "glib2Source source recipe":
  test "pins the official source release":
    let spec = registeredFetchSpec("glib2Source")
    check spec.url == GlibSourceUrl
    check spec.hashHex == GlibSourceHash
    check spec.hashAlg == dshaSha256
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

    let versions = registeredVersions("glib2Source")
    check versions.len == 1
    check versions[0].version == GlibVersion
    check versions[0].sourceRevision == GlibVersion
    check versions[0].sourceUrl == GlibSourceUrl
    check versions[0].sourceRepository == GlibSourceRepository

  test "declares the complete source dependency interface":
    check registeredNativeBuildDeps("glib2Source") == @GlibNativeBuildDeps
    check registeredBuildDeps("glib2Source") == @GlibBuildDeps

  test "configures a hermetic release build without fallbacks":
    resetBuildActionRegistry()
    buildGlib2SourcePackage()
    let setupAction = findMesonSetupAction()
    check setupAction.argByName("options").encodedValues() ==
      @["libdir=lib"] & @GlibConfigureOptions
    check setupAction.argByName("wrapMode").encodedValue == "nofallback"
    check setupAction.readOnlyRoots == @["./src"]
    check "./src" notin setupAction.declaredOutputs
    for action in registeredBuildActions():
      check action.call.packageName notin ["autotools", "cmake"]

  test "publishes the four GLib libraries":
    let artifacts = registeredArtifacts("glib2Source")
    check artifacts.mapIt(it.artifactName) ==
      @["libGlib2", "libGObject", "libGio", "libGModule"]
    for artifact in artifacts:
      check artifact.packageName == "glib2Source"
      check artifact.kind == dakLibrary

  when defined(reproProviderMode):
    test "library staging probes GLib's versioned shared-library names":
      let projectRoot = currentSourcePath.parentDir
      let packageDef = PackageDef(
        packageName: "glib2Source",
        sourceFile: projectRoot / "repro.nim",
        hasDevEnv: false,
        devEnvBodyHash: "",
        toolUses: @[])
      let fragment = buildPackageFragment(
        packageDef,
        dummyRequest(projectRoot),
        proc() = buildGlib2SourcePackage(),
        includeDefault = false)
      let stage = extractActions(fragment).findById(
        "autotools-stage-library-glib2Source-libGlib2")
      let script = stage.inlineScriptOf()
      let usrLib = (projectRoot / "build" / "out" / "usr" / "lib").
        replace("\\", "/")
      let usrLib64 = (projectRoot / "build" / "out" / "usr" / "lib64").
        replace("\\", "/")
      const libraryExtension =
        when defined(windows): ".dll"
        elif defined(macosx): ".dylib"
        else: ".so"

      check stage.commandStatsId == "autotools_package.stage.library"
      check "\"" & usrLib & "/libglib\"-*" & libraryExtension in script
      check "\"" & usrLib64 & "/libglib\"-*" & libraryExtension in script
      check "no library candidate for libGlib2" in script

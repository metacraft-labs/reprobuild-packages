import std/unittest

when defined(reproProviderMode):
  import std/[os, strutils]
  import repro_core

import repro_project_dsl
import ./repro

suite "zlib source recipe":
  test "pins the official release archive":
    let spec = registeredFetchSpec("zlibSource")
    check spec.packageName == "zlibSource"
    check spec.kind == dfkTarball
    check spec.url == ZlibSourceUrl
    check spec.hashAlg == dshaSha256
    check spec.hashHex == ZlibSourceHash
    check spec.extractStrip == 1

  test "records upstream version metadata":
    let versions = registeredVersions("zlibSource")
    check versions.len == 1
    check versions[0].version == ZlibVersion
    check versions[0].sourceRevision == "v" & ZlibVersion
    check versions[0].sourceUrl == ZlibSourceUrl
    check versions[0].sourceRepository == "https://github.com/madler/zlib"

  test "declares the complete build-tool contract":
    check registeredNativeBuildDeps("zlibSource") ==
      @ZlibNativeBuildDeps

  test "exports the compression library interface":
    let artifacts = registeredArtifacts("zlibSource")
    check artifacts.len == 1
    check artifacts[0].packageName == "zlibSource"
    check artifacts[0].artifactName == "libZ"
    check artifacts[0].kind == dakLibrary

  when defined(reproProviderMode):
    proc dummyRequest(projectRoot: string): ProviderGraphRequest =
      ProviderGraphRequest(
        kind: prkGraphInvocation,
        providerArtifactId: "test-provider",
        entryPointId: "zlibSource.root",
        entryPointBodyHash: "test-body",
        reason: girExplicitUserRequest,
        arguments: projectRoot,
        namespace: "project")

    proc extractActions(fragment: GraphFragment): seq[BuildActionDef] =
      for node in fragment.nodes:
        if node.kind == gnkAction:
          result.add(decodeBuildActionPayload(toBytes(node.payload)))

    proc argValues(action: BuildActionDef; name: string): seq[string] =
      for arg in action.call.arguments:
        if arg.name == name:
          if arg.encodedValue.len == 0:
            return @[]
          return arg.encodedValue.split("\x1f")
      @[]

    proc inlineScriptOf(action: BuildActionDef): string =
      let argv = action.argValues("argv")
      if argv.len >= 3: argv[2] else: ""

    test "provider uses the upstream build contract for each platform":
      let projectRoot = currentSourcePath.parentDir
      let pkg = PackageDef(
        packageName: "zlibSource",
        sourceFile: projectRoot / "repro.nim",
        hasDevEnv: false,
        devEnvBodyHash: "",
        toolUses: @[])
      let fragment = buildPackageFragment(
        pkg,
        dummyRequest(projectRoot),
        proc() = buildZlibSourcePackage(),
        includeDefault = false)
      let actions = extractActions(fragment)

      var configure, compile, install, stageLibrary, installMirror =
        default(BuildActionDef)
      for action in actions:
        if action.commandStatsId == "autotools_package.configure":
          configure = action
        elif action.call.packageName == "make" and
            action.call.executableName == "makeBin":
          if "install" in action.argValues("targets"):
            install = action
          else:
            compile = action
        elif action.id == "autotools-stage-library-zlibSource-libZ":
          stageLibrary = action
        elif action.id == "install-mirror-zlibSource":
          installMirror = action

      check configure.id.len > 0
      check compile.id.len > 0
      check install.id.len > 0
      check stageLibrary.id.len > 0
      check installMirror.id.len > 0

      when defined(windows):
        let configureScript = configure.inlineScriptOf()
        check "cp -aL src/. " & ZlibBuildDir & "/" in configureScript
        for option in ZlibWindowsMakeOptions:
          check option in compile.argValues("vars")
          check option in install.argValues("vars")
        check compile.dependencyPolicy.kind == bdpMakeDepfile
        check install.dependencyPolicy.kind == bdpMakeDepfile
        check compile.dependencyPolicy.depfiles == @ZlibWindowsMakeDepfiles
        check install.dependencyPolicy.depfiles == @ZlibWindowsMakeDepfiles
        check stageLibrary.dependencyPolicy.kind == bdpAutomaticMonitor
        check installMirror.dependencyPolicy.kind == bdpAutomaticMonitor
        let stageScript = stageLibrary.inlineScriptOf()
        check ZlibBuildDir & "/out/usr/bin/zlib1.dll" in stageScript
        check ZlibBuildDir & "/out/usr/bin/libZ.dll" notin stageScript
      else:
        check compile.dependencyPolicy.kind == bdpAutomaticMonitor
        check install.dependencyPolicy.kind == bdpAutomaticMonitor
        check stageLibrary.dependencyPolicy.kind == bdpAutomaticMonitor
        check installMirror.dependencyPolicy.kind == bdpAutomaticMonitor
        check "--shared" in configure.inlineScriptOf()

import std/unittest

when defined(reproProviderMode):
  import std/[os, strutils]
  import repro_core

import repro_project_dsl
import ./repro

suite "libffi source recipe":
  test "pins the official release archive":
    let spec = registeredFetchSpec("libffiSource")
    check spec.packageName == "libffiSource"
    check spec.kind == dfkTarball
    check spec.url == LibffiSourceUrl
    check spec.hashAlg == dshaSha256
    check spec.hashHex == LibffiSourceHash
    check spec.extractStrip == 1

  test "records upstream version metadata":
    let versions = registeredVersions("libffiSource")
    check versions.len == 1
    check versions[0].version == LibffiVersion
    check versions[0].sourceRevision == "v" & LibffiVersion
    check versions[0].sourceUrl == LibffiSourceUrl
    check versions[0].sourceRepository == "https://github.com/libffi/libffi"

  test "uses only tools required by a release archive":
    check registeredNativeBuildDeps("libffiSource") ==
      @LibffiNativeBuildDeps
    check "autoconf" notin registeredNativeBuildDeps("libffiSource")
    check "automake" notin registeredNativeBuildDeps("libffiSource")
    check "libtool" notin registeredNativeBuildDeps("libffiSource")

  test "exports the shared library interface":
    let artifacts = registeredArtifacts("libffiSource")
    check artifacts.len == 1
    check artifacts[0].packageName == "libffiSource"
    check artifacts[0].artifactName == "libFfi"
    check artifacts[0].kind == dakLibrary

  when defined(reproProviderMode):
    proc dummyRequest(projectRoot: string): ProviderGraphRequest =
      ProviderGraphRequest(
        kind: prkGraphInvocation,
        providerArtifactId: "test-provider",
        entryPointId: "libffiSource.root",
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

    test "provider preserves the audited configure and build contract":
      let projectRoot = currentSourcePath.parentDir
      let pkg = PackageDef(
        packageName: "libffiSource",
        sourceFile: projectRoot / "repro.nim",
        hasDevEnv: false,
        devEnvBodyHash: "",
        toolUses: @[])
      let fragment = buildPackageFragment(
        pkg,
        dummyRequest(projectRoot),
        proc() = buildLibffiSourcePackage(),
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
        elif action.id == "autotools-stage-library-libffiSource-libFfi":
          stageLibrary = action
        elif action.id == "install-mirror-libffiSource":
          installMirror = action

      let configureScript = configure.inlineScriptOf()
      check configure.id.len > 0
      check compile.id.len > 0
      check install.id.len > 0
      check stageLibrary.id.len > 0
      check installMirror.id.len > 0
      for option in LibffiBaseConfigureOptions:
        check option in configureScript
      check "--disable-dependency-tracking" notin configureScript
      check configure.declaredOutputs == @[projectRoot / LibffiBuildDir]
      check configure.readOnlyRoots == @[projectRoot / "src"]

      when defined(windows):
        for option in LibffiWindowsConfigureOptions:
          check option in configureScript
        check ("MAKEFLAGS", "-j1") in compile.env
        check ("MAKEFLAGS", "-j1") in install.env
        check compile.dependencyPolicy.kind == bdpMakeDepfile
        check install.dependencyPolicy.kind == bdpMakeDepfile
        check compile.dependencyPolicy.depfiles == @LibffiMakeDepfiles
        check install.dependencyPolicy.depfiles == @LibffiMakeDepfiles
        var expectedPostInstallDepfiles: seq[string] = @[]
        for depfile in LibffiMakeDepfiles:
          expectedPostInstallDepfiles.add(LibffiBuildDir & "/" & depfile)
        check stageLibrary.dependencyPolicy.kind == bdpMakeDepfile
        check installMirror.dependencyPolicy.kind == bdpMakeDepfile
        check stageLibrary.dependencyPolicy.depfiles ==
          expectedPostInstallDepfiles
        check installMirror.dependencyPolicy.depfiles ==
          expectedPostInstallDepfiles
        let stageScript = stageLibrary.inlineScriptOf()
        check "/usr/bin" in stageScript
        check ".dll" in stageScript
        check ".dll.a" in stageScript
      else:
        for option in LibffiWindowsConfigureOptions:
          check option notin configureScript
        check compile.dependencyPolicy.kind == bdpAutomaticMonitor
        check install.dependencyPolicy.kind == bdpAutomaticMonitor
        check stageLibrary.dependencyPolicy.kind == bdpAutomaticMonitor
        check installMirror.dependencyPolicy.kind == bdpAutomaticMonitor

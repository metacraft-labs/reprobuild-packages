import std/unittest

when defined(reproProviderMode):
  import std/[os, strutils]
  import repro_core

import repro_project_dsl
import ./repro

suite "pkgconf source recipe":
  test "pins the upstream release archive":
    let spec = registeredFetchSpec("pkgconfSource")
    check spec.packageName == "pkgconfSource"
    check spec.kind == dfkTarball
    check spec.url == PkgconfSourceUrl
    check spec.hashAlg == dshaSha256
    check spec.hashHex == PkgconfSourceHash
    check spec.extractStrip == 1

  test "records the upstream version identity":
    let versions = registeredVersions("pkgconfSource")
    check versions.len == 1
    check versions[0].version == PkgconfVersion
    check versions[0].sourceRevision == "pkgconf-" & PkgconfVersion
    check versions[0].sourceUrl == PkgconfSourceUrl
    check versions[0].sourceRepository == "https://github.com/pkgconf/pkgconf"

  test "uses only tools required by the release archive":
    check registeredNativeBuildDeps("pkgconfSource") ==
      @PkgconfNativeBuildDeps

  test "exports the implementation, compatibility command, and library":
    let artifacts = registeredArtifacts("pkgconfSource")
    check artifacts.len == 3
    check artifacts[0].artifactName == "pkgconf"
    check artifacts[0].kind == dakExecutable
    check artifacts[1].artifactName == "pkgConfig"
    check artifacts[1].kind == dakExecutable
    check artifacts[2].artifactName == "libpkgconf"
    check artifacts[2].kind == dakLibrary
    for artifact in artifacts:
      check artifact.packageName == "pkgconfSource"

  when defined(reproProviderMode):
    proc dummyRequest(projectRoot: string): ProviderGraphRequest =
      ProviderGraphRequest(
        kind: prkGraphInvocation,
        providerArtifactId: "test-provider",
        entryPointId: "pkgconfSource.root",
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

    test "provider builds the release without regenerating Autotools files":
      let projectRoot = currentSourcePath.parentDir
      let packageDef = PackageDef(
        packageName: "pkgconfSource",
        sourceFile: projectRoot / "repro.nim",
        hasDevEnv: false,
        devEnvBodyHash: "",
        toolUses: @[])
      let fragment = buildPackageFragment(
        packageDef,
        dummyRequest(projectRoot),
        proc() = buildPkgconfSourcePackage(),
        includeDefault = false)
      let actions = extractActions(fragment)

      var configure, compile, install = default(BuildActionDef)
      for action in actions:
        if action.commandStatsId == "autotools_package.configure":
          configure = action
        elif action.call.packageName == "make" and
            action.call.executableName == "makeBin":
          if "install" in action.argValues("targets"):
            install = action
          else:
            compile = action

      check configure.id.len > 0
      check compile.id.len > 0
      check install.id.len > 0
      check configure.inlineScriptOf().contains("./src/configure")
      check not configure.inlineScriptOf().contains("autoreconf")
      for option in PkgconfBaseConfigureOptions:
        check option in configure.inlineScriptOf()
      check configure.declaredOutputs == @[projectRoot / PkgconfBuildDir]
      check configure.readOnlyRoots == @[projectRoot / "src"]

      when defined(windows):
        for option in PkgconfWindowsConfigureOptions:
          check option in configure.inlineScriptOf()
        for option in PkgconfSharedConfigureOptions:
          check option notin configure.inlineScriptOf()
        let conversionExclusion =
          ("MSYS2_ARG_CONV_EXCL", PkgconfWindowsArgConversionExclusions)
        let staticCppFlags = ("CPPFLAGS", PkgconfWindowsCppFlags)
        check conversionExclusion in configure.env
        check conversionExclusion in compile.env
        check conversionExclusion in install.env
        check staticCppFlags in configure.env
        check staticCppFlags in compile.env
        check staticCppFlags in install.env
        check compile.dependencyPolicy.kind == bdpMakeDepfile
        check install.dependencyPolicy.kind == bdpMakeDepfile
        check compile.dependencyPolicy.depfiles == @PkgconfMakeDepfiles
        check install.dependencyPolicy.depfiles == @PkgconfMakeDepfiles
      else:
        for option in PkgconfSharedConfigureOptions:
          check option in configure.inlineScriptOf()
        for option in PkgconfWindowsConfigureOptions:
          check option notin configure.inlineScriptOf()
        check compile.dependencyPolicy.kind == bdpAutomaticMonitor
        check install.dependencyPolicy.kind == bdpAutomaticMonitor

      let implementation = actions.findById(
        "autotools-stage-executable-pkgconfSource-pkgconf")
      let compatibility = actions.findById(
        "autotools-stage-alias-pkgconfSource-pkgConfig")
      let library = actions.findById(
        "autotools-stage-library-pkgconfSource-libpkgconf")
      let mirror = actions.findById("install-mirror-pkgconfSource")

      when defined(windows):
        var postInstallDepfiles: seq[string] = @[]
        for depfile in PkgconfMakeDepfiles:
          postInstallDepfiles.add(PkgconfBuildDir & "/" & depfile)
        for action in [implementation, compatibility, library, mirror]:
          check action.dependencyPolicy.kind == bdpMakeDepfile
          check action.dependencyPolicy.depfiles == postInstallDepfiles
      else:
        for action in [implementation, compatibility, library, mirror]:
          check action.dependencyPolicy.kind == bdpAutomaticMonitor
      check "/usr/bin/pkgconf" in compatibility.inlineScriptOf()
      check "/usr/bin/pkg-config" notin compatibility.inlineScriptOf()
      when defined(windows):
        let compatibilityOutputDir =
          projectRoot / ".repro" / "output" / "pkgConfig"
        check compatibility.outputs == @[
          compatibilityOutputDir / "pkgConfig.exe",
          compatibilityOutputDir / "pkgconf.exe",
        ]
        check "#!/bin/sh" notin compatibility.inlineScriptOf()
      else:
        let compatibilityOutputDir =
          projectRoot / ".repro" / "output" / "pkgConfig"
        check compatibility.outputs == @[
          compatibilityOutputDir / "pkgConfig",
          compatibilityOutputDir / "pkgconf",
        ]
        check "#!/bin/sh" in compatibility.inlineScriptOf()

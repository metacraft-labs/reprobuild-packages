## Smoke test for the from-source ``glibcSource`` recipe.
##
## Pins the M9.H/I/K trio's behaviour on the FORTY-SECOND real
## production from-source recipe. glibc's unique coverage angle vs
## the prior forty-one is the SEVEN-artifact mixed-kind shape (six
## libraries + one executable for the dynamic linker) — the new
## record-holder for largest single from-source artifact set,
## eclipsing the prior util-linux eight-artifact record because
## glibc's artifacts span the FULL C runtime + the dynamic linker
## itself (the program the kernel hands every dynamically-linked ELF
## at exec time). A regression that collapsed the artifact-name
## partitioning at this cardinality (or mis-tagged any of the seven
## individual kind discriminants) would surface here.
##
## Coverage (≥8 tests with multiple assertions each):
##
##   * ``fetch:`` block round-trip (M9.H) — URL + sha256 length +
##     algorithm + kind discriminant + extractStrip.
##   * Emitted configure flag order, native tool bindings and build environment.
##   * SEVEN artifact registration (M3) — six libraries tagged
##     ``dakLibrary`` (libC + libM + libPthread + libDl + libRt +
##     libCrypt) + one executable tagged ``dakExecutable`` (ldso for
##     the dynamic linker), all in the same package's artifact set.
##   * ``versions:`` block round-trip (M2) — upstream tag + URL +
##     repository for ``repro update-source``.

import std/[strutils, unittest]

import repro_project_dsl

# Side-effect import: triggers the package macro which registers
# fetch spec + configure flags + six library + one executable
# artifacts under ``glibcSource`` at module init time.
import ./repro

when defined(reproProviderMode):
  import std/os
  import repro_core

  proc emittedActions(): seq[BuildActionDef] =
    let projectRoot = currentSourcePath.parentDir
    let package = PackageDef(
      packageName: "glibcSource", sourceFile: projectRoot / "repro.nim",
      hasDevEnv: false, devEnvBodyHash: "", toolUses: @[])
    let request = ProviderGraphRequest(
      kind: prkGraphInvocation, providerArtifactId: "test-provider",
      entryPointId: "glibcSource.root", entryPointBodyHash: "test-body",
      reason: girExplicitUserRequest, arguments: projectRoot,
      namespace: "project")
    let fragment = buildPackageFragment(package, request,
      proc() = buildGlibcSourcePackage(), includeDefault = false)
    for node in fragment.nodes:
      if node.kind == gnkAction:
        result.add(decodeBuildActionPayload(toBytes(node.payload)))

  proc configureAction(actions: seq[BuildActionDef]): BuildActionDef =
    for action in actions:
      if action.commandStatsId == "autotools_package.configure":
        return action
    raise newException(ValueError, "glibc configure action is missing")

  proc actionById(actions: seq[BuildActionDef]; id: string): BuildActionDef =
    for action in actions:
      if action.id == id:
        return action
    raise newException(ValueError, "glibc action is missing: " & id)

  proc configureScript(action: BuildActionDef): string =
    for arg in action.call.arguments:
      if arg.name == "argv":
        let argv = arg.encodedValue.split("\x1f")
        if argv.len >= 3:
          return argv[2]
    raise newException(ValueError, "glibc configure command is missing")

# Keep this fixture aligned with the source runtime used by the image.
const ExpectedUrl =
  "https://ftp.gnu.org/gnu/glibc/glibc-2.42.tar.xz"

const ExpectedHash =
  "d1775e32e4628e64ef930f435b67bb63af7599acb6be2b335b9f19f16509f17f"

const ExpectedConfigureFlags = @[
  "--disable-werror",
  "--enable-bind-now",
  "--enable-stack-protector=strong",
  "--enable-kernel=4.19",
  "--without-selinux",
]

suite "glibcSource — from-source recipe smoke test":

  test "fetch spec carries the upstream URL verbatim":
    # M9.H registry round-trip — URL is recorded exactly as declared.
    let spec = registeredFetchSpec("glibcSource")
    check spec.packageName == "glibcSource"
    check spec.url == ExpectedUrl

  test "fetch spec hash is a 64-char sha256 hex string":
    # The release tarball hash must move in lockstep with its URL.
    let spec = registeredFetchSpec("glibcSource")
    check spec.hashHex.len == 64
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    # Tarball vs git-archive discriminant + the canonical
    # ``--strip-components=1`` convention upstream ftp.gnu.org release
    # tarballs use.
    let spec = registeredFetchSpec("glibcSource")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "declares build-machine tools and target Linux headers":
    let dependencies = registeredAuthoredNativeBuildDeps("glibcSource")
    for tool in ["awk", "diff", "python3 >=3.9"]:
      check tool in dependencies
    check registeredBuildDeps("glibcSource") == @["linux-headers >=4.19"]

  when defined(reproProviderMode):
    test "configure action preserves the production flag order":
      let script = emittedActions().configureAction().configureScript()
      var previous = -1
      for flag in ExpectedConfigureFlags:
        let position = script.find(flag)
        check position > previous
        previous = position

    test "configure make and install bind native tools and build environment":
      let actions = emittedActions()
      for action in [actions.configureAction(),
          actions.actionById("autotools-make-build-glibcSource-build"),
          actions.actionById("autotools-make-install-glibcSource-build")]:
        require action.toolIdentityRefKinds.len == action.toolIdentityRefs.len
        for tool in ["awk", "diff", "python3"]:
          let index = action.toolIdentityRefs.find(tool)
          require index >= 0
          check action.toolIdentityRefKinds[index] == tirkNative
        let headersIndex = action.toolIdentityRefs.find("linux-headers")
        require headersIndex >= 0
        check action.toolIdentityRefKinds[headersIndex] == tirkBuild
        check ("AWK", "awk") in action.env
        check ("CFLAGS", "-O2 -g") in action.env
        check ("NIX_HARDENING_ENABLE",
          "bindnow format libcxxhardeningfast pic relro " &
          "stackclashprotection strictflexarrays1 strictoverflow " &
          "zerocallusedregs") in action.env

  test "artifacts register six libraries + one executable with correct kinds":
    # M3 artifact registry: libC + libM + libPthread + libDl + libRt +
    # libCrypt are tagged ``dakLibrary`` while ldso is tagged
    # ``dakExecutable``. The unique coverage of THIS recipe is the
    # SEVEN-artifact mixed-kind shape spanning the full C runtime + the
    # dynamic linker itself. A regression that flattened the kind
    # discriminator would mis-route the M9.L install path (``lib/``
    # vs ``bin/``); a regression that collapsed the artifact-name
    # partitioning at the seven-artifact cardinality would not produce
    # seven distinct entries with the expected names below.
    let arts = registeredArtifacts("glibcSource")
    check arts.len == 7
    var seenLibC = false
    var seenLibM = false
    var seenLibPthread = false
    var seenLibDl = false
    var seenLibRt = false
    var seenLibCrypt = false
    var seenLdso = false
    for art in arts:
      check art.packageName == "glibcSource"
      case art.artifactName
      of "libC":
        seenLibC = true
        check art.kind == dakLibrary
      of "libM":
        seenLibM = true
        check art.kind == dakLibrary
      of "libPthread":
        seenLibPthread = true
        check art.kind == dakLibrary
      of "libDl":
        seenLibDl = true
        check art.kind == dakLibrary
      of "libRt":
        seenLibRt = true
        check art.kind == dakLibrary
      of "libCrypt":
        seenLibCrypt = true
        check art.kind == dakLibrary
      of "ldso":
        seenLdso = true
        check art.kind == dakExecutable
      else:
        discard
    check seenLibC
    check seenLibM
    check seenLibPthread
    check seenLibDl
    check seenLibRt
    check seenLibCrypt
    check seenLdso

  test "versions block records the upstream tag + URL + repository":
    # M2 versions registry: the upstream ftp.gnu.org release tag is
    # recorded for ``repro update-source``. The repository points at the
    # canonical sourceware.org git mirror that hosts the glibc source
    # tree.
    let vs = registeredVersions("glibcSource")
    check vs.len == 1
    check vs[0].version == "2.42"
    check vs[0].sourceRevision == "glibc-2.42"
    check vs[0].sourceUrl ==
      "https://ftp.gnu.org/gnu/glibc/glibc-2.42.tar.xz"
    check vs[0].sourceRepository ==
      "https://sourceware.org/git/glibc.git"

  test "ldconfig uses the guarded observable dynamic link patch":
    const recipeSource = staticRead("./repro.nim")
    const patchSource = staticRead("./patches/enable-dynamic-ldconfig.py")
    const comparatorSource = staticRead("./patches/ldconfig-cache-libcmp.c")
    check recipeSource.contains(
      "python3 ./patches/enable-dynamic-ldconfig.py ./src")
    check recipeSource.contains("srcPatches = glibcSourcePatches")
    check not recipeSource.contains("makeVars = @[\"others-static=sln\"]")
    check patchSource.contains("others-static\\t+= ldconfig")
    check patchSource.contains("CFLAGS-ldconfig.c += -DNO_HIDDEN")
    check patchSource.contains("ldconfig-cache-libcmp")
    check comparatorSource.contains("_dl_cache_libcmp")
    check recipeSource.contains(
      "postConfigureCommands = @[\"mkdir -p elf\"]")

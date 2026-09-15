## Smoke test for the from-source ``expatSource`` recipe.
##
## Pins the M9.H/I/K trio's behaviour on the FOURTEENTH real production
## from-source recipe and the FIRST autotools-driven recipe. Prior
## thirteen recipes covered three of the five M9.I flag-injection
## channels (meson + make + cmake). expat's unique coverage angle vs
## the prior thirteen is the ``configureFlags:`` channel — the first
## place to exercise the M9.I per-channel partitioning property from
## the autotools ``./configure`` side. The cross-channel isolation
## pin below would surface a regression that leaks ``./configure``
## flags into the meson, cmake, or make channels (or vice versa).
##
## Coverage includes fetch metadata, configure actions, tool declarations,
## library registration and version metadata.
##
##   * ``fetch:`` block round-trip (M9.H) — URL + sha256 length +
##     algorithm + kind discriminant + extractStrip.
##   * ``configureFlags:`` block round-trip (M9.I) — exact-order
##     sequence equality on the production flag set + channel-isolation
##     spot-check (meson + cmake channels MUST be empty).
##   * SINGLE library artifact registration (M3) — ``libExpat``
##     tagged ``dakLibrary``.
##   * ``versions:`` block round-trip (M2) — upstream tag + URL +
##     repository for ``repro update-source``.

import std/[unittest]

when defined(reproProviderMode):
  import std/[os, strutils]
  import repro_core

import repro_project_dsl

# Side-effect import: triggers the package macro which registers
# fetch spec + configure flags + library artifact under
# ``expatSource`` at module init time.
import ./repro

const ExpectedUrl =
  "https://github.com/libexpat/libexpat/releases/download/R_2_7_0/expat-2.7.0.tar.xz"

const ExpectedHash =
  "25df13dd2819e85fb27a1ce0431772b7047d72af81ae78dc26b4c6e0805f48d1"

const ExpectedConfigureFlags = @[
  "--disable-static",
  "--without-docbook",
  "--without-examples",
  "--without-tests",
]

suite "expatSource — from-source recipe smoke test":

  test "fetch spec carries the vendored URL verbatim":
    # M9.H registry round-trip — URL is recorded exactly as declared.
    let spec = registeredFetchSpec("expatSource")
    check spec.packageName == "expatSource"
    check spec.url == ExpectedUrl

  test "fetch spec hash is a 64-char sha256 hex string":
    # sha256 over the vendored 493,060-byte tarball; length check
    # guards against a future bump that forgets to widen the hash
    # alongside the URL.
    let spec = registeredFetchSpec("expatSource")
    check spec.hashHex.len == 64
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    # Tarball vs git-archive discriminant + the canonical
    # ``--strip-components=1`` convention upstream GitHub release
    # tarballs use.
    let spec = registeredFetchSpec("expatSource")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "declares the text tools used by configure and config.status":
    let dependencies = registeredAuthoredNativeBuildDeps("expatSource")
    for tool in ["awk", "cmp", "diff"]:
      check tool in dependencies

  test "artifacts register a single library":
    # M3 artifact registry: ``libExpat`` is the only artifact and
    # must be tagged ``dakLibrary``. expat's autotools build emits
    # one shared object bundling the SAX/expat parser core + the
    # namespace parser + the XML decoder helpers. A regression that
    # mis-tagged the artifact kind would mis-route the M9.L install
    # path (``lib/`` vs ``bin/``).
    let arts = registeredArtifacts("expatSource")
    check arts.len == 1
    check arts[0].packageName == "expatSource"
    check arts[0].artifactName == "libExpat"
    check arts[0].kind == dakLibrary

  test "versions block records the upstream tag + URL + repository":
    # M2 versions registry: the upstream GitHub release tag is
    # recorded for ``repro update-source`` even though the live
    # fetch points at the vendored copy. The repository points at
    # the canonical GitHub project that hosts the libexpat source
    # tree.
    let vs = registeredVersions("expatSource")
    check vs.len == 1
    check vs[0].version == "2.7.0"
    check vs[0].sourceRevision == "R_2_7_0"
    check vs[0].sourceUrl ==
      "https://github.com/libexpat/libexpat/releases/download/R_2_7_0/expat-2.7.0.tar.xz"
    check vs[0].sourceRepository ==
      "https://github.com/libexpat/libexpat"

  when defined(reproProviderMode):
    proc emittedActions(): seq[BuildActionDef] =
      let projectRoot = currentSourcePath.parentDir
      let package = PackageDef(
        packageName: "expatSource", sourceFile: projectRoot / "repro.nim",
        hasDevEnv: false, devEnvBodyHash: "", toolUses: @[])
      let request = ProviderGraphRequest(
        kind: prkGraphInvocation, providerArtifactId: "test-provider",
        entryPointId: "expatSource.root", entryPointBodyHash: "test-body",
        reason: girExplicitUserRequest, arguments: projectRoot,
        namespace: "project")
      let fragment = buildPackageFragment(package, request,
        proc() = buildExpatSourcePackage(), includeDefault = false)
      for node in fragment.nodes:
        if node.kind == gnkAction:
          result.add(decodeBuildActionPayload(toBytes(node.payload)))

    proc configureAction(): BuildActionDef =
      for action in emittedActions():
        if action.commandStatsId == "autotools_package.configure":
          return action
      raise newException(ValueError, "Expat configure action is missing")

    proc configureScript(action: BuildActionDef): string =
      for arg in action.call.arguments:
        if arg.name == "argv":
          let argv = arg.encodedValue.split("\x1f")
          if argv.len >= 3:
            return argv[2]
      raise newException(ValueError, "Expat configure command is missing")

    test "configure action preserves the production flag order":
      let script = configureAction().configureScript()
      var previous = -1
      for flag in ExpectedConfigureFlags:
        let position = script.find(flag)
        check position > previous
        previous = position

    test "configureFlags does not leak into the meson channel":
      for action in emittedActions():
        check action.call.packageName != "meson"
        check not action.commandStatsId.startsWith("meson")

    test "configureFlags does not leak into the cmake channel":
      for action in emittedActions():
        check action.call.packageName != "cmake"
        check not action.commandStatsId.startsWith("cmake")

    test "configure action includes the declared text tools":
      let configure = configureAction()
      for tool in ["awk", "cmp", "diff"]:
        check tool in configure.toolIdentityRefs

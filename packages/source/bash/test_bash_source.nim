## Smoke test for the from-source ``bashSource`` recipe.
##
## Checks the release pin, emitted configure flags, required awk/cmp tool
## identities, POSIX sh installation target, and public artifacts. These
## registry/graph tests do not replace a real from-source build.

import std/[strutils, unittest]

import repro_project_dsl

# Side-effect import: triggers the package macro which registers
# fetch spec + configure flags + one executable artifact under
# ``bashSource`` at module init time.
import ./repro

const ExpectedUrl =
  "https://ftp.gnu.org/gnu/bash/bash-5.2.37.tar.gz"

const ExpectedHash =
  "9599b22ecd1d5787ad7d3b7bf0c59f312b3396d1e281175dd1f8a4014da621ff"

const ExpectedConfigureFlags = @[
  "--disable-static",
  "--without-bash-malloc",
  "--enable-readline",
  "--enable-history",
  "--enable-job-control",
]

proc argValues(action: BuildActionDef; name: string): seq[string] =
  for arg in action.call.arguments:
    if arg.name == name and arg.encodedValue.len > 0:
      return arg.encodedValue.split('\x1f')
  @[]

proc actionById(id: string): BuildActionDef =
  for action in registeredBuildActions():
    if action.id == id:
      return action
  raise newException(ValueError, "action not found: " & id)

proc configureAction(): BuildActionDef =
  for action in registeredBuildActions():
    let argv = action.argValues("argv")
    if argv.len == 3 and argv[0 .. 1] == @["sh", "-c"] and
        "../src/configure " in argv[2]:
      return action
  raise newException(ValueError, "configure action not found")

suite "bashSource — from-source recipe smoke test":

  test "fetch spec carries the vendored URL verbatim":
    # M9.H registry round-trip — URL is recorded exactly as declared.
    let spec = registeredFetchSpec("bashSource")
    check spec.packageName == "bashSource"
    check spec.url == ExpectedUrl

  test "fetch spec hash is a 64-char sha256 hex string":
    # sha256 over the vendored 11,128,314-byte tarball; length check
    # guards against a future bump that forgets to widen the hash
    # alongside the URL.
    let spec = registeredFetchSpec("bashSource")
    check spec.hashHex.len == 64
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    # Tarball vs git-archive discriminant + the canonical
    # ``--strip-components=1`` convention upstream ftp.gnu.org release
    # tarballs use.
    let spec = registeredFetchSpec("bashSource")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "configure command retains the production flag sequence":
    resetBuildActionRegistry()
    buildBashSourcePackage()
    let argv = configureAction().argValues("argv")
    check argv[2].endsWith("../src/configure --prefix=/usr " &
      ExpectedConfigureFlags.join(" "))

  test "declares utilities for configure and generated headers":
    for tool in ["awk", "cmp"]:
      check tool in registeredAuthoredNativeBuildDeps("bashSource")

  test "configure action carries the required utility identities":
    resetBuildActionRegistry()
    buildBashSourcePackage()
    for tool in ["awk", "cmp"]:
      check tool in configureAction().toolIdentityRefs

  test "build and installation retain utilities and the POSIX shell alias target":
    resetBuildActionRegistry()
    buildBashSourcePackage()
    let build = actionById("autotools-make-build-bashSource-build")
    let install = actionById("autotools-make-install-bashSource-build")
    for tool in ["awk", "cmp"]:
      check tool in build.toolIdentityRefs
      check tool in install.toolIdentityRefs
    check install.argValues("targets") == @["install-sh-alias"]

  test "artifacts register the bash interpreter plus its sh alias":
    # M3 artifact registry: bash's autotools build emits one load-
    # bearing binary (the shell interpreter) and the recipe's
    # ``install-sh-alias`` patch additionally plants ``$(bindir)/sh``
    # as a link to it, so the POSIX ``sh`` tool name is provisionable
    # for Ninja / Make command runners that spawn ``/bin/sh -c``.
    # Both are tagged ``dakExecutable``; the auxiliary ``bashbug``
    # helper + loadable builtins are NOT registered in v1. A
    # regression that flattened the kind discriminator would mis-route
    # the M9.L install path; a regression that collapsed the
    # artifact-name partitioning would not produce two distinctly
    # named entries in declaration order.
    let arts = registeredArtifacts("bashSource")
    check arts.len == 2
    check arts[0].packageName == "bashSource"
    check arts[0].artifactName == "bash"
    check arts[0].kind == dakExecutable
    check arts[1].packageName == "bashSource"
    check arts[1].artifactName == "sh"
    check arts[1].kind == dakExecutable

  test "versions block records the upstream tag + URL + repository":
    # M2 versions registry: the upstream ftp.gnu.org release tag is
    # recorded for ``repro update-source`` even though the live fetch
    # points at the vendored copy. The repository points at the
    # canonical savannah.gnu.org mirror that hosts the bash source
    # tree.
    let vs = registeredVersions("bashSource")
    check vs.len == 1
    check vs[0].version == "5.2.37"
    check vs[0].sourceRevision == "bash-5.2.37"
    check vs[0].sourceUrl ==
      "https://ftp.gnu.org/gnu/bash/bash-5.2.37.tar.gz"
    check vs[0].sourceRepository ==
      "https://git.savannah.gnu.org/git/bash.git"

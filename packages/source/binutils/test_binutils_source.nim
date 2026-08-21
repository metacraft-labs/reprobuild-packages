## Smoke test for the from-source ``binutilsSource`` recipe.
##
## Pins the M9.H/I/K trio's behaviour on the M9.N Batch E compiler-
## chain slice. binutils's unique coverage angles vs the prior 82
## from-source recipes:
##
##   * FIRST recipe in the corpus to declare ELEVEN ``executable``
##     artifacts sharing a single ``./configure`` + ``make`` install-
##     tree. Pins the from-source-autotools convention's per-artifact
##     stage-copy fan-out at the eleven-binary cardinality.
##   * The lowered configure action records all required linker options
##     plus the explicit exclusions that keep optional build tools out
##     of the source closure.
##   * Real sha256 on the fetch channel — the test asserts the exact
##     64-char hex hash recorded in the recipe + the algorithm tag.
##
## Coverage (>=8 tests with multiple assertions each):
##
##   * ``fetch:`` block round-trip (M9.H) — URL + sha256 length +
##     algorithm + kind discriminant + extractStrip.
##   * Lowered configure action inspection — required options and
##     optional-tool exclusions must reach the executed command.
##   * Exact native and build dependency closure.
##   * ELEVEN ``executable`` artifact registration (M3) — ld + as +
##     ar + nm + objcopy + objdump + ranlib + strip + readelf + size
##     + strings all tagged ``dakExecutable``.
##   * ``versions:`` block round-trip (M2) — upstream tag + URL +
##     repository for ``repro update-source``.

import std/[strutils, unittest]

import repro_project_dsl

# Side-effect import: triggers the package macro which registers
# fetch spec + configure flags + eleven executable artifacts under
# ``binutilsSource`` at module init time.
import ./repro

const ExpectedUrl =
  "https://ftp.gnu.org/gnu/binutils/binutils-2.43.tar.xz"

# Real sha256 over the upstream binutils-2.43.tar.xz tarball; see
# ``repro.nim``'s sha256 strategy section.
const ExpectedHash =
  "b53606f443ac8f01d1d5fc9c39497f2af322d99e14cea5c0b4b124d630379365"

const ExpectedConfigureFlags = @[
  "--enable-gold",
  "--enable-ld=default",
  "--enable-plugins",
  "--enable-shared",
  "--disable-werror",
  "--disable-gprofng",
]

const ExpectedGeneratedToolOverrides = @[
  ("MAKEINFO", "true"),
  ("BISON", ":"),
  ("YACC", ":"),
  ("FLEX", ":"),
  ("LEX", ":"),
]

suite "binutilsSource — from-source recipe smoke test":

  test "fetch spec carries the upstream URL verbatim":
    # M9.H registry round-trip — URL is recorded exactly as declared.
    let spec = registeredFetchSpec("binutilsSource")
    check spec.packageName == "binutilsSource"
    check spec.url == ExpectedUrl

  test "fetch spec hash is the real sha256 over the upstream tarball":
    # Real sha256 over the upstream ftp.gnu.org tarball; computed
    # locally + asserted exactly.
    let spec = registeredFetchSpec("binutilsSource")
    check spec.hashHex.len == 64
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    # Tarball vs git-archive discriminant + the canonical
    # ``--strip-components=1`` convention.
    let spec = registeredFetchSpec("binutilsSource")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "lowered configure action carries the production options":
    var configureCommand = ""
    for action in registeredBuildActions():
      for arg in action.call.arguments:
        if arg.name == "argv" and arg.encodedValue.contains("../src/configure"):
          configureCommand = arg.encodedValue
    check configureCommand.len > 0
    for flag in ExpectedConfigureFlags:
      check configureCommand.contains(flag)

  test "generated tools are disabled in the environment and recursive make":
    var configuredOverrides: seq[string] = @[]
    var makeVarsEncoding = ""
    for action in registeredBuildActions():
      for (name, value) in action.env:
        if (name, value) in ExpectedGeneratedToolOverrides:
          configuredOverrides.add(name)
      for arg in action.call.arguments:
        if arg.name == "vars" and arg.encodedValue.contains("MAKEINFO=true"):
          makeVarsEncoding = arg.encodedValue
    check makeVarsEncoding.len > 0
    for (name, value) in ExpectedGeneratedToolOverrides:
      check name in configuredOverrides
      check makeVarsEncoding.contains(name & "=" & value)

  test "uses only tools required by the release archive":
    let native = registeredNativeBuildDeps("binutilsSource")
    check native == @["gcc >=11", "make >=4.3", "perl >=5.32"]
    check "bison >=3.6" notin native
    check "flex >=2.6" notin native

  test "documentation suppression removes the texinfo dependency":
    check registeredBuildDeps("binutilsSource").len == 0
  test "artifacts register eleven executables all tagged dakExecutable":
    # M3 artifact registry: ld + as + ar + nm + objcopy + objdump +
    # ranlib + strip + readelf + size + strings are all tagged
    # ``dakExecutable``. A regression that flattened the kind
    # discriminator at the eleven-artifact cardinality would surface
    # here.
    let arts = registeredArtifacts("binutilsSource")
    check arts.len == 11
    var seenLd = false
    var seenAs = false
    var seenAr = false
    var seenNm = false
    var seenObjcopy = false
    var seenObjdump = false
    var seenRanlib = false
    var seenStrip = false
    var seenReadelf = false
    var seenSize = false
    var seenStrings = false
    for art in arts:
      check art.packageName == "binutilsSource"
      check art.kind == dakExecutable
      case art.artifactName
      of "ld":
        seenLd = true
      of "as":
        seenAs = true
      of "ar":
        seenAr = true
      of "nm":
        seenNm = true
      of "objcopy":
        seenObjcopy = true
      of "objdump":
        seenObjdump = true
      of "ranlib":
        seenRanlib = true
      of "strip":
        seenStrip = true
      of "readelf":
        seenReadelf = true
      of "size":
        seenSize = true
      of "strings":
        seenStrings = true
      else:
        discard
    check seenLd
    check seenAs
    check seenAr
    check seenNm
    check seenObjcopy
    check seenObjdump
    check seenRanlib
    check seenStrip
    check seenReadelf
    check seenSize
    check seenStrings

  test "versions block records the upstream tag + URL + repository":
    # M2 versions registry: the upstream ftp.gnu.org release tag is
    # recorded for ``repro update-source``. The repository points at
    # the canonical sourceware.org git tree.
    let vs = registeredVersions("binutilsSource")
    check vs.len == 1
    check vs[0].version == "2.43"
    check vs[0].sourceRevision == "binutils-2_43"
    check vs[0].sourceUrl ==
      "https://ftp.gnu.org/gnu/binutils/binutils-2.43.tar.xz"
    check vs[0].sourceRepository ==
      "https://sourceware.org/git/binutils-gdb.git"

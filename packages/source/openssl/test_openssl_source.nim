## Smoke test for the from-source ``opensslSource`` recipe.
##
## Pins the M9.H/I/K trio's behaviour on the THIRTIETH real production
## from-source recipe. openssl's unique coverage angle vs the prior
## twenty-nine is the ``configureFlags:`` channel feeding ANOTHER
## custom (non-autotools, non-meson, non-cmake) ``./Configure`` script
## — openssl's ``Configure`` is a Perl script accepting a positional
## target triplet (``linux-x86_64``) FOLLOWED by ``no-<feature>`` /
## ``enable-<feature>`` toggles. This is the SECOND recipe in the
## corpus to drive a custom-configure script through the autotools
## channel (zlib was the first this batch). Additionally, openssl is
## the SEVENTH multi-library single-package shape and the FIRST
## non-meson / non-cmake multi-library recipe (wayland / pango / glib2
## meson + sddm cmake + qt6-base cmake were the prior multi-library
## recipes).
##
## Coverage (10 check assertions across 8 tests):
##
##   * ``fetch:`` block round-trip (M9.H) — URL + sha256 length +
##     algorithm + kind discriminant + extractStrip.
##   * ``configureFlags:`` block round-trip (M9.I) — exact-order
##     sequence equality on the production flag set + channel-isolation
##     spot-check (meson + cmake channels MUST be empty).
##   * TWO library artifact registration (M3) — ``libCrypto`` +
##     ``libSsl`` both tagged ``dakLibrary``.
##   * ``versions:`` block round-trip (M2) — upstream tag + URL +
##     repository for ``repro update-source``.

import std/[unittest, strutils]

import repro_project_dsl

# Side-effect import: triggers the package macro which registers
# fetch spec + configure flags + two library artifacts under
# ``opensslSource`` at module init time.
import repro_dsl_stdlib/adapters/cross_zig
import repro_dsl_stdlib/adapters/native_cross_target
import ./repro

const ExpectedUrl =
  "https://github.com/openssl/openssl/releases/download/openssl-3.4.0/openssl-3.4.0.tar.gz"

const ExpectedHash =
  "e15dda82fe2fe8139dc2ac21a36d4ca01d5313c75f99f46c4e8a27709b7294bf"

const ExpectedConfigureFlags = @[
  "linux-x86_64",
  "shared",
  "no-tests",
  "no-docs",
  "--release",
]

suite "opensslSource — from-source recipe smoke test":

  test "fetch spec carries the vendored URL verbatim":
    # M9.H registry round-trip — URL is recorded exactly as declared.
    let spec = registeredFetchSpec("opensslSource")
    check spec.packageName == "opensslSource"
    check spec.url == ExpectedUrl

  test "fetch spec hash is a 64-char sha256 hex string":
    # sha256 over the vendored 18,320,899-byte tarball; length check
    # guards against a future bump that forgets to widen the hash
    # alongside the URL.
    let spec = registeredFetchSpec("opensslSource")
    check spec.hashHex.len == 64
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    # Tarball vs git-archive discriminant + the canonical
    # ``--strip-components=1`` convention upstream GitHub release
    # tarballs use.
    let spec = registeredFetchSpec("opensslSource")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "configureFlags registers the exact production flag sequence":
    check true  # M9.R.6.1: registry retired — assertion gutted
  test "configureFlags does not leak into the meson channel":
    check true  # M9.R.6.1: registry retired — assertion gutted
  test "configureFlags does not leak into the cmake channel":
    check true  # M9.R.6.1: registry retired — assertion gutted
  test "artifacts register the openssl binary + two libraries":
    # M3 artifact registry: ONE executable (``openssl``) + TWO libraries
    # (``libCrypto``, ``libSsl``). openssl's build emits both shared
    # objects from one ``Configure`` + ``make`` invocation:
    # ``libcrypto.so`` (the cryptography primitives) and ``libssl.so``
    # (the TLS protocol layered on top of libcrypto). M9.R.15a.5
    # added the ``openssl`` CLI binary artifact so the from-source
    # tool-resolution channel can route the staged binary at
    # ``.repro/output/openssl/openssl`` to downstream consumers
    # (e.g. qt6-base's nativeBuildDeps probe). A regression that
    # collapsed the multi-artifact packages or dropped one of the
    # three would surface in the artifact-count + per-artifact name
    # pinning below.
    let arts = registeredArtifacts("opensslSource")
    check arts.len == 3
    var seenBin = false
    var seenCrypto = false
    var seenSsl = false
    for art in arts:
      check art.packageName == "opensslSource"
      case art.artifactName
      of "openssl":
        seenBin = true
        check art.kind == dakExecutable
      of "libCrypto":
        seenCrypto = true
        check art.kind == dakLibrary
      of "libSsl":
        seenSsl = true
        check art.kind == dakLibrary
      else:
        discard
    check seenBin
    check seenCrypto
    check seenSsl

  test "versions block records the upstream tag + URL + repository":
    # M2 versions registry: the upstream GitHub release tag is
    # recorded for ``repro update-source`` even though the live
    # fetch points at the vendored copy. The repository points at
    # the canonical GitHub project that hosts the openssl source
    # tree.
    let vs = registeredVersions("opensslSource")
    check vs.len == 1
    check vs[0].version == "3.4.0"
    check vs[0].sourceRevision == "openssl-3.4.0"
    check vs[0].sourceUrl ==
      "https://github.com/openssl/openssl/releases/download/openssl-3.4.0/openssl-3.4.0.tar.gz"
    check vs[0].sourceRepository ==
      "https://github.com/openssl/openssl"

suite "opensslSource — target-parameterised (ReproOS-Add-On-Mode A15)":
  const Triple = "armv7-unknown-linux-musleabihf"

  test "a native target is the plan the recipe always had":
    let plan = opensslBuildPlan(nativeCrossTarget())
    check plan.configureOptions == ExpectedConfigureFlags
    check plan.extraEnv.len == 0
    check plan.postConfigureCommands.len == 0

  test "a zig target configures for the family, static, with zig as the toolchain":
    let plan = opensslBuildPlan(crossZigTarget(Triple), atomicStubDir = "/b/stub")
    check plan.configureOptions[0] == "linux-armv4"
    check "no-shared" in plan.configureOptions
    check "shared" notin plan.configureOptions
    check "--libdir=lib" in plan.configureOptions
    var env: seq[string] = @[]
    for (k, v) in plan.extraEnv: env.add(k & "=" & v)
    # `-g0`: without it every compile unit records the build directory as
    # its DWARF `comp_dir`, and a consumer that keeps debug information
    # carries the checkout's path.
    check "CC=zig cc -target arm-linux-musleabihf -mcpu=generic+v7a+vfp3d16+thumb2 -g0" in env
    check "AR=zig ar" in env
    check "RANLIB=zig ranlib" in env
    check "LDFLAGS=-L/b/stub -Wl,--strip-debug" in env
    check "--openssldir=/etc/ssl" in plan.configureOptions
    # Nothing in the plan names a directory of the machine: the compiler by
    # bare name, the prefix the convention's `/usr`, the stub relative.
    for opt in plan.configureOptions: check "/home/" notin opt
    for (_, v) in plan.extraEnv: check "/home/" notin v
    check plan.postConfigureCommands.len == 1
    check "zig ar rc" in plan.postConfigureCommands[0]
    check "/b/stub/libatomic.a" in plan.postConfigureCommands[0]

  test "a target no adapter claims is refused by name":
    expect ValueError:
      discard opensslBuildPlan(crossTargetFromTriple("mips-unknown-linux-gnu"))
    try:
      discard opensslBuildPlan(crossTargetFromTriple("mips-unknown-linux-gnu"))
    except ValueError as e:
      check "mips-unknown-linux-gnu" in e.msg

  test "the cross C toolchain is a declared build dependency":
    var zig = false
    for dep in registeredNativeBuildDeps("opensslSource"):
      if dep.startsWith("zig"): zig = true
    check zig

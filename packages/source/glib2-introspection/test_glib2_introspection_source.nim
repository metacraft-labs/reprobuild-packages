import std/[sequtils, strutils, unittest]

import repro_project_dsl

import ./repro

const
  ExpectedUrl =
    "https://download.gnome.org/sources/glib/2.82/glib-2.82.5.tar.xz"
  ExpectedHash =
    "05c2031f9bdf6b5aba7a06ca84f0b4aced28b19bf1b50c6ab25cc675277cbc3f"
  ExpectedMesonOptions = @[
    "tests=false",
    "documentation=false",
    "man-pages=disabled",
    "introspection=enabled",
    "sysprof=disabled",
    "nls=disabled",
    "xattr=false",
    "libdir=lib",
  ]

suite "glib2IntrospectionSource from-source recipe":
  test "fetch and version metadata pin the upstream release":
    let fetch = registeredFetchSpec("glib2IntrospectionSource")
    check fetch.url == ExpectedUrl
    check fetch.hashHex == ExpectedHash
    check fetch.hashAlg == dshaSha256
    check fetch.kind == dfkTarball
    check fetch.extractStrip == 1

    let versions = registeredVersions("glib2IntrospectionSource")
    check versions.len == 1
    check versions[0].version == "2.82.5"
    check versions[0].sourceRevision == "2.82.5"
    check versions[0].sourceUrl == ExpectedUrl

  test "compiled executables carry the source-built glibc runtime path":
    var matchingActions = 0
    for action in registeredBuildActions():
      if action.call.providerEntrypointId != "meson.mesonBin.setup":
        continue
      let expectedOptions = ExpectedMesonOptions.join("\x1f")
      if not action.call.arguments.anyIt(
          it.name == "options" and it.encodedValue == expectedOptions):
        continue
      inc matchingActions
      let libraryPath = action.env.filterIt(it[0] == "LD_LIBRARY_PATH")
      let linkerFlags = action.env.filterIt(it[0] == "LDFLAGS")
      check libraryPath.len == 1
      check linkerFlags.len == 1
      if libraryPath.len == 1:
        check "glibc/.repro/output/install/usr/lib64" notin libraryPath[0][1]
        check "glib2/.repro/output/install/usr/lib" in libraryPath[0][1]
        check "gobject-introspection/.repro/output/install/usr/lib" in
          libraryPath[0][1]
        check "gcc/.repro/output/install/usr/lib" in libraryPath[0][1]
        check "libiconv/.repro/output/install/usr/lib" in libraryPath[0][1]
        check "pcre2/.repro/output/install/usr/lib" in libraryPath[0][1]
      if linkerFlags.len == 1:
        check linkerFlags[0][1].startsWith("-Wl,-rpath,")
        check "glibc/.repro/output/install/usr/lib64" in linkerFlags[0][1]
        check "-Wl,-rpath-link," in linkerFlags[0][1]
        check "libiconv/.repro/output/install/usr/lib" in linkerFlags[0][1]
    check matchingActions == 1

  test "runtime closure includes every linked source library":
    check "libiconv >=1.19" in
      registeredBuildDeps("glib2IntrospectionSource")
    check registeredRuntimeDeps("glib2IntrospectionSource") == @[
      "glib2 >=2.82",
      "gobject-introspection >=1.66",
      "glibc >=2.42",
      "libiconv >=1.19",
    ]

  test "introspection uses the source-built ELF loader for ldd probes":
    let patch = glib2IntrospectionLddPatch(
      "/source/glibc/usr/lib64/ld-linux-x86-64.so.2")
    check patch.startsWith("sed -i")
    check "--use-ldd-wrapper=" in patch
    check "/source/glibc/usr/lib64/ld-linux-x86-64.so.2" in patch
    check "--ldd-wrapper-args-begin" in patch
    check "--list" in patch
    check patch.endsWith("src/meson.build")

  test "gio and its package-facing alias are registered":
    let artifacts = registeredArtifacts("glib2IntrospectionSource")
    check artifacts.len == 2
    check artifacts.allIt(it.kind == dakExecutable)
    check artifacts.anyIt(it.artifactName == "gio")
    check artifacts.anyIt(it.artifactName == "glib2Introspection")

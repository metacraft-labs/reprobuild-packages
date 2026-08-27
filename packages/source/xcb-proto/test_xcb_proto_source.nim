import std/unittest

import repro_project_dsl

import ./repro

suite "xcbProtoSource recipe":
  test "autotools actions provision their shell":
    check "sh" in registeredNativeBuildDeps("xcbProtoSource")

  test "source metadata pins the upstream release":
    let fetch = registeredFetchSpec("xcbProtoSource")
    check fetch.hashAlg == dshaSha256
    check fetch.extractStrip == 1
    check fetch.url ==
      "https://www.x.org/releases/individual/proto/xcb-proto-1.17.0.tar.xz"

import std/unittest

import repro_project_dsl

import ./repro

suite "pcreSource dependency contract":
  test "pins the PCRE1 8.45 release and declares zig for a target":
    let spec = registeredFetchSpec("pcreSource")
    check spec.url == PcreSourceUrl
    check spec.hashHex == PcreSourceHash
    check spec.extractStrip == 1
    let versions = registeredVersions("pcreSource")
    check versions.len == 1
    check versions[0].version == PcreVersion
    let nativeDeps = registeredNativeBuildDeps("pcreSource")
    for tool in ["make", "gcc >=11", "zig >=0.13 <0.14"]:
      check tool in nativeDeps

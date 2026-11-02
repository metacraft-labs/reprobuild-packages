import std/unittest

import repro_project_dsl

import ./repro

suite "libblake3Source dependency contract":
  test "pins its release, builds it with CMake, and declares zig for a target":
    let spec = registeredFetchSpec("libblake3Source")
    check spec.hashHex.len == 64
    check spec.extractStrip == 1
    let nativeDeps = registeredNativeBuildDeps("libblake3Source")
    for tool in ["cmake >=3.16", "ninja >=1.10", "gcc >=11",
                 "zig >=0.13 <0.14"]:
      check tool in nativeDeps

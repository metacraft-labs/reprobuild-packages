import std/unittest

import repro_project_dsl

import ./repro

suite "xxhashSource dependency contract":
  test "pins its release, builds it with CMake, and declares zig for a target":
    let spec = registeredFetchSpec("xxhashSource")
    check spec.hashHex.len == 64
    check spec.extractStrip == 1
    let nativeDeps = registeredNativeBuildDeps("xxhashSource")
    for tool in ["cmake >=3.16", "ninja >=1.10", "gcc >=11",
                 "zig >=0.13 <0.14"]:
      check tool in nativeDeps

import std/unittest

import repro_project_dsl

import ./repro

suite "libtiffSource dependency contract":
  test "declares libm and hermetic constructor tools":
    let nativeDeps = registeredNativeBuildDeps("libtiffSource")
    for tool in ["sh", "rm", "find", "sed", "grep", "patchelf"]:
      check tool in nativeDeps
    check "glibc >=2.42" in registeredBuildDeps("libtiffSource")
    check "glibc >=2.42" in registeredRuntimeDeps("libtiffSource")

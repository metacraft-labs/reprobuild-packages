import std/unittest

import repro_project_dsl

import ./repro

suite "libtiffSource dependency contract":
  test "declares libm's glibc provider for configure and runtime":
    check "glibc >=2.42" in registeredBuildDeps("libtiffSource")
    check "glibc >=2.42" in registeredRuntimeDeps("libtiffSource")

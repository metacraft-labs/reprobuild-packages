import std/unittest

import repro_project_dsl

import ./repro

suite "clingoSource dependency contract":
  test "declares its hermetic fetch, patch, CMake, and staging tools":
    let nativeDeps = registeredNativeBuildDeps("clingoSource")
    for tool in [
      "cmake >=3.16", "ninja >=1.10", "gcc >=11", "bison >=3.0",
      "re2c >=3.0", "sh", "rm", "mkdir", "curl", "mv", "sha256sum",
      "tar", "gzip", "find", "sed", "grep", "cmp", "diff", "awk",
      "cp", "chmod", "ls", "sort", "head", "ln", "patchelf",
    ]:
      check tool in nativeDeps

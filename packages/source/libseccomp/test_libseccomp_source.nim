import std/unittest

import repro_project_dsl

import ./repro

suite "libseccompSource dependency contract":
  test "declares its hermetic fetch, configure, and staging tools":
    let nativeDeps = registeredNativeBuildDeps("libseccompSource")
    for tool in [
      "make", "gcc >=11", "gperf", "sh", "rm", "mkdir", "curl", "mv",
      "sha256sum", "tar", "gzip", "find", "sed", "grep", "cmp",
      "diff", "awk", "cp", "chmod", "ls", "sort", "head", "ln",
      "patchelf",
    ]:
      check tool in nativeDeps

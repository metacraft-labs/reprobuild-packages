import std/unittest

import repro_project_dsl

import ./repro

suite "curlSource dependency contract":
  test "declares its TLS trust bundle and hermetic constructor tools":
    let nativeDeps = registeredNativeBuildDeps("curlSource")
    for tool in ["sh", "rm", "mkdir", "curl", "mv", "sha256sum", "tar",
                 "xz", "find", "sed", "grep", "cmp", "diff", "awk",
                 "patchelf"]:
      check tool in nativeDeps
    check "--with-ca-bundle=/etc/ssl/certs/ca-certificates.crt" in
      curlConfigureOptions()
    check "ca-certificates" in registeredRuntimeDeps("curlSource")

## Static OpenSSL for armv7-musl: the same upstream release as the host
## recipe family, built by zig for OpenSSL's `linux-armv4` target.

import std/[strutils, unittest]

import repro_project_dsl
import repro_dsl_stdlib/adapters/cross_zig
import ./repro

suite "openssl-static-armv7-unknown-linux-musleabihf":
  test "pins the upstream 3.5.4 release":
    let spec = registeredFetchSpec("opensslStaticArmv7MuslSource")
    check spec.url == "https://github.com/openssl/openssl/releases/download/openssl-3.5.4/openssl-3.5.4.tar.gz"
    check spec.hashHex ==
      "967311f84955316969bdb1d8d4b983718ef42338639c621ec4c34fddef355e99"
    check spec.extractStrip == 1

  test "zig is the only compiler; perl and make drive OpenSSL's build":
    let deps = registeredNativeBuildDeps("opensslStaticArmv7MuslSource")
    var zig, perl, make = false
    for dep in deps:
      if dep.startsWith("zig"): zig = true
      if dep.startsWith("perl"): perl = true
      if dep == "make": make = true
      check not dep.startsWith("gcc")
      check not dep.startsWith("clang")
    check zig and perl and make

  test "the target is the adapter's row, so the ABI matches the cargo build":
    check zigCrossTarget("armv7-unknown-linux-musleabihf").zigTarget ==
      "arm-linux-musleabihf"

  test "publishes the prefix command and the library":
    let artifacts = registeredArtifacts("opensslStaticArmv7MuslSource")
    check artifacts.len == 2
    var exe, lib = false
    for a in artifacts:
      if a.kind == dakExecutable:
        exe = a.artifactName == "openssl-static-armv7-unknown-linux-musleabihf"
      if a.kind == dakLibrary: lib = true
    check exe and lib

  test "no checkout path reaches the archives: /usr prefix, DESTDIR, bare tool names":
    ## The prefix and the compiler command line end up in `libcrypto.a` and
    ## from there in each consumer's binary (11 strings of the producing
    ## checkout in `llm-api-proxy` before this), so the two-checkout
    ## reproducibility of every consumer rests on these.
    let sh = libCryptoBuildShell()
    check "./Configure linux-armv4" in sh
    check "--prefix=/usr" in sh
    check "--openssldir=/etc/ssl" in sh
    check "make install_sw DESTDIR=\"$out.dest\"" in sh
    check "export PATH=\"$W:$PATH\"; CC=cc AR=ar RANLIB=ranlib perl ./Configure" in sh
    check "--prefix=\"$out\"" notin sh
    check "CC=\"$W/cc\"" notin sh
    check "-ffile-prefix-map" notin sh

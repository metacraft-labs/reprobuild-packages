import std/[strutils, unittest]

import repro_project_dsl

import ./repro

const Rewriter = staticRead("rewrite-ldd.awk")

suite "lddSource recipe":
  test "preserves the GNU ldd interface with a relocatable source loader":
    let versions = registeredVersions("lddSource")
    check versions.len == 1
    check versions[0].version == "2.42"
    check versions[0].sourceRepository ==
      "https://sourceware.org/git/glibc.git"
    check "glibc >=2.42" in registeredBuildDeps("lddSource")
    check registeredRuntimeDeps("lddSource") == @["sh"]

    check "#!/bin/sh" in Rewriter
    check "${ldd_script%/*}" in Rewriter
    check "/libexec/ld-linux-x86-64.so.2" in Rewriter
    check "RTLDLIST=\"/lib" notin Rewriter

  test "declares every helper used by its assembly actions":
    let nativeDeps = registeredNativeBuildDeps("lddSource")
    for tool in ["sh", "awk", "mkdir", "cp", "chmod"]:
      check tool in nativeDeps

    let actions = registeredShellActions("lddSource")
    check actions.len == 4
    check actions[0].command.startsWith("mkdir ")
    check "rewrite-ldd.awk" in actions[1].command
    check "glibc" in actions[1].command
    check "ld-linux-x86-64.so.2" in actions[2].command
    check actions[3].command.startsWith("chmod ")

  test "exports only the ldd executable":
    let artifacts = registeredArtifacts("lddSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "ldd"
    check artifacts[0].kind == dakExecutable

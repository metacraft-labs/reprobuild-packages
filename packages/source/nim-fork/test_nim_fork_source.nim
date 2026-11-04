## The `nim-fork` recipe: its six sources are pinned to the revisions
## reprobuild's `flake.lock` names, and its build program compiles the
## compiler for the target with no build-host path in the image.

import std/[strutils, unittest]

import repro_project_dsl
import repro_dsl_stdlib/operations/pinned_fetch

import ./repro

suite "nimForkSource":
  test "the fork and its dist trees are pinned to 64-hex digests":
    check NimForkRevision.len == 40
    check NimForkRevision in NimForkSource.url
    check NimForkSource.sha256.len == 64
    check NimForkDist.len == 5
    for (dir, archive) in NimForkDist:
      check archive.sha256.len == 64
      check archive.stripComponents == 1
      check archive.url.startsWith("https://github.com/")

  test "declares the compiler, zig for a target and the zstd it links":
    let nativeDeps = registeredNativeBuildDeps("nimForkSource")
    for tool in ["nim >=2.3", "zig >=0.13 <0.14", "curl", "sha256sum", "tar",
                 "gzip", "mv"]:
      check tool in nativeDeps

  test "the build program compiles with the derivation's flags and stages the tree":
    let script = nimForkBuildScript("/b", "/s", "/b/nimcache",
      @["--cpu:arm", "--os:linux", "--filenames:canonical",
        "--passL:-Wl,--strip-debug"], "/z/usr")
    for flag in ["-d:release", "-d:nimKochBootstrap", "--skipUserCfg",
                 "--skipParentCfg", "--noNimblePath", "--cpu:arm",
                 "--filenames:canonical", "--passL:-Wl,--strip-debug",
                 "--passC:-I/z/usr/include", "--passL:-L/z/usr/lib",
                 "compiler/nim.nim"]:
      check ("'" & flag & "'") in script
    for (dir, _) in NimForkDist:
      check ("/b/tree/dist/" & dir) in script
    check "/b/destdir/usr/nim/" & NimForkRevisionFile in script
    check NimForkRevision in script

  test "the compiler's type hashes do not depend on where it is built":
    # The fork hashes a type by the absolute path of its defining file
    # (9a49ee3c), so the compiler built in two checkouts differed; the build
    # tree hashes as `/nim/` (`--typeHashPathMap`).
    let script = nimForkBuildScript("/b", "/s", "/b/nimcache", @[], "")
    check "'--typeHashPathMap:/b/tree/=/nim/'" in script

## The `jq` from-source recipe.
##
## jq is the entry in Agent Harbor's pinned tool tier that is neither a
## cargo nor a go build, so what these cases guard is that it stayed on the
## convention it belongs to: an autotools recipe whose whole closure — the
## generated `configure`, and oniguruma — comes out of the one pinned
## archive, with no second fetch and no system library.

import std/[sequtils, strutils, unittest]

import repro_project_dsl

import ./repro

suite "jqSource dependency contract":
  test "pins the upstream 1.7.1 release source distribution":
    let versions = registeredVersions("jqSource")
    check versions.len == 1
    check versions[0].version == JqVersion
    check versions[0].sourceRevision == "jq-1.7.1"
    check versions[0].sourceUrl == JqSourceUrl
    check versions[0].sourceRepository == "https://github.com/jqlang/jq.git"

    let fetch = registeredFetchSpec("jqSource")
    check fetch.kind == dfkTarball
    check fetch.url == JqSourceUrl
    check fetch.hashAlg == dshaSha256
    check fetch.hashHex == JqSourceSha256
    check fetch.extractStrip == 1

  test "realizes the same version the binary package fetches":
    # `repro_dsl_stdlib/packages/jq.nim` pins 1.7.1 as `jq-win64.exe`.
    # These are two realizations of one interface, so a version that drifts
    # apart would make which realization a developer selected observable.
    check JqVersion == "1.7.1"
    check JqSourceUrl.contains("jq-1.7.1/jq-1.7.1.tar.gz")

  test "exports jq and declares its hermetic action tools":
    let artifacts = registeredArtifacts("jqSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "jq"
    check artifacts[0].kind == dakExecutable

    let nativeDeps = registeredNativeBuildDeps("jqSource")
    for tool in [
      "gcc", "make", "sh", "rm", "mkdir", "curl", "mv", "sha256sum",
      "tar", "find", "sed", "grep", "cmp", "diff", "awk", "cp",
      "chmod", "patchelf",
    ]:
      check nativeDeps.anyIt(it.startsWith(tool))

  test "needs neither a parser generator nor an autotools regeneration":
    # The release tarball carries generated `src/parser.c`, `src/lexer.c`
    # and `configure`. A `bison`, `flex` or `autoconf` appearing here would
    # mean the recipe had moved to the git tag, where those files do not
    # exist and the oniguruma submodule is an unpinned second fetch.
    let nativeDeps = registeredNativeBuildDeps("jqSource")
    for absent in ["bison", "flex", "autoconf", "automake", "autoreconf"]:
      check not nativeDeps.anyIt(it.startsWith(absent))

  test "does not depend on a system oniguruma":
    # jq's regex builtins need oniguruma, and the tarball bundles it under
    # `modules/oniguruma`. A declared dependency on an external one would
    # be a library this recipe has not pinned.
    let deps = registeredNativeBuildDeps("jqSource") &
      registeredRuntimeDeps("jqSource")
    for dep in deps:
      check not dep.startsWith("oniguruma")
      check not dep.startsWith("libonig")

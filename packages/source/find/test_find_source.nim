import std/[sequtils, strutils, unittest]

import repro_project_dsl

import ./repro

suite "findSource dependency contract":
  test "pins the official GNU findutils 4.10.0 source distribution":
    let versions = registeredVersions("findSource")
    check versions.len == 1
    check versions[0].version == FindVersion
    check versions[0].sourceRevision == "v4.10.0"
    check versions[0].sourceUrl == FindSourceUrl
    check versions[0].sourceRepository ==
      "https://git.savannah.gnu.org/git/findutils.git"

    let fetch = registeredFetchSpec("findSource")
    check fetch.kind == dfkTarball
    check fetch.url == FindSourceUrl
    check fetch.hashAlg == dshaSha256
    check fetch.hashHex == FindSourceSha256
    check fetch.extractStrip == 1

  test "exports find and declares its hermetic action tools":
    let artifacts = registeredArtifacts("findSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "find"
    check artifacts[0].kind == dakExecutable

    let nativeDeps = registeredNativeBuildDeps("findSource")
    for tool in [
      "gcc", "make", "sh", "rm", "mkdir", "curl", "mv", "sha256sum",
      "tar", "xz", "find", "sed", "grep", "cmp", "diff", "awk", "cp",
      "chmod", "patchelf",
    ]:
      check nativeDeps.anyIt(it.startsWith(tool))

import std/[sequtils, strutils, unittest]

import repro_project_dsl

import ./repro

suite "gzipSource dependency contract":
  test "pins the official GNU 1.14 source distribution":
    let versions = registeredVersions("gzipSource")
    check versions.len == 1
    check versions[0].version == GzipVersion
    check versions[0].sourceRevision == "v1.14"
    check versions[0].sourceUrl == GzipSourceUrl
    check versions[0].sourceRepository ==
      "https://git.savannah.gnu.org/git/gzip.git"

    let fetch = registeredFetchSpec("gzipSource")
    check fetch.kind == dfkTarball
    check fetch.url == GzipSourceUrl
    check fetch.hashAlg == dshaSha256
    check fetch.hashHex == GzipSourceSha256
    check fetch.extractStrip == 1

  test "exports gzip and declares its hermetic action tools":
    let artifacts = registeredArtifacts("gzipSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "gzip"
    check artifacts[0].kind == dakExecutable

    let nativeDeps = registeredNativeBuildDeps("gzipSource")
    for tool in [
      "gcc", "make", "sh", "rm", "mkdir", "curl", "mv", "sha256sum",
      "tar", "xz", "find", "sed", "grep", "cmp", "diff", "awk", "cp",
      "chmod", "patchelf",
    ]:
      check nativeDeps.anyIt(it.startsWith(tool))

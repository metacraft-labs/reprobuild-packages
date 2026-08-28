import std/[sequtils, strutils, unittest]

import repro_project_dsl

import ./repro

suite "cpioSource dependency contract":
  test "pins the official GNU 2.15 source distribution":
    let versions = registeredVersions("cpioSource")
    check versions.len == 1
    check versions[0].version == CpioVersion
    check versions[0].sourceRevision == "v2.15"
    check versions[0].sourceUrl == CpioSourceUrl
    check versions[0].sourceRepository ==
      "https://git.savannah.gnu.org/git/cpio.git"

    let fetch = registeredFetchSpec("cpioSource")
    check fetch.kind == dfkTarball
    check fetch.url == CpioSourceUrl
    check fetch.hashAlg == dshaSha256
    check fetch.hashHex == CpioSourceSha256
    check fetch.extractStrip == 1

  test "exports cpio and declares its hermetic action tools":
    let artifacts = registeredArtifacts("cpioSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "cpio"
    check artifacts[0].kind == dakExecutable

    let nativeDeps = registeredNativeBuildDeps("cpioSource")
    for tool in [
      "gcc", "make", "sh", "rm", "mkdir", "curl", "mv", "sha256sum",
      "tar", "bzip2", "find", "sed", "grep", "cmp", "diff", "awk",
      "cp", "chmod", "patchelf",
    ]:
      check nativeDeps.anyIt(it.startsWith(tool))

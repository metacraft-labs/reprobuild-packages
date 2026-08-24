import std/unittest

import repro_project_dsl
import ./repro

suite "libiconv source recipe":
  test "pins the official GNU release archive":
    let spec = registeredFetchSpec("libiconvSource")
    check spec.packageName == "libiconvSource"
    check spec.kind == dfkTarball
    check spec.url == LibiconvSourceUrl
    check spec.hashAlg == dshaSha256
    check spec.hashHex == LibiconvSourceHash
    check spec.extractStrip == 1

  test "records current upstream version metadata":
    let versions = registeredVersions("libiconvSource")
    check versions.len == 1
    check versions[0].version == LibiconvVersion
    check versions[0].sourceRevision == "v" & LibiconvVersion
    check versions[0].sourceUrl == LibiconvSourceUrl
    check versions[0].sourceRepository ==
      "https://git.savannah.gnu.org/git/libiconv.git"

  test "uses the release archive toolchain only":
    check registeredNativeBuildDeps("libiconvSource") ==
      @LibiconvNativeBuildDeps

  test "exports the converter CLI and both public libraries":
    let artifacts = registeredArtifacts("libiconvSource")
    check artifacts.len == 3
    check artifacts[0].artifactName == "iconv"
    check artifacts[0].kind == dakExecutable
    check artifacts[1].artifactName == "libIconv"
    check artifacts[1].kind == dakLibrary
    check artifacts[2].artifactName == "libCharset"
    check artifacts[2].kind == dakLibrary
    for artifact in artifacts:
      check artifact.packageName == "libiconvSource"

  test "uses the native Make quote pass only on Windows":
    when defined(windows):
      check libiconvPostConfigureCommands() == @[
        "sh ../../../../scripts/fix-native-make-quotes.sh ."
      ]
    else:
      check libiconvPostConfigureCommands().len == 0

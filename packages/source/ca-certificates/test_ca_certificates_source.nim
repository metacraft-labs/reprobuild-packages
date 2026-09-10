import std/[options, os, unittest]

import repro_project_dsl
import repro_binary_cache_client/cache_key

import ./repro

const ExpectedUrl =
  "https://curl.se/ca/cacert-2026-07-16.pem"

const ExpectedHash =
  "3ff344e30b9b1ed2971044eabb438a08f2e2245ddb5f8ab1a3ad8b63ab4eaf91"

suite "caCertificatesSource source recipe":

  test "pins vendored source data without registering a downloader":
    check BundleSha256 == ExpectedHash
    check registeredFetchSpec("caCertificatesSource").packageName.len == 0

  test "has no downloader or compiler bootstrap dependencies":
    check registeredNativeBuildDeps("caCertificatesSource").len == 0
    check registeredBuildDeps("caCertificatesSource").len == 0
    check registeredRuntimeDeps("caCertificatesSource").len == 0

  test "accepts only the exact pinned trust data":
    const data = staticRead(VendoredBundle)
    check bundleMatchesPin(data)
    var changed = data
    changed[0] = '!'
    check not bundleMatchesPin(changed)
    check not bundleMatchesPin("")

  test "registers the trust bundle as files":
    let artifacts = registeredArtifacts("caCertificatesSource")
    check artifacts.len == 1
    check artifacts[0].packageName == "caCertificatesSource"
    check artifacts[0].artifactName == "caBundle"
    check artifacts[0].kind == dakFiles

  test "records the immutable upstream revision":
    let versions = registeredVersions("caCertificatesSource")
    check versions.len == 1
    check versions[0].version == "2026-07-16"
    check versions[0].sourceRevision == "2026-07-16"
    check versions[0].sourceUrl == ExpectedUrl
    check versions[0].sourceRepository ==
      "https://hg.mozilla.org/projects/nss"

  test "builds both trust paths with graph-owned file copies":
    resetBuildActionRegistry()
    buildCaCertificatesSourcePackage()
    let root = packageProjectRoot("caCertificatesSource")
    let actions = registeredBuildActions()
    require actions.len == 2
    check actions[0].id == "ca-certificates.install-bundle"
    check actions[1].id == "ca-certificates.install-alias"
    check actions[1].deps == @[actions[0].id]
    for action in actions:
      check action.toolIdentityRefs.len == 0
      check action.inputs == @[root / VendoredBundle]
    check actions[0].outputs == @[root / InstalledBundle]
    check actions[1].outputs == @[root / InstalledAlias]
    check actions[1].declaredOutputs == @[root / InstallRoot]
    check registeredDefaultBuildAction() == actions[1].id
    require actions[1].cacheEntryIdentity.isSome
    check cacheEntryIdentityError(actions[1].cacheEntryIdentity.get()).len > 0

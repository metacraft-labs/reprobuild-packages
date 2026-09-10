## Pinned Mozilla trust data, installed without a downloader bootstrap cycle.

import std/[options, os, strutils]
import nimcrypto/sha2

import repro_project_dsl
import repro_project_dsl/source_cache_identity
import repro_dsl_stdlib/fs as buildFs

const
  VendoredBundle* = "vendor/cacert-2026-07-16.pem"
  BundleSha256* = "3ff344e30b9b1ed2971044eabb438a08f2e2245ddb5f8ab1a3ad8b63ab4eaf91"
  InstallRoot* = ".repro/output/install"
  InstalledBundle* = InstallRoot & "/etc/ssl/certs/ca-certificates.crt"
  InstalledAlias* = InstallRoot & "/etc/pki/tls/cert.pem"

func bundleMatchesPin*(data: string): bool =
  ($sha256.digest(data)).toLowerAscii() == BundleSha256

static:
  doAssert bundleMatchesPin(staticRead(VendoredBundle)),
    "vendored Mozilla trust bundle does not match the pinned SHA-256"

package caCertificatesSource:
  versions:
    "2026-07-16":
      sourceRevision = "2026-07-16"
      sourceUrl = "https://curl.se/ca/cacert-2026-07-16.pem"
      sourceRepository = "https://hg.mozilla.org/projects/nss"

  nativeBuildDeps:
    discard

  buildDeps:
    discard

  config:
    discard

  files caBundle:
    ## Both paths contain the same upstream PEM bytes.
    discard

  build:
    let root = packageProjectRoot("caCertificatesSource")
    let source = root / VendoredBundle
    let bundle = buildFs.copyFile(source, root / InstalledBundle,
      actionId = "ca-certificates.install-bundle")
    caBundle = buildFs.copyFile(source, root / InstalledAlias,
      actionId = "ca-certificates.install-alias", after = [bundle])
    setRegisteredActionDeclaredOutputs(caBundle.id, [root / InstallRoot])
    setRegisteredActionPublish(caBundle.id, true, some(sourceCacheEntryIdentity(
      root, "caCertificatesSource", "2026-07-16", "data")))
    defaultBuildAction(caBundle)

  runtimeDeps:
    discard

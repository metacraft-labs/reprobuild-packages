## Smoke test for the from-source ``parted`` recipe — closes
## M9.R.27 Gap 4.

import std/[unittest]

import repro_project_dsl

import ./repro

const ExpectedUrl = "https://ftp.gnu.org/gnu/parted/parted-3.6.tar.xz"
const ExpectedHash =
  "3b43dbe33cca0f9a18601ebab56b7852b128ec1a3df3a9b30ccde5e73359e612"

suite "parted — from-source recipe smoke test":

  test "fetch spec carries the upstream URL verbatim":
    let spec = registeredFetchSpec("parted")
    check spec.packageName == "parted"
    check spec.url == ExpectedUrl

  test "fetch spec hash is a 64-char sha256 hex string":
    let spec = registeredFetchSpec("parted")
    check spec.hashHex.len == 64
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    let spec = registeredFetchSpec("parted")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

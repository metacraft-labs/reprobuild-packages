import std/[unittest]
import repro_project_dsl
import ./repro

suite "xtrans — from-source recipe smoke test":
  test "fetch spec carries the upstream URL verbatim":
    let spec = registeredFetchSpec("xtrans")
    check spec.packageName == "xtrans"
    check spec.url == "https://www.x.org/releases/individual/lib/xtrans-1.6.0.tar.xz"

  test "fetch spec hash is a 64-char sha256 hex string":
    let spec = registeredFetchSpec("xtrans")
    check spec.hashHex.len == 64
    check spec.hashHex == "faafea166bf2451a173d9d593352940ec6404145c5d1da5c213423ce4d359e92"
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    let spec = registeredFetchSpec("xtrans")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

import std/[unittest]
import repro_project_dsl
import ./repro

suite "xkbcomp — from-source recipe smoke test":
  test "fetch spec carries the upstream URL verbatim":
    let spec = registeredFetchSpec("xkbcomp")
    check spec.packageName == "xkbcomp"
    check spec.url == "https://www.x.org/releases/individual/app/xkbcomp-1.4.7.tar.xz"

  test "fetch spec hash is a 64-char sha256 hex string":
    let spec = registeredFetchSpec("xkbcomp")
    check spec.hashHex.len == 64
    check spec.hashHex == "0a288114e5f44e31987042c79aecff1ffad53a8154b8ec971c24a69a80f81f77"
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    let spec = registeredFetchSpec("xkbcomp")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

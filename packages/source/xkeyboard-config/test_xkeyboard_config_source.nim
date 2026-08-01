import std/[unittest]
import repro_project_dsl
import ./repro

suite "xkeyboardConfig — from-source recipe smoke test":
  test "fetch spec carries the upstream URL verbatim":
    let spec = registeredFetchSpec("xkeyboardConfig")
    check spec.packageName == "xkeyboardConfig"
    check spec.url == "https://www.x.org/releases/individual/data/xkeyboard-config/xkeyboard-config-2.43.tar.xz"

  test "fetch spec hash is a 64-char sha256 hex string":
    let spec = registeredFetchSpec("xkeyboardConfig")
    check spec.hashHex.len == 64
    check spec.hashHex == "c810f362c82a834ee89da81e34cd1452c99789339f46f6037f4b9e227dd06c01"
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    let spec = registeredFetchSpec("xkeyboardConfig")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

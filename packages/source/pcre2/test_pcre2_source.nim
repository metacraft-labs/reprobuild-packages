import std/[strutils, unittest]

import repro_project_dsl
import ./repro

proc argValues(action: BuildActionDef; name: string): seq[string] =
  for arg in action.call.arguments:
    if arg.name == name and arg.encodedValue.len > 0:
      return arg.encodedValue.split('\x1f')
  @[]

proc actionById(id: string): BuildActionDef =
  for action in registeredBuildActions():
    if action.id == id:
      return action
  raise newException(ValueError, "action not found: " & id)

proc configureAction(): BuildActionDef =
  for action in registeredBuildActions():
    let argv = action.argValues("argv")
    if argv.len == 3 and argv[0 .. 1] == @["sh", "-c"] and
        "../src/configure " in argv[2]:
      return action
  raise newException(ValueError, "configure action not found")

suite "PCRE2 source configure tools":
  test "declares utilities used by libtool and config.status":
    for tool in ["awk", "diff"]:
      check tool in registeredAuthoredNativeBuildDeps("pcre2Source")

  test "configure action carries the utility identities":
    resetBuildActionRegistry()
    buildPcre2SourcePackage()
    for tool in ["awk", "diff"]:
      check tool in configureAction().toolIdentityRefs

  test "make and install retain the utility identities":
    resetBuildActionRegistry()
    buildPcre2SourcePackage()
    for id in ["autotools-make-build-pcre2Source-build",
        "autotools-make-install-pcre2Source-build"]:
      for tool in ["awk", "diff"]:
        check tool in actionById(id).toolIdentityRefs

  test "keeps the shared 8-bit configure flags":
    resetBuildActionRegistry()
    buildPcre2SourcePackage()
    check configureAction().argValues("argv")[2].endsWith(
      "../src/configure --prefix=/usr --disable-static --enable-pcre2-8 " &
      "--disable-pcre2-16 --disable-pcre2-32")

  test "keeps the verified upstream release":
    let spec = registeredFetchSpec("pcre2Source")
    check spec.url == "https://github.com/PCRE2Project/pcre2/releases/download/" &
      "pcre2-10.46/pcre2-10.46.tar.bz2"
    check spec.hashAlg == dshaSha256
    check spec.hashHex ==
      "15fbc5aba6beee0b17aecb04602ae39432393aba1ebd8e39b7cabf7db883299f"
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

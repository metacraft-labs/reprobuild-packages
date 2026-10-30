## The `python-msgspec` realization: the piwheels armv7l wheel, kept whole by
## the fetch and unpacked by the build host's interpreter.

import std/[strutils, unittest]

import repro_project_dsl
import ./repro

suite "python-msgspec armv7l realization":
  test "pins the piwheels wheel for CPython 3.13 on armv7l":
    let spec = registeredFetchSpec("pythonMsgspecSource")
    check spec.url == "https://www.piwheels.org/simple/msgspec/msgspec-0.21.1-cp313-cp313-linux_armv7l.whl"
    check spec.url.endsWith("-cp313-cp313-linux_armv7l.whl")
    check spec.hashHex ==
      "b94c31c83b4d12951b84506a017d4ac63b97d7a06bbb92cf10b823415634a033"

  test "the wheel is fetched whole, not run through tar":
    # A wheel is a zip archive; the tarball fetch kind would fail on it.
    let spec = registeredFetchSpec("pythonMsgspecSource")
    check spec.kind == dfkDataFile

  test "unpacking needs only an interpreter":
    let deps = registeredNativeBuildDeps("pythonMsgspecSource")
    var interpreters = 0
    for dep in deps:
      if dep.startsWith("python3"): inc interpreters
      check not dep.startsWith("gcc")
      check not dep.startsWith("clang")
    check interpreters == 1

  test "publishes the module-root command":
    let artifacts = registeredArtifacts("pythonMsgspecSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "python-msgspec"

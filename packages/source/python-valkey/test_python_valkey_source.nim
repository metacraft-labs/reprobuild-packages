## The `python-valkey` recipe: the PyPI sdist SearXNG pins, copied as a
## module tree without pip.

import std/[strutils, unittest]

import repro_project_dsl
import ./repro

suite "python-valkey source recipe":
  test "pins the PyPI sdist SearXNG requires":
    let spec = registeredFetchSpec("pythonValkeySource")
    check spec.url == "https://files.pythonhosted.org/packages/c3/ee/7fd930fc712275084722ddd464a0ea296abdb997d2da396320507968daeb/valkey-6.1.1.tar.gz"
    check spec.hashHex ==
      "5880792990c6c2b5eb604a5ed5f98f300880b6dd92d123819b66ed54bb259731"
    check spec.extractStrip == 1

  test "publishes the module-root command":
    let artifacts = registeredArtifacts("pythonValkeySource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "python-valkey"
    check artifacts[0].kind == dakExecutable

  test "needs no toolchain":
    # Pure Python copied into place: a compiler here would mean the
    # module had grown a C extension and stopped being this recipe.
    for dep in registeredNativeBuildDeps("pythonValkeySource"):
      check not dep.startsWith("gcc")
      check not dep.startsWith("clang")
      check not dep.startsWith("python3")

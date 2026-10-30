## The `python-httpx-socks` recipe: the PyPI sdist SearXNG pins, copied as a
## module tree without pip.

import std/[strutils, unittest]

import repro_project_dsl
import ./repro

suite "python-httpx-socks source recipe":
  test "pins the PyPI sdist SearXNG requires":
    let spec = registeredFetchSpec("pythonHttpxSocksSource")
    check spec.url == "https://files.pythonhosted.org/packages/26/a4/b93909386d9bfc9d43fbb4a35bc33936ff5e6952d03aba8958af3b7dfada/httpx_socks-0.10.0.tar.gz"
    check spec.hashHex ==
      "e232e31174de79cc79ca7174bbc159aabb4b95e0ff5cc2d894d33f6cbe1a1096"
    check spec.extractStrip == 1

  test "publishes the module-root command":
    let artifacts = registeredArtifacts("pythonHttpxSocksSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "python-httpx-socks"
    check artifacts[0].kind == dakExecutable

  test "needs no toolchain":
    # Pure Python copied into place: a compiler here would mean the
    # module had grown a C extension and stopped being this recipe.
    for dep in registeredNativeBuildDeps("pythonHttpxSocksSource"):
      check not dep.startsWith("gcc")
      check not dep.startsWith("clang")
      check not dep.startsWith("python3")

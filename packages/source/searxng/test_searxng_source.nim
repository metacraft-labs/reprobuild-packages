## The `searxng` recipe: upstream's tree at the commit the fleet's NixOS
## hosts run, assembled with the three requirements no distribution ships.

import std/[strutils, unittest]

import repro_project_dsl
import ./repro

suite "searxng source recipe":
  test "pins the commit nixpkgs pins":
    let spec = registeredFetchSpec("searxngSource")
    check spec.url == "https://github.com/searxng/searxng/archive/dce3bb69bb45519bde01c610e09e45cd42fd896c.tar.gz"
    check spec.hashHex ==
      "bdf08984b48d9e6fd7e3eecf8a272aad7bd4ba911cee34e39b677c0ea1595154"
    check spec.extractStrip == 1

  test "assembles exactly the requirements Debian trixie lacks":
    # Everything else SearXNG imports comes from the consuming host's
    # `package(apt, ...)` closure; a dependency appearing here that Debian
    # ships would be a second copy shadowing the distribution's.
    let deps = registeredNativeBuildDeps("searxngSource")
    check "python-msgspec" in deps
    check "python-httpx-socks" in deps
    check "python-valkey" in deps
    for dep in deps:
      check not dep.startsWith("python-") or dep in
        ["python-msgspec", "python-httpx-socks", "python-valkey"]
      check not dep.startsWith("gcc")
      check not dep.startsWith("clang")

  test "publishes the launcher":
    let artifacts = registeredArtifacts("searxngSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "searxng"
    check artifacts[0].kind == dakExecutable

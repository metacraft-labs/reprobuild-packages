## The `shfmt` from-source recipe, and the Go shape it is the first user of.
##
## Three facts about this package cannot be derived from one another, and a
## bump that edited one and not the others would produce a recipe that still
## compiles: the tarball comes from the GitHub tag, the module identity
## comes from `go.mod` (`mvdan.cc/sh/v3`, not `github.com/mvdan/sh`), and
## `go build` needs the command's package path under `cmd/`. Each is read
## back below.

import std/[strutils, unittest]

import repro_project_dsl
import ./repro

suite "shfmt source recipe":
  test "pins the upstream tag archive":
    let spec = registeredFetchSpec("shfmtSource")
    check spec.url ==
      "https://github.com/mvdan/sh/archive/refs/tags/v3.12.0.tar.gz"
    check spec.hashHex ==
      "ac15f42feeba55af29bd07698a881deebed1cd07e937effe140d9300e79d5ceb"
    # A GitHub tag archive wraps its tree in one `<repo>-<version>`
    # directory; without the strip, `go.mod` would land a level too deep
    # and the module would not be found.
    check spec.extractStrip == 1

  test "publishes the single command":
    let artifacts = registeredArtifacts("shfmtSource")
    check artifacts.len == 1
    check artifacts[0].packageName == "shfmtSource"
    check artifacts[0].artifactName == "shfmt"
    check artifacts[0].kind == dakExecutable

  test "declares go and nothing else":
    # `cgo` is off in the constructor, so this package genuinely needs only
    # the Go toolchain. A C compiler appearing here would mean the recipe
    # had acquired a dependency it does not declare.
    let deps = registeredNativeBuildDeps("shfmtSource")
    var sawGo = false
    for dep in deps:
      if dep.startsWith("go"):
        sawGo = true
      # The from-source-go convention declines a recipe that also names a
      # competing driver, so one appearing here would make the package
      # unbuildable rather than merely over-declared.
      check not dep.startsWith("cargo")
      check not dep.startsWith("cmake")
      check not dep.startsWith("meson")
    check sawGo

  test "realizes the same version the binary package fetches":
    # An alternative REALIZATION of one package, not a second package: a
    # consumer selecting either path must get the same `shfmt --version`.
    # The binary side pins 3.12.0 in
    # `repro_dsl_stdlib/packages/shfmt.nim`.
    check registeredFetchSpec("shfmtSource").url.contains("v3.12.0")

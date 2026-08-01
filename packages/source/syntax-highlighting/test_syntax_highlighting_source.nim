## Smoke test for the from-source ``syntaxHighlighting`` recipe (M9.R.15q.10.3).

import std/[strutils, unittest]

import repro_project_dsl

import ./repro

suite "syntaxHighlighting — from-source recipe smoke test":

  test "fetch spec is registered":
    let spec = registeredFetchSpec("syntaxHighlighting")
    check spec.hashHex.len == 64
    check spec.url.endsWith("syntax-highlighting-6.10.0.tar.xz")

  test "artifact libKF6SyntaxHighlighting registered":
    let arts = registeredArtifacts("syntaxHighlighting")
    check arts.len == 1
    check arts[0].artifactName == "libKF6SyntaxHighlighting"

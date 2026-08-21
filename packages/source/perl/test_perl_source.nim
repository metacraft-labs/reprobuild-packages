import std/[strutils, unittest]

import repro_project_dsl
import ./repro

suite "perlSource from-source recipe smoke test":
  test "runtime wrapper carries its private library and module roots":
    let actions = registeredShellActions("perlSource")
    check actions.len >= 2
    check actions[^2].command.contains("perl.real")
    check actions[^2].command.contains("LD_LIBRARY_PATH")
    check actions[^2].command.contains("PERL5LIB")

  test "build validates core module loading through the wrapper":
    let actions = registeredShellActions("perlSource")
    check actions.len >= 1
    check actions[^1].command.contains("-Mstrict")
    check actions[^1].command.contains("source-perl-ok")

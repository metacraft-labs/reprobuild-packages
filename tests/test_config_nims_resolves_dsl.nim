## This checkout's `config.nims` must, on its own, resolve every module the
## reprobuild DSL imports.
##
## WHY.  The Justfile recipes (`test-package`, `check-package`, `coverage`,
## ...) run a bare `nim c` / `nim check` with no `--path:` flags, so the
## search path they compile with is exactly what `config.nims` registers.
## `repro build` passes its own paths and does not exercise that. When
## reprobuild's DSL grew imports of new sibling packages (`clispec`, from
## nim-cli-spec), `config.nims` was not taught about them and every bare-nim
## recipe failed with `cannot open file: clispec/model`, while the repro test
## graph stayed green.
##
## HOW.  The test runs the real `nim` from PATH as a child process, from the
## checkout root, on `tests/config_nims_probe/dsl_import_probe.nim`, which
## imports what a source recipe imports. Nim reads this checkout's
## `config.nims` because it sits in a parent directory of the probe -- the
## same way it does for the Justfile recipes. No mocks: the compiler, the
## config file and the sibling checkouts are all real. A missing `nim` is a
## failure, not a skip, because then nothing was tested.

import std/[os, osproc, strutils, tempfiles, unittest]

const checkoutRoot = currentSourcePath().parentDir.parentDir
const probe = "tests" / "config_nims_probe" / "dsl_import_probe.nim"

suite "config.nims resolves the reprobuild DSL":
  test "a bare `nim check` of a recipe-shaped module succeeds":
    let nim = findExe("nim")
    check nim.len > 0
    if nim.len == 0:
      checkpoint "`nim` is not on PATH; the test cannot run without it"
      fail()
    else:
      check fileExists(checkoutRoot / "config.nims")
      check fileExists(checkoutRoot / probe)
      # A throwaway nimcache keeps the check from writing into the checkout
      # and from reusing a cache another compile left behind.
      # `--noNimblePath` drops Nim's default `~/.nimble/pkgs2` search path,
      # so a package that happens to be installed there (an upstream
      # `confutils`, say) cannot stand in for one `config.nims` failed to
      # register. The Justfile recipes do not pass it, but a pass without
      # that path implies a pass with it: `--path:` entries are searched
      # before the Nimble ones.
      let nimcache = createTempDir("config-nims-probe-", "")
      defer: removeDir(nimcache)
      let (output, exitCode) = execCmdEx(
        quoteShellCommand([nim, "check", "--hints:off", "--warnings:off",
                           "--noNimblePath", "--nimcache:" & nimcache,
                           probe]),
        workingDir = checkoutRoot)
      if exitCode != 0:
        # The first unresolved import cascades into thousands of follow-on
        # errors; the cause is at the top, so show only the head.
        const shownLines = 40
        let lines = output.strip().splitLines()
        var shown = lines[0 ..< min(lines.len, shownLines)].join("\n")
        if lines.len > shownLines:
          shown.add("\n... (" & $(lines.len - shownLines) & " more lines)")
        checkpoint "nim check exited " & $exitCode & ":\n" & shown
      check exitCode == 0

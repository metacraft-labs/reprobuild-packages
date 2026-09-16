import std/[os, strutils, unittest]

import repro_core/ambient_execution
import repro_project_dsl

import ./repro

when defined(reproProviderMode) and defined(linux):
  var fixtureNumber = 0

  proc assembleFixture(layout: string; plainPaths = false): tuple[
      code: int, diagnostic: string, sourceCopied: bool,
      bootstrapCalled: bool, targetCalled: bool, correctModules: bool,
      staleRemoved: bool, stampPreserved: bool, aliasPresent: bool] =
    inc fixtureNumber
    let root = getTempDir() /
      ("repro-python-assembly-" & $getCurrentProcessId() & "-" & $fixtureNumber)
    doAssert not dirExists(root)
    createDir(root)
    defer: removeDir(root)
    let sourceRoot = root / "source catalog"
    let prefix = sourceRoot / "python3" / ".repro/output/install/usr"
    let bootstrap = root / "bootstrap"
    let bin = root / "tools"
    let outDir = root / (if plainPaths: "output" else: "output prefix")
    let extracted = root / (if plainPaths: "mako" else: "mako source")
    let modules = root / (if plainPaths: "modules" else: "module sources")
    let sourceMarker = root / "target-called"
    let bootstrapMarker = root / "bootstrap-called"
    let shellPath = uncontrolledFindExe("sh")
    doAssert shellPath.len > 0
    for path in [prefix / "bin", bootstrap / "bin", bin, outDir / ".stamps",
                 extracted / "mako", modules]:
      createDir(path)
    if layout != "missing":
      createDir(prefix / "lib/python3.13")
    if layout == "multiple":
      createDir(prefix / "lib/python3.12")
    writeFile(prefix / "source-only", "source interpreter\n")
    writeFile(outDir / "old-bootstrap-file", "stale\n")
    writeFile(outDir / ".stamps/keep", "keep\n")
    writeFile(prefix / "bin/python3", "#!" & shellPath & "\n: > " &
      quoteShell(sourceMarker) & "\nexit 97\n")
    setFilePermissions(prefix / "bin/python3", {fpUserRead, fpUserWrite, fpUserExec})
    if layout == "missing-interpreter":
      removeFile(prefix / "bin/python3")
    writeFile(bin / "python3", "#!" & shellPath & "\n: > " &
      quoteShell(bootstrapMarker) & "\ncase \"$*\" in\n" &
      "  *sys.prefix*) printf '%s\\n' " & quoteShell(bootstrap) & ";;\n" &
      "  *) printf '%s\\n' 9.99;;\nesac\n")
    setFilePermissions(bin / "python3", {fpUserRead, fpUserWrite, fpUserExec})
    writeFile(extracted / "mako/__init__.py", "# fixture\n")
    for name in ["markupsafe", "packaging", "jinja2", "setuptools",
                 "_distutils_hack", "pkg_resources", "markdown"]:
      createDir(modules / name)
      writeFile(modules / name / "__init__.py", "# fixture\n")
    writeFile(modules / "distutils-precedence.pth", "# fixture\n")
    for name in ["markupsafe", "packaging", "jinja2", "setuptools", "markdown"]:
      let helper = bin / ("python-" & name)
      writeFile(helper, "#!" & shellPath & "\nprintf '%s\\n' " &
        quoteShell(modules) & "\n")
      setFilePermissions(helper, {fpUserRead, fpUserWrite, fpUserExec})
    let oldPath = getEnv("PATH")
    let hadRoot = existsEnv("REPRO_FROM_SOURCE_ROOT")
    let oldRoot = getEnv("REPRO_FROM_SOURCE_ROOT")
    putEnv("PATH", bin & PathSep & oldPath)
    putEnv("REPRO_FROM_SOURCE_ROOT", sourceRoot)
    defer:
      putEnv("PATH", oldPath)
      if hadRoot: putEnv("REPRO_FROM_SOURCE_ROOT", oldRoot)
      else: delEnv("REPRO_FROM_SOURCE_ROOT")
    resetDslPortShellStateForPackage("python3WithModulesSource")
    buildPython3WithModulesSourcePackage()
    let actions = registeredShellActions("python3WithModulesSource")
    doAssert actions.len > 0
    for action in actions:
      let command = dslPortSubstituteShellPlaceholders(
        action.command, "", extracted, outDir)
      let execution = uncontrolledExecCmdEx(quoteShellCommand(
        @[shellPath, "-ec", command]), workingDir = root)
      result.code = execution.exitCode
      result.diagnostic = execution.output
      if result.code != 0:
        break
    result.sourceCopied = fileExists(outDir / "source-only")
    result.bootstrapCalled = fileExists(bootstrapMarker)
    result.targetCalled = fileExists(sourceMarker)
    result.correctModules = true
    for name in ["mako", "markupsafe", "packaging", "jinja2", "setuptools",
                 "_distutils_hack", "pkg_resources", "markdown"]:
      result.correctModules = result.correctModules and fileExists(
        outDir / "lib/python3.13/site-packages" / name / "__init__.py")
    result.correctModules = result.correctModules and fileExists(
      outDir / "lib/python3.13/site-packages/distutils-precedence.pth")
    result.staleRemoved = not fileExists(outDir / "old-bootstrap-file")
    result.stampPreserved = fileExists(outDir / ".stamps/keep")
    result.aliasPresent = symlinkExists(outDir / "bin/python3-with-modules")

suite "python3WithModulesSource recipe":
  test "the copied interpreter is a package input, not a bootstrap tool":
    check "python3 >=3.8" in registeredBuildDeps("python3WithModulesSource")
    check "python3 >=3.8" notin registeredAuthoredNativeBuildDeps("python3WithModulesSource")

  test "custom install actions declare every shell helper":
    let nativeDeps = registeredNativeBuildDeps("python3WithModulesSource")
    for tool in ["sh", "mkdir", "find", "rm", "cp", "chmod", "ln"]:
      check tool in nativeDeps

  test "the package exports the augmented Python executable":
    let artifacts = registeredArtifacts("python3WithModulesSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "python3-with-modules"
    check artifacts[0].kind == dakExecutable

  when defined(reproProviderMode) and defined(linux):
    test "does not package an otherwise usable bootstrap interpreter":
      let assembled = assembleFixture("single", plainPaths = true)
      check assembled.code == 0
      check assembled.sourceCopied
      check not assembled.bootstrapCalled
      check not assembled.targetCalled
      check assembled.correctModules

    test "assembles only the source interpreter and its ABI without executing Python":
      let assembled = assembleFixture("single")
      check assembled.code == 0
      check assembled.sourceCopied
      check not assembled.bootstrapCalled
      check not assembled.targetCalled
      check assembled.correctModules
      check assembled.staleRemoved
      check assembled.stampPreserved
      check assembled.aliasPresent

    test "rejects a source prefix with no standard library":
      let assembled = assembleFixture("missing")
      check assembled.code != 0
      check "expected one Python standard-library directory" in assembled.diagnostic
      check not assembled.bootstrapCalled
      check not assembled.targetCalled

    test "rejects an ambiguous standard-library ABI":
      let assembled = assembleFixture("multiple")
      check assembled.code != 0
      check "expected one Python standard-library directory" in assembled.diagnostic
      check not assembled.bootstrapCalled
      check not assembled.targetCalled

    test "a missing source interpreter never falls back or clears the old output":
      let assembled = assembleFixture("missing-interpreter")
      check assembled.code != 0
      check "source Python interpreter missing" in assembled.diagnostic
      check not assembled.bootstrapCalled
      check not assembled.targetCalled
      check not assembled.staleRemoved
      check assembled.stampPreserved

import std/[os, sets, strutils, unittest]
import repro_project_dsl
import ../repro
import ../source_tests

resetBuildActionRegistry()
resetBuildTargetRegistry()
buildReprobuildPackagesPackage()

proc action(id: string): BuildActionDef =
  for candidate in registeredBuildActions():
    if candidate.id == id:
      return candidate
  raise newException(ValueError, "missing action: " & id)

proc targetDef(name: string): BuildTargetDef =
  for candidate in registeredBuildTargets():
    if candidate.name == name:
      return candidate
  raise newException(ValueError, "missing target: " & name)

suite "source recipe test graph":
  test "does not register source package implementations":
    for packageDef in registeredPackages():
      check not packageDef.packageName.endsWith("Source")

  test "every host-supported recipe test has separate build and execute edges":
    var outputs = initHashSet[string]()
    for source in sourceTestFiles:
      let name = source.splitFile.name.replace('_', '-')
      when not (defined(linux) and defined(amd64)):
        if name == "test-kernel-config-has-attestation-knobs":
          continue
      let compiled = action("packages.build." & name)
      let executed = action("packages.run." & name)
      check source in compiled.inputs
      check "config.nims" in compiled.inputs
      check "gcc" in compiled.toolIdentityRefs
      check compiled.dependencyPolicy.kind == automaticMonitorPolicy().kind
      check compiled.cacheable
      check compiled.id in executed.deps
      check not executed.cacheable
      check targetDef(name).actions == @[executed.id]
      require compiled.outputs.len == 1
      check compiled.outputs[0] in executed.inputs
      check compiled.outputs[0] == "build" / "test-bin" / ("build-" & name & ExeExt)
      check compiled.outputs[0] notin outputs
      outputs.incl(compiled.outputs[0])

  test "source unit tests do not run the real kernel configuration gate":
    let unitTests = targetDef("test-source-recipes")
    check unitTests.actions.len == sourceTestFiles.len - 1
    check "packages.run.test-kernel-config-has-attestation-knobs" notin unitTests.actions
    let integration = targetDef("test-source-integration")
    when defined(linux) and defined(amd64):
      check integration.actions == @["packages.run.test-kernel-config-has-attestation-knobs"]
      let executed = action(integration.actions[0])
      for tool in ["gcc", "binutils", "make", "flex", "bison", "m4", "bc",
          "curl", "sha256sum", "tar", "xz", "sh", "dirname", "env",
          "mktemp", "mv", "realpath"]:
        check tool in executed.toolIdentityRefs
    else:
      check integration.actions.len == 0

  test "Gettext script tools are declared on its execute edge":
    let executed = action("packages.run.test-gettext-source")
    for tool in ["sh", "find", "awk", "cmp", "mv", "rm", "sort", "grep"]:
      check tool in executed.toolIdentityRefs

  test "lint does not compile or execute source recipe tests":
    check targetDef("lint").actions ==
      @["packages.check-catalog", "packages.check-source-tests"]

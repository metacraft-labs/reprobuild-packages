import std/[os, strutils]
import repro_project_dsl
import repro_dsl_stdlib/packages/python3
import ct_test_nim_unittest
import source_tests

package reprobuildPackages:
  nativeBuildDeps:
    "python3 >=3.10"
    "nim >=2.2 <3.0"
    "gcc"
    "sh"
    "awk"
    "find"
    "cmp"
    "mv"
    "rm"
    "sort"
    "grep"
    "make"
    "flex"
    "bison"
    "bc"
    "curl"
    "sha256sum"
    "tar"
    "xz"
    "sed"
    "mkdir"
    "cp"
    "chmod"
    "ln"
    "cat"
    "head"
    "tail"
    "cut"
    "tr"
    "uname"
    "binutils"
    "m4"
    "dirname"
    "env"
    "mktemp"
    "realpath"

  devEnv:
    task("refresh-source-tests",
      "python3 scripts/source_test_catalog.py --write",
      description = "Refresh the source recipe test inventory")

  build:
    let catalog = buildAction(
      id = "packages.check-catalog",
      call = inlineExecCall(["python3", "scripts/check_catalog.py"]),
      inputs = ["scripts/check_catalog.py"],
      toolIdentityRefs = ["python3"],
      dependencyPolicy = automaticMonitorPolicy(),
      cacheable = false)
    let catalogTests = buildAction(
      id = "packages.test-catalog",
      call = inlineExecCall(["python3", "scripts/test_check_catalog.py"]),
      inputs = ["scripts/check_catalog.py", "scripts/test_check_catalog.py"],
      toolIdentityRefs = ["python3"],
      dependencyPolicy = automaticMonitorPolicy(),
      cacheable = false)
    let inventory = buildAction(
      id = "packages.check-source-tests",
      call = inlineExecCall(["python3", "scripts/source_test_catalog.py"]),
      inputs = ["scripts/source_test_catalog.py", "source_tests.nim"],
      toolIdentityRefs = ["python3"],
      dependencyPolicy = automaticMonitorPolicy(),
      cacheable = false)
    let inventoryTests = buildAction(
      id = "packages.test-source-inventory",
      call = inlineExecCall(["python3", "scripts/test_source_test_catalog.py"]),
      inputs = ["scripts/source_test_catalog.py", "scripts/test_source_test_catalog.py"],
      toolIdentityRefs = ["python3"],
      dependencyPolicy = automaticMonitorPolicy(),
      cacheable = false)

    var sourceTests: seq[BuildActionDef] = @[]
    var integrationTests: seq[BuildActionDef] = @[]
    for source in sourceTestFiles:
      let name = source.splitFile.name.replace('_', '-')
      let integration = name == "test-kernel-config-has-attestation-knobs"
      when not (defined(linux) and defined(amd64)):
        if integration:
          continue
      let binary = "build" / "test-bin" / ("build-" & name & ExeExt)
      let compiled = buildNimUnittest.build(
        source = source,
        binary = binary,
        actionId = "packages.build." & name,
        defines = @["reproProviderMode"],
        extraInputs = @["config.nims"])
      appendRegisteredActionToolIdentityRefs(compiled.action.id, ["gcc"])
      let executed = compiled.testBinary.run(
        actionId = "packages.run." & name,
        after = @[compiled.action],
        registerImplicitName = false,
        cacheable = false)
      if name == "test-gettext-source":
        appendRegisteredActionToolIdentityRefs(executed.id,
          ["sh", "find", "awk", "cmp", "mv", "rm", "sort", "grep"])
      elif name == "test-python3-with-modules-source":
        appendRegisteredActionToolIdentityRefs(executed.id,
          ["sh", "mkdir", "find", "rm", "cp", "chmod", "ln"])
      elif integration:
        appendRegisteredActionToolIdentityRefs(executed.id,
          ["sh", "make", "gcc", "binutils", "flex", "bison", "m4", "bc", "curl", "sha256sum",
           "tar", "xz", "sed", "mkdir", "ln", "cat", "head", "tail", "cut",
           "tr", "uname", "find", "awk", "rm", "grep", "dirname", "env",
           "mktemp", "mv", "realpath"])
      discard target(name, executed)
      if integration:
        integrationTests.add(executed)
      else:
        sourceTests.add(executed)

    let graphTest = buildNimUnittest.build(
      source = "tests/test_source_graph.nim",
      binary = "build" / "test-bin" / ("build-source-graph" & ExeExt),
      actionId = "packages.build.source-graph",
      defines = @["reproProviderMode"],
      extraInputs = @["config.nims"])
    appendRegisteredActionToolIdentityRefs(graphTest.action.id, ["gcc"])
    let graphTestRun = graphTest.testBinary.run(
      actionId = "packages.test-source-graph",
      after = @[graphTest.action],
      registerImplicitName = false,
      cacheable = false)

    discard target("check-catalog", catalog)
    discard target("test-catalog", catalogTests)
    discard target("check-source-tests", inventory)
    discard target("test-source-inventory", inventoryTests)
    discard target("test-source-graph", graphTestRun)
    discard collect("lint", actions = @[catalog, inventory])
    discard collect("test-source-recipes", actions = sourceTests)
    discard collect("test-source-integration", actions = integrationTests)
    discard collect("test", actions =
      @[catalogTests, inventoryTests, graphTestRun] & sourceTests)

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
      elif name == "test-gobject-introspection-source":
        appendRegisteredActionToolIdentityRefs(executed.id, ["sh", "sed", "chmod"])
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

    ## The pinned CLI tool tier's two realizations, checked against each
    ## other. It imports both the canonical interfaces from
    ## `repro_dsl_stdlib` and the eight `packages/source/` recipes, which no
    ## per-recipe test can do -- the claim is about a PAIR.
    let tierTest = buildNimUnittest.build(
      source = "tests/test_tier_realizations_agree.nim",
      binary = "build" / "test-bin" / ("test-tier-realizations" & ExeExt),
      actionId = "packages.build.tier-realizations",
      defines = @["reproProviderMode"],
      extraInputs = @["config.nims"])
    appendRegisteredActionToolIdentityRefs(tierTest.action.id, ["gcc"])
    let tierTestRun = tierTest.testBinary.run(
      actionId = "packages.test-tier-realizations",
      after = @[tierTest.action],
      registerImplicitName = false,
      cacheable = false)

    ## The platform coverage report's gate. It fails when a
    ## (package, platform) cell is realized by nothing and explained by
    ## nothing -- the state a new package or a new platform axis arrives in.
    let coverageTest = buildNimUnittest.build(
      source = "tests/test_platform_coverage.nim",
      binary = "build" / "test-bin" / ("test-platform-coverage" & ExeExt),
      actionId = "packages.build.platform-coverage",
      defines = @["reproProviderMode"],
      extraInputs = @["config.nims", "tools/platform-coverage.tsv",
                      "tools/dev_env_platform_coverage.nim"])
    appendRegisteredActionToolIdentityRefs(coverageTest.action.id, ["gcc"])
    let coverageTestRun = coverageTest.testBinary.run(
      actionId = "packages.test-platform-coverage",
      after = @[coverageTest.action],
      registerImplicitName = false,
      cacheable = false)

    discard target("check-catalog", catalog)
    discard target("test-catalog", catalogTests)
    discard target("check-source-tests", inventory)
    discard target("test-source-inventory", inventoryTests)
    discard target("test-source-graph", graphTestRun)
    discard target("test-tier-realizations", tierTestRun)
    discard target("test-platform-coverage", coverageTestRun)
    discard collect("lint", actions = @[catalog, inventory])
    discard collect("test-source-recipes", actions = sourceTests)
    discard collect("test-source-integration", actions = integrationTests)
    discard collect("test", actions =
      @[catalogTests, inventoryTests, graphTestRun, tierTestRun,
        coverageTestRun] & sourceTests)

import repro_project_dsl
import repro_dsl_stdlib/packages/python3

package reprobuildPackages:
  nativeBuildDeps:
    "python3 >=3.10"

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
    discard target("check-catalog", catalog)
    discard target("test-catalog", catalogTests)
    discard collect("lint", actions = @[catalog])
    discard collect("test", actions = @[catalogTests])

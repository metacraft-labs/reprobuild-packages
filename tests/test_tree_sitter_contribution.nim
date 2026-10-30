## Read the real registered interface and contribution together: a duplicate
## interface or stale fingerprint must fail before Windows provisioning.
## Range controls use the production selector over the imported real records;
## they neither download an archive nor mock tool resolution.
import std/[os, sequtils, strutils, unittest]
import repro_project_dsl
import repro_interface_artifacts
import repro_interface_artifacts/contribution_records
import repro_tool_profiles/realization_selection
import "../packages/contributions/tree-sitter/repro"
import tree_sitter_contribution_support

suite "tree-sitter Windows archives":
  test "targets the canonical interface without redefining it":
    let packages = registeredPackages()
    let targets = packages.filterIt(it.packageName == "tree-sitter")
    require targets.len == 1
    let actualFingerprint = canonicalPackageInterfaceFingerprint(targets[0], packages)
    check actualFingerprint == ExpectedSourceTreeSitterFingerprint
    check TreeSitterInterfaceFingerprint == LegacyTreeSitterFingerprint
    echo "canonical source tree-sitter fingerprint: ", actualFingerprint
    let root = currentSourcePath.parentDir.parentDir /
      "packages/contributions/tree-sitter"
    if actualFingerprint == TreeSitterInterfaceFingerprint:
      let artifact = artifactFromRegisteredDsl(root / "repro.nim")
      require artifact.projectInterface.provisioningContributions.len == 1
      check artifact.projectInterface.provisioningContributions[0].targetInterfaceFingerprint ==
        actualFingerprint
    else:
      var refusal = ""
      try:
        discard artifactFromRegisteredDsl(root / "repro.nim")
      except ValueError as error:
        refusal = error.msg
      check "interface mismatch" in refusal
      check TreeSitterInterfaceFingerprint in refusal
      check actualFingerprint in refusal
    let contributions = registeredProvisioningContributions()
    require contributions.len == 1
    let contribution = contributions[0]
    check contribution.targetPackage == "tree-sitter"
    check contribution.targetInterfaceFingerprint == TreeSitterInterfaceFingerprint
    check contribution.contributor == "github:metacraft-labs/reprobuild-packages"
    check contribution.tarballProvisioning.len == 2
    for (cpu, asset) in [("x86_64", "x64"), ("aarch64", "arm64")]:
      let matches = contribution.tarballProvisioning.filterIt(it.cpu == cpu)
      require matches.len == 1
      let archive = matches[0]
      check archive.os == "windows"
      check archive.archiveType == "zip"
      check archive.executablePath == "tree-sitter.exe"
      check archive.stripComponents == 0
      check archive.packageId == "tree-sitter@0.27.0"
      check archive.url == "https://github.com/tree-sitter/tree-sitter/releases/" &
        "download/v0.27.0/tree-sitter-cli-windows-" & asset & ".zip"
      check archive.sha256.len == 64
      check archive.lockIdentity == "tarball:tree-sitter@0.27.0:windows-" &
        cpu & ":sha256:" & archive.sha256

  test "both Windows targets satisfy only the offered realization version":
    let contributions = thinTreeSitterContributions()
    require contributions.len == 1
    let records = contributions[0].tarballProvisioning
    for target in [realizationTargetFor(pcX86_64, poWindows, mlX86_64_v1),
                   realizationTargetFor(pcAArch64, poWindows)]:
      let selected = selectTarballRecord(records, target,
        versionRange = "==0.27.0")
      check selected.status == kcSelected
      require selected.index >= 0
      check records[selected.index].detail.version == TreeSitterVersion
      for incompatible in ["<0.27.0", ">=0.28.0", "==0.26.0"]:
        check selectTarballRecord(records, target,
          versionRange = incompatible).status == kcVersionNotOffered

  test "published records match the imported module":
    let root = currentSourcePath.parentDir.parentDir /
      "packages/contributions/tree-sitter"
    let fresh = renderContributionRecords(thinTreeSitterContributions(), root)
    if getEnv("REPRO_UPDATE_CONTRIBUTION_RECORDS") == "1":
      writeFile(root / "provisioning-contributions.json", fresh)
    check readFile(root / "provisioning-contributions.json") == fresh

## Read the real registered interface and contribution together: a duplicate
## interface or stale fingerprint must fail before Windows provisioning.
import std/[os, sequtils, strutils, unittest]
import repro_project_dsl
import repro_interface_artifacts
import repro_interface_artifacts/contribution_records
import "../packages/contributions/tree-sitter/repro"

suite "tree-sitter Windows archives":
  test "targets the canonical interface without redefining it":
    let packages = registeredPackages()
    let targets = packages.filterIt(it.packageName == "tree-sitter")
    require targets.len == 1
    check canonicalPackageInterfaceFingerprint(targets[0], packages) ==
      TreeSitterInterfaceFingerprint
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

  test "published records match the imported module":
    let root = currentSourcePath.parentDir.parentDir /
      "packages/contributions/tree-sitter"
    let artifact = artifactFromRegisteredDsl(root / "repro.nim")
    let fresh = renderContributionRecords(
      artifact.projectInterface.provisioningContributions, root)
    if getEnv("REPRO_UPDATE_CONTRIBUTION_RECORDS") == "1":
      writeFile(root / "provisioning-contributions.json", fresh)
    check readFile(root / "provisioning-contributions.json") == fresh

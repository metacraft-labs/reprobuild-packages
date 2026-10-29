## Production registration, range selection and published metadata use the real
## canonical interface and contribution. No fake rustup is substituted.
## On Windows x64 the native arm also realizes the verified upstream binary in
## a private store and runs manager --version/--help. Other hosts establish only
## metadata, never native executable conformance.
import std/[os, sequtils, strutils, unittest]
import repro_project_dsl
import repro_interface_artifacts
import repro_interface_artifacts/contribution_records
import repro_tool_profiles/realization_selection
import "../packages/contributions/rustup/repro"
when defined(windows) and defined(amd64):
  import std/[osproc, tempfiles]
  import repro_tool_profiles/tarball_conformance

suite "rustup Windows manager contribution":
  test "keeps the canonical interface and names the real manager":
    let packages = registeredPackages()
    let canonical = packages.filterIt(it.packageName == "rustup")
    require canonical.len == 1
    check canonicalPackageInterfaceFingerprint(canonical[0], packages) ==
      RustupInterfaceFingerprint
    let contributions = registeredProvisioningContributions()
    require contributions.len == 1
    let contribution = contributions[0]
    check contribution.targetPackage == "rustup"
    check contribution.targetInterfaceFingerprint == RustupInterfaceFingerprint
    check contribution.contributor == "github:metacraft-labs/reprobuild-packages"
    require contribution.tarballProvisioning.len == 1
    let arm = contribution.tarballProvisioning[0]
    check arm.url == RustupWindowsX64Url
    check arm.sha256 == RustupWindowsX64Sha256
    check arm.archiveType == "raw"
    check arm.executablePath == "bin/rustup.exe"
    check arm.detail.version == RustupVersion
    check arm.packageId == "rustup@" & RustupVersion
    check arm.os == "windows"
    check arm.cpu == "x86_64"
    check arm.lockIdentity == "tarball:rustup@" & RustupVersion &
      ":windows-x86_64:sha256:" & RustupWindowsX64Sha256

  test "registered realization satisfies only its offered version and target":
    let root = currentSourcePath.parentDir.parentDir / "packages/contributions/rustup"
    let artifact = artifactFromRegisteredDsl(root / "repro.nim")
    let records = artifact.projectInterface.provisioningContributions[0].tarballProvisioning
    let target = realizationTargetFor(pcX86_64, poWindows, mlX86_64_v1)
    for constraint in [">=1", "==1.29.1"]:
      let chosen = selectTarballRecord(records, target, versionRange = constraint)
      check chosen.status == kcSelected
      require chosen.index >= 0
      check records[chosen.index].executablePath == "bin/rustup.exe"
    for wrong in ["<1.29.1", ">=1.30.0", "==1.28.2"]:
      check selectTarballRecord(records, target, versionRange = wrong).status ==
        kcVersionNotOffered
    check selectTarballRecord(records,
      realizationTargetFor(pcAArch64, poWindows), versionRange = ">=1").status != kcSelected

  test "published records match the actual imported contribution":
    let root = currentSourcePath.parentDir.parentDir / "packages/contributions/rustup"
    let artifact = artifactFromRegisteredDsl(root / "repro.nim")
    let fresh = renderContributionRecords(artifact.projectInterface.provisioningContributions, root)
    if getEnv("REPRO_UPDATE_CONTRIBUTION_RECORDS") == "1":
      writeFile(root / "provisioning-contributions.json", fresh)
    check readFile(root / "provisioning-contributions.json") == fresh

  when defined(windows) and defined(amd64):
    test "real raw realization runs the upstream manager without installing it":
      let root = currentSourcePath.parentDir.parentDir / "packages/contributions/rustup"
      let artifact = artifactFromRegisteredDsl(root / "repro.nim")
      let arm = artifact.projectInterface.provisioningContributions[0].tarballProvisioning[0]
      let iface = toProjectInterface(PackageDef(packageName: "rustupConformanceConsumer",
        nativeBuildDeps: @[PackageUseDef(rawConstraint: "rustup >=1",
          packageSelector: "rustup", executableName: "rustup", depKind: "native")]),
        registeredPackages())
      require iface.toolUses.len == 1
      let scratch = createTempDir("rustup-manager-conformance-", "")
      defer: removeDir(scratch)
      # Neither realization probes nor manager diagnostics may select the
      # operator's rustup state or install a toolchain into their home.
      var previous: seq[tuple[name, value: string, present: bool]] = @[]
      for name in ["RUSTUP_HOME", "CARGO_HOME"]:
        previous.add((name, getEnv(name), existsEnv(name)))
        putEnv(name, scratch / name.toLowerAscii())
      previous.add(("RUSTUP_TOOLCHAIN", getEnv("RUSTUP_TOOLCHAIN"), existsEnv("RUSTUP_TOOLCHAIN")))
      delEnv("RUSTUP_TOOLCHAIN")
      defer:
        for item in previous:
          if item.present: putEnv(item.name, item.value)
          else: delEnv(item.name)
      let verdict = conformTarballArm(iface.toolUses[0], arm, scratch / "store")
      require verdict.verdict == acvOk
      require verdict.detail.len == 0
      check verdict.resolvedExecutablePath.endsWith("rustup.exe")
      let version = execCmdEx(quoteShell(verdict.resolvedExecutablePath) & " --version",
        workingDir = scratch)
      check version.exitCode == 0
      check version.output.startsWith("rustup " & RustupVersion)
      let help = execCmdEx(quoteShell(verdict.resolvedExecutablePath) & " --help",
        workingDir = scratch)
      check help.exitCode == 0
      check help.output.contains("toolchain")
      check help.output.contains("rustup")
      check not help.output.contains("rustup-init[EXE]")
      check not dirExists(getEnv("RUSTUP_HOME") / "toolchains")

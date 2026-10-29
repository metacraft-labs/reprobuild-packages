## Official native Windows CLI archives. The public tree-sitter interface
## remains owned by repro_dsl_stdlib. Archives contain tree-sitter.exe at root.
## https://github.com/tree-sitter/tree-sitter/releases/tag/v0.27.0
import repro_project_dsl
import repro_dsl_stdlib/packages/tree_sitter

const TreeSitterVersion* = "0.27.0"
const TreeSitterInterfaceFingerprint* =
  "615a1cf7519f1779f345957e62b58621bd89d931f5877010f49293815d977f11"
const ReleaseBase = "https://github.com/tree-sitter/tree-sitter/releases/download/v" &
  TreeSitterVersion & "/tree-sitter-cli-windows-"

provisioningFor "tree-sitter":
  interfaceFingerprint "615a1cf7519f1779f345957e62b58621bd89d931f5877010f49293815d977f11"
  contributor "github:metacraft-labs/reprobuild-packages"

  tarball url = ReleaseBase & "x64.zip",
    sha256 = "46188d31c1f3847307b03e92f3a3f60606eb04147609e26cdd50a07f7d0b35da",
    archiveType = "zip",
    executablePath = "tree-sitter.exe",
    packageId = "tree-sitter@" & TreeSitterVersion,
    cpu = "x86_64",
    os = "windows",
    lockIdentity = "tarball:tree-sitter@" & TreeSitterVersion &
      ":windows-x86_64:sha256:46188d31c1f3847307b03e92f3a3f60606eb04147609e26cdd50a07f7d0b35da"

  tarball url = ReleaseBase & "arm64.zip",
    sha256 = "e44462444fa7fc873b07e6d0735c6772980c7be6024184b40529a17904da58bf",
    archiveType = "zip",
    executablePath = "tree-sitter.exe",
    packageId = "tree-sitter@" & TreeSitterVersion,
    cpu = "aarch64",
    os = "windows",
    lockIdentity = "tarball:tree-sitter@" & TreeSitterVersion &
      ":windows-aarch64:sha256:e44462444fa7fc873b07e6d0735c6772980c7be6024184b40529a17904da58bf"

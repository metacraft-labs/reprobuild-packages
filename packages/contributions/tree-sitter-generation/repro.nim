## Official Windows CLI archives for the typed parser-generation interface.
## The legacy CLI-only contribution remains separate and unchanged.
## https://github.com/tree-sitter/tree-sitter/releases/tag/v0.27.0
import repro_project_dsl
import repro_dsl_stdlib/packages/tree_sitter

const TreeSitterGenerationVersion* = "0.27.0"
const TreeSitterGenerationInterfaceFingerprint* =
  "882b1e92da51ab840f15eb1d9b334b8738094cf4086fd2cebfea4664e065525e"
const ReleaseBase = "https://github.com/tree-sitter/tree-sitter/releases/download/v" &
  TreeSitterGenerationVersion & "/tree-sitter-cli-windows-"

provisioningFor "tree-sitter":
  interfaceFingerprint "882b1e92da51ab840f15eb1d9b334b8738094cf4086fd2cebfea4664e065525e"
  contributor "github:metacraft-labs/reprobuild-packages"

  tarball url = ReleaseBase & "x64.zip",
    sha256 = "46188d31c1f3847307b03e92f3a3f60606eb04147609e26cdd50a07f7d0b35da",
    archiveType = "zip",
    executablePath = "tree-sitter.exe",
    version = TreeSitterGenerationVersion,
    packageId = "tree-sitter@" & TreeSitterGenerationVersion,
    cpu = "x86_64",
    os = "windows",
    lockIdentity = "tarball:tree-sitter@" & TreeSitterGenerationVersion &
      ":windows-x86_64:sha256:46188d31c1f3847307b03e92f3a3f60606eb04147609e26cdd50a07f7d0b35da"

  tarball url = ReleaseBase & "arm64.zip",
    sha256 = "e44462444fa7fc873b07e6d0735c6772980c7be6024184b40529a17904da58bf",
    archiveType = "zip",
    executablePath = "tree-sitter.exe",
    version = TreeSitterGenerationVersion,
    packageId = "tree-sitter@" & TreeSitterGenerationVersion,
    cpu = "aarch64",
    os = "windows",
    lockIdentity = "tarball:tree-sitter@" & TreeSitterGenerationVersion &
      ":windows-aarch64:sha256:e44462444fa7fc873b07e6d0735c6772980c7be6024184b40529a17904da58bf"

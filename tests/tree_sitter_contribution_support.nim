## Archive metadata can be projected before its canonical target is present.
## This is the existing thin-contribution projection, using real registered
## declarations, not a substitute interface or resolver. Each test separately
## exercises full canonical extraction and its strict fingerprint refusal.
## Compiler/source-context coverage is distinct from executing an SDK image.
{.experimental: "callOperator".}
import std/sequtils
import repro_project_dsl
import repro_interface_artifacts
import repro_dsl_stdlib/packages/tree_sitter as tree_sitter_module

const LegacyTreeSitterFingerprint* = "615a1cf7519f1779f345957e62b58621bd89d931f5877010f49293815d977f11"
const GeneratingTreeSitterFingerprint* = "882b1e92da51ab840f15eb1d9b334b8738094cf4086fd2cebfea4664e065525e"
const ExpectedSourceTreeSitterFingerprint* =
  when compiles(tree_sitter.generate(grammar = "fingerprint-grammar.js",
      outputDir = "fingerprint-output", abi = 14)):
    GeneratingTreeSitterFingerprint
  else:
    LegacyTreeSitterFingerprint

proc thinTreeSitterContributions*(): seq[InterfaceProvisioningContribution] =
  let targets = registeredPackages().filterIt(it.packageName == "tree-sitter")
  if targets.len != 1:
    raise newException(ValueError, "expected exactly one canonical tree-sitter")
  # Omitting target metadata is the normal thin-catalog surface. It preserves
  # the pinned contribution identity; it does not establish compatibility.
  toProjectInterface(targets[0], contributions =
    registeredProvisioningContributions()).provisioningContributions

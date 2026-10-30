## Tree-sitter's C runtime library and public C headers.
## This package does not provide the Tree-sitter command-line generator.

import repro_project_dsl

package `tree-sitter-runtime`:
  versions:
    "0.25.10":
      sourceRepository = "https://github.com/tree-sitter/tree-sitter"

  library `tree-sitter`:
    kind static

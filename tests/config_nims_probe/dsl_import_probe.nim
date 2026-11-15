## Probe module for `tests/test_config_nims_resolves_dsl.nim`. It is never
## built into a binary: the test only runs `nim check` on it.
##
## It imports what a source recipe under `packages/source/*/repro.nim`
## imports, so a clean `nim check` of it, with no `--path:` on the command
## line, shows that this checkout's `config.nims` alone puts the reprobuild
## DSL and everything the DSL imports on the search path -- which is all a
## bare `nim c` / `nim check` from the Justfile recipes (`test-package`,
## `check-package`, `coverage`, ...) gets.
##
## It lives in its own directory under `tests/` so that nothing that globs
## for tests picks it up: `scripts/source_test_catalog.py` catalogs only
## `packages/source/**/test_*.nim`, and this file is not named `test_*`.

import repro_project_dsl
import repro_dsl_stdlib/types/package_result
import repro_dsl_stdlib/constructors

check:
  pwsh -NoProfile -File scripts/check-catalog.ps1

fingerprints:
  nim c -r --nimcache:build/nimcache-interface-fingerprints tools/package_interface_fingerprints.nim

check-package selector:
  nim check "packages/source/{{selector}}/repro.nim"

# Run every `test_*.nim` beside a source recipe
test-package selector:
  #!/usr/bin/env bash
  # Each test is a standalone `std/unittest` binary. They are built into
  # `build/` (gitignored) so the recipe directory stays clean.
  set -euo pipefail
  shopt -s nullglob
  found=0
  for t in "packages/source/{{selector}}"/test_*.nim; do
    found=1
    name="$(basename "${t%.nim}")"
    echo "== $t"
    nim c -r --hints:off --warnings:off \
      --out:"$PWD/build/test-bin/$name" \
      --nimcache:"$PWD/build/nimcache-$name" \
      "$t"
  done
  if [ "$found" -eq 0 ]; then
    echo "no tests beside packages/source/{{selector}}" >&2
    exit 1
  fi

# The platform coverage report for the dev-environment tool tier: for each
# package and each platform, what this catalog can do -- and for each gap,
# whether upstream ships nothing there or nobody has pinned what it does.
#
# `just coverage` prints the org-mode table; `just coverage-check` is the
# gate, and fails when a cell is realized by nothing and explained by
# nothing in tools/platform-coverage.tsv.
coverage *args:
  nim c -r --hints:off --warnings:off \
    --out:"$PWD/build/dev-env-platform-coverage" \
    --nimcache:"$PWD/build/nimcache-platform-coverage" \
    tools/dev_env_platform_coverage.nim {{args}}

coverage-check:
  just coverage --check

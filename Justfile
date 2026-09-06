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

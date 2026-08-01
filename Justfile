check:
  pwsh -NoProfile -File scripts/check-catalog.ps1

fingerprints:
  nim c -r --nimcache:build/nimcache-interface-fingerprints tools/package_interface_fingerprints.nim

check-package selector:
  nim check "packages/source/{{selector}}/repro.nim"

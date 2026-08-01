check:
  pwsh -NoProfile -File scripts/check-catalog.ps1

check-package selector:
  nim check "packages/source/{{selector}}/repro.nim"


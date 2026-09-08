$ErrorActionPreference = 'Stop'

# Compatibility entry point; repro lint owns the contributor workflow.
python3 (Join-Path $PSScriptRoot 'check_catalog.py') @args
exit $LASTEXITCODE

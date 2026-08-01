$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$recipesRoot = Join-Path $root 'packages/source'
$recipes = Get-ChildItem -LiteralPath $recipesRoot -Directory | Sort-Object Name
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($recipe in $recipes) {
    $definition = Join-Path $recipe.FullName 'repro.nim'
    if (-not (Test-Path -LiteralPath $definition)) {
        $failures.Add("$($recipe.Name): missing repro.nim")
        continue
    }

    $source = Get-Content -LiteralPath $definition -Raw
    if ($source -notmatch '(?m)^package\s+') {
        $failures.Add("$($recipe.Name): missing package declaration")
    }
    if ($source -match '(?m)^package\s+[A-Za-z0-9_]+Source:') {
        $failures.Add("$($recipe.Name): package identity still has Source suffix")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "Validated $($recipes.Count) independently addressable source recipes."


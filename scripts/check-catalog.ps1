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
    if ([regex]::IsMatch($source, '(?m)^\s*"pkgconf(?:\s|\")')) {
        $failures.Add(
            "$($recipe.Name): declare the pkg-config capability, not its pkgconf provider"
        )
    }
    $packageMatch = [regex]::Match(
        $source,
        '(?m)^package\s+([A-Za-z0-9_`-]+):'
    )
    if (-not $packageMatch.Success) {
        $failures.Add("$($recipe.Name): missing package declaration")
        continue
    }

    $packageName = $packageMatch.Groups[1].Value.Trim('`')
    if ($recipe.Name -eq 'create-dmg') {
        if ($packageName -ne 'create-dmg') {
            $failures.Add("$($recipe.Name): expected package identity create-dmg, got $packageName")
        }
    }
    elseif (-not $packageName.EndsWith('Source', [StringComparison]::Ordinal)) {
        $failures.Add("$($recipe.Name): private recipe package identity must end in Source, got $packageName")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "Validated $($recipes.Count) source recipes with private implementation identities."

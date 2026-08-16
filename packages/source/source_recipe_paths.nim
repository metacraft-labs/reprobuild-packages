import std/os

import repro_project_dsl

const DefaultSourceRecipeRoot =
  "/opt/repro/reprobuild-packages/packages/source"

proc sourceRecipeRoot*(): string =
  let providerRoot = activeProviderProjectRoot()
  let providerCatalogRoot =
    if providerRoot.len > 0: parentDir(providerRoot)
    else: DefaultSourceRecipeRoot
  getEnv("REPRO_FROM_SOURCE_ROOT",
    getEnv("REPROBUILD_RECIPE_ROOT", providerCatalogRoot))

proc sourcePackageRoot*(packageName: string): string =
  joinPath(sourceRecipeRoot(), packageName)

proc sourcePackageInstallRoot*(packageName: string): string =
  packageInstallMirrorRoot(sourceRecipeRoot(), packageName)

proc sourcePackageInstallPath*(packageName: string,
                               pathParts: varargs[string]): string =
  result = sourcePackageInstallRoot(packageName)
  for pathPart in pathParts:
    result = joinPath(result, pathPart)

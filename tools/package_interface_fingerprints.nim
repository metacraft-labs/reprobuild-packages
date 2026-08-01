import std/[algorithm, sequtils, strutils]

import repro_interface_artifacts
import repro_project_dsl

import ../packages/source/bash/repro as bashRecipe
import ../packages/source/busybox/repro as busyboxRecipe
import ../packages/source/cmake/repro as cmakeRecipe

const PublishedPackages = ["bash", "busybox", "cmake"]

let packages = registeredPackages()
var selected = packages.filterIt(
  it.packageName in PublishedPackages and
  it.sourceFile.replace('\\', '/').endsWith(
    "/packages/source/" & it.packageName & "/repro.nim"))
selected.sort(proc (a, b: PackageDef): int = cmp(a.packageName, b.packageName))

if selected.len != PublishedPackages.len:
  raise newException(ValueError,
    "expected package registrations " & PublishedPackages.join(", ") &
    "; got " & packages.mapIt(it.packageName).join(", "))
for packageDef in selected:
  echo packageDef.packageName, " ",
    canonicalPackageInterfaceFingerprint(packageDef, packages)

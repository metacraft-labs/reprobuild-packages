import std/[algorithm, sequtils, strutils]

import repro_interface_artifacts
import repro_project_dsl

import repro_dsl_stdlib/packages/bash as bashInterface
import repro_dsl_stdlib/packages/cmake as cmakeInterface
import ../packages/interfaces/busybox/repro as busyboxInterface
import ../packages/interfaces/llvm/repro as llvmInterface
import ../packages/interfaces/patchelf/repro as patchelfInterface

const PublishedPackages = ["bash", "busybox", "cmake", "llvm", "patchelf"]

let packages = registeredPackages()
var selected = packages.filterIt(
  it.packageName in PublishedPackages)
selected.sort(proc (a, b: PackageDef): int = cmp(a.packageName, b.packageName))

if selected.len != PublishedPackages.len:
  raise newException(ValueError,
    "expected one canonical registration for each of " &
    PublishedPackages.join(", ") & "; got " &
    selected.mapIt(it.packageName).join(", "))
for packageDef in selected:
  echo packageDef.packageName, " ",
    canonicalPackageInterfaceFingerprint(packageDef, packages)

## Integration control: run the normal runtime source build before this file.
## Selection is made from a real canonical library-only consumer declaration;
## no executable or synthetic provisioning record stands in for the library.
import std/[os, json]
import repro_project_dsl
import repro_interface_artifacts
import repro_tool_profiles
import "../../../interfaces/tree-sitter-runtime/repro"

package treeSitterRuntimeSelectionControl:
  uses:
    "tree-sitter-runtime"

let root = currentSourcePath.parentDir.parentDir
let packages = registeredPackages()
var selected: InterfaceToolUse
var found = false
for pkg in packages:
  if pkg.packageName == "treeSitterRuntimeSelectionControl":
    let iface = toProjectInterface(pkg, packages)
    doAssert iface.toolUses.len == 1
    selected = iface.toolUses[0]
    found = true
doAssert found
doAssert selected.packageSelector == "tree-sitter-runtime"
let resolved = tryResolveFromSourceTool(selected, root.parentDir)
doAssert resolved.kind == rrResolved
let profile = resolved.profile
let includeRoot = root / ".repro/output/install/usr/include"
let libraryRoot = root / ".repro/output/install/usr/lib"
doAssert absolutePath(includeRoot) in profile.cpathList
doAssert absolutePath(libraryRoot) in profile.libraryPathList
doAssert readFile(profile.resolvedExecutablePath)[0 ..< 8] == "!<arch>\n"
echo $(%*{
  "selector": selected.packageSelector,
  "installMethod": profile.installMethod,
  "resolvedLibrary": profile.resolvedExecutablePath,
  "includeDirs": profile.cpathList,
  "libDirs": profile.libraryPathList
})

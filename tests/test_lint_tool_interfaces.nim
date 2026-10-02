## The lint and formatting tools' interfaces: every hand-written identity in
## a release-archive slice has to agree with the others.
##
## A slice spells its version, platform and digest several times over -- in
## the URL, the `packageId`, the `cpu`/`os` pair and the `lockIdentity` -- and
## each is typed by hand. A bump or a copied slice that updated one and not
## the others still compiles and still realizes, but locks one thing and
## fetches another: the lock would name the Windows digest for a Linux slice,
## or two slices would claim the same platform and the first would silently
## win. These cases read the registered slices back and hold them to one
## shape. They say nothing about whether a digest is RIGHT -- each module's
## header records how its digests were checked against the downloaded bytes.

import std/[os, sequtils, sets, strutils, unittest]

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

import ../packages/interfaces/shellcheck/repro as shellcheckInterface
import ../packages/interfaces/shfmt/repro as shfmtInterface
import ../packages/interfaces/typos/repro as typosInterface
import ../packages/interfaces/prek/repro as prekInterface
import ../packages/interfaces/nixfmt/repro as nixfmtInterface
import ../packages/interfaces/repomix/repro as repomixInterface

const Interfaces = [
  ("shellcheck", "0.11.0", "https://github.com/koalaman/shellcheck/releases/download/v0.11.0/"),
  ("shfmt", "3.12.0", "https://github.com/mvdan/sh/releases/download/v3.12.0/"),
  ("typos", "1.45.0", "https://github.com/crate-ci/typos/releases/download/v1.45.0/"),
  ("prek", "0.3.2", "https://github.com/j178/prek/releases/download/v0.3.2/"),
  ("nixfmt", "1.2.0", "https://github.com/NixOS/nixfmt/releases/download/v1.2.0/"),
]

proc interfaceNamed(name: string): PackageDef =
  let hits = registeredPackages().filterIt(it.packageName == name)
  doAssert hits.len == 1, "expected exactly one interface named " & name &
    ", found " & $hits.len
  hits[0]

suite "lint tool interfaces":
  test "every slice's identity agrees with its URL, platform and digest":
    for (name, version, releaseBase) in Interfaces:
      let pkg = interfaceNamed(name)
      for slice in pkg.tarballProvisioning:
        checkpoint(name & " " & slice.os & "-" & slice.cpu & ": " & slice.url)
        check slice.url.startsWith(releaseBase)
        check slice.packageId == name & "@" & version
        check slice.sha256.len == 64
        check slice.sha256.allIt(it in {'0' .. '9', 'a' .. 'f'})
        check slice.lockIdentity == "tarball:" & name & "@" & version & ":" &
          slice.os & "-" & slice.cpu & ":sha256:" & slice.sha256

  test "no platform is claimed twice, and every slice names one":
    for (name, _, _) in Interfaces:
      var seen = initHashSet[string]()
      for slice in interfaceNamed(name).tarballProvisioning:
        checkpoint(name & " " & slice.url)
        check slice.cpu in ["x86_64", "aarch64"]
        check slice.os in ["windows", "linux", "macos"]
        let key = slice.os & "-" & slice.cpu
        check key notin seen
        seen.incl(key)

  test "the command is the package's own name on every platform":
    for (name, _, _) in Interfaces:
      let pkg = interfaceNamed(name)
      for slice in pkg.tarballProvisioning:
        checkpoint(name & " " & slice.os & "-" & slice.cpu)
        let expected = (if slice.os == "windows": name & ".exe" else: name)
        check slice.executablePath == expected
      check pkg.nixProvisioning.len == 1
      check pkg.nixProvisioning[0].selector == "nixpkgs#" & name
      check pkg.nixProvisioning[0].executablePath == "bin/" & name
      check pkg.nixProvisioning[0].nixpkgsRev == CanonicalNixpkgsRev

  test "archives that wrap their payload in a directory strip it":
    # shellcheck's and prek's tarballs put the binary under a
    # `<name>-<version-or-target>/` directory; typos's tarballs and every zip
    # here hold it at the root. A wrong strip realizes a prefix whose
    # declared command does not exist.
    for (name, _, _) in Interfaces:
      for slice in interfaceNamed(name).tarballProvisioning:
        checkpoint(name & " " & slice.url)
        let wrapped =
          (name == "shellcheck" and slice.archiveType == "tar.xz") or
          (name == "prek" and slice.archiveType == "tar.gz")
        check slice.stripComponents == (if wrapped: 1 else: 0)

suite "repomix's npm realization":
  # Not a release archive: the npm registry tarball, run by `node`, with its
  # runtime dependency closure from `closures/repomix.manifest`. So it is
  # held to its own shape rather than the release-archive one above.
  let pkg = interfaceNamed("repomix")
  let manifestPath = currentSourcePath.parentDir.parentDir / "packages" /
    "interfaces" / "repomix" / "closures" / "repomix.manifest"

  test "one platform-neutral slice, launched by node":
    check pkg.tarballProvisioning.len == 1
    let slice = pkg.tarballProvisioning[0]
    # JavaScript and WebAssembly: the same bytes on every host.
    check slice.cpu == ""
    check slice.os == ""
    check slice.url == "https://registry.npmjs.org/repomix/-/repomix-1.18.1.tgz"
    check slice.packageId == "repomix@1.18.1"
    check slice.lockIdentity == "tarball:repomix@1.18.1:sha256:" & slice.sha256
    check slice.stripComponents == 1
    check slice.executablePath == "bin/repomix.cjs"
    check slice.executableAlias == "repomix"
    check slice.launcher == "node"
    check slice.closureManifest == "closures/repomix.manifest"
    check pkg.nixProvisioning.len == 1
    check pkg.nixProvisioning[0].selector == "nixpkgs#repomix"

  test "every closure entry is a pinned registry archive under node_modules":
    var paths = initHashSet[string]()
    var count = 0
    for line in readFile(manifestPath).splitLines():
      if line.len == 0 or line.startsWith("#"):
        continue
      let fields = line.splitWhitespace()
      checkpoint(line)
      check fields.len == 3
      check fields[0].startsWith("node_modules/")
      check ".." notin fields[0]
      check fields[0] notin paths
      paths.incl(fields[0])
      check fields[1].len == 64
      check fields[1].allIt(it in {'0' .. '9', 'a' .. 'f'})
      check fields[2].startsWith("https://registry.npmjs.org/")
      inc count
    # The 170 archives `npm install --omit=dev` installs for 1.18.1 from
    # upstream's lock. A count that moved without the version moving means
    # the pin and its closure have come apart.
    check count == 170
    # Two of them nest a second version under their dependent, where npm
    # puts a version that conflicts with the hoisted one.
    check "node_modules/body-parser/node_modules/content-type" in paths

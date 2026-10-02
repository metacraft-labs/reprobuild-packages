## The lint and formatting tools' interfaces (RunQuota's, and reprobuild's
## `actionlint`): every hand-written identity in
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

import std/[sequtils, sets, strutils, unittest]

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

import ../packages/interfaces/shellcheck/repro as shellcheckInterface
import ../packages/interfaces/shfmt/repro as shfmtInterface
import ../packages/interfaces/typos/repro as typosInterface
import ../packages/interfaces/prek/repro as prekInterface
import ../packages/interfaces/nixfmt/repro as nixfmtInterface
import ../packages/interfaces/repomix/repro as repomixInterface
import ../packages/interfaces/actionlint/repro as actionlintInterface

const Interfaces = [
  ("shellcheck", "0.11.0", "https://github.com/koalaman/shellcheck/releases/download/v0.11.0/"),
  ("shfmt", "3.12.0", "https://github.com/mvdan/sh/releases/download/v3.12.0/"),
  ("typos", "1.45.0", "https://github.com/crate-ci/typos/releases/download/v1.45.0/"),
  ("prek", "0.3.2", "https://github.com/j178/prek/releases/download/v0.3.2/"),
  ("nixfmt", "1.2.0", "https://github.com/NixOS/nixfmt/releases/download/v1.2.0/"),
  ("repomix", "", ""),
  ("actionlint", "1.7.9", "https://github.com/rhysd/actionlint/releases/download/v1.7.9/"),
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

## Generate a `hackage-vendor.manifest` from a cabal `plan.json`.
##
## A from-source Haskell recipe (`cabal_package` / the `from-source-cabal`
## convention in reprobuild) builds offline against a `file+noindex`
## repository holding exactly its pinned Hackage closure. This tool writes
## the committed description of that repository from the plan cabal made.
##
## Usage:
##
##     nim r tools/hackage_closure_manifest.nim \
##       --plan=<dist-newstyle/cache/plan.json> --out=<manifest> \
##       [--index-state=<the index-state the plan was solved at>] \
##       [--cache=<dir>]
##
## ## Making the plan
##
## Solve the build with the same compiler and patches the recipe uses, from
## the patched source tree, against a pinned Hackage index state, with a
## throw-away `CABAL_DIR` so nothing of the user's own cabal setup enters
## the plan:
##
##     export CABAL_DIR=$(mktemp -d)
##     cabal update 'hackage.haskell.org,<index-state>'
##     cabal build <target> --dry-run      # writes dist-newstyle/cache/plan.json
##
## ## What is verified
##
## `plan.json` records, for every package taken from Hackage, the SHA-256
## of its source tarball (`pkg-src-sha256`) and of the package description
## the solver used (`pkg-cabal-sha256`, which differs from the tarball's own
## `.cabal` when Hackage carries a revision). Every tarball is downloaded and
## checked against the first. For the second, Hackage's revision list is
## searched for the revision with that digest; a revision other than 0 is
## downloaded, checked, and recorded as `<name>-<version>.cabal`, which
## cabal reads in place of the tarball's description. Any mismatch stops the
## tool, so the manifest is bound to the plan rather than to whatever Hackage
## served on the day.
##
## The format, and the reader the build uses, live in reprobuild's
## `repro_core/hackage_closure`, which this tool writes through: a manifest
## it writes is by construction one the build can read.

import std/[algorithm, json, os, osproc, strutils, tables]

import nimcrypto/sha2

import repro_core/hackage_closure

type
  Planned = object
    name, version, srcSha256, cabalSha256: string

proc die(message: string) {.noreturn.} =
  stderr.writeLine("hackage-closure-manifest: " & message)
  quit(1)

proc sha256Hex(data: string): string =
  var bytes = newSeq[byte](data.len)
  if data.len > 0:
    copyMem(addr bytes[0], unsafeAddr data[0], data.len)
  toLowerAscii($sha256.digest(bytes))

proc fetch(url, cacheDir, name: string): string =
  ## Through a cache keyed by file name, so a re-run does not download
  ## again. `curl` rather than an in-process client: this tool runs when a
  ## pin moves, not in a build, and that keeps it free of a TLS build flag.
  let target = cacheDir / name
  if not fileExists(target):
    let part = target & ".part"
    removeFile(part)
    let res = execCmdEx("curl -fsSL --retry 5 --retry-all-errors -o " & quoteShell(part) & " " &
      quoteShell(url))
    if res.exitCode != 0 or not fileExists(part):
      die("download failed: " & url & "\n" & res.output)
    moveFile(part, target)
  readFile(target)

proc revisions(packageId, cacheDir: string): JsonNode =
  let target = cacheDir / (packageId & ".revisions.json")
  if not fileExists(target):
    let url = HackageDownloadBase & packageId & "/revisions/"
    let res = execCmdEx("curl -fsSL --retry 5 --retry-all-errors -H " &
      quoteShell("Accept: application/json") & " -o " & quoteShell(target) &
      " " & quoteShell(url))
    if res.exitCode != 0:
      die("cannot list the revisions of " & packageId & ": " & res.output)
  parseFile(target)

proc plannedPackages(plan: JsonNode): seq[Planned] =
  ## Every package the plan takes from a Hackage repository, once (a plan
  ## lists one unit per component, so a package with a library and an
  ## executable appears twice). Packages GHC ships (`pre-existing`) and the
  ## project's own (`local`) are not part of the closure.
  var seen = initTable[string, Planned]()
  for unit in plan{"install-plan"}:
    let src = unit{"pkg-src"}
    if src.isNil or src{"type"}.getStr() != "repo-tar":
      continue
    let repoUri = src{"repo", "uri"}.getStr()
    if "hackage.haskell.org" notin repoUri:
      die(unit{"pkg-name"}.getStr() & " comes from " & repoUri &
        ", not Hackage; only Hackage packages can be pinned")
    let p = Planned(name: unit{"pkg-name"}.getStr(),
      version: unit{"pkg-version"}.getStr(),
      srcSha256: unit{"pkg-src-sha256"}.getStr().toLowerAscii(),
      cabalSha256: unit{"pkg-cabal-sha256"}.getStr().toLowerAscii())
    if p.srcSha256.len != 64 or p.cabalSha256.len != 64:
      die(p.name & "-" & p.version & " has no tarball or description " &
        "digest in the plan")
    let id = p.name & "-" & p.version
    if seen.hasKey(id):
      if seen[id] != p:
        die(id & " appears twice in the plan with different digests")
    else:
      seen[id] = p
  for _, p in seen.pairs:
    result.add(p)
  result.sort(proc (a, b: Planned): int = cmp(a.name & "-" & a.version,
    b.name & "-" & b.version))

when isMainModule:
  var planPath, outPath, indexState = ""
  var cacheDir = getTempDir() / "hackage-closure-manifest"
  for i in 1 .. paramCount():
    let arg = paramStr(i)
    if arg.startsWith("--plan="): planPath = arg["--plan=".len .. ^1]
    elif arg.startsWith("--out="): outPath = arg["--out=".len .. ^1]
    elif arg.startsWith("--index-state="):
      indexState = arg["--index-state=".len .. ^1]
    elif arg.startsWith("--cache="): cacheDir = arg["--cache=".len .. ^1]
    else: die("unknown argument: " & arg)
  if planPath.len == 0 or outPath.len == 0:
    die("usage: --plan=<plan.json> --out=<manifest> " &
      "[--index-state=<state>] [--cache=<dir>]")
  if not fileExists(planPath):
    die("no plan at " & planPath)
  let plan = parseFile(planPath)
  let packages = plannedPackages(plan)
  if packages.len == 0:
    die("the plan takes nothing from Hackage; no manifest is needed")
  createDir(cacheDir)

  var entries: seq[HackageVendorEntry] = @[]
  var revised = 0
  for i, p in packages:
    let id = p.name & "-" & p.version
    stderr.writeLine("[" & $(i + 1) & "/" & $packages.len & "] " & id)
    let tarball = fetch(sdistUrl(id), cacheDir, id & ".tar.gz")
    if sha256Hex(tarball) != p.srcSha256:
      die(id & ".tar.gz: Hackage served sha256 " & sha256Hex(tarball) &
        ", the plan pins " & p.srcSha256)
    entries.add(HackageVendorEntry(fileName: id & ".tar.gz",
      sha256: p.srcSha256, url: sdistUrl(id)))
    var revision = -1
    for r in revisions(id, cacheDir):
      if r{"sha256"}.getStr().toLowerAscii() == p.cabalSha256:
        revision = r{"number"}.getInt()
    if revision < 0:
      die(id & ": no Hackage revision of its description has the digest " &
        "the plan used (" & p.cabalSha256 & ")")
    if revision > 0:
      let cabalFile = fetch(revisionUrl(id, revision), cacheDir,
        id & ".r" & $revision & ".cabal")
      if sha256Hex(cabalFile) != p.cabalSha256:
        die(id & " revision " & $revision & ": Hackage served a different " &
          "description than the plan used")
      entries.add(HackageVendorEntry(fileName: id & ".cabal",
        sha256: p.cabalSha256, url: revisionUrl(id, revision)))
      inc revised

  let compiler = plan{"compiler-id"}.getStr("?")
  let platform = plan{"os"}.getStr("?") & "-" & plan{"arch"}.getStr("?")
  var comments = @[
    "GENERATED by reprobuild-packages tools/hackage_closure_manifest.nim",
    "-- do not hand-edit.",
    "",
    "The Hackage closure of a cabal plan solved with " & compiler &
      " for " & platform &
      (if indexState.len > 0: " at index-state " & indexState else: "") &
      ":",
    $packages.len & " source tarballs, and the revised description of the " &
      $revised & " whose plan used a Hackage revision. Every digest is the",
    "one plan.json recorded, checked against the downloaded file."]
  createDir(parentDir(absolutePath(outPath)))
  writeFile(outPath, renderHackageVendorManifest(entries, comments))
  # Read it back through the parser the build uses.
  discard parseHackageVendorManifest(readFile(outPath))
  stderr.writeLine("wrote " & $entries.len & " entries to " & outPath)

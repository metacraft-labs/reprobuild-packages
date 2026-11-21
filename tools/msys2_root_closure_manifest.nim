## Generate the `closureManifest` of an MSYS root composite from a pinned
## MSYS2 package database snapshot.
##
## An MSYS root is a directory with MSYS2's own layout (`usr/bin/msys-2.0.dll`,
## `usr/bin/make.exe`, `usr/bin/sh.exe`, ...) built from pinned package files,
## never by running `pacman`. The realization unpacks one package as the
## tarball's primary archive and every other package of the closure over the
## same root (closure entries whose destination is `.`). This tool computes
## that closure from the packages the root must provide, following each
## package's `%DEPENDS%` through `%PROVIDES%`, exactly as pacman would, and
## writes the entries in dependency order with the digests the database
## records for each package file.
##
## Usage:
##
##     nim r tools/msys2_root_closure_manifest.nim \
##       --db=<msys.db> --primary=<package> --root=<package> [--root=...] \
##       [--mirror=https://repo.msys2.org/msys/x86_64] [--out=<manifest>] \
##       [--check=<committed manifest>]
##
## `--db` is a snapshot of the repository database (`msys.db`, a
## zstd-compressed tar of one `<name>-<version>/desc` per package). Its
## SHA-256 is written into the manifest header, so a regeneration from a
## different snapshot is visible in review. `--primary` names the package the
## recipe's primary archive is (it is resolved like any other, and left out of
## the manifest). `--check` regenerates and fails, naming the first
## difference, when the committed manifest's entries differ from the output.
##
## The database is unpacked with the host's `zstd` and `tar`; nothing is
## downloaded. The digests are the database's `%SHA256SUM%`, the same values
## pacman verifies.

import std/[algorithm, os, osproc, sequtils, strutils, tables]

import nimcrypto/[hash, sha2]

type
  MsysPackage* = object
    name*: string
    version*: string
    filename*: string
    sha256*: string
    depends*: seq[string]
    provides*: seq[string]

  ClosureError* = object of ValueError

proc fail(message: string) {.noreturn.} =
  raise newException(ClosureError, "msys2-root-closure-manifest: " & message)

proc bareName(constraint: string): string =
  ## `libintl>=0.22` -> `libintl`; `sh` -> `sh`.
  result = constraint.strip()
  for op in [">=", "<=", "=", ">", "<"]:
    let at = result.find(op)
    if at > 0:
      result = result[0 ..< at]
      break

proc parseDesc*(text: string): MsysPackage =
  ## One `desc` file: `%KEY%` lines, each followed by its values up to a blank
  ## line.
  var key = ""
  for raw in text.splitLines():
    let line = raw.strip()
    if line.len == 0:
      key = ""
      continue
    if line.startsWith("%") and line.endsWith("%") and line.len > 2:
      key = line
      continue
    case key
    of "%NAME%": result.name = line
    of "%VERSION%": result.version = line
    of "%FILENAME%": result.filename = line
    of "%SHA256SUM%": result.sha256 = line.toLowerAscii
    of "%DEPENDS%": result.depends.add(line)
    of "%PROVIDES%": result.provides.add(line)
    else: discard

proc readDatabaseDir*(dir: string): seq[MsysPackage] =
  ## Every `*/desc` under an unpacked database directory.
  for kind, entry in walkDir(dir):
    if kind == pcDir and fileExists(entry / "desc"):
      let pkg = parseDesc(readFile(entry / "desc"))
      if pkg.name.len == 0 or pkg.filename.len == 0 or pkg.sha256.len != 64:
        fail("malformed database entry " & entry & "/desc")
      result.add(pkg)
  result.sort(proc(a, b: MsysPackage): int = cmp(a.name, b.name))

proc readDatabase*(dbPath: string): seq[MsysPackage] =
  let scratch = getTempDir() / ("msys2-db-" & $getCurrentProcessId())
  removeDir(scratch)
  createDir(scratch)
  defer: removeDir(scratch)
  let unpacked = execCmdEx("zstd -dc " & quoteShell(dbPath) & " | tar -x -C " &
    quoteShell(scratch))
  if unpacked.exitCode != 0:
    fail("could not unpack " & dbPath & ": " & unpacked.output)
  readDatabaseDir(scratch)

proc resolveClosure*(packages: openArray[MsysPackage];
                     roots: openArray[string]): seq[MsysPackage] =
  ## The packages `roots` need, dependencies before dependents. A dependency
  ## is satisfied by a package of that name, else by the one package that
  ## provides it; none, or several providers, is an error (a closure is
  ## pinned, so an ambiguity is a decision for the recipe, not this tool).
  ## Ties are broken by name, so the order is deterministic.
  var byName = initTable[string, MsysPackage]()
  var providers = initTable[string, seq[string]]()
  for pkg in packages:
    byName[pkg.name] = pkg
    for provided in pkg.provides:
      providers.mgetOrPut(bareName(provided), @[]).add(pkg.name)
  proc lookup(want, wantedBy: string): string =
    if byName.hasKey(want):
      return want
    let candidates = providers.getOrDefault(want)
    if candidates.len == 1:
      return candidates[0]
    if candidates.len == 0:
      fail("no package is or provides " & want & " (needed by " & wantedBy &
        ")")
    fail("several packages provide " & want & " (needed by " & wantedBy &
      "): " & candidates.sorted().join(", ") & "; name one as a --root")
  var state = initTable[string, int]()   # 1 = visiting, 2 = done
  var order: seq[MsysPackage]
  proc visit(name, wantedBy: string) =
    let resolved = lookup(name, wantedBy)
    let current = state.getOrDefault(resolved)
    if current == 2:
      return
    if current == 1:
      # pacman tolerates dependency cycles (msys2-runtime and its users);
      # the order inside a cycle is immaterial to an unpack that never
      # overwrites.
      return
    state[resolved] = 1
    let pkg = byName[resolved]
    for dep in pkg.depends.mapIt(bareName(it)).sorted():
      visit(dep, resolved)
    state[resolved] = 2
    order.add(pkg)
  for root in roots:
    visit(root, "--root")
  order

proc manifestLines*(closure: openArray[MsysPackage];
                    primary, mirror: string): seq[string] =
  for pkg in closure:
    if pkg.name == primary:
      continue
    result.add(". " & pkg.sha256 & " " & mirror.strip(chars = {'/'},
      leading = false) & "/" & pkg.filename & " tar.zst 0")

proc entryLines*(text: string): seq[string] =
  for raw in text.splitLines():
    let line = raw.strip()
    if line.len > 0 and not line.startsWith("#"):
      result.add(line.splitWhitespace().join(" "))

proc renderManifest*(closure: openArray[MsysPackage];
                     primary, mirror, dbDigest: string;
                     roots: openArray[string]): string =
  var primaryLine = ""
  for pkg in closure:
    if pkg.name == primary:
      primaryLine = pkg.filename & " sha256 " & pkg.sha256
  if primaryLine.len == 0:
    fail("the primary package " & primary & " is not in the closure of " &
      roots.join(", "))
  result = "# Generated by tools/msys2_root_closure_manifest.nim; do not edit.\n" &
    "# MSYS2 package database snapshot: sha256 " & dbDigest & "\n" &
    "# Roots: " & roots.join(" ") & "\n" &
    "# Primary archive (the recipe's tarball): " & primaryLine & "\n" &
    "# Every line is unpacked over the prefix root, dependencies first.\n"
  for line in manifestLines(closure, primary, mirror):
    result.add(line & "\n")

proc fileSha256(path: string): string =
  toLowerAscii($sha256.digest(readFile(path)))

when isMainModule:
  var db, primary, outPath, check = ""
  var mirror = "https://repo.msys2.org/msys/x86_64"
  var roots: seq[string]
  for arg in commandLineParams():
    let (key, value) =
      if "=" in arg: (arg.split('=', 1)[0], arg.split('=', 1)[1])
      else: (arg, "")
    case key
    of "--db": db = value
    of "--primary": primary = value
    of "--root": roots.add(value)
    of "--mirror": mirror = value
    of "--out": outPath = value
    of "--check": check = value
    else:
      stderr.writeLine("msys2-root-closure-manifest: unknown argument " & arg)
      quit(2)
  if db.len == 0 or primary.len == 0 or roots.len == 0:
    stderr.writeLine("usage: msys2_root_closure_manifest --db=<msys.db> " &
      "--primary=<package> --root=<package>... [--mirror=<url>] " &
      "[--out=<manifest>] [--check=<manifest>]")
    quit(2)
  try:
    let closure = resolveClosure(readDatabase(db), @[primary] & roots)
    let text = renderManifest(closure, primary, mirror, fileSha256(db), roots)
    if check.len > 0:
      let committed = entryLines(readFile(check))
      let generated = entryLines(text)
      if committed != generated:
        for i in 0 ..< max(committed.len, generated.len):
          let a = if i < committed.len: committed[i] else: "<none>"
          let b = if i < generated.len: generated[i] else: "<none>"
          if a != b:
            stderr.writeLine("msys2-root-closure-manifest: " & check &
              " differs from the database at entry " & $(i + 1) &
              ":\n  committed: " & a & "\n  generated: " & b)
            break
        quit(1)
      echo "msys2-root-closure-manifest: " & check & " matches (" &
        $generated.len & " entries)"
    elif outPath.len > 0:
      writeFile(outPath, text)
    else:
      stdout.write(text)
  except ClosureError as err:
    stderr.writeLine(err.msg)
    quit(1)

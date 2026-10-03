## Generate a `closureManifest` from an npm lock file.
##
## A tarball realization of an npm package (`launcher = "node"`) unpacks the
## package's own registry archive. When that package is not a self-contained
## bundle -- its code `require`s/`import`s its dependencies from
## `node_modules` -- the realization also names a `closureManifest`: a
## committed list of pinned archives that realize unpacks into the prefix
## beside it (`TarballProvisioningDef.closureManifest` in reprobuild's
## `repro_project_dsl/types`). This tool writes that list from the lock file
## upstream committed, so a version bump is a command rather than a
## transcription.
##
## Usage:
##
##     nim r tools/npm_closure_manifest.nim \
##       --lock=<package-lock.json> --out=<manifest> \
##       [--lock-source=<where the lock came from, for the header>] \
##       [--expect=<name>@<version>] [--root=<lock key>] \
##       [--platform=<npm-os>-<npm-cpu>] [--cache=<dir>]
##
## ## What the closure is
##
## The RUNTIME closure of one package -- what `npm install --omit=dev`
## would put under that package's `node_modules` -- walked the way npm
## resolves a `require`:
##
## * From the root entry, follow `dependencies`, `optionalDependencies` and
##   the non-optional `peerDependencies` (npm 7+ installs those).
##   `devDependencies` and optional peers are never followed.
## * Each dependency name is resolved from the DEPENDENT's position in the
##   tree: `<dependent>/node_modules/<name>` first, then the same probe in
##   every ancestor, ending at the root's `node_modules`. That is npm's own
##   lookup, and it is what keeps two versions of one package apart when the
##   lock nests the second one under the dependent that needs it.
## * An optional dependency the lock does not carry, or whose `os`/`cpu`
##   constraints exclude the platform, is skipped, as npm skips it. A
##   required one in either position is an error.
## * An entry npm marks `inBundle` ships inside its dependent's archive and
##   has no archive of its own.
##
## `--root` defaults to the lock's own project (the `""` entry): the lock an
## upstream commits in its repository pins the dependency tree of the package
## it publishes, so the published package is the root. `--expect` checks that
## the lock's root really is the package and version the recipe pins.
##
## A closure whose members carry `os`/`cpu` constraints is platform-specific
## and needs `--platform`; without it such a closure is refused rather than
## written as if it were neutral.
##
## ## What is verified
##
## npm pins every archive by its `integrity` (an SRI digest, normally
## sha512); reprobuild's realize step verifies sha256. So every archive is
## downloaded once, CHECKED against the lock's `integrity` -- a mismatch, or an
## entry with no `integrity`, stops the tool -- and only then hashed with
## sha256 for the manifest. The sha256 in the manifest is therefore bound to
## the digest upstream's lock file committed to, not merely to whatever the
## URL served at generation time.

import std/[algorithm, base64, json, os, osproc, sets, strformat, strutils,
            tables]

import nimcrypto/[sha, sha2]

type
  ClosureEntry = object
    key: string        ## the lock's `packages` key
    path: string       ## where it lands, relative to the realized prefix
    url: string
    integrity: string

proc die(message: string) {.noreturn.} =
  stderr.writeLine("npm-closure-manifest: " & message)
  quit(1)

proc parentScope(key: string): string =
  ## The tree position one level up from `key`, for npm's ancestor walk.
  ##
  ## `node_modules/a/node_modules/@s/b` -> `node_modules/a`;
  ## `node_modules/a` -> `` (the root). A workspace key such as
  ## `packages/cli` resolves through the root next, as npm does.
  let idx = key.rfind("node_modules/")
  if idx <= 0: ""
  else: key[0 ..< idx - 1]

proc resolveDependency(packages: JsonNode; fromKey, name: string): string =
  ## The lock key npm would load `name` from when `fromKey` requires it, or
  ## "" when no position in the tree carries it.
  var scope = fromKey
  while true:
    let candidate =
      if scope.len == 0: "node_modules/" & name
      else: scope & "/node_modules/" & name
    if packages.hasKey(candidate):
      return candidate
    if scope.len == 0:
      return ""
    scope = parentScope(scope)

iterator namesIn(entry: JsonNode; field: string): string =
  let deps = entry{field}
  if not deps.isNil and deps.kind == JObject:
    for name in deps.keys:
      yield name

proc constrained(entry: JsonNode): bool =
  entry.hasKey("os") or entry.hasKey("cpu") or entry.hasKey("libc")

proc admits(entry: JsonNode; platform: string): bool =
  ## npm's `os`/`cpu` check. A `!`-prefixed value excludes; any positive
  ## value means the list is an allow-list.
  if platform.len == 0:
    return true
  let parts = platform.split('-')
  for (field, want) in {"os": parts[0], "cpu": parts[1]}:
    if not entry.hasKey(field):
      continue
    var allowed = false
    var anyPositive = false
    for value in entry[field]:
      let v = value.getStr()
      if v.startsWith("!"):
        if v[1 .. ^1] == want:
          return false
      else:
        anyPositive = true
        if v == want:
          allowed = true
    if anyPositive and not allowed:
      return false
  true

proc walkClosure(packages: JsonNode; root, platform: string):
    seq[ClosureEntry] =
  if not packages.hasKey(root):
    die("the lock file has no entry \"" & root & "\"")
  var seen = initHashSet[string]()
  var stack = @[root]
  var platformSpecific: seq[string] = @[]
  while stack.len > 0:
    let key = stack.pop()
    if key in seen:
      continue
    seen.incl(key)
    let entry = packages[key]
    if entry{"link"}.getBool(false):
      die(key & " is a workspace link, not an archive; a runtime closure " &
        "of a published package cannot contain one")
    if key != root:
      if entry.constrained:
        platformSpecific.add(key)
      if entry{"inBundle"}.getBool(false):
        # Shipped inside its dependent's archive: nothing to fetch, and its
        # own dependencies are bundled with it.
        continue
      if not entry.hasKey("resolved"):
        die("lock entry has no `resolved` url: " & key)
      if not entry.hasKey("integrity"):
        die("lock entry has no `integrity`, so nothing pins its bytes: " & key)
      result.add(ClosureEntry(key: key, url: entry["resolved"].getStr(),
        integrity: entry["integrity"].getStr()))

    proc follow(name: string; optional: bool) =
      let target = resolveDependency(packages, key, name)
      if target.len == 0:
        if optional:
          return
        die(key & " depends on " & name & ", which the lock file does not " &
          "carry anywhere npm would look for it")
      if not packages[target].admits(platform):
        if optional:
          return
        die(key & " requires " & target & ", whose os/cpu constraints " &
          "exclude " & platform)
      stack.add(target)

    for name in entry.namesIn("dependencies"):
      follow(name, optional = false)
    for name in entry.namesIn("optionalDependencies"):
      follow(name, optional = true)
    for name in entry.namesIn("peerDependencies"):
      # An OPTIONAL peer is never installed on its own account -- it is a
      # compatibility range for a package something else may bring (valibot
      # names typescript this way). If something does bring it, that edge
      # reaches it.
      if not entry{"peerDependenciesMeta", name, "optional"}.getBool(false):
        follow(name, optional = false)
  if platform.len == 0 and platformSpecific.len > 0:
    die("the closure has platform-specific members (" &
      platformSpecific.join(", ") & "); generate one manifest per platform " &
      "with --platform=<npm-os>-<npm-cpu>")

proc placeEntries(entries: var seq[ClosureEntry]; root: string) =
  ## Where each archive lands relative to the realized prefix, which holds
  ## the ROOT package's own archive. For the default root the lock's keys
  ## already are those paths. For a nested root, entries under it move up
  ## and hoisted ones stay where npm put them, and two that would land on
  ## one path are refused rather than silently overwritten.
  var taken = initTable[string, string]()
  for entry in entries.mitems:
    entry.path =
      if root.len > 0 and entry.key.startsWith(root & "/"):
        entry.key[root.len + 1 .. ^1]
      else:
        entry.key
    if taken.hasKey(entry.path):
      die("two closure members land on " & entry.path & ": " &
        taken[entry.path] & " and " & entry.key)
    taken[entry.path] = entry.key
  entries.sort(proc (a, b: ClosureEntry): int = cmp(a.path, b.path))

proc bytesOf(data: string): seq[byte] =
  result = newSeq[byte](data.len)
  if data.len > 0:
    copyMem(addr result[0], unsafeAddr data[0], data.len)

proc sriDigest(algorithm: string; data: string): string =
  ## The base64 digest an SRI string carries, for one algorithm.
  let input = bytesOf(data)
  case algorithm
  of "sha512": encode(sha512.digest(input).data)
  of "sha384": encode(sha384.digest(input).data)
  of "sha256": encode(sha256.digest(input).data)
  of "sha1": encode(sha1.digest(input).data)
  else: ""

proc verifyIntegrity(entry: ClosureEntry; data: string) =
  ## Check the bytes against the lock's SRI `integrity`.
  ##
  ## SRI may list several digests; npm checks the strongest algorithm it
  ## knows, and so does this. An integrity with no algorithm this tool
  ## understands is refused rather than treated as verified.
  var best = ""
  var expected: seq[string] = @[]
  for rank in ["sha512", "sha384", "sha256", "sha1"]:
    for token in entry.integrity.splitWhitespace():
      let dash = token.find('-')
      if dash > 0 and token[0 ..< dash] == rank:
        var digest = token[dash + 1 .. ^1]
        let opt = digest.find('?')
        if opt >= 0:
          digest = digest[0 ..< opt]
        expected.add(digest)
    if expected.len > 0:
      best = rank
      break
  if best.len == 0:
    die("no supported digest in the integrity of " & entry.key & ": " &
      entry.integrity)
  let actual = sriDigest(best, data)
  if actual notin expected:
    die("integrity mismatch for " & entry.key & " (" & entry.url & "): " &
      "the lock pins " & best & "-" & expected[0] & ", the URL served " &
      best & "-" & actual)

proc fetch(url, cacheDir: string): string =
  ## The archive's bytes, through a cache keyed by the URL's path so a
  ## re-run (after a failure, or for a second platform) does not download
  ## again. The cache is only a convenience: every read is verified.
  var name = url
  for prefix in ["https://", "http://"]:
    if name.startsWith(prefix):
      name = name[prefix.len .. ^1]
  var safe = ""
  for ch in name:
    safe.add(if ch in {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '.', '-', '_'}: ch
             else: '_')
  let target = cacheDir / safe
  if not fileExists(target):
    let part = target & ".part"
    removeFile(part)
    let res = execCmdEx("curl -fsSL --retry 5 --retry-all-errors -o " & quoteShell(part) & " " &
      quoteShell(url))
    if res.exitCode != 0 or not fileExists(part):
      die("download failed: " & url & "\n" & res.output)
    moveFile(part, target)
  readFile(target)

when isMainModule:
  var lockPath, outPath, platform, expect, lockSource = ""
  var root = ""
  var cacheDir = getTempDir() / "npm-closure-manifest"
  for i in 1 .. paramCount():
    let arg = paramStr(i)
    if arg.startsWith("--lock="): lockPath = arg["--lock=".len .. ^1]
    elif arg.startsWith("--out="): outPath = arg["--out=".len .. ^1]
    elif arg.startsWith("--root="): root = arg["--root=".len .. ^1]
    elif arg.startsWith("--platform="): platform = arg["--platform=".len .. ^1]
    elif arg.startsWith("--expect="): expect = arg["--expect=".len .. ^1]
    elif arg.startsWith("--lock-source="):
      lockSource = arg["--lock-source=".len .. ^1]
    elif arg.startsWith("--cache="): cacheDir = arg["--cache=".len .. ^1]
    else: die("unknown argument: " & arg)
  if lockPath.len == 0 or outPath.len == 0:
    die("usage: --lock=<package-lock.json> --out=<manifest> " &
      "[--lock-source=<text>] [--expect=<name>@<version>] [--root=<key>] " &
      "[--platform=<npm-os>-<npm-cpu>] [--cache=<dir>]")
  if platform.len > 0 and platform.split('-').len != 2:
    die("--platform must be <npm-os>-<npm-cpu>, e.g. win32-x64")
  if not fileExists(lockPath):
    die("no lock file at " & lockPath)
  let lock = parseFile(lockPath)
  if not lock.hasKey("packages"):
    die("not a lockfileVersion 2/3 lock file (no `packages`): " & lockPath)
  let packages = lock["packages"]
  if expect.len > 0:
    let at = expect.rfind('@')
    if at <= 0:
      die("--expect must be <name>@<version>")
    let entry = packages{root}
    if entry.isNil:
      die("the lock file has no entry \"" & root & "\"")
    var name = entry{"name"}.getStr()
    if name.len == 0 and root.len > 0:
      name = root[root.rfind("node_modules/") + "node_modules/".len .. ^1]
    let version = entry{"version"}.getStr()
    if name != expect[0 ..< at] or version != expect[at + 1 .. ^1]:
      die("the lock's root is " & name & "@" & version & ", not " & expect)

  var entries = walkClosure(packages, root, platform)
  if entries.len == 0:
    die("the closure is empty; a package with no dependencies needs no " &
      "closureManifest")
  placeEntries(entries, root)

  createDir(cacheDir)
  var lines: seq[string] = @[]
  for i, entry in entries:
    stderr.writeLine(&"[{i + 1}/{entries.len}] {entry.path}")
    let data = fetch(entry.url, cacheDir)
    verifyIntegrity(entry, data)
    lines.add(entry.path & " " & toLowerAscii($sha256.digest(bytesOf(data))) &
      " " & entry.url)

  let rootName =
    if expect.len > 0: expect
    elif root.len == 0: packages[""]{"name"}.getStr("the lock's root") & "@" &
      packages[""]{"version"}.getStr("?")
    else: root
  var header = @[
    "# Runtime dependency closure of " & rootName & ".",
    "#",
    "# GENERATED by tools/npm_closure_manifest.nim -- do not hand-edit.",
    "# Every entry is a package npm would install for it (dependencies,",
    "# optional and peer dependencies, never devDependencies), at the",
    "# position and `resolved` URL its lock file records, from:",
    "#   " & (if lockSource.len > 0: lockSource else: lastPathPart(lockPath)),
    "# Each archive was downloaded and checked against the lock's sha512",
    "# `integrity` before its sha256 -- what reprobuild verifies -- was taken.",
    "#",
    "# Format (see TarballProvisioningDef.closureManifest):",
    "#   <prefix-relative-path> <sha256> <url>"]
  if platform.len > 0:
    header.add("#")
    header.add("# For " & platform & ": optional dependencies whose npm os/cpu")
    header.add("# constraints exclude it are omitted.")
  createDir(parentDir(absolutePath(outPath)))
  writeFile(outPath, (header & lines).join("\n") & "\n")
  stderr.writeLine(&"wrote {entries.len} entries to {outPath}")

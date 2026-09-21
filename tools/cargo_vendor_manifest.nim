## Generate a `cargo-vendor.manifest` from an upstream `Cargo.lock`.
##
## This is what a package author runs once, and again whenever the pin
## moves. Its output is committed beside the recipe, because the closure has
## to be readable at graph-emission time and the lockfile it comes from does
## not exist then — the lockfile arrives with the source, which the fetch
## action has not run yet.
##
## Usage:
##
##     nim r tools/cargo_vendor_manifest.nim <Cargo.lock> [<output>]
##
## With no output path the manifest goes to stdout, so a refresh can be
## piped and diffed before it is written:
##
##     nim r tools/cargo_vendor_manifest.nim upstream/Cargo.lock \
##       | diff -u packages/source/just/cargo-vendor.manifest -
##
## The reading and the refusals live in `repro_core/cargo_lock`, which is
## also what the convention reads the committed file back with. One
## implementation, so a manifest this tool writes is by construction one the
## build can read.

import std/[os, osproc, sequtils, streams, strutils]

import repro_core/cargo_lock

proc usage(): string =
  "usage: cargo_vendor_manifest <Cargo.lock> [<output>] [--git-cache DIR]\n" &
  "\n" &
  "Reads a cargo lockfile and writes the pinned vendor manifest the\n" &
  "from-source-cargo convention consumes. Writes to stdout when no output\n" &
  "path is given.\n" &
  "\n" &
  "When the lockfile has git dependencies, each is cloned at its pinned\n" &
  "commit so the crate's subdirectory within the repo can be recorded — a\n" &
  "repo may ship several crates in subdirectories, and only the matching\n" &
  "one is vendored. `--git-cache DIR` reuses clones across runs (default: a\n" &
  "temp directory). Requires `git` and network for git-bearing lockfiles;\n" &
  "a crates.io-only lockfile needs neither."

proc run(cmd: string; args: openArray[string]; cwd = ""): tuple[
    ok: bool, output: string] =
  ## Run a process, capturing merged output. A thin wrapper so the git
  ## calls read as one line each.
  try:
    let p = startProcess(cmd, workingDir = cwd, args = @args,
      options = {poUsePath, poStdErrToStdOut})
    let outp = p.outputStream.readAll()
    let code = p.waitForExit()
    p.close()
    (code == 0, outp)
  except CatchableError as err:
    (false, err.msg)

proc cloneGitAt(url, commit, dest: string) =
  ## Fetch exactly `commit` from `url` into `dest`, once. The commit is an
  ## immutable content address, so a cached tree at it needs no refresh.
  ##
  ## The commit is fetched BY ITS SHA rather than by cloning a branch: a
  ## lockfile can pin a revision that no branch tip points at any more (a
  ## `?rev=` on a commit that has since been built on), and a plain
  ## `git clone` of the default branch would not carry it — the failure is
  ## `unable to read tree`. `git fetch origin <sha>` gets the one commit
  ## GitHub still serves it as reachable. `--depth 1` keeps it to that
  ## commit's tree rather than its whole history.
  if dirExists(dest):
    return
  let part = dest & ".part"
  removeDir(part)
  createDir(part)
  for step in [
      @["init", "--quiet", part],
      @["-C", part, "remote", "add", "origin", url],
      @["-C", part, "fetch", "--quiet", "--depth", "1", "origin", commit],
      @["-C", part, "checkout", "--quiet", "FETCH_HEAD"]]:
    let r = run("git", step)
    if not r.ok:
      quit("cargo_vendor_manifest: git " & step.join(" ") &
        " failed for " & url & " @ " & commit & ":\n" & r.output, 1)
  moveDir(part, dest)

proc findCrateSubdir(repoRoot, crateName: string): string =
  ## The path, relative to `repoRoot` and in POSIX form, of the directory
  ## whose `Cargo.toml` names `crateName` under `[package]`. `.` when the
  ## crate is the repo root. Raises when no such crate is in the tree — a
  ## lockfile that names a crate the repo does not provide is a mismatch the
  ## author has to see, not paper over.
  var found = ""
  for path in walkDirRec(repoRoot, yieldFilter = {pcFile}):
    if path.extractFilename != "Cargo.toml":
      continue
    if "/target/" in path.replace('\\', '/') or
        "\\target\\" in path:
      continue
    let name =
      try: cratePackageName(readFile(path))
      except CatchableError: ""
    if name == crateName:
      let rel = path.parentDir.relativePath(repoRoot).replace('\\', '/')
      if rel.len == 0 or rel == ".":
        return "."
      if found.len > 0 and found != rel:
        quit("cargo_vendor_manifest: crate '" & crateName & "' is defined " &
          "in two directories of the same repo (" & found & " and " & rel &
          "); the manifest cannot choose", 1)
      found = rel
  if found.len == 0:
    quit("cargo_vendor_manifest: crate '" & crateName & "' was not found " &
      "in the cloned git repo under " & repoRoot & "; the lockfile names a " &
      "crate the repo does not provide", 1)
  found

proc resolveGitSubdirs(plan: var seq[VendorEntry]; cacheDir: string) =
  ## Fill each git entry's `gitSubdir` by cloning its repo and finding the
  ## crate. Clones are keyed by commit and shared, so a repo that provides
  ## several crates is cloned once.
  createDir(cacheDir)
  for entry in plan.mitems:
    if not entry.isGit:
      continue
    let clone = cacheDir / ("git-" & entry.gitCommit)
    cloneGitAt(entry.gitUrl, entry.gitCommit, clone)
    entry.gitSubdir = findCrateSubdir(clone, entry.name)

when isMainModule:
  let raw = commandLineParams()
  if raw.len >= 1 and raw[0] in ["-h", "--help"]:
    quit(usage(), 0)
  # Positional args and a `--git-cache DIR` option, in any order.
  var positional: seq[string] = @[]
  var gitCache = ""
  var i = 0
  while i < raw.len:
    if raw[i] == "--git-cache":
      if i + 1 >= raw.len:
        quit("cargo_vendor_manifest: --git-cache needs a directory", 2)
      gitCache = raw[i + 1]
      i += 2
    else:
      positional.add(raw[i])
      i += 1
  if positional.len < 1 or positional.len > 2:
    quit(usage(), 2)
  if gitCache.len == 0:
    gitCache = getTempDir() / "repro-cargo-vendor-git-cache"

  let lockPath = positional[0]
  if not fileExists(lockPath):
    quit("cargo_vendor_manifest: no such file: " & lockPath, 2)

  let text =
    try:
      readFile(lockPath)
    except CatchableError as err:
      quit("cargo_vendor_manifest: cannot read " & lockPath & ": " &
        err.msg, 2)

  let manifest =
    try:
      var plan = vendorPlan(parseCargoLock(text))
      if plan.anyIt(it.isGit):
        # A git-bearing lockfile: clone each git repo at its commit and
        # record the crate's subdirectory. Skipped entirely for a
        # crates.io-only lockfile, which needs neither git nor network.
        resolveGitSubdirs(plan, gitCache)
      renderVendorManifest(plan)
    except CargoLockError as err:
      # The reader's refusals are the useful output here: each one names a
      # lockfile construct that would have produced a closure the build
      # could not satisfy. Passing the message through unchanged is what
      # makes them actionable at the point a recipe is authored rather
      # than at the point somebody else's build fails.
      quit("cargo_vendor_manifest: " & err.msg, 1)

  if positional.len == 2:
    let outputPath = positional[1]
    createDir(outputPath.parentDir)
    writeFile(outputPath, manifest)
    let crates = manifest.strip().splitLines().len - 1
    stderr.writeLine("cargo_vendor_manifest: wrote " & $crates &
      " crates to " & outputPath)
  else:
    stdout.write(manifest)

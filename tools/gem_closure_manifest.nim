## Generate a `gemClosure` manifest from a Nix Ruby-with-gems derivation, and
## check a committed one against it.
##
## A tarball arm of a Ruby SDK that declares `gemClosure` installs exactly the
## gems its committed manifest names, each pinned by SHA-256, offline
## (`TarballProvisioningDef.gemClosure` in reprobuild's
## `repro_project_dsl/types`). On Linux and macOS the same SDK is a Nix
## derivation (`ruby.withPackages (ps: [...])`), and the Nix closure is the
## authority: this tool writes the manifest from it, so the two cannot drift.
##
## Usage:
##
##     nim r tools/gem_closure_manifest.nim \
##       (--file=<default.nix> [--attr=<attr path>] | --flake=<ref>#<attr>) \
##       [--system=x86_64-linux] [--out=<manifest>] [--check=<manifest>] \
##       [--raw-json]
##
## `--file` names a Nix file evaluating to the Ruby-with-gems derivation (a
## function taking `{ system }` is called with `--system`); `--flake` names a
## flake output. `--check` regenerates and exits non-zero, naming the first
## difference, when the committed manifest differs from the closure in any
## name, version, platform, digest or position: the check a consumer runs on
## Linux so that a gem added to or removed from its Nix SDK is never missing
## from, or left over in, the Windows manifest.
##
## ## What the closure is
##
## The gem derivations reachable from the derivation's `gems` through
## `propagatedBuildInputs` (what `ruby.withPackages` installs). nixpkgs builds
## each from `https://rubygems.org/gems/<name>-<version>.gem` and pins it by
## SHA-256, so the manifest's digest is the same bytes in another encoding;
## nothing is downloaded. A gem whose source is not a published `.gem` (a git
## or path gem) has no such pin and is refused.
##
## ## The order
##
## Line order is install order: every gem after the gems it depends on, ties
## broken by name, so the output is deterministic and a gem whose `extconf.rb`
## requires another gem (nokogiri needs `mini_portile2`) is installed after it.

import std/[algorithm, json, os, osproc, sets, strutils, tables]

type
  NixGem* = object
    name*: string
    version*: string
    platform*: string
    url*: string
    sha256*: string
    deps*: seq[string]

  GeneratorError* = object of ValueError

proc fail(message: string) {.noreturn.} =
  raise newException(GeneratorError, "gem-closure-manifest: " & message)

proc nixString(s: string): string = escapeJson(s)

proc closureExpression*(source: string): string =
  ## The Nix expression that lists the gem closure of ``source`` (an
  ## expression evaluating to the Ruby-with-gems derivation) as JSON-ready
  ## attribute sets. Hashes are converted to hex by Nix itself.
  "let\n" &
  "  sdk = " & source & ";\n" &
  "  isGem = d: builtins.isAttrs d && d ? gemName;\n" &
  "  closure = builtins.genericClosure {\n" &
  "    startSet = map (d: { key = d.outPath; drv = d; })\n" &
  "      (builtins.filter isGem (sdk.gems or (throw \"the derivation has no " &
  "`gems`; is it ruby.withPackages?\")));\n" &
  "    operator = item: map (d: { key = d.outPath; drv = d; })\n" &
  "      (builtins.filter isGem (item.drv.propagatedBuildInputs or []));\n" &
  "  };\n" &
  "  hexOf = src: if (src.outputHashAlgo or \"sha256\") != \"sha256\" then " &
  "\"unsupported:\" + (src.outputHashAlgo or \"\") else\n" &
  "    builtins.convertHash { hash = src.outputHash; hashAlgo = \"sha256\"; " &
  "toHashFormat = \"base16\"; };\n" &
  "in map (item: let d = item.drv; in {\n" &
  "  name = d.gemName;\n" &
  "  version = d.version;\n" &
  "  platform = if (d.platform or null) == null then \"ruby\" else d.platform;\n" &
  "  type = d.gemType or \"gem\";\n" &
  "  urls = d.src.urls or (if (d.src.url or \"\") != \"\" then [ d.src.url ] else []);\n" &
  "  sha256 = hexOf d.src;\n" &
  "  deps = map (p: p.gemName) (builtins.filter isGem (d.propagatedBuildInputs or []));\n" &
  "}) closure\n"

proc sourceExpression*(file, attr, flake, system: string): string =
  if flake.len > 0:
    let hash = flake.find('#')
    if hash < 0:
      fail("--flake must be <ref>#<attr>")
    return "(builtins.getFlake " & nixString(flake[0 ..< hash]) & ")." &
      flake[hash + 1 .. ^1]
  if file.len == 0:
    fail("give --file=<nix file> or --flake=<ref>#<attr>")
  let path = absolutePath(file)
  result = "(let f = import " & nixString(path) & "; v = if builtins.isFunction f " &
    "then f { system = " & nixString(system) & "; } else f; in v)"
  if attr.len > 0:
    result = "(" & result & ")." & attr

proc parseGems*(node: JsonNode): seq[NixGem] =
  var seen = initHashSet[string]()
  for item in node:
    let name = item["name"].getStr()
    if name in seen:
      fail("the closure has two versions of " & name & "; a manifest names " &
        "each gem once")
    seen.incl(name)
    let kind = item{"type"}.getStr("gem")
    if kind != "gem":
      fail(name & " is a " & kind & " gem, not a published .gem; it has no " &
        "rubygems.org archive to pin")
    var gem = NixGem(name: name, version: item["version"].getStr(),
      platform: item{"platform"}.getStr("ruby"),
      sha256: item["sha256"].getStr().toLowerAscii)
    if gem.sha256.len != 64 or
        not gem.sha256.allCharsInSet({'0' .. '9', 'a' .. 'f'}):
      fail(name & ": the source hash is not a SHA-256 (" & gem.sha256 & ")")
    let fileName =
      if gem.platform == "ruby": name & "-" & gem.version & ".gem"
      else: name & "-" & gem.version & "-" & gem.platform & ".gem"
    for url in item{"urls"}:
      let text = url.getStr()
      if text.startsWith("https://") and text.endsWith("/" & fileName):
        gem.url = text
        break
    if gem.url.len == 0:
      fail(name & " " & gem.version & ": no https:// source URL ends in " &
        fileName)
    for dep in item{"deps"}:
      gem.deps.add(dep.getStr())
    result.add(gem)

proc installOrder*(gems: openArray[NixGem]): seq[NixGem] =
  ## Dependencies first, ties by name.
  var byName = initTable[string, NixGem]()
  for gem in gems:
    byName[gem.name] = gem
  var names: seq[string]
  for gem in gems:
    names.add(gem.name)
  names.sort()
  var state = initTable[string, int]()
  var order: seq[NixGem]
  proc visit(name: string) =
    if state.getOrDefault(name) != 0:
      return
    state[name] = 1
    var deps = byName[name].deps
    deps.sort()
    for dep in deps:
      if byName.hasKey(dep):
        visit(dep)
    state[name] = 2
    order.add(byName[name])
  for name in names:
    visit(name)
  order

proc manifestLine*(gem: NixGem): string =
  gem.name & " " & gem.version & " " & gem.platform & " " & gem.sha256 & " " &
    gem.url

proc renderManifest*(gems: openArray[NixGem]; origin: string): string =
  result = "# Generated by tools/gem_closure_manifest.nim from " & origin &
    "; do not edit.\n" &
    "# " & $gems.len & " gems. Line order is install order (dependencies " &
    "first).\n" &
    "# <name> <version> <platform> <sha256> <url>\n"
  for gem in gems:
    result.add(manifestLine(gem) & "\n")

proc entryLines*(text: string): seq[string] =
  for raw in text.splitLines():
    let line = raw.strip()
    if line.len > 0 and not line.startsWith("#"):
      result.add(line.splitWhitespace().join(" "))

proc firstDifference*(committed, generated: openArray[string]): string =
  ## "" when equal, else the first differing position, described.
  for i in 0 ..< max(committed.len, generated.len):
    let a = if i < committed.len: committed[i] else: "<none>"
    let b = if i < generated.len: generated[i] else: "<none>"
    if a != b:
      return "line " & $(i + 1) & ":\n  committed: " & a &
        "\n  from Nix:  " & b
  ""

proc evaluateClosureJson*(source: string): string =
  ## The closure as Nix reports it, as JSON text (``closureExpression``).
  let expr = closureExpression(source)
  let res = execCmdEx(quoteShellCommand(@["nix", "eval", "--impure", "--json",
    "--expr", expr]))
  if res.exitCode != 0:
    fail("nix eval failed:\n" & res.output)
  # `nix eval` may print warnings before the value; the value is the last
  # line.
  var jsonText = ""
  for line in res.output.splitLines():
    if line.startsWith("["):
      jsonText = line
  if jsonText.len == 0:
    fail("nix eval printed no value:\n" & res.output)
  jsonText

proc evaluateClosure*(source: string): seq[NixGem] =
  installOrder(parseGems(parseJson(evaluateClosureJson(source))))

when isMainModule:
  var file, attr, flake, outPath, check = ""
  var rawJson = false
  var system = "x86_64-linux"
  for arg in commandLineParams():
    let (key, value) =
      if "=" in arg: (arg.split('=', 1)[0], arg.split('=', 1)[1])
      else: (arg, "")
    case key
    of "--file": file = value
    of "--attr": attr = value
    of "--flake": flake = value
    of "--system": system = value
    of "--out": outPath = value
    of "--check": check = value
    of "--raw-json": rawJson = true
    else:
      stderr.writeLine("gem-closure-manifest: unknown argument " & arg)
      quit(2)
  try:
    let origin = if flake.len > 0: flake
                 else: file & (if attr.len > 0: " (" & attr & ")" else: "")
    let source = sourceExpression(file, attr, flake, system)
    if rawJson:
      # What Nix reports, before ordering: for review, and for recording a
      # test fixture.
      echo evaluateClosureJson(source)
      quit(0)
    let gems = evaluateClosure(source)
    let text = renderManifest(gems, origin)
    if check.len > 0:
      let difference = firstDifference(entryLines(readFile(check)),
        entryLines(text))
      if difference.len > 0:
        stderr.writeLine("gem-closure-manifest: " & check & " differs from " &
          "the Nix closure of " & origin & " at " & difference)
        quit(1)
      echo "gem-closure-manifest: " & check & " matches the Nix closure (" &
        $gems.len & " gems)"
    elif outPath.len > 0:
      writeFile(outPath, text)
    else:
      stdout.write(text)
  except GeneratorError as err:
    stderr.writeLine(err.msg)
    quit(1)

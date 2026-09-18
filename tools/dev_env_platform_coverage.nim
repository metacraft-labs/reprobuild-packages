## Which platforms the dev-environment tool tier actually covers.
##
## Reprobuild's answer to "will this work on my machine?" is per package and
## per platform, and a missing answer has two very different causes that
## look identical from the outside:
##
##   * upstream publishes nothing for that platform, so there is nothing to
##     realize and never will be until upstream ships an asset; or
##   * upstream publishes an asset and this catalog has not pinned it yet.
##
## The first is a fact about the world and the second is work. A report that
## prints "no" for both tells a developer nothing about whether to wait, to
## file an issue upstream, or to send a patch here. So this tool never
## decides which one a gap is: every gap has to be DECLARED, with its state
## and a reason, in `platform-coverage.tsv` beside this file. An undeclared
## gap is `UNCLASSIFIED`, and that is the only state the gate fails on.
##
## So the gate does not forbid gaps — it forbids UNEXAMINED ones. A catalog
## that covered nothing could pass it, having said so of every cell; one
## that grew a package and never looked at five of its six platforms could
## not.
##
## ## What set of packages
##
## The 29 imported below are the tools Agent Harbor's `repro.nim` declares
## in its `uses:` block and resolves from `repro_dsl_stdlib` — the first dev
## environment this catalog was driven to completion against, and the one
## whose milestones ask for this report. The set is spelled out as imports
## rather than read from a list, because Nim resolves imports at compile
## time and a name that stopped existing should fail to build rather than
## silently drop a row.
##
## The six coding-agent CLIs that dev environment also names —
## `claude-code`, `codex`, `codex-acp`, `copilot`, `goose`, `opencode` — are
## NOT here. They belong to a different federated catalog,
## `reprobuild-llm-agent-packages`, which reports its own coverage from
## `inventory/upstream.toml`. Reaching across the two would make this
## repository's tests depend on a sibling checkout being present, and it
## would put the authority for one catalog's coverage claims in another
## catalog's tree. Each reports its own; a consumer reads both.
##
## ## Usage
##
##   nim c -r tools/dev_env_platform_coverage.nim            # org table
##   nim c -r tools/dev_env_platform_coverage.nim --check    # gate only
##   nim c -r tools/dev_env_platform_coverage.nim --format=tsv
##
## `--check` exits non-zero when a cell is realized by nothing and declared
## by nothing, and when the TSV carries a row for a cell that IS realized —
## a stale claim about upstream is as misleading as an unexamined gap.

import std/[algorithm, os, sequtils, sets, strformat, strutils, tables]

import repro_project_dsl

import repro_dsl_stdlib/packages/rustc
import repro_dsl_stdlib/packages/cargo
import repro_dsl_stdlib/packages/rustfmt
import repro_dsl_stdlib/packages/clippy
import repro_dsl_stdlib/packages/cargo_nextest
import repro_dsl_stdlib/packages/python3
import repro_dsl_stdlib/packages/just
import repro_dsl_stdlib/packages/node
import repro_dsl_stdlib/packages/uv
import repro_dsl_stdlib/packages/prek
import repro_dsl_stdlib/packages/shfmt
import repro_dsl_stdlib/packages/addlicense
import repro_dsl_stdlib/packages/jq
import repro_dsl_stdlib/packages/clang
import repro_dsl_stdlib/packages/mingw_gcc
import repro_dsl_stdlib/packages/ninja
import repro_dsl_stdlib/packages/go
import repro_dsl_stdlib/packages/postgresql
import repro_dsl_stdlib/packages/mailpit
import repro_dsl_stdlib/packages/ergo
import repro_dsl_stdlib/packages/neovim
import repro_dsl_stdlib/packages/windows_terminal
import repro_dsl_stdlib/packages/piper
import repro_dsl_stdlib/packages/taplo
import repro_dsl_stdlib/packages/cargo_sort
import repro_dsl_stdlib/packages/wix
import repro_dsl_stdlib/packages/tmux
import repro_dsl_stdlib/packages/msys2_libevent
import repro_dsl_stdlib/packages/msys2_ncurses

const
  ## The tools Agent Harbor's `repro.nim` names and this catalog owns. Kept
  ## as data beside the imports so a package that is imported but not
  ## declared, or declared but not imported, shows up as a diff rather than
  ## as a quietly shorter table.
  DeclaredTools* = [
    "rustc", "cargo", "rustfmt", "clippy", "cargo-nextest",
    "python3", "just", "node", "uv",
    "prek", "shfmt", "addlicense", "jq",
    "clang", "mingw-gcc", "ninja", "go",
    "postgresql", "mailpit", "ergo",
    "neovim", "windows-terminal", "piper",
    "taplo", "cargo-sort", "wix",
    "tmux", "msys2-libevent", "msys2-ncurses",
  ]

  ## The platforms a Reprobuild realization can name. `cpu` and `os` are the
  ## spellings the DSL's tarball slices use.
  Platforms* = [
    ("x86_64", "windows"),
    ("aarch64", "windows"),
    ("x86_64", "linux"),
    ("aarch64", "linux"),
    ("x86_64", "macos"),
    ("aarch64", "macos"),
  ]

  CoverageNotesFile* = "platform-coverage.tsv"

type
  Coverage* = enum
    ## What this catalog can do for one (package, platform) pair.
    covDirect          ## A tarball slice names this exact cpu/os.
    covNix             ## Reached through the pinned nixpkgs channel.
    covScoop           ## Reached through a Scoop app (Windows).
    covUpstreamNone    ## Upstream ships nothing here. Declared.
    covNotPinned       ## Upstream ships something; nothing pins it. Declared.
    covUnclassified    ## Nobody has looked. The state the gate fails on.

  CoverageNote* = object
    package*, cpu*, os*, reason*: string
    state*: Coverage

proc label*(state: Coverage): string =
  case state
  of covDirect: "direct"
  of covNix: "nix"
  of covScoop: "scoop"
  of covUpstreamNone: "upstream-none"
  of covNotPinned: "not-pinned"
  of covUnclassified: "UNCLASSIFIED"

proc coverageNotesHeader*(): string =
  ## The TSV's required first line. Built rather than spelled as a literal
  ## so the tab characters cannot be mistaken for spaces in a diff.
  "# package\tcpu\tos\tstate\treason"

proc parseState*(text: string): Coverage =
  ## Only the two DECLARABLE states are accepted. `direct`, `nix` and
  ## `scoop` are facts the catalog already states in the recipe, so writing
  ## one here would be a second, un-cross-checked copy of it; and
  ## `UNCLASSIFIED` is the absence of a row, not something to write down.
  case text
  of "upstream-none": covUpstreamNone
  of "not-pinned": covNotPinned
  else:
    raise newException(ValueError,
      CoverageNotesFile & ": state must be `upstream-none` or " &
      "`not-pinned`, got `" & text & "`")

proc notesPath(): string =
  currentSourcePath.parentDir / CoverageNotesFile

proc parseNotes*(text: string): seq[CoverageNote] =
  ## One row per declared gap. Tab-separated, because the reason is prose
  ## and a comma would need quoting.
  var sawHeader = false
  var seen = initHashSet[string]()
  for rawLine in text.splitLines():
    let line = rawLine.strip(leading = false)
    if line.len == 0:
      continue
    if line.startsWith("#"):
      if line == coverageNotesHeader():
        sawHeader = true
      continue
    let fields = line.split('\t')
    if fields.len != 5:
      raise newException(ValueError,
        CoverageNotesFile & ": expected 5 tab-separated fields, got " &
        $fields.len & ": " & line)
    if fields[4].strip().len == 0:
      raise newException(ValueError,
        CoverageNotesFile & ": a row with no reason is not a declaration " &
        "of anything: " & line)
    let note = CoverageNote(package: fields[0].strip(), cpu: fields[1].strip(),
      os: fields[2].strip(), state: parseState(fields[3].strip()),
      reason: fields[4].strip())
    let key = note.package & "\t" & note.cpu & "\t" & note.os
    if key in seen:
      # Two rows for one cell is how a report starts contradicting itself:
      # whichever is read first wins, and the other stays as a plausible
      # comment nobody rechecks.
      raise newException(ValueError,
        CoverageNotesFile & ": " & note.package & " " & note.os & "-" &
        note.cpu & " is declared twice")
    seen.incl(key)
    result.add(note)
  if not sawHeader:
    raise newException(ValueError,
      CoverageNotesFile & ": missing the required header line")

proc packageByName(name: string): PackageDef =
  let hits = registeredPackages().filterIt(it.packageName == name)
  if hits.len != 1:
    raise newException(ValueError, "expected exactly one package named " &
      name & ", found " & $hits.len &
      " (is its module imported at the top of this file?)")
  hits[0]

proc realizationOf*(pkg: PackageDef; cpu, os: string): Coverage =
  ## What the CATALOG offers for this cell, ignoring the notes entirely.
  ## Direct wins, then Scoop on Windows, then nix elsewhere;
  ## `covUnclassified` means the catalog offers nothing and the answer has
  ## to come from a declaration.
  for slice in pkg.tarballProvisioning:
    # An empty cpu or os means the slice is not platform-qualified, which
    # the DSL allows for architecture-neutral payloads.
    let cpuMatches = slice.cpu.len == 0 or slice.cpu == cpu
    let osMatches = slice.os.len == 0 or slice.os == os
    if cpuMatches and osMatches:
      return covDirect
  if os == "windows" and pkg.scoopProvisioning.len > 0:
    return covScoop
  if os in ["linux", "macos"] and pkg.nixProvisioning.len > 0:
    return covNix
  covUnclassified

proc coverageOf*(pkg: PackageDef; cpu, os: string;
                 notes: seq[CoverageNote]): Coverage =
  result = realizationOf(pkg, cpu, os)
  if result != covUnclassified:
    return
  for note in notes:
    if note.package == pkg.packageName and note.cpu == cpu and note.os == os:
      return note.state

type Row* = object
  package*: string
  states*: seq[Coverage]   ## One per entry of `Platforms`, in that order.

proc buildRows*(notes: seq[CoverageNote]): seq[Row] =
  for name in DeclaredTools:
    let pkg = packageByName(name)
    var row = Row(package: name)
    for (cpu, os) in Platforms:
      row.states.add(coverageOf(pkg, cpu, os, notes))
    result.add(row)

proc platformHeading(cpu, os: string): string =
  os & "-" & cpu

proc sortedNotes(notes: seq[CoverageNote]): seq[CoverageNote] =
  result = notes
  result.sort(proc (a, b: CoverageNote): int =
    result = cmp(a.package, b.package)
    if result == 0:
      result = cmp(a.os & "-" & a.cpu, b.os & "-" & b.cpu))

proc renderOrg*(rows: seq[Row]; notes: seq[CoverageNote]): string =
  var widths: seq[int] = @[]
  var headings: seq[string] = @[]
  for (cpu, os) in Platforms:
    let heading = platformHeading(cpu, os)
    headings.add(heading)
    widths.add(max(heading.len, len("upstream-none")))
  var packageWidth = len("package")
  for row in rows:
    packageWidth = max(packageWidth, row.package.len)

  result.add("| " & "package".alignLeft(packageWidth))
  for i, heading in headings:
    result.add(" | " & heading.alignLeft(widths[i]))
    discard i
  result.add(" |\n")

  result.add("|-" & repeat('-', packageWidth))
  for width in widths:
    result.add("-+-" & repeat('-', width))
  result.add("-|\n")

  for row in rows:
    result.add("| " & row.package.alignLeft(packageWidth))
    for i, state in row.states:
      result.add(" | " & state.label.alignLeft(widths[i]))
    result.add(" |\n")

  var byState = initTable[Coverage, seq[CoverageNote]]()
  for note in sortedNotes(notes):
    byState.mgetOrPut(note.state, @[]).add(note)
  for state in [covUpstreamNone, covNotPinned]:
    if state notin byState:
      continue
    result.add("\nEvery =" & state.label & "= cell, and why:\n")
    for note in byState[state]:
      result.add("  - " & note.package & " " &
        platformHeading(note.cpu, note.os) & ": " & note.reason & "\n")

proc renderTsv*(rows: seq[Row]): string =
  result.add("package")
  for (cpu, os) in Platforms:
    result.add("\t" & platformHeading(cpu, os))
  result.add("\n")
  for row in rows:
    result.add(row.package)
    for state in row.states:
      result.add("\t" & state.label)
    result.add("\n")

proc checkProblems*(rows: seq[Row]; notes: seq[CoverageNote]): seq[string] =
  ## Two ways the report can be wrong, both reported by name.
  for row in rows:
    for i, state in row.states:
      if state == covUnclassified:
        let (cpu, os) = Platforms[i]
        result.add("unexamined: " & row.package & " " &
          platformHeading(cpu, os) & " -- nothing realizes it and nothing " &
          "in " & CoverageNotesFile & " says why; add a row declaring " &
          "`upstream-none` or `not-pinned`, or pin the asset")
  # A note for a cell the catalog now covers is a stale claim, and leaving
  # it in makes the next real gap easier to dismiss.
  var covered = initHashSet[string]()
  for row in rows:
    for i, state in row.states:
      if state in [covDirect, covNix, covScoop]:
        let (cpu, os) = Platforms[i]
        covered.incl(row.package & "\t" & cpu & "\t" & os)
  for note in notes:
    let key = note.package & "\t" & note.cpu & "\t" & note.os
    if key in covered:
      result.add("stale: " & note.package & " " &
        platformHeading(note.cpu, note.os) &
        " is covered by this catalog now, so the " & CoverageNotesFile &
        " row claiming `" & note.state.label & "` is wrong")
  var known = initHashSet[string]()
  for name in DeclaredTools:
    known.incl(name)
  var knownPlatforms = initHashSet[string]()
  for (cpu, os) in Platforms:
    knownPlatforms.incl(cpu & "\t" & os)
  for note in notes:
    if note.package notin known:
      result.add("unknown package in " & CoverageNotesFile & ": " &
        note.package)
    if (note.cpu & "\t" & note.os) notin knownPlatforms:
      result.add("unknown platform in " & CoverageNotesFile & ": " &
        platformHeading(note.cpu, note.os) & " (for " & note.package & ")")

proc summarize(rows: seq[Row]): Table[Coverage, int] =
  for row in rows:
    for state in row.states:
      result.mgetOrPut(state, 0) += 1

proc loadNotes*(): seq[CoverageNote] =
  parseNotes(readFile(notesPath()))

when isMainModule:
  var format = "org"
  var checkOnly = false
  for i in 1 .. paramCount():
    let arg = paramStr(i)
    if arg == "--check":
      checkOnly = true
    elif arg.startsWith("--format="):
      format = arg["--format=".len .. ^1]
    else:
      quit("unknown argument: " & arg &
        "\nusage: dev_env_platform_coverage [--check] [--format=org|tsv]", 2)

  let notes = loadNotes()
  let rows = buildRows(notes)
  let problems = checkProblems(rows, notes)

  if not checkOnly:
    case format
    of "org": stdout.write(renderOrg(rows, notes))
    of "tsv": stdout.write(renderTsv(rows))
    else: quit("unknown --format: " & format, 2)
    let counts = summarize(rows)
    stdout.write(&"\n{rows.len} packages x {Platforms.len} platforms: ")
    var parts: seq[string] = @[]
    for state in [covDirect, covScoop, covNix, covNotPinned, covUpstreamNone,
                  covUnclassified]:
      let n = counts.getOrDefault(state, 0)
      if n > 0:
        parts.add($n & " " & state.label)
    stdout.write(parts.join(", ") & "\n")

  if problems.len > 0:
    stderr.write("\n")
    for problem in problems:
      stderr.write("error: " & problem & "\n")
    quit(1)
  if checkOnly:
    echo "platform coverage: every cell is either realized or declared"

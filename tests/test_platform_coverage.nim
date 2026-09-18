## The platform coverage report, and the gate that keeps it honest.
##
## The report's whole value is the distinction between "upstream ships
## nothing for that platform" and "upstream ships something and nobody has
## pinned it", so what is tested here is that the tool cannot blur them:
## it never invents either answer, it fails when a cell has no answer at
## all, and it fails when an answer has been overtaken by the catalog.
##
## The last case runs the real TSV against the real catalog, which is the
## gate itself. Everything above it is there so a failure in that one case
## points at the cause rather than just at the total.

import std/[sequtils, strutils, unittest]

import ../tools/dev_env_platform_coverage as coverage

const Header = "# package\tcpu\tos\tstate\treason"

proc row(package, cpu, os, state, reason: string): string =
  package & "\t" & cpu & "\t" & os & "\t" & state & "\t" & reason

suite "the coverage notes file":
  test "a declaration round-trips":
    let notes = coverage.parseNotes(Header & "\n" &
      row("shfmt", "aarch64", "windows", "upstream-none",
          "upstream publishes 386 and amd64 only"))
    check notes.len == 1
    check notes[0].package == "shfmt"
    check notes[0].cpu == "aarch64"
    check notes[0].os == "windows"
    check notes[0].state == coverage.covUpstreamNone
    check notes[0].reason == "upstream publishes 386 and amd64 only"

  test "the header is required":
    # Without it a file could be a stray TSV from anywhere, and the tool
    # would read its rows as coverage claims.
    expect ValueError:
      discard coverage.parseNotes(
        row("shfmt", "aarch64", "windows", "upstream-none", "because"))

  test "a row with no reason is refused":
    # A state with no reason is the thing this report exists to replace: an
    # unexplained "no". It has to be impossible to write.
    expect ValueError:
      discard coverage.parseNotes(Header & "\n" &
        row("shfmt", "aarch64", "windows", "upstream-none", ""))

  test "a truncated row is refused rather than partly read":
    expect ValueError:
      discard coverage.parseNotes(Header & "\n" &
        "shfmt\taarch64\twindows\tupstream-none")

  test "only the two declarable states are accepted":
    # `direct`, `nix` and `scoop` are facts the recipe already states, so a
    # row claiming one would be a second, un-cross-checked copy.
    for rejected in ["direct", "nix", "scoop", "UNCLASSIFIED", "yes", ""]:
      expect ValueError:
        discard coverage.parseNotes(Header & "\n" &
          row("shfmt", "aarch64", "windows", rejected, "because"))

  test "one cell declared twice is refused":
    # Whichever row is read first would win and the other would stay as a
    # plausible comment nobody rechecks.
    expect ValueError:
      discard coverage.parseNotes(Header & "\n" &
        row("shfmt", "aarch64", "windows", "upstream-none", "first") & "\n" &
        row("shfmt", "aarch64", "windows", "not-pinned", "second"))

  test "comments and blank lines are not rows":
    let notes = coverage.parseNotes(
      "# a note about the file\n\n" & Header & "\n\n" &
      row("shfmt", "aarch64", "windows", "upstream-none", "because") & "\n")
    check notes.len == 1

suite "what the gate catches":
  test "an unexamined cell fails, and names the two ways to fix it":
    # Every cell of every package minus the declarations: with an empty
    # notes file the whole table is unexamined, so this is the state the
    # gate exists for.
    let rows = coverage.buildRows(@[])
    let problems = coverage.checkProblems(rows, @[])
    check problems.len > 0
    check problems.anyIt(it.startsWith("unexamined: "))
    check problems.anyIt(it.contains("upstream-none") and
      it.contains("not-pinned"))

  test "a declaration for a cell the catalog covers fails as stale":
    # rustc's Windows x86_64 slice is pinned, so claiming upstream ships
    # nothing there is a false statement about upstream that would make the
    # next real gap easier to dismiss.
    let stale = @[coverage.CoverageNote(package: "rustc", cpu: "x86_64",
      os: "windows", state: coverage.covUpstreamNone,
      reason: "this is not true")]
    let problems = coverage.checkProblems(coverage.buildRows(stale), stale)
    check problems.anyIt(it.startsWith("stale: ") and it.contains("rustc"))

  test "a declaration for a package or platform nobody reports fails":
    # A typo'd name would otherwise sit in the file explaining nothing, and
    # the cell it was meant for would stay unexamined.
    let typo = @[
      coverage.CoverageNote(package: "shmft", cpu: "aarch64", os: "windows",
        state: coverage.covUpstreamNone, reason: "typo in the name"),
      coverage.CoverageNote(package: "shfmt", cpu: "riscv64", os: "windows",
        state: coverage.covUpstreamNone, reason: "platform nobody reports"),
    ]
    let problems = coverage.checkProblems(coverage.buildRows(typo), typo)
    check problems.anyIt(it.contains("unknown package") and
      it.contains("shmft"))
    check problems.anyIt(it.contains("unknown platform") and
      it.contains("riscv64"))

suite "the committed report":
  let notes = coverage.loadNotes()
  let rows = coverage.buildRows(notes)

  test "every cell is either realized or declared":
    # THE GATE. A new package, or a new platform in the axis list, arrives
    # here as a failure naming exactly which cells nobody has looked at.
    let problems = coverage.checkProblems(rows, notes)
    for problem in problems:
      checkpoint(problem)
    check problems.len == 0

  test "the table is complete":
    check rows.len == coverage.DeclaredTools.len
    for row in rows:
      check row.states.len == coverage.Platforms.len

  test "the report renders the distinction it exists for":
    let org = coverage.renderOrg(rows, notes)
    check org.contains("upstream-none")
    check org.contains("not-pinned")
    check org.contains("Every =upstream-none= cell, and why:")
    check org.contains("Every =not-pinned= cell, and why:")
    # A rendered table that still said UNCLASSIFIED anywhere would mean the
    # gate above and the output had come apart.
    check not org.contains("UNCLASSIFIED")

  test "the host platform is fully covered":
    # The weakest useful claim about the machine this runs on: every tool
    # the dev environment declares has a realization here. If this fails,
    # the dev environment cannot activate, whatever the rest of the table
    # says.
    const hostCpu = when defined(amd64): "x86_64"
                    elif defined(arm64): "aarch64"
                    else: ""
    const hostOs = when defined(windows): "windows"
                   elif defined(linux): "linux"
                   elif defined(macosx): "macos"
                   else: ""
    if hostCpu.len == 0 or hostOs.len == 0:
      skip()
    else:
      var index = -1
      for i, platform in coverage.Platforms:
        if platform[0] == hostCpu and platform[1] == hostOs:
          index = i
      check index >= 0
      for row in rows:
        checkpoint(row.package & " on " & hostOs & "-" & hostCpu & ": " &
          row.states[index].label)
        check row.states[index] in
          [coverage.covDirect, coverage.covNix, coverage.covScoop]

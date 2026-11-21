## The MSYS root closure generator: the packages an MSYS root must provide
## become root-overlay closure entries, every package after the packages it
## depends on, each pinned by the digest the package database records.
##
## Mock, justified: the package database here is a handful of `desc` files
## written by the test in MSYS2's database format, rather than a real
## `msys.db` snapshot (half a megabyte that changes with every MSYS2
## release). What is tested is the closure walk -- names, `%PROVIDES%`,
## version constraints, cycles, ambiguity -- which needs a database shaped
## to exercise each case, not a real one.

import std/[os, strutils, tempfiles, unittest]

import ../tools/msys2_root_closure_manifest as generator

proc digest(c: char): string = repeat(c, 64)

proc writeDesc(root, name, version: string; sha: char;
               depends: seq[string] = @[]; provides: seq[string] = @[]) =
  let dir = root / (name & "-" & version)
  createDir(dir)
  var text = "%FILENAME%\n" & name & "-" & version & "-x86_64.pkg.tar.zst\n\n" &
    "%NAME%\n" & name & "\n\n%VERSION%\n" & version & "\n\n" &
    "%SHA256SUM%\n" & digest(sha) & "\n\n"
  if depends.len > 0:
    text.add("%DEPENDS%\n" & depends.join("\n") & "\n\n")
  if provides.len > 0:
    text.add("%PROVIDES%\n" & provides.join("\n") & "\n\n")
  writeFile(dir / "desc", text)

proc database(): string =
  result = createTempDir("msys2-db-", "")
  writeDesc(result, "msys2-runtime", "3.6.12-1", 'a')
  writeDesc(result, "gcc-libs", "16.2.0-1", 'b', @["msys2-runtime"])
  writeDesc(result, "libintl", "0.22.5-1", 'c', @["gcc-libs", "libiconv>=1.17"])
  writeDesc(result, "libiconv", "1.19.1-1", 'd', @["gcc-libs"])
  writeDesc(result, "bash", "5.3.20-3", 'e', @["msys2-runtime"], @["sh"])
  writeDesc(result, "make", "4.4.1-3", 'f', @["libintl", "sh"])
  writeDesc(result, "unrelated", "1.0-1", '0', @["make"])

suite "MSYS root closure generator":
  test "dependencies come first, through PROVIDES and version constraints":
    let db = database()
    defer: removeDir(db)
    let closure = resolveClosure(readDatabaseDir(db),
      ["msys2-runtime", "make"])
    var names: seq[string]
    for pkg in closure:
      names.add(pkg.name)
    check names == @["msys2-runtime", "gcc-libs", "libiconv", "libintl",
                     "bash", "make"]
    check "unrelated" notin names

  test "the manifest unpacks every package but the primary over the root":
    let db = database()
    defer: removeDir(db)
    let closure = resolveClosure(readDatabaseDir(db),
      ["msys2-runtime", "make"])
    let lines = manifestLines(closure, "msys2-runtime",
      "https://repo.msys2.org/msys/x86_64/")
    check lines.len == 5
    check lines[^1] == ". " & digest('f') &
      " https://repo.msys2.org/msys/x86_64/make-4.4.1-3-x86_64.pkg.tar.zst" &
      " tar.zst 0"
    for line in lines:
      check line.startsWith(". ")
      check "msys2-runtime" notin line
    let text = renderManifest(closure, "msys2-runtime",
      "https://repo.msys2.org/msys/x86_64", digest('9'), ["make"])
    check ("sha256 " & digest('9')) in text
    check entryLines(text) == lines

  test "a missing or ambiguous dependency is refused":
    let db = database()
    defer: removeDir(db)
    writeDesc(db, "needs-ghost", "1-1", '1', @["ghost"])
    expect ClosureError:
      discard resolveClosure(readDatabaseDir(db), ["needs-ghost"])
    writeDesc(db, "dash", "0.5-1", '2', provides = @["sh"])
    expect ClosureError:
      discard resolveClosure(readDatabaseDir(db), ["make"])

  test "a dependency cycle terminates":
    let db = database()
    defer: removeDir(db)
    writeDesc(db, "cyc-a", "1-1", '3', @["cyc-b"])
    writeDesc(db, "cyc-b", "1-1", '4', @["cyc-a"])
    let closure = resolveClosure(readDatabaseDir(db), ["cyc-a"])
    check closure.len == 2

  test "a malformed database entry is refused":
    let db = database()
    defer: removeDir(db)
    createDir(db / "broken-1")
    writeFile(db / "broken-1" / "desc", "%NAME%\nbroken\n")
    expect ClosureError:
      discard readDatabaseDir(db)

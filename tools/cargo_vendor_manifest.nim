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

import std/[os, strutils]

import repro_core/cargo_lock

proc usage(): string =
  "usage: cargo_vendor_manifest <Cargo.lock> [<output>]\n" &
  "\n" &
  "Reads a cargo lockfile and writes the pinned crates.io vendor\n" &
  "manifest the from-source-cargo convention consumes. Writes to stdout\n" &
  "when no output path is given."

when isMainModule:
  let args = commandLineParams()
  if args.len < 1 or args.len > 2 or args[0] in ["-h", "--help"]:
    quit(usage(), if args.len >= 1 and args[0] in ["-h", "--help"]: 0 else: 2)

  let lockPath = args[0]
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
      renderVendorManifest(vendorPlan(parseCargoLock(text)))
    except CargoLockError as err:
      # The reader's refusals are the useful output here: each one names a
      # lockfile construct that would have produced a closure the build
      # could not satisfy. Passing the message through unchanged is what
      # makes them actionable at the point a recipe is authored rather
      # than at the point somebody else's build fails.
      quit("cargo_vendor_manifest: " & err.msg, 1)

  if args.len == 2:
    let outputPath = args[1]
    createDir(outputPath.parentDir)
    writeFile(outputPath, manifest)
    let crates = manifest.strip().splitLines().len - 1
    stderr.writeLine("cargo_vendor_manifest: wrote " & $crates &
      " crates to " & outputPath)
  else:
    stdout.write(manifest)

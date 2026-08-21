import std/[os, strutils]

let reprobuildRoot = block:
  let configured = getEnv("REPROBUILD_SRC")
  if configured.len > 0: configured
  else: ".." / "reprobuild"

let libsRoot = reprobuildRoot / "libs"
if dirExists(libsRoot):
  for kind, path in walkDir(libsRoot):
    if kind == pcDir and dirExists(path / "src"):
      switch("path", path / "src")

proc addDependencyPath(envName, siblingName: string) =
  let root = block:
    let configured = getEnv(envName)
    if configured.len > 0: configured
    else: ".." / siblingName
  let sourcePath =
    if dirExists(root / "src"): root / "src"
    else: root
  if dirExists(sourcePath):
    switch("path", sourcePath)

addDependencyPath("SHM_QUEUE_SRC", "nim-shm-queue")
addDependencyPath("SHM_GSET_SRC", "nim-shm-gset")
addDependencyPath("STACKABLE_HOOKS_SRC", "nim-stackable-hooks")
addDependencyPath("REPRO_TEST_ADAPTERS_SRC", "reprobuild-test-adapters")

let nimcryptoRoot = libsRoot / "nimcrypto"
if fileExists(nimcryptoRoot / "nimcrypto" / "hash.nim"):
  switch("path", nimcryptoRoot)

let blake3Headers = libsRoot / "blake3" / "src" / "blake3" / "vendor"
let xxhashHeaders = libsRoot / "xxh3" / "src" / "xxh3" / "vendor"
if fileExists(blake3Headers / "blake3.h") and
    fileExists(xxhashHeaders / "xxhash.h"):
  switch("define", "reproVendoredHash")
  switch("passC", "-DREPRO_VENDORED_HASH")
  switch("passC", "-I" & blake3Headers)
  switch("passC", "-I" & xxhashHeaders)

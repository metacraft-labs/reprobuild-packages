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

let nimcryptoRoot = libsRoot / "nimcrypto"
if fileExists(nimcryptoRoot / "nimcrypto" / "hash.nim"):
  switch("path", nimcryptoRoot)

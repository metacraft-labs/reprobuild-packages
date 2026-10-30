## The armv7-musl Rust sysroot: upstream's rust-std component, pinned to the
## catalog's rustc version, merged with the host toolchain.

import std/[strutils, unittest]

import repro_project_dsl
import ./repro

suite "rust-sysroot-armv7-unknown-linux-musleabihf":
  test "pins the rust-std component of the catalog's rustc version":
    let spec = registeredFetchSpec("rustSysrootArmv7MuslSource")
    check spec.url == "https://static.rust-lang.org/dist/rust-std-1.94.0-armv7-unknown-linux-musleabihf.tar.xz"
    check spec.hashHex ==
      "abfc0e7c1eaff1e3332b5c6262d12da309035a228261d07155add44464ed52f4"
    check spec.extractStrip == 2

  test "requires the matching host toolchain and nothing for the target":
    # The component is a library for the host rustc to read; a cross C
    # toolchain here would mean the recipe had started compiling.
    let deps = registeredNativeBuildDeps("rustSysrootArmv7MuslSource")
    var rustc, cargo = false
    for dep in deps:
      if dep.startsWith("rustc >=1.94"): rustc = true
      if dep.startsWith("cargo >=1.94"): cargo = true
      check not dep.startsWith("zig")
      check not dep.startsWith("gcc")
    check rustc and cargo

  test "publishes the prefix command named after the package":
    let artifacts = registeredArtifacts("rustSysrootArmv7MuslSource")
    check artifacts.len == 1
    check artifacts[0].artifactName == "rust-sysroot-armv7-unknown-linux-musleabihf"

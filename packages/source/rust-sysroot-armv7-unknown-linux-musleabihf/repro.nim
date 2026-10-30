## A Rust sysroot that can compile for `armv7-unknown-linux-musleabihf`.
##
## rustc looks for a target's standard library under its own sysroot,
## `<prefix>/lib/rustlib/<triple>/lib`, and the `rustc` the catalog realizes
## (`rust-1.94.0-<host>.tar.xz`) carries only the host's. Upstream ships every
## other target's standard library as a separate component,
## `rust-std-<version>-<triple>.tar.xz`, meant to be merged into the same
## prefix — which is what `rustup target add` does.
##
## This recipe is that merge, as a prefix of its own: the host toolchain's
## tree reproduced by symbolic links, with the target component's
## `lib/rustlib/<triple>/` copied in. `bin/rustc` is a COPY rather than a
## link, because rustc finds its sysroot through the real path of its own
## executable (`current_exe()` resolves links), so a linked `rustc` would
## resolve to the host prefix and never see the target library. Everything
## `bin/rustc` loads lives under `lib/` (`$ORIGIN/../lib`), which is why
## `lib/` is a real directory of links and not one link.
##
## A cross recipe points cargo at it with `RUSTC=<this prefix>/bin/rustc`
## (`cargo_package(..., extraEnv)`): cargo then drives this rustc for the
## host (build scripts, proc macros) and the target alike, and both standard
## libraries are present. `cargo` itself stays the catalog's.
##
## The component's version must equal the host rustc's — a standard library
## built by one rustc is not loadable by another — so the pin here follows
## `rustc.nim` in the reprobuild stdlib (1.94.0) and the build refuses a
## mismatch by reading `rustc --version`.

import repro_project_dsl

const
  RustVersion = "1.94.0"
  Triple = "armv7-unknown-linux-musleabihf"
  RustStdUrl = "https://static.rust-lang.org/dist/rust-std-" & RustVersion &
    "-" & Triple & ".tar.xz"
  RustStdSha256 =
    "abfc0e7c1eaff1e3332b5c6262d12da309035a228261d07155add44464ed52f4"

package rustSysrootArmv7MuslSource:
  versions:
    "1.94.0":
      sourceRevision = RustVersion
      sourceUrl = RustStdUrl
      sourceRepository = "https://github.com/rust-lang/rust"

  fetch:
    url: RustStdUrl
    sha256: RustStdSha256
    # The component tarball is `rust-std-<ver>-<triple>/rust-std-<triple>/lib/...`;
    # two components of strip land `lib/rustlib/<triple>/` at `src/lib/`.
    extractStrip: 2

  nativeBuildDeps:
    "rustc >=1.94 <1.95"
    "cargo >=1.94 <1.95"

  # Named after the package, as every catalog package a consumer reaches by
  # name is: the command prints the prefix, and `bin/rustc` beside it is the
  # compiler a consumer points `RUSTC` at.
  executable `rust-sysroot-armv7-unknown-linux-musleabihf`:
    build:
      # The host prefix is the one whose `rustc` the engine put on PATH.
      shell "set -e; HOST_RUSTC=$(command -v rustc); " &
        "HOST_PREFIX=$(CDPATH= cd -- \"$(dirname -- \"$HOST_RUSTC\")/..\" && pwd); " &
        "case \"$(\"$HOST_RUSTC\" --version)\" in \"rustc " & RustVersion & " \"*) ;; " &
        "*) echo \"rust-sysroot: host rustc is $(\"$HOST_RUSTC\" --version), the " &
        Triple & " standard library is " & RustVersion & "\" >&2; exit 1;; esac; " &
        "mkdir -p \"$out\"; find \"$out\" -mindepth 1 -maxdepth 1 ! -name .stamps -exec rm -rf -- {} +; " &
        "mkdir -p \"$out/bin\" \"$out/lib/rustlib\"; " &
        "cp \"$HOST_RUSTC\" \"$out/bin/rustc\"; " &
        "for f in \"$HOST_PREFIX\"/bin/*; do n=$(basename \"$f\"); " &
        "[ \"$n\" = rustc ] || ln -s \"$f\" \"$out/bin/$n\"; done; " &
        "for f in \"$HOST_PREFIX\"/lib/*; do n=$(basename \"$f\"); " &
        "[ \"$n\" = rustlib ] || ln -s \"$f\" \"$out/lib/$n\"; done; " &
        "for f in \"$HOST_PREFIX\"/lib/rustlib/*; do n=$(basename \"$f\"); " &
        "[ \"$n\" = " & Triple & " ] || ln -s \"$f\" \"$out/lib/rustlib/$n\"; done; " &
        "cp -a \"$extracted/lib/rustlib/" & Triple & "\" \"$out/lib/rustlib/\"; " &
        "test -d \"$out/lib/rustlib/" & Triple & "/lib\""
      # The proof the merge is what rustc sees: it must answer for the
      # target and for the host from this prefix alone.
      shell "\"$out/bin/rustc\" --print sysroot | grep -qx \"$out\" && " &
        "\"$out/bin/rustc\" --target " & Triple & " --print target-libdir >/dev/null"
      shell "printf '#!/bin/sh\nPREFIX=$(CDPATH= cd -- \"$(dirname -- \"$0\")/..\" && pwd)\necho \"$PREFIX\"\n' " &
        "> \"$out/bin/rust-sysroot-" & Triple & "\"; chmod 755 \"$out/bin/rust-sysroot-" & Triple & "\""

  runtimeDeps:
    discard

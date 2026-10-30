## OpenSSL for `armv7-unknown-linux-musleabihf`, static libraries only.
##
## The target-side OpenSSL a cross-compiled Rust program links when its
## closure holds `openssl-sys` with `OPENSSL_NO_VENDOR=1` (agent-harbor's
## `llm-api-proxy` does: upstream's own Nix build sets it, and the recipe for
## it keeps the same choice so the two builds agree on what they link).
## `openssl-sys` is pointed at this prefix with
## `<TRIPLE>_OPENSSL_DIR=<prefix>` and `<TRIPLE>_OPENSSL_STATIC=1`.
##
## `packages/source/openssl` builds the host's shared libraries with
## `Configure linux-x86_64`; this is the same source at OpenSSL's
## `linux-armv4` target, `no-shared`, compiled and archived by zig
## (`repro_dsl_stdlib/adapters/cross_zig`, the same driver and flags the
## cargo build uses, so the objects agree on ABI). OpenSSL's `Configure`
## takes the toolchain from `CC`, `AR` and `RANLIB`; `AR` and `RANLIB` must
## be zig's too, because a GNU `ar` would archive fine but a GNU `ranlib`
## on an LLVM-produced archive is not guaranteed to agree with the linker
## that reads it.
##
## `no-apps`: only the libraries are wanted, and the `openssl` command's
## link line asks for `-latomic`, which zig's musl target has no library
## for (atomics are in compiler-rt; the cargo side carries an empty
## `libatomic.a` for the same reason).
##
## Reproducible across checkouts: `Configure` compiles its prefix
## (`OPENSSLDIR`, `MODULESDIR`, …) and its own compiler command line
## (`buildinf.h`, what `OPENSSL_version(OPENSSL_CFLAGS)` reports) into
## `libcrypto.a`, and a consumer links them into its binary. The prefix is
## therefore the checkout-independent `/usr` (with `/etc/ssl` as the
## OpenSSL directory, which is where the target's distribution keeps it),
## installed through `DESTDIR` into `$out`; and the zig wrappers are named
## by their bare names (`cc`, `ar`, `ranlib`) with their directory first on
## PATH, so the recorded command line carries no path. OpenSSL compiles its
## sources by relative path, so `__FILE__` needs no mapping (a
## `-ffile-prefix-map` would itself put the build directory into that
## command line). The build date is `SOURCE_DATE_EPOCH`, which the engine
## sets. `test_openssl_static_armv7_source.nim` checks the spelling.
##
## What still names the checkout: zig's driver emits DWARF by default, and
## each compile unit's `DW_AT_comp_dir` in `libcrypto.a` is the build
## directory (978 occurrences). The archives are an intermediate — the
## cargo side links them with `-C strip=debuginfo`, so no consumer binary
## carries them (measured: two checkouts, one `llm-api-proxy`). `-g0`
## would drop them, but it changes the recorded command line and so the
## consumer's bytes, which would move `LlmApiProxyBinarySha256` and the
## published digest; it is deferred to the next toolchain change that
## moves them anyway.
##
## Pinned at 3.5.4, the current LTS line; the hash is the upstream release
## tarball's.

import std/[os, strutils]

import repro_project_dsl
import repro_dsl_stdlib/adapters/cross_zig

const
  OpensslVersion = "3.5.4"
  Triple = "armv7-unknown-linux-musleabihf"
  OpensslUrl = "https://github.com/openssl/openssl/releases/download/openssl-" &
    OpensslVersion & "/openssl-" & OpensslVersion & ".tar.gz"
  OpensslSha256 =
    "967311f84955316969bdb1d8d4b983718ef42338639c621ec4c34fddef355e99"

proc q(value: string): string =
  "'" & value.replace("'", "'\\''") & "'"

proc writeWrappers(): string =
  ## Shell that writes the zig wrappers of `cross_zig` into the directory the
  ## shell variable `W` names. The texts are the adapter's, so this recipe
  ## and the cargo build drive zig identically. The `-L` directory a wrapper
  ## carries is only needed by the rust linker role, which this recipe does
  ## not write; `$W/lib` keeps the adapter's shape.
  let t = zigCrossTarget(Triple)
  result = "mkdir -p \"$W/lib\"; "
  for role in ["cc", "c++", "ar", "ranlib"]:
    result.add("printf '%s' " & q(zigCrossWrapperScript(role, t, "$W/lib")) &
      " > \"$W/" & role & "\"; chmod 755 \"$W/" & role & "\"; ")

proc libCryptoBuildShell*(): string =
  ## The library's build shell, exported so the recipe's test can hold the
  ## checkout-independence settings to their spelling. OpenSSL's build
  ## writes into the source tree, so it is built from a copy; `$out` holds
  ## only the installed prefix.
  "set -e; W=\"$out.wrappers\"; rm -rf \"$W\" \"$out.build\" \"$out.dest\"; mkdir -p \"$out\"; " &
    "find \"$out\" -mindepth 1 -maxdepth 1 ! -name .stamps ! -name bin -exec rm -rf -- {} +; " &
    writeWrappers() &
    "cp -a \"$extracted\" \"$out.build\"; cd \"$out.build\"; " &
    "export PATH=\"$W:$PATH\"; CC=cc AR=ar RANLIB=ranlib " &
    "perl ./Configure linux-armv4 no-shared no-apps no-tests no-docs no-async " &
    "no-engine no-dso --prefix=/usr --openssldir=/etc/ssl --libdir=lib >/dev/null; " &
    "make -j4 >/dev/null; make install_sw DESTDIR=\"$out.dest\" >/dev/null; " &
    "cp -a \"$out.dest/usr/.\" \"$out/\"; " &
    "rm -rf \"$out.build\" \"$out.dest\" \"$W\"; " &
    "test -f \"$out/lib/libcrypto.a\" && test -f \"$out/lib/libssl.a\" && " &
    "test -f \"$out/include/openssl/ssl.h\""

package opensslStaticArmv7MuslSource:
  versions:
    "3.5.4":
      sourceRevision = "openssl-" & OpensslVersion
      sourceUrl = OpensslUrl
      sourceRepository = "https://github.com/openssl/openssl"

  fetch:
    url: OpensslUrl
    sha256: OpensslSha256
    extractStrip: 1

  nativeBuildDeps:
    "zig >=0.13 <0.14"
    "perl >=5.32"
    "make"

  # The prefix command a consumer reaches the package by (`$(openssl-static-…)`
  # prints the prefix); the libraries are the payload.
  executable `openssl-static-armv7-unknown-linux-musleabihf`:
    build:
      shell "mkdir -p \"$out/bin\"; printf '#!/bin/sh\nPREFIX=$(CDPATH= cd -- \"$(dirname -- \"$0\")/..\" && pwd)\necho \"$PREFIX\"\n' " &
        "> \"$out/bin/openssl-static-" & Triple & "\"; chmod 755 \"$out/bin/openssl-static-" & Triple & "\""

  library libCrypto:
    build:
      shell libCryptoBuildShell()

  runtimeDeps:
    discard

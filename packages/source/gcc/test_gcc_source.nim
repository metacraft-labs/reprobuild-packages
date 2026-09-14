## Registry checks for GCC's source pin, compiler/runtime interface, and
## bootstrap/configure/build/install/staging pipeline. These checks do not
## substitute for compiling GCC and exercising the installed compiler.

import std/[strutils, unittest]

import repro_project_dsl

import ./repro

const ExpectedUrl =
  "https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.gz"

# Real sha256 over the upstream gcc-14.2.0.tar.gz tarball; see
# ``repro.nim``'s sha256 strategy section.
const ExpectedHash =
  "7d376d445f93126dc545e2c0086d0f647c3094aae081cdb78f42ce2bc25e7293"

suite "gccSource — from-source recipe smoke test":

  test "fetch spec carries the upstream URL verbatim":
    # M9.H registry round-trip — URL is recorded exactly as declared.
    let spec = registeredFetchSpec("gccSource")
    check spec.packageName == "gccSource"
    check spec.url == ExpectedUrl

  test "fetch spec hash is the real sha256 over the upstream tarball":
    # Real sha256 over the upstream ftp.gnu.org tarball; computed
    # locally + asserted exactly.
    let spec = registeredFetchSpec("gccSource")
    check spec.hashHex.len == 64
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    # Tarball vs git-archive discriminant + the canonical
    # ``--strip-components=1`` convention upstream ftp.gnu.org release
    # tarballs use.
    let spec = registeredFetchSpec("gccSource")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "declares a bootstrap compiler and source arithmetic libraries":
    check registeredAuthoredNativeBuildDeps("gccSource") == @[
      "clang", "binutils >=2.39", "make >=4.3", "perl >=5.32",
      "bison >=3.6", "flex >=2.6"]
    check registeredBuildDeps("gccSource") == @[
      "gmp >=6.2", "mpfr >=4.1", "mpc >=1.2"]
    check registeredRuntimeDeps("gccSource") == @["binutils >=2.39"]

  test "artifacts register three executables and four runtime libraries":
    let arts = registeredArtifacts("gccSource")
    check arts.len == 7
    var seenGcc = false
    var seenGxx = false
    var seenCpp = false
    var seenLibgccS = false
    var seenLibstdcxx = false
    var seenLibgomp = false
    var seenLibatomic = false
    for art in arts:
      check art.packageName == "gccSource"
      case art.artifactName
      of "gcc":
        seenGcc = true
        check art.kind == dakExecutable
      of "g++":
        seenGxx = true
        check art.kind == dakExecutable
      of "cpp":
        seenCpp = true
        check art.kind == dakExecutable
      of "libgcc_s":
        seenLibgccS = true
        check art.kind == dakLibrary
      of "libstdc++":
        seenLibstdcxx = true
        check art.kind == dakLibrary
      of "libgomp":
        seenLibgomp = true
        check art.kind == dakLibrary
      of "libatomic":
        seenLibatomic = true
        check art.kind == dakLibrary
      else:
        check false
    check seenGcc
    check seenGxx
    check seenCpp
    check seenLibgccS
    check seenLibstdcxx
    check seenLibgomp
    check seenLibatomic

  test "versions block records the upstream tag + URL + repository":
    # M2 versions registry: the upstream ftp.gnu.org release tag is
    # recorded for ``repro update-source``. The repository points at
    # the canonical gcc.gnu.org git tree.
    let vs = registeredVersions("gccSource")
    check vs.len == 1
    check vs[0].version == "14.2.0"
    check vs[0].sourceRevision == "releases/gcc-14.2.0"
    check vs[0].sourceUrl == ExpectedUrl
    check vs[0].sourceRepository ==
      "https://gcc.gnu.org/git/gcc.git"

  test "shell() action registry records the gcc mkdir-configure-build-install pipeline":
    let rows = registeredShellActions("gccSource")
    require rows.len == 5
    for r in rows:
      check r.packageName == "gccSource"
      check r.artifactName == "gcc"
    check "mkdir -p $extracted/build $bootstrap_sysroot/usr" in rows[0].command
    check "bootstrap_sysroot=$extracted/bootstrap-sysroot" in rows[0].command
    check "ln -sfn $glibc_include $bootstrap_sysroot/usr/include" in rows[0].command
    check "ln -sfn $glibc_lib $bootstrap_sysroot/lib" in rows[0].command
    for command in [rows[0].command, rows[1].command]:
      check command.startsWith("LD_LIBRARY_PATH=; export LD_LIBRARY_PATH;")
    let configure = rows[1].command
    check "cd $extracted/build && CC=clang CXX=clang++ LD=$raw_binutils/bin/ld " in configure
    check "LDFLAGS_FOR_TARGET=-Wl,--dynamic-linker=$glibc_lib/ld-linux-x86-64.so.2 " in configure
    check configure.endsWith("../configure --prefix=$out --enable-languages=c,c++ " &
      "--disable-multilib --disable-bootstrap --disable-nls --disable-werror " &
      "--disable-libsanitizer --disable-libitm --disable-libvtv --disable-libssp " &
      "--disable-libquadmath --with-build-sysroot=$extracted/bootstrap-sysroot " &
      "--with-gmp=$gmp_prefix --with-mpfr=$mpfr_prefix --with-mpc=$mpc_prefix")
    check "--without-headers" notin configure
    for library in ["gmp", "mpfr", "mpc"]:
      check library & "_prefix=$(pwd)/../../" & library &
        "/.repro/output/install/usr" in configure
      for command in [rows[2].command, rows[3].command]:
        check "$extracted/../../" & library & "/.repro/output/install/usr/lib" in command
    check rows[2].command.endsWith(
      "cd $extracted/build && LD_LIBRARY_PATH=$source_libs NIX_HARDENING_ENABLE= make -j8")
    check rows[3].command.endsWith(
      "cd $extracted/build && LD_LIBRARY_PATH=$source_libs make install")

  test "stages the complete sysroot and compiled compiler drivers":
    let rows = registeredShellActions("gccSource")
    require rows.len == 5
    let stage = rows[4].command
    for library in ["libgcc_s", "libstdc++", "libgomp", "libatomic"]:
      check library & ".so " in stage
    check "test -e $out/lib/ld-linux-x86-64.so.2" in stage
    check "ln -sfn $bootstrap_include $out/include/bootstrap-libc" in stage
    check "ln -sfn ../../../include/bootstrap-libc $out/lib/bootstrap-sysroot/usr/include" in stage
    check "wrapper_src=$(dirname $extracted)/gcc-driver-wrapper.c" in stage
    check "for driver in gcc g++; do" in stage
    check "$out/bin/gcc.real --sysroot=$out/lib/bootstrap-sysroot -O2" in stage
    check "$wrapper_src -o $out/bin/$driver" in stage
    check stage.endsWith("rm -f $out/bin/c++; ln -s g++ $out/bin/c++")

  test "shell() ids carry the per-artifact sequence number":
    # M9.N Batch C.1 — auto-generated ids follow the
    # ``<package>-<artifact>-<seq>`` shape; sequence increments per
    # artifact.
    let rows = registeredShellActions("gccSource")
    require rows.len == 5
    for index, row in rows:
      check row.id == "gccSource-gcc-" & $(index + 1)

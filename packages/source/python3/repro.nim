## CPython runtime built from the official source release.
##
## ReproOS ships Python entry points from systemd, Plasma, libinput,
## iproute2, and other source-built packages. Keeping Python itself in
## the source suite prevents those runtime tools from depending on a
## bootstrap interpreter.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package python3Source:
  versions:
    "3.13.12":
      sourceRevision = "v3.13.12"
      sourceUrl = "https://www.python.org/ftp/python/3.13.12/Python-3.13.12.tgz"
      sourceRepository = "https://github.com/python/cpython"

  fetch:
    url: "https://www.python.org/ftp/python/3.13.12/Python-3.13.12.tgz"
    sha256: "12e7cb170ad2d1a69aee96a1cc7fc8de5b1e97a2bdac51683a3db016ec9a2996"
    extractStrip: 1

  nativeBuildDeps:
    "autoconf"
    "make"
    "pkg-config"
    "gcc >=11"
    # The install mirror normalizes the interpreter's RPATH so libpython is
    # found relative to the relocated source prefix.
    "patchelf"
    ## Configure generates Makefile.pre through awk while source Readline is
    ## on the library path. Keep the helper on the source toolchain runtime.
    "gawk"

  buildDeps:
    "expat"
    "libffi"
    "libxcrypt"
    "ncurses"
    "openssl"
    "readline"
    "sqlite"
    "xz"
    "zlib"

  executable python3:
    discard

  build:
    setCurrentOwningPackageOverride("python3Source")
    try:
      let opts = @[
        "--enable-shared",
        "--disable-test-modules",
        "--with-ensurepip=no",
        "--with-platlibdir=lib",
        "--with-system-expat",
        "--without-static-libpython",
      ]
      # These optional modules require libraries that are not part of the
      # ReproOS runtime closure. Core Python, ctypes, SSL, sqlite, readline,
      # and lzma remain enabled against source-built providers.
      let pythonBuildEnv = @[
        ("PYTHONDONTWRITEBYTECODE", "1"),
        ("py_cv_module__bz2", "disabled"),
        ("py_cv_module__dbm", "disabled"),
        ("py_cv_module__gdbm", "disabled"),
        ("py_cv_module__tkinter", "disabled"),
        ("py_cv_module_nis", "disabled"),
      ]
      # CPython invokes its bootstrap interpreter with -E, so the environment
      # cannot prevent bytecode writes. Add -B to both build-time interpreters
      # before configure generates the Makefile.
      let pythonSourcePatches = @[
        "sed -i 's|^PYTHON_FOR_REGEN?=@PYTHON_FOR_REGEN@$|PYTHON_FOR_REGEN?=@PYTHON_FOR_REGEN@ -B|' src/Makefile.pre.in",
        "sed -i 's|^PYTHON_FOR_BUILD=@PYTHON_FOR_BUILD@$|PYTHON_FOR_BUILD=@PYTHON_FOR_BUILD@ -B|' src/Makefile.pre.in",
        "sed -i 's|^PYTHON_FOR_FREEZE=@PYTHON_FOR_FREEZE@$|PYTHON_FOR_FREEZE=@PYTHON_FOR_FREEZE@ -B|' src/Makefile.pre.in",
        "sed -i 's|\\./$(BUILDPYTHON)|./$(BUILDPYTHON) -B|g' src/Makefile.pre.in",
      ]
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = opts,
        extraEnv = pythonBuildEnv,
        srcPatches = pythonSourcePatches)
      discard pkg.executable("python3")
      pkg.installTreeMirror()
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  LibffiVersion* = "3.4.6"
  LibffiSourceUrl* =
    "https://github.com/libffi/libffi/releases/download/v3.4.6/" &
    "libffi-3.4.6.tar.gz"
  LibffiSourceHash* =
    "b0dea9df23c863a7a50e825440f3ebffabd65df1497108e5d437747843895a4e"
  LibffiBuildDir* = ".repro/build/libffi-autotools"
  LibffiBaseConfigureOptions* = [
    "--disable-static",
    "--disable-docs",
    "--disable-multi-os-directory",
  ]
  # The shell reports an MSYS host, while the selected compiler targets
  # native Windows. Make that cross-host boundary explicit for Libtool.
  # Static trampolines are supported on Linux and Cygwin, but not MinGW.
  LibffiWindowsConfigureOptions* = [
    "--host=x86_64-w64-mingw32",
    "--disable-exec-static-tramp",
  ]
  LibffiNativeBuildDeps* = [
    "make",
    "gcc >=11",
  ]
  LibffiMakeDepfiles* = [
    "src/.deps/prep_cif.Plo",
    "src/.deps/types.Plo",
    "src/.deps/raw_api.Plo",
    "src/.deps/java_raw_api.Plo",
    "src/.deps/closures.Plo",
    "src/.deps/tramp.Plo",
    "src/x86/.deps/ffiw64.Plo",
    "src/x86/.deps/win64.Plo",
  ]

package libffiSource:
  versions:
    "3.4.6":
      sourceRevision = "v" & LibffiVersion
      sourceUrl = LibffiSourceUrl
      sourceRepository = "https://github.com/libffi/libffi"

  fetch:
    url: LibffiSourceUrl
    sha256: LibffiSourceHash
    extractStrip: 1

  # Release archives contain configure, Makefile.in, and the project-local
  # libtool script. Autoconf, Automake, and Libtool are needed only when
  # regenerating those files from a Git checkout.
  nativeBuildDeps:
    "make"
    "gcc >=11"

  config:
    discard

  library libFfi:
    discard

  build:
    setCurrentOwningPackageOverride("libffiSource")
    try:
      var configureOptions = @LibffiBaseConfigureOptions
      when defined(windows):
        configureOptions.add(LibffiWindowsConfigureOptions)
      let makeJobs =
        when defined(windows): 1
        else: 0
      let makeDependencyPolicy =
        when defined(windows):
          makeDepfilePolicy(depfiles = LibffiMakeDepfiles)
        else:
          automaticMonitorPolicy()
      var postInstallDepfiles: seq[string] = @[]
      for depfile in LibffiMakeDepfiles:
        postInstallDepfiles.add(LibffiBuildDir & "/" & depfile)
      let postInstallDependencyPolicy =
        when defined(windows):
          makeDepfilePolicy(depfiles = postInstallDepfiles)
        else:
          automaticMonitorPolicy()
      let pkg = autotools_package(
        srcDir = "./src",
        buildDir = LibffiBuildDir,
        configureOptions = configureOptions,
        makeJobs = makeJobs,
        makeDependencyPolicy = makeDependencyPolicy,
        postInstallDependencyPolicy = postInstallDependencyPolicy)
      discard pkg.library("libFfi")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

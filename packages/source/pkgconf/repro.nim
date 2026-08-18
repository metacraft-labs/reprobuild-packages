import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  PkgconfVersion* = "2.3.0"
  PkgconfSourceUrl* =
    "https://distfiles.ariadne.space/pkgconf/pkgconf-2.3.0.tar.xz"
  PkgconfSourceHash* =
    "3a9080ac51d03615e7c1910a0a2a8df08424892b5f13b0628a204d3fcce0ea8b"
  PkgconfBuildDir* = ".repro/build/pkgconf-autotools"
  PkgconfNativeBuildDeps* = [
    "make",
    "gcc >=11",
  ]
  PkgconfBaseConfigureOptions* = [
    "--with-system-libdir=/lib:/usr/lib",
    "--with-system-includedir=/usr/include",
  ]
  PkgconfSharedConfigureOptions* = [
    "--disable-static",
  ]
  PkgconfWindowsConfigureOptions* = [
    "--host=x86_64-w64-mingw32",
    # Keep the command-line tools self-contained. A shared build makes both
    # executables depend on libpkgconf-5.dll outside their artifact output.
    "--enable-static",
    "--disable-shared",
  ]
  PkgconfWindowsArgConversionExclusions* =
    "-DPERSONALITY_PATH=;-DPKG_DEFAULT_PATH=;" &
    "-DSYSTEM_INCLUDEDIR=;-DSYSTEM_LIBDIR="
  PkgconfWindowsCppFlags* = "-DPKGCONFIG_IS_STATIC"
  PkgconfMakeDepfiles* = [
    "cli/.deps/bomtool-getopt_long.Po",
    "cli/.deps/pkgconf-getopt_long.Po",
    "cli/.deps/pkgconf-main.Po",
    "cli/.deps/pkgconf-renderer-msvc.Po",
    "cli/bomtool/.deps/bomtool-main.Po",
    "libpkgconf/.deps/argvsplit.Plo",
    "libpkgconf/.deps/audit.Plo",
    "libpkgconf/.deps/bsdstubs.Plo",
    "libpkgconf/.deps/cache.Plo",
    "libpkgconf/.deps/client.Plo",
    "libpkgconf/.deps/dependency.Plo",
    "libpkgconf/.deps/fileio.Plo",
    "libpkgconf/.deps/fragment.Plo",
    "libpkgconf/.deps/parser.Plo",
    "libpkgconf/.deps/path.Plo",
    "libpkgconf/.deps/personality.Plo",
    "libpkgconf/.deps/pkg.Plo",
    "libpkgconf/.deps/queue.Plo",
    "libpkgconf/.deps/tuple.Plo",
  ]

package pkgconfSource:
  versions:
    "2.3.0":
      sourceRevision = "pkgconf-" & PkgconfVersion
      sourceUrl = PkgconfSourceUrl
      sourceRepository = "https://github.com/pkgconf/pkgconf"

  fetch:
    url: PkgconfSourceUrl
    sha256: PkgconfSourceHash
    extractStrip: 1

  # The release archive includes configure, Makefile.in, and ltmain.sh.
  # Regenerating them would add a circular Autotools bootstrap dependency.
  nativeBuildDeps:
    "make"
    "gcc >=11"

  config:
    discard

  executable pkgconf:
    discard

  executable pkgConfig:
    discard

  library libpkgconf:
    discard

  build:
    setCurrentOwningPackageOverride("pkgconfSource")
    try:
      var configureOptions = @PkgconfBaseConfigureOptions
      var extraEnv: seq[(string, string)] = @[]
      when defined(windows):
        configureOptions.add(PkgconfWindowsConfigureOptions)
        # Automake's recipes pass Unix path lists as quoted C macros to the
        # native MinGW compiler. Preserve those arguments byte-for-byte.
        extraEnv.add(("MSYS2_ARG_CONV_EXCL",
          PkgconfWindowsArgConversionExclusions))
        extraEnv.add(("CPPFLAGS", PkgconfWindowsCppFlags))
      else:
        configureOptions.add(PkgconfSharedConfigureOptions)
      let makeDependencyPolicy =
        when defined(windows):
          makeDepfilePolicy(depfiles = PkgconfMakeDepfiles)
        else:
          automaticMonitorPolicy()
      var postInstallDepfiles: seq[string] = @[]
      for depfile in PkgconfMakeDepfiles:
        postInstallDepfiles.add(PkgconfBuildDir & "/" & depfile)
      let postInstallDependencyPolicy =
        when defined(windows):
          makeDepfilePolicy(depfiles = postInstallDepfiles)
        else:
          automaticMonitorPolicy()
      let pkg = autotools_package(
        srcDir = "./src",
        buildDir = PkgconfBuildDir,
        configureOptions = configureOptions,
        makeDependencyPolicy = makeDependencyPolicy,
        postInstallDependencyPolicy = postInstallDependencyPolicy,
        extraEnv = extraEnv)
      discard pkg.executable("pkgconf")
      # Upstream installs pkgconf; this provides the conventional pkg-config
      # interface without modifying the fetched source tree.
      discard pkg.executableAlias("pkgConfig", "pkgconf")
      discard pkg.library("libpkgconf")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

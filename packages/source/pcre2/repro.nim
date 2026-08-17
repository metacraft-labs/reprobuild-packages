import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package pcre2Source:
  versions:
    "10.46":
      sourceRevision = "pcre2-10.46"
      sourceUrl = "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.46/pcre2-10.46.tar.bz2"
      sourceRepository = "https://github.com/PCRE2Project/pcre2"
  fetch:
    url: "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.46/pcre2-10.46.tar.bz2"
    sha256: "15fbc5aba6beee0b17aecb04602ae39432393aba1ebd8e39b7cabf7db883299f"
    extractStrip: 1
  nativeBuildDeps:
    "make"
    "gcc >=11"
  config:
    discard
  library pcre2:
    discard
  executable pcre2grep:
    discard
  build:
    setCurrentOwningPackageOverride("pcre2Source")
    try:
      let makeJobs =
        when defined(windows): 1
        else: 0
      let depfiles = [
        "src/.deps/libpcre2_8_la-*.Plo",
        "src/.deps/libpcre2_posix_la-*.Plo",
        "src/.deps/pcre2grep-*.Po",
        "src/.deps/pcre2test-*.Po",
        "src/.deps/pcre2posix_test-*.Po",
      ]
      let makeDependencyPolicy =
        when defined(windows):
          makeDepfilePolicy(depfiles = depfiles)
        else:
          automaticMonitorPolicy()
      var postInstallDepfiles: seq[string] = @[]
      for depfile in depfiles:
        postInstallDepfiles.add("build/" & depfile)
      let postInstallDependencyPolicy =
        when defined(windows):
          makeDepfilePolicy(depfiles = postInstallDepfiles)
        else:
          automaticMonitorPolicy()
      let pkg = autotools_package(srcDir = "./src", configureOptions = @[
        "--disable-static",
        "--enable-pcre2-8",
        "--disable-pcre2-16",
        "--disable-pcre2-32",
      ], makeJobs = makeJobs, makeDependencyPolicy = makeDependencyPolicy,
        postInstallDependencyPolicy = postInstallDependencyPolicy)
      discard pkg.executable("pcre2grep")
      discard pkg.executableAlias("pcre2", sourceName = "pcre2-config")
    finally:
      clearCurrentOwningPackageOverride()
  runtimeDeps:
    discard

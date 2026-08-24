import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  LibiconvVersion* = "1.19"
  LibiconvSourceUrl* =
    "https://ftp.gnu.org/gnu/libiconv/libiconv-" & LibiconvVersion & ".tar.gz"
  LibiconvSourceHash* =
    "88dd96a8c0464eca144fc791ae60cd31cd8ee78321e67397e25fc095c4a19aa6"
  LibiconvBuildDir* = ".repro/build/libiconv-autotools"
  LibiconvBaseConfigureOptions* = [
    "--disable-static",
    "--enable-shared",
  ]
  LibiconvWindowsConfigureOptions* = [
    "--host=x86_64-w64-mingw32",
  ]
  LibiconvNativeBuildDeps* = [
    "make",
    "gcc >=11",
  ]

proc libiconvPostConfigureCommands*(): seq[string] =
  when defined(windows):
    @["sh ../../../../scripts/fix-windows-native-makefiles.sh ."]
  else:
    @[]

package libiconvSource:
  versions:
    "1.19":
      sourceRevision = "v" & LibiconvVersion
      sourceUrl = LibiconvSourceUrl
      sourceRepository = "https://git.savannah.gnu.org/git/libiconv.git"

  fetch:
    url: LibiconvSourceUrl
    sha256: LibiconvSourceHash
    extractStrip: 1

  nativeBuildDeps:
    "make"
    "gcc >=11"

  config:
    discard

  executable iconv:
    discard

  library libIconv:
    discard

  library libCharset:
    discard

  build:
    setCurrentOwningPackageOverride("libiconvSource")
    try:
      var configureOptions = @LibiconvBaseConfigureOptions
      when defined(windows):
        configureOptions.add(LibiconvWindowsConfigureOptions)
      let pkg = autotools_package(
        srcDir = "./src",
        buildDir = LibiconvBuildDir,
        configureOptions = configureOptions,
        postConfigureCommands = libiconvPostConfigureCommands())
      discard pkg.executable("iconv")
      discard pkg.library("libIconv")
      discard pkg.library("libCharset")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

import std/[os, strutils, unittest]

import repro_core/ambient_execution
import repro_project_dsl

import ../source_recipe_paths
import ./repro

suite "gettext source recipe":
  test "pins the official GNU release archive":
    let spec = registeredFetchSpec("gettextSource")
    check spec.packageName == "gettextSource"
    check spec.kind == dfkTarball
    check spec.url == GettextSourceUrl
    check spec.hashAlg == dshaSha256
    check spec.hashHex == GettextSourceHash
    check spec.extractStrip == 1

  test "records current upstream version metadata":
    let versions = registeredVersions("gettextSource")
    check versions.len == 1
    check versions[0].version == GettextVersion
    check versions[0].sourceRevision == "v" & GettextVersion
    check versions[0].sourceUrl == GettextSourceUrl
    check versions[0].sourceRepository == GettextSourceRepository

  test "declares the expected build closure":
    check registeredNativeBuildDeps("gettextSource") ==
      @GettextNativeBuildDeps
    check registeredBuildDeps("gettextSource") == @GettextBuildDeps

  test "selects platform-specific libintl and linker options":
    var expectedOptions = @GettextBaseConfigureOptions
    when defined(windows):
      expectedOptions.add("--host=x86_64-w64-mingw32")
      expectedOptions.add("--with-libiconv-prefix=" &
        sourcePackageInstallPath("libiconv", "usr"))
      check gettextBuildEnvironment().len == 0
    else:
      expectedOptions.add("--without-included-libintl")
      check gettextBuildEnvironment() == @[(
        "LDFLAGS",
        "-Wl,-rpath," & sourcePackageInstallPath("gettext", "usr", "lib")
      )]
    check gettextConfigureOptions() == expectedOptions

  test "exports the catalog tools":
    let artifacts = registeredArtifacts("gettextSource")
    check artifacts.len == 3
    check artifacts[0].artifactName == "msgfmt"
    check artifacts[1].artifactName == "msgmerge"
    check artifacts[2].artifactName == "xgettext"
    for artifact in artifacts:
      check artifact.packageName == "gettextSource"
      check artifact.kind == dakExecutable

  test "uses the native Make quote pass only on Windows":
    when defined(windows):
      check gettextPostConfigureCommands() == @[
        "sh ../../scripts/fix-native-make-quotes.sh ."
      ]
    else:
      check gettextPostConfigureCommands().len == 0

  test "quote pass rewrites affected flags exactly once":
    let shellPath = uncontrolledFindExe("sh")
    require shellPath.len > 0

    let fixtureDir = getTempDir() /
      ("repro-gettext-quote-test-" & $getCurrentProcessId())
    let fixtureMakefile = fixtureDir / "Makefile"
    let scriptPath = currentSourcePath().parentDir.parentDir /
      "scripts" / "fix-native-make-quotes.sh"
    if dirExists(fixtureDir):
      removeDir(fixtureDir)
    createDir(fixtureDir)
    defer:
      removeDir(fixtureDir)

    writeFile(fixtureMakefile, """
AM_CPPFLAGS = -DLOCALEDIR=\"/usr/share/locale\"
bindir_c_make = \"$(bindir)\"
msgfmt_CPPFLAGS = $(AM_CPPFLAGS) -DINSTALLDIR=\"/usr/bin\"
gettext_CFLAGS = -DINSTALLDIR=$(bindir_c_make)
PLAIN_VALUE = untouched
""")

    let command = quoteShellCommand(@[shellPath, scriptPath, fixtureDir])
    check uncontrolledExecCmdEx(command).exitCode == 0
    check uncontrolledExecCmdEx(command).exitCode == 0

    let patched = readFile(fixtureMakefile)
    check patched.count(
      "# reprobuild native GNU make quote compatibility") == 1
    check patched.contains(
      "reprobuild_original_AM_CPPFLAGS := $(AM_CPPFLAGS)")
    check patched.contains(
      """AM_CPPFLAGS = $(subst ","",$(reprobuild_original_AM_CPPFLAGS))""")
    check patched.contains(
      "reprobuild_original_msgfmt_CPPFLAGS := $(msgfmt_CPPFLAGS)")
    check patched.contains(
      """msgfmt_CPPFLAGS = $(subst ","",$(reprobuild_original_msgfmt_CPPFLAGS))""")
    check patched.contains(
      "reprobuild_original_bindir_c_make := $(bindir_c_make)")
    check patched.contains(
      """bindir_c_make = $(subst ","",$(reprobuild_original_bindir_c_make))""")
    check not patched.contains("reprobuild_original_gettext_CFLAGS")
    check not patched.contains("reprobuild_original_PLAIN_VALUE")

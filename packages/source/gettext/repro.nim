## GNU gettext runtime and catalog tools built from the official release.
##
## Windows uses GNU libiconv explicitly and retains gettext's bundled
## libintl. Other hosts use the platform libintl implementation.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

import ../source_recipe_paths

const
  GettextVersion* = "1.0"
  GettextSourceUrl* =
    "https://ftp.gnu.org/gnu/gettext/gettext-" & GettextVersion & ".tar.xz"
  GettextSourceHash* =
    "71132a3fb71e68245b8f2ac4e9e97137d3e5c02f415636eb508ae607bc01add7"
  GettextSourceRepository* =
    "https://git.savannah.gnu.org/git/gettext.git"
  GettextBaseConfigureOptions* = [
    "--disable-static",
    "--disable-java",
    "--disable-csharp",
    "--disable-acl",
    "--disable-xattr",
    "--disable-libasprintf",
    "--without-emacs",
  ]
  GettextNativeBuildDeps* = [
    "autoconf",
    "automake",
    "libtool",
    "make",
    "gcc >=11",
    "pkg-config",
  ]
  GettextBuildDeps* = [
    "libiconv >=1.19",
    "libxml2 >=2.9",
  ]

proc gettextConfigureOptions*(): seq[string] =
  result = @GettextBaseConfigureOptions
  when defined(windows):
    result.add("--host=x86_64-w64-mingw32")
    result.add("--with-libiconv-prefix=" &
      sourcePackageInstallPath("libiconv", "usr"))
  else:
    result.add("--without-included-libintl")

proc gettextBuildEnvironment*(): seq[(string, string)] =
  when defined(windows):
    # PE/COFF binaries do not use ELF runtime search paths. Backslashes in a
    # native path would also be re-evaluated as shell escapes by libtool.
    @[]
  else:
    @[(
      "LDFLAGS",
      "-Wl,-rpath," & sourcePackageInstallPath("gettext", "usr", "lib")
    )]

proc gettextPostConfigureCommands*(): seq[string] =
  when defined(windows):
    # Native GNU Make strips escaped quotes when it delegates recipes to MSYS.
    @["sh ../../scripts/fix-native-make-quotes.sh ."]
  else:
    @[]

package gettextSource:
  versions:
    "1.0":
      sourceRevision = "v" & GettextVersion
      sourceUrl = GettextSourceUrl
      sourceRepository = GettextSourceRepository

  fetch:
    url: GettextSourceUrl
    sha256: GettextSourceHash
    extractStrip: 1

  nativeBuildDeps:
    "autoconf"
    "automake"
    "libtool"
    "make"
    "gcc >=11"
    "pkg-config"

  buildDeps:
    "libiconv >=1.19"
    "libxml2 >=2.9"

  config:
    discard

  executable msgfmt:
    discard

  executable msgmerge:
    discard

  executable xgettext:
    discard

  build:
    setCurrentOwningPackageOverride("gettextSource")
    try:
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = gettextConfigureOptions(),
        allowSourceWrites = true,
        postConfigureCommands = gettextPostConfigureCommands(),
        extraEnv = gettextBuildEnvironment())
      discard pkg.executable("msgfmt")
      discard pkg.executable("msgmerge")
      discard pkg.executable("xgettext")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

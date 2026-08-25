## GLib core libraries built from the official GNOME release.
##
## Optional integrations without source dependencies in this catalog are
## disabled explicitly. GLib still requires gettext's libintl interface on
## Windows even when translation catalogs are not generated.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

const
  GlibVersion* = "2.82.5"
  GlibSourceUrl* =
    "https://download.gnome.org/sources/glib/2.82/glib-" & GlibVersion &
      ".tar.xz"
  GlibSourceHash* =
    "05c2031f9bdf6b5aba7a06ca84f0b4aced28b19bf1b50c6ab25cc675277cbc3f"
  GlibSourceRepository* = "https://gitlab.gnome.org/GNOME/glib"
  GlibConfigureOptions* = [
    "tests=false",
    "documentation=false",
    "man-pages=disabled",
    "introspection=disabled",
    "nls=disabled",
    "xattr=false",
    "selinux=disabled",
    "libmount=disabled",
    "dtrace=disabled",
    "systemtap=disabled",
    "sysprof=disabled",
  ]
  GlibNativeBuildDeps* = [
    "meson >=0.79",
    "ninja >=1.10",
    "gcc >=11",
    "python3",
    "pkg-config",
  ]
  GlibBuildDeps* = [
    "pcre2 >=10.34",
    "libffi",
    "zlib",
    "gettext >=0.21",
  ]

package glib2Source:
  versions:
    "2.82.5":
      sourceRevision = GlibVersion
      sourceUrl = GlibSourceUrl
      sourceRepository = GlibSourceRepository

  fetch:
    url: GlibSourceUrl
    sha256: GlibSourceHash
    extractStrip: 1

  nativeBuildDeps:
    "meson >=0.79"
    "ninja >=1.10"
    "gcc >=11"
    "python3"
    "pkg-config"

  buildDeps:
    "pcre2 >=10.34"
    "libffi"
    "zlib"
    "gettext >=0.21"

  config:
    discard

  library libGlib2:
    discard

  library libGObject:
    discard

  library libGio:
    discard

  library libGModule:
    discard

  build:
    setCurrentOwningPackageOverride("glib2Source")
    try:
      let pkg = meson_package(
        srcDir = "./src",
        configureOptions = @GlibConfigureOptions,
        wrapMode = "nofallback")
      discard pkg.library("libGlib2")
      discard pkg.library("libGObject")
      discard pkg.library("libGio")
      discard pkg.library("libGModule")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

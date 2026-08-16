import std/strutils

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

import ../source_recipe_paths

package evolutionDataServerSource:
  versions:
    "3.54.3":
      sourceRevision = "3.54.3"
      sourceUrl = "https://download.gnome.org/sources/evolution-data-server/3.54/evolution-data-server-3.54.3.tar.xz"
      sourceRepository = "https://gitlab.gnome.org/GNOME/evolution-data-server"
  fetch:
    url: "https://download.gnome.org/sources/evolution-data-server/3.54/evolution-data-server-3.54.3.tar.xz"
    sha256: "5108dc38ee5cc1f8ef9155e87f6c4129f9644550a0962c5ae23ff807b57cb8d0"
    extractStrip: 1
  nativeBuildDeps:
    "cmake >=3.16"
    "ninja >=1.10"
    "gcc >=11"
    "pkg-config"
    "gperf >=3.1"
  buildDeps:
    "glib2 >=2.70"
    "libxml2 >=2.10"
    "libsoup3 >=3.0"
    "json-glib >=1.6"
    "util-linux"
    "sqlite >=3.40"
    "libsecret >=0.20"
    "libical >=3.0"
    "nspr >=4.36"
    "nss >=3.90"
    "icu"
    "zlib"
  config:
    discard
  library libEDataServer:
    discard
  library libEBackend:
    discard
  library libECal:
    discard
  library libEdataCal:
    discard
  library libCamel:
    discard
  build:
    setCurrentOwningPackageOverride("evolutionDataServerSource")
    try:
      let cpath = @[
        sourcePackageInstallPath("glib2", "usr", "include", "glib-2.0"),
        sourcePackageInstallPath(
          "glib2", "usr", "lib", "glib-2.0", "include"),
        sourcePackageInstallPath("libxml2", "usr", "include", "libxml2"),
        sourcePackageInstallPath(
          "json-glib", "usr", "include", "json-glib-1.0"),
        sourcePackageInstallPath("util-linux", "usr", "include"),
        sourcePackageInstallPath(
          "libsecret", "usr", "include", "libsecret-1"),
        sourcePackageInstallPath("libical", "usr", "include"),
        sourcePackageInstallPath("nspr", "usr", "include", "nspr"),
        sourcePackageInstallPath("nss", "usr", "include", "nss"),
      ].join(":")
      let pkg = cmake_package(srcDir = "./src", generator = "Ninja",
        cacheVars = @[
          "ENABLE_GTK=OFF",
          "ENABLE_GTK4=OFF",
          "ENABLE_OAUTH2_WEBKITGTK=OFF",
          "ENABLE_OAUTH2_WEBKITGTK4=OFF",
          "ENABLE_TESTS=OFF",
          "ENABLE_INSTALLED_TESTS=OFF",
          "ENABLE_EXAMPLES=OFF",
          "ENABLE_GOA=OFF",
          "ENABLE_WEATHER=OFF",
          "ENABLE_CANBERRA=OFF",
          "ENABLE_INTROSPECTION=OFF",
          "ENABLE_VALA_BINDINGS=OFF",
          "ENABLE_GTK_DOC=OFF",
          "WITH_PRIVATE_DOCS=OFF",
          "WITH_OPENLDAP=OFF",
          "WITH_SUNLDAP=OFF",
          "WITH_KRB5=OFF",
          "WITH_LIBDB=OFF",
          "CMAKE_BUILD_TYPE=Release",
          "CMAKE_POLICY_VERSION_MINIMUM=3.5",
        ], allowSourceWrites = true, extraEnv = @[("CPATH", cpath)])
      discard pkg.library("libEDataServer")
      discard pkg.library("libEBackend")
      discard pkg.library("libECal")
      discard pkg.library("libEdataCal")
      discard pkg.library("libCamel")
    finally:
      clearCurrentOwningPackageOverride()
  runtimeDeps:
    "glib2 >=2.70"
    "libxml2 >=2.10"
    "libsoup3 >=3.0"
    "json-glib >=1.6"
    "util-linux"
    "sqlite >=3.40"
    "libsecret >=0.20"
    "libical >=3.0"
    "nspr >=4.36"
    "nss >=3.90"
    "icu"
    "zlib"

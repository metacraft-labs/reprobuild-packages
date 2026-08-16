import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

import ../source_recipe_paths

package libsoup3Source:
  versions:
    "3.6.5":
      sourceRevision = "3.6.5"
      sourceUrl = "https://download.gnome.org/sources/libsoup/3.6/libsoup-3.6.5.tar.xz"
      sourceRepository = "https://gitlab.gnome.org/GNOME/libsoup"
  fetch:
    url: "https://download.gnome.org/sources/libsoup/3.6/libsoup-3.6.5.tar.xz"
    sha256: "6891765aac3e949017945c3eaebd8cc8216df772456dc9f460976fbdb7ada234"
    extractStrip: 1
  nativeBuildDeps:
    "meson >=1.0"
    "ninja >=1.10"
    "gcc >=11"
    "pkg-config"
  buildDeps:
    "glib2 >=2.70"
    "nghttp2 >=1.50"
    "sqlite >=3.40"
    "libpsl >=0.20"
    "zlib"
  config:
    discard
  library libSoup3:
    discard
  build:
    setCurrentOwningPackageOverride("libsoup3Source")
    try:
      let glib2 = sourcePackageInstallRoot("glib2")
      let pkg = meson_package(srcDir = "./src", configureOptions = @[
        "gssapi=disabled", "ntlm=disabled", "brotli=disabled",
        "tls_check=false", "introspection=disabled", "vapi=disabled",
        "docs=disabled", "tests=false", "autobahn=disabled",
        "installed_tests=false", "sysprof=disabled", "fuzzing=disabled",
        "pkcs11_tests=disabled",
      ], extraEnv = @[
        ("CPATH", glib2 & "/usr/include/glib-2.0:" &
          glib2 & "/usr/lib/glib-2.0/include:" &
          sourcePackageInstallPath("nghttp2", "usr", "include") & ":" &
          sourcePackageInstallPath("sqlite", "usr", "include") & ":" &
          sourcePackageInstallPath("libpsl", "usr", "include") & ":" &
          sourcePackageInstallPath("zlib", "usr", "include")),
      ])
      discard pkg.library("libSoup3")
    finally:
      clearCurrentOwningPackageOverride()
  runtimeDeps:
    "glib2 >=2.70"
    "nghttp2 >=1.50"
    "sqlite >=3.40"
    "libpsl >=0.20"
    "zlib"

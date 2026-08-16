import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

import ../source_recipe_paths

package gjsSource:
  versions:
    "1.82.3":
      sourceRevision = "1.82.3"
      sourceUrl = "https://download.gnome.org/sources/gjs/1.82/gjs-1.82.3.tar.xz"
      sourceRepository = "https://gitlab.gnome.org/GNOME/gjs"
  fetch:
    url: "https://download.gnome.org/sources/gjs/1.82/gjs-1.82.3.tar.xz"
    sha256: "63e84b9c82a60d166c8704322f8907945e25d9bbd0b80485468d3126505c027d"
    extractStrip: 1
  nativeBuildDeps:
    "meson >=0.64"
    "ninja >=1.10"
    "gcc >=11"
    "pkg-config"
    "glib2-introspection >=2.82"
  buildDeps:
    "glib2 >=2.80"
    "libffi"
    "gobject-introspection >=1.66"
    "cairo"
    "mozjs128 >=128"
  config:
    discard
  library libGjs:
    discard
  executable gjs:
    discard
  build:
    setCurrentOwningPackageOverride("gjsSource")
    try:
      let glib2 = sourcePackageInstallRoot("glib2")
      let gobjectIntrospection =
        sourcePackageInstallRoot("gobject-introspection")
      let glib2Introspection =
        sourcePackageInstallRoot("glib2-introspection")
      let mozjs = sourcePackageInstallRoot("mozjs128")
      let zlib = sourcePackageInstallRoot("zlib")
      let glibc = sourcePackageInstallRoot("glibc")
      let pkg = meson_package(srcDir = "./src", configureOptions = @[
        "readline=disabled",
        "profiler=disabled",
        "installed_tests=false",
        "dtrace=false",
        "systemtap=false",
      ], extraEnv = @[
        ("CPATH", glib2 & "/usr/include/glib-2.0:" &
          glib2 & "/usr/lib/glib-2.0/include"),
        ("PYTHONPATH", gobjectIntrospection &
          "/usr/lib/gobject-introspection"),
        ("GI_GIR_PATH", glib2Introspection & "/usr/share/gir-1.0"),
        ("GI_TYPELIB_PATH", glib2Introspection &
          "/usr/lib/girepository-1.0"),
        ("LDFLAGS", "-Wl,-rpath-link," & zlib & "/usr/lib " &
          "-Wl,-rpath-link," & glibc & "/usr/lib64"),
        ("LD_LIBRARY_PATH", mozjs & "/usr/lib:" &
          zlib & "/usr/lib:" &
          glib2 & "/usr/lib:" &
          gobjectIntrospection & "/usr/lib:" &
          sourcePackageInstallRoot("libffi") & "/usr/lib:" &
          sourcePackageInstallRoot("pcre2") & "/usr/lib:" &
          sourcePackageInstallRoot("libxml2") & "/usr/lib"),
      ])
      discard pkg.library("libGjs")
      discard pkg.executable("gjs")
    finally:
      clearCurrentOwningPackageOverride()
  runtimeDeps:
    "glib2 >=2.80"
    "libffi"
    "gobject-introspection >=1.66"
    "cairo"
    "mozjs128 >=128"

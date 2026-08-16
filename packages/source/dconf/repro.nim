import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package dconfSource:
  versions:
    "0.40.0":
      sourceRevision = "0.40.0"
      sourceUrl = "https://download.gnome.org/sources/dconf/0.40/dconf-0.40.0.tar.xz"
      sourceRepository = "https://gitlab.gnome.org/GNOME/dconf"

  fetch:
    url: "https://download.gnome.org/sources/dconf/0.40/dconf-0.40.0.tar.xz"
    sha256: "cf7f22a4c9200421d8d3325c5c1b8b93a36843650c9f95d6451e20f0bcb24533"
    extractStrip: 1

  nativeBuildDeps:
    "meson >=0.47"
    "ninja >=1.10"
    "gcc >=11"
    "pkg-config"

  buildDeps:
    "glib2 >=2.44"
    "dbus >=1.12"

  config:
    discard

  executable dconf:
    discard

  library libDconf:
    discard

  build:
    setCurrentOwningPackageOverride("dconfSource")
    try:
      let pkg = meson_package(srcDir = "./src", configureOptions = @[
        "bash_completion=false",
        "man=false",
        "gtk_doc=false",
        "vapi=false",
        "systemduserunitdir=/usr/lib/systemd/user",
      ])
      discard pkg.executable("dconf")
      discard pkg.library("libDconf")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    "glib2 >=2.44"
    "dbus >=1.12"

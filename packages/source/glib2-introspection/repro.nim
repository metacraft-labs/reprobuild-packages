import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

import ../source_recipe_paths

proc glib2IntrospectionLddPatch*(glibcLoader: string): string =
  "sed -i \"/^gir_args = \\[$/a\\  " &
    "'--use-ldd-wrapper=" & glibcLoader & "',\\n  " &
    "'--ldd-wrapper-args-begin',\\n  '--list',\\n  " &
    "'--ldd-wrapper-args-end',\" src/meson.build"

package glib2IntrospectionSource:
  versions:
    "2.82.5":
      sourceRevision = "2.82.5"
      sourceUrl = "https://download.gnome.org/sources/glib/2.82/glib-2.82.5.tar.xz"
      sourceRepository = "https://gitlab.gnome.org/GNOME/glib"
  fetch:
    url: "https://download.gnome.org/sources/glib/2.82/glib-2.82.5.tar.xz"
    sha256: "05c2031f9bdf6b5aba7a06ca84f0b4aced28b19bf1b50c6ab25cc675277cbc3f"
    extractStrip: 1
  nativeBuildDeps:
    "meson >=0.79"
    "ninja >=1.10"
    "gcc >=11"
    "python3"
    "pkg-config"
    "gobject-introspection >=1.66"
  buildDeps:
    "glib2 >=2.82"
    "pcre2 >=10.34"
    "libffi"
    "libiconv >=1.19"
    "zlib"
    "glibc >=2.42"
  config:
    discard
  executable gio:
    discard
  executable glib2Introspection:
    name: "glib2-introspection"
    discard
  build:
    setCurrentOwningPackageOverride("glib2IntrospectionSource")
    try:
      let glib2 = sourcePackageInstallRoot("glib2")
      let glibc = sourcePackageInstallRoot("glibc")
      let gcc = sourcePackageInstallRoot("gcc")
      let libiconv = sourcePackageInstallRoot("libiconv")
      let glibcLoader = glibc &
        "/usr/lib64/ld-linux-x86-64.so.2"
      let gobjectIntrospection =
        sourcePackageInstallRoot("gobject-introspection")
      let pkg = meson_package(
        srcDir = "./src",
        configureOptions = @[
          "tests=false",
          "documentation=false",
          "man-pages=disabled",
          "introspection=enabled",
          "sysprof=disabled",
          "nls=disabled",
          "xattr=false",
          "libdir=lib",
        ],
        extraEnv = @[
          ("PYTHONPATH", gobjectIntrospection &
            "/usr/lib/gobject-introspection"),
          ("GI_GIR_PATH", sourcePackagePath(
            "gobject-introspection", "build", "gir")),
          ("LDFLAGS", "-Wl,--dynamic-linker=" & glibcLoader & " " &
            "-Wl,-rpath," & glibc & "/usr/lib64 " &
            "-Wl,-rpath-link," & libiconv & "/usr/lib"),
          ("LD_LIBRARY_PATH", glib2 & "/usr/lib:" &
            gobjectIntrospection & "/usr/lib:" &
            gcc & "/usr/lib:" &
            libiconv & "/usr/lib:" &
            sourcePackageInstallRoot("libffi") & "/usr/lib:" &
            sourcePackageInstallRoot("pcre2") & "/usr/lib"),
        ],
        srcPatches = @[
          glib2IntrospectionLddPatch(glibcLoader),
        ])
      discard pkg.executable("gio")
      discard pkg.executableAlias("glib2-introspection", sourceName = "gio")
    finally:
      clearCurrentOwningPackageOverride()
  runtimeDeps:
    "glib2 >=2.82"
    "gobject-introspection >=1.66"
    "glibc >=2.42"
    "libiconv >=1.19"

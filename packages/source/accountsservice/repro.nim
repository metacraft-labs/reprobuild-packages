import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

import ../source_recipe_paths

package accountsserviceSource:
  versions:
    "23.13.9":
      sourceRevision = "23.13.9"
      sourceUrl = "https://www.freedesktop.org/software/accountsservice/accountsservice-23.13.9.tar.xz"
      sourceRepository = "https://gitlab.freedesktop.org/accountsservice/accountsservice"
  fetch:
    url: "https://www.freedesktop.org/software/accountsservice/accountsservice-23.13.9.tar.xz"
    sha256: "adda4cdeae24fa0992e7df3ffff9effa7090be3ac233a3edfdf69d5a9c9b924f"
    extractStrip: 1
  nativeBuildDeps:
    "meson >=0.56"
    "ninja >=1.10"
    "gcc >=11"
    "pkg-config"
    "gettext"
    "python3"
  buildDeps:
    "glib2"
    "polkit"
    "dbus"
    "systemd"
    "libxcrypt"
  config:
    discard
  library libaccountsservice:
    discard
  build:
    setCurrentOwningPackageOverride("accountsserviceSource")
    try:
      let glib2 = sourcePackageInstallRoot("glib2")
      let polkit = sourcePackageInstallRoot("polkit")
      let patches = @[
        "sed -i 's|^    VERSION_FROM_DIR_NAME=.*|    VERSION_FROM_DIR_NAME=23.13.9|' src/generate-version.sh",
        "mv src/data/org.freedesktop.accounts.policy.in src/data/org.freedesktop.accounts.policy",
        "sed -i \"s/input: policy + '.in'/input: policy/\" src/data/meson.build",
      ]
      let pkg = meson_package(srcDir = "./src", configureOptions = @[
        "admin_group=wheel",
        "localstatedir=/var",
        "systemdsystemunitdir=/usr/lib/systemd/system",
        "introspection=false",
        "vapi=false",
        "docbook=false",
        "gtk_doc=false",
      ], extraEnv = @[
        ("PKG_CONFIG_ALLOW_SYSTEM_CFLAGS", "1"),
        ("CPATH", glib2 & "/usr/include/glib-2.0:" &
          glib2 & "/usr/lib64/glib-2.0/include"),
        ("CFLAGS", "-Wno-error=implicit-function-declaration"),
        ("GETTEXTDATADIRS", polkit & "/usr/share/gettext"),
      ], srcPatches = patches)
      discard pkg.library("libaccountsservice")
    finally:
      clearCurrentOwningPackageOverride()
  runtimeDeps:
    "glib2"
    "polkit"
    "dbus"
    "systemd"
    "libxcrypt"

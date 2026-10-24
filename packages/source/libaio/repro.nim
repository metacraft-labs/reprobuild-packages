import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package libaioSource:
  versions:
    "0.3.113":
      sourceRevision = "libaio-0.3.113"
      sourceUrl = "https://deb.debian.org/debian/pool/main/liba/libaio/libaio_0.3.113.orig.tar.gz"
      sourceRepository = "https://pagure.io/libaio"
  fetch:
    url: "https://deb.debian.org/debian/pool/main/liba/libaio/libaio_0.3.113.orig.tar.gz"
    sha256: "2c44d1c5fd0d43752287c9ae1eb9c023f04ef848ea8d4aafa46e9aedb678200b"
    extractStrip: 1
  nativeBuildDeps:
    "awk"
    "diff"
    "make"
    "gcc >=11"
  config:
    discard
  library libaio:
    discard
  build:
    setCurrentOwningPackageOverride("libaioSource")
    try:
      let pkg = autotools_package(srcDir = "./src", configureOptions = @[
        "prefix=/usr", "libdir=/usr/lib",
      ], skipConfigure = true)
      discard pkg.library("libaio")
    finally:
      clearCurrentOwningPackageOverride()
  runtimeDeps:
    discard

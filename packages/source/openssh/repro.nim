## OpenSSH client and server built from the upstream portable release.

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package opensshSource:
  versions:
    "10.4p1":
      sourceRevision = "V_10_4_P1"
      sourceUrl = "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.4p1.tar.gz"
      sourceRepository = "https://github.com/openssh/openssh-portable"

  fetch:
    url: "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.4p1.tar.gz"
    sha256: "ef6026dd2aea8d56059638d5d3262902c892ceba9f88395835e0d06d3fb63238"
    extractStrip: 1

  nativeBuildDeps:
    "gcc >=11"
    "make >=4"

  buildDeps:
    "openssl"
    "zlib"

  config:
    discard

  executable ssh:
    discard

  executable sshd:
    discard

  executable sshKeygen:
    discard

  build:
    setCurrentOwningPackageOverride("opensshSource")
    try:
      let pkg = autotools_package(srcDir = "./src", configureOptions = @[
        "--sysconfdir=/etc/ssh",
        "--with-privsep-path=/var/empty",
        "--with-privsep-user=sshd",
        "--without-pam",
        "--without-selinux",
        "--without-kerberos5",
        "--without-libedit",
        "--disable-lastlog",
        "--disable-utmp",
        "--disable-utmpx",
        "--disable-wtmp",
        "--disable-wtmpx",
      ], installTarget = "install-nokeys")
      discard pkg.executable("ssh")
      discard pkg.executable("sshd")
      discard pkg.executableAlias("sshKeygen", sourceName = "ssh-keygen")
      pkg.installTreeMirror()
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    "openssl"
    "zlib"

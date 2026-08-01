import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

package bzip2Source:
  versions:
    "1.0.8":
      sourceRevision = "bzip2-1.0.8"
      sourceUrl = "https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz"
      sourceRepository = "https://sourceware.org/git/bzip2.git"

  fetch:
    url: "https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz"
    sha256: "ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269"
    extractStrip: 1

  nativeBuildDeps:
    "make >=4.3"
    "gcc >=11"

  config:
    discard

  executable bzip2:
    discard

  library libBz2:
    discard

  build:
    setCurrentOwningPackageOverride("bzip2Source")
    try:
      let patches = @[
        "printf '\n.PHONY: repro_install\nrepro_install:\n\t$(MAKE) -f Makefile-libbz2_so clean\n\t$(MAKE) -f Makefile-libbz2_so\n\tmkdir -p $(DESTDIR)/usr/bin $(DESTDIR)/usr/include $(DESTDIR)/usr/lib\n\tcp -a bzip2 bzip2recover bzgrep bzmore bzdiff $(DESTDIR)/usr/bin/\n\tln -sfn bzip2 $(DESTDIR)/usr/bin/bunzip2\n\tln -sfn bzip2 $(DESTDIR)/usr/bin/bzcat\n\tln -sfn bzgrep $(DESTDIR)/usr/bin/bzegrep\n\tln -sfn bzgrep $(DESTDIR)/usr/bin/bzfgrep\n\tln -sfn bzmore $(DESTDIR)/usr/bin/bzless\n\tln -sfn bzdiff $(DESTDIR)/usr/bin/bzcmp\n\tcp -a bzlib.h $(DESTDIR)/usr/include/\n\tcp -a libbz2.a libbz2.so.1.0.8 $(DESTDIR)/usr/lib/\n\tln -sfn libbz2.so.1.0.8 $(DESTDIR)/usr/lib/libbz2.so.1.0\n\tln -sfn libbz2.so.1.0.8 $(DESTDIR)/usr/lib/libbz2.so.1\n\tln -sfn libbz2.so.1.0.8 $(DESTDIR)/usr/lib/libbz2.so\n' >> ./src/Makefile",
      ]
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = @["PREFIX=/usr"],
        skipConfigure = true,
        installTarget = "repro_install",
        srcPatches = patches,
      )
      pkg.installTreeMirror()
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

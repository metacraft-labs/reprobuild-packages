## Perl runtime built from the official CPAN source release.
##
## Several source-built packages install operational Perl helpers. The
## complete install mirror keeps those scripts on a source-built
## interpreter and includes Perl's core module tree.

import repro_project_dsl
import repro_dsl_stdlib/types

package perlSource:
  versions:
    "5.40.0":
      sourceRevision = "v5.40.0"
      sourceUrl = "https://www.cpan.org/src/5.0/perl-5.40.0.tar.gz"
      sourceRepository = "https://github.com/Perl/perl5"

  fetch:
    url: "https://www.cpan.org/src/5.0/perl-5.40.0.tar.gz"
    sha256: "c740348f357396327a9795d3e8323bafd0fe8a5c7835fc1cbaba0cc8dfe7161f"
    extractStrip: 1

  nativeBuildDeps:
    "make"
    "gcc >=11"

  buildDeps:
    "linux-headers >=4.19"
    "libxcrypt"

  executable perl:
    build:
      # Compile FHS paths into Perl, install through DESTDIR, then expose
      # the resulting tree at the custom convention's output root.
      shell "./Configure -des -Dcc=gcc -Dprefix=/usr -Dvendorprefix=/usr -Dsiteprefix=/usr -Duseshrplib -Dman1dir=none -Dman3dir=none"
      shell "echo \"d_perl_lc_all_uses_name_value_pairs='define'\" >> config.sh && sh config_h.SH"
      shell "make -j8"
      shell "rm -rf $out/stage && make DESTDIR=$out/stage install"
      shell "cp -a $out/stage/usr/. $out/ && rm -rf $out/stage"
      shell "ln -sf perl5/5.40.0/x86_64-linux/CORE/libperl.so $out/lib/libperl.so"
      shell "mv $out/bin/perl $out/bin/perl.real && printf '%s\\n' '#!/bin/sh' 'prefix=$(CDPATH= cd -- \"$(dirname -- \"$0\")/..\" && pwd)' 'export LD_LIBRARY_PATH=\"$prefix/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"' 'export PERL5LIB=\"$prefix/lib/perl5/5.40.0:$prefix/lib/perl5/5.40.0/x86_64-linux${PERL5LIB:+:$PERL5LIB}\"' 'exec \"$prefix/bin/perl.real\" \"$@\"' > $out/bin/perl && chmod 0755 $out/bin/perl"
      shell "$out/bin/perl -Mstrict -e 'print qq(source-perl-ok\\n)'"

  runtimeDeps:
    discard

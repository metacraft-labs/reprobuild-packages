NR == 1 {
  print "#!/bin/sh"
  next
}

/^RTLDLIST=/ {
  print "ldd_script=$0"
  print "case $ldd_script in"
  print "  */*) ldd_dir=${ldd_script%/*} ;;"
  print "  *) ldd_dir=. ;;"
  print "esac"
  print "RTLDLIST=\"$(CDPATH= cd -- \"$ldd_dir/..\" && pwd)/libexec/ld-linux-x86-64.so.2\""
  next
}

{ print }

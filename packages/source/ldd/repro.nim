## Relocatable GNU ldd assembled from the source-built glibc output.
##
## Glibc's installed ldd script names the distribution's conventional ELF
## loaders under /lib. Those paths do not exist in a hermetic Nix build host.
## This recipe preserves the upstream script and rewrites only its interpreter
## discovery so it uses a source-built loader shipped beside the script.

import repro_project_dsl

import ../source_recipe_paths

package lddSource:
  versions:
    "2.42":
      sourceRevision = "glibc-2.42-relocatable-ldd"
      sourceUrl = "in-tree-wrapper:from-glibc-2.42"
      sourceRepository = "https://sourceware.org/git/glibc.git"

  nativeBuildDeps:
    "sh"
    "awk"
    "mkdir"
    "cp"
    "chmod"

  buildDeps:
    "glibc >=2.42"

  executable ldd:
    build:
      let glibcLdd = sourcePackageInstallPath("glibc", "usr", "bin", "ldd")
      let glibcLoader = sourcePackageInstallPath(
        "glibc", "usr", "lib64", "ld-linux-x86-64.so.2")
      let rewriter = sourcePackagePath("ldd", "rewrite-ldd.awk")
      shell "mkdir -p $out/bin $out/libexec"
      shell "awk -f \"" & rewriter & "\" \"" & glibcLdd &
        "\" > $out/bin/ldd"
      shell "cp \"" & glibcLoader &
        "\" $out/libexec/ld-linux-x86-64.so.2"
      shell "chmod 0755 $out/bin/ldd $out/libexec/ld-linux-x86-64.so.2"

  runtimeDeps:
    "sh"

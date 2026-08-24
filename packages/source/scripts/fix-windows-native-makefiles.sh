#!/bin/sh

set -eu

build_dir=${1:-.}
marker='# reprobuild native GNU make quote compatibility'
vars_file="${TMPDIR:-/tmp}/repro-make-quote-vars.$$"
missing_vars_file="${vars_file}.missing"
tools_file="${vars_file}.tools"
trap 'rm -f "$vars_file" "$missing_vars_file" "$tools_file"' \
  EXIT HUP INT TERM

find "$build_dir" -type f \( -name Makefile -o -name makefile \) -print |
while IFS= read -r makefile; do
  # Native windres cannot resolve its implicit `gcc` preprocessor through the
  # POSIX-form PATH inherited from MSYS. Bind the configured compiler and use
  # a temporary file so windres does not route the command through popen.
  awk '
    /^(WINDRES|RC)[ \t]*=[ \t]*windres[ \t]*$/ {
      sub(/windres[ \t]*$/,
        "windres --use-temp-file --preprocessor=\"$(CC)\" " \
        "--preprocessor-arg=-E --preprocessor-arg=-xc-header " \
        "--preprocessor-arg=-DRC_INVOKED")
    }
    { print }
  ' "$makefile" > "$tools_file"
  if ! cmp -s "$makefile" "$tools_file"; then
    mv "$tools_file" "$makefile"
  fi

  awk '
    function emit() {
      if (name != "" && has_quote &&
          (name == "DEFS" || name ~ /(CPPFLAGS|CFLAGS|CXXFLAGS)$/ ||
           name ~ /_c_make$/)) {
        print name
      }
      name = ""
      has_quote = 0
    }

    name == "" && match($0, /^[A-Za-z0-9_]+[ \t]*[:+?]?=/) {
      name = substr($0, RSTART, RLENGTH)
      sub(/[ \t]*[:+?]?=$/, "", name)
    }

    name != "" {
      if (index($0, "\\\"") != 0) {
        has_quote = 1
      }
      if ($0 !~ /\\$/) {
        emit()
      }
    }

    END {
      if (name != "") {
        emit()
      }
    }
  ' "$makefile" | sort -u > "$vars_file"

  if test ! -s "$vars_file"; then
    continue
  fi

  : > "$missing_vars_file"
  while IFS= read -r variable; do
    if ! grep -Fq "reprobuild_original_${variable} :=" "$makefile"; then
      printf '%s\n' "$variable" >> "$missing_vars_file"
    fi
  done < "$vars_file"

  if test ! -s "$missing_vars_file"; then
    continue
  fi

  {
    if ! grep -Fqx "$marker" "$makefile"; then
      printf '\n%s\n' "$marker"
    fi
    while IFS= read -r variable; do
      printf 'reprobuild_original_%s := $(%s)\n' "$variable" "$variable"
    done < "$missing_vars_file"
    while IFS= read -r variable; do
      printf '%s = $(subst ","",$(reprobuild_original_%s))\n' \
        "$variable" "$variable"
    done < "$missing_vars_file"
  } >> "$makefile"
done

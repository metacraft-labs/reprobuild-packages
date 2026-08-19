#!/usr/bin/env python3
"""Make glibc 2.42's image-time ldconfig observable to io-mon."""

from pathlib import Path
import shutil
import sys


def replace_once(text: str, old: str, new: str, description: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(
            f"expected one {description} in glibc 2.42, found {count}"
        )
    return text.replace(old, new, 1)


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: enable-dynamic-ldconfig.py GLIBC_SOURCE_ROOT")

    source_root = Path(sys.argv[1])
    makefile_path = source_root / "elf" / "Makefile"
    makefile = makefile_path.read_text(encoding="utf-8")

    makefile = replace_once(
        makefile,
        "others-static\t+= ldconfig\n",
        "",
        "static ldconfig registration",
    )

    modules_before = """ldconfig-modules := \\
  cache \\
  chroot_canon \\
  readlib \\
  static-stubs \\
  stringtable \\
  xmalloc \\
  xstrdup \\
  # ldconfig-modules
"""
    modules_after = modules_before.replace(
        "  static-stubs \\\n", "  ldconfig-cache-libcmp \\\n"
    )
    makefile = replace_once(
        makefile,
        modules_before,
        modules_after,
        "ldconfig module list",
    )

    cflags = """others-extras   = $(ldconfig-modules)

# These objects form a normal dynamic executable. Avoid glibc's internal
# hidden aliases so their libc calls remain dynamically interposable.
CFLAGS-ldconfig.c += -DNO_HIDDEN
CFLAGS-cache.c += -DNO_HIDDEN
CFLAGS-chroot_canon.c += -DNO_HIDDEN
CFLAGS-readlib.c += -DNO_HIDDEN
CFLAGS-ldconfig-cache-libcmp.c += -DNO_HIDDEN
CFLAGS-stringtable.c += -DNO_HIDDEN
CFLAGS-xmalloc.c += -DNO_HIDDEN
CFLAGS-xstrdup.c += -DNO_HIDDEN
"""
    makefile = replace_once(
        makefile,
        "others-extras   = $(ldconfig-modules)\n",
        cflags,
        "ldconfig extra-module declaration",
    )
    makefile_path.write_text(makefile, encoding="utf-8")

    comparator_source = Path(__file__).with_name("ldconfig-cache-libcmp.c")
    shutil.copyfile(comparator_source, source_root / "elf" / comparator_source.name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

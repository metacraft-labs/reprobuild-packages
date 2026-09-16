## Source-built Python environment for build-time code generators.
##
## Mesa requires Mako during configuration and code generation. The recipe
## copies the completed source CPython prefix and adds pinned Mako and
## MarkupSafe source trees without relying on pip, wheels, or Nix packages.

import std/os

import repro_project_dsl

import ../source_recipe_paths

const ModuleRootScript =
  "set -- \"$out\"/lib/python[0-9]*; " &
  "if [ \"$#\" -ne 1 ] || [ ! -d \"$1\" ]; then " &
  "printf '%s\\n' 'expected one Python standard-library directory' >&2; exit 1; fi; " &
  "MODULE_ROOT=\"$1/site-packages\"; "

package python3WithModulesSource:
  versions:
    "1.3.12":
      sourceRevision = "1.3.12"
      sourceUrl = "https://files.pythonhosted.org/packages/00/62/791b31e69ae182791ec67f04850f2f062716bbd205483d63a215f3e062d3/mako-1.3.12.tar.gz"
      sourceRepository = "https://github.com/sqlalchemy/mako"

  fetch:
    url: "https://files.pythonhosted.org/packages/00/62/791b31e69ae182791ec67f04850f2f062716bbd205483d63a215f3e062d3/mako-1.3.12.tar.gz"
    sha256: "9f778e93289bd410bb35daadeb4fc66d95a746f0b75777b942088b7fd7af550a"
    extractStrip: 1

  nativeBuildDeps:
    "python-markupsafe"
    "python-jinja2"
    "python-packaging"
    "python-setuptools"
    "python-markdown"
    "sh"
    "mkdir"
    "find"
    "rm"
    "cp"
    "chmod"
    "ln"

  buildDeps:
    "python3 >=3.8"

  executable `python3-with-modules`:
    build:
      let pythonPrefix = sourcePackageInstallPath("python3", "usr")
      shell "PYTHON_PREFIX=" & quoteShell(pythonPrefix) & "; " &
        "test -x \"$PYTHON_PREFIX/bin/python3\" || { " &
        "printf '%s\\n' 'source Python interpreter missing' >&2; exit 1; }; " &
        "mkdir -p \"$out\"; " &
        "find \"$out\" -mindepth 1 -maxdepth 1 ! -name .stamps -exec rm -rf -- {} +; " &
        "cp -a \"$PYTHON_PREFIX\"/. \"$out/\"; chmod -R u+w \"$out\""
      # Inspect the copied layout: neither a bootstrap nor a HOST interpreter
      # can choose the ABI of this environment, especially in a cross build.
      shell ModuleRootScript & "mkdir -p \"$MODULE_ROOT\"; " &
        "cp -a \"$extracted/mako\" \"$MODULE_ROOT/\"; " &
        "MARKUPSAFE_ROOT=$(python-markupsafe); cp -a \"$MARKUPSAFE_ROOT/markupsafe\" \"$MODULE_ROOT/\"; " &
        "PACKAGING_ROOT=$(python-packaging); cp -a \"$PACKAGING_ROOT/packaging\" \"$MODULE_ROOT/\""
      shell ModuleRootScript &
        "JINJA2_ROOT=$(python-jinja2); cp -a \"$JINJA2_ROOT/jinja2\" \"$MODULE_ROOT/\""
      shell ModuleRootScript &
        "SETUPTOOLS_ROOT=$(python-setuptools); cp -a \"$SETUPTOOLS_ROOT/setuptools\" " &
        "\"$SETUPTOOLS_ROOT/_distutils_hack\" \"$SETUPTOOLS_ROOT/pkg_resources\" " &
        "\"$SETUPTOOLS_ROOT/distutils-precedence.pth\" \"$MODULE_ROOT/\"; " &
        "MARKDOWN_ROOT=$(python-markdown); cp -a \"$MARKDOWN_ROOT/markdown\" \"$MODULE_ROOT/\""
      shell "ln -sf python3 \"$out/bin/python3-with-modules\""

  runtimeDeps:
    discard

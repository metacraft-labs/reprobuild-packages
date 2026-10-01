"""Find every workspace repository that depends on this catalog, and check that
its CI can reach it.

A `uses:` name reprobuild's stdlib does not bundle is looked up in this
catalog as `packages/interfaces/<name>/repro.nim`. A repository whose recipes
use such a name therefore needs the catalog wherever those recipes are
compiled -- and for a package that MOVED here from the stdlib (`sqlite3` was
the first), reprobuild refuses to compile the recipe without it.

So every consumer must declare, in its own repository, how CI provides the
catalog. This check accepts the two channels reprobuild-specs
Provisioning-Contributions.md ("Catalog Lookup And Provisioning") names:

* a `reprobuild-packages` entry in `.github/sibling-repos`, which
  `setup-dev-env` clones beside the checkout, where the lookup finds it;
* `REPROBUILD_PACKAGES_ROOT` exported by the repository's Nix files or
  workflows, for recipes compiled in a Nix dev shell with no sibling.

It cannot tell which CI job compiles which recipe; the engine's compile error
is what catches a job the declared channel does not reach. What it does
catch is a consumer with no channel at all, which is the state every consumer
was in when `sqlite3` moved. Run it after moving a package here.

It also flags a recipe that imports a stdlib package module by path
(`import repro_dsl_stdlib/packages/<name>`) instead of naming the package in
`uses:`. That import does not go through the catalog lookup, so when the
engine deletes the module the recipe stops compiling -- and no single recipe
state compiles with both the engine before the move and the engine after it.
An import of a MOVED module fails the audit: it must be dropped, relying on
`uses:`, in the same promotion window as the engine change (reprobuild-specs
issues/2026-09-30-moving-a-package-out-of-the-stdlib-breaks-recipes-that-import-it.md).
An import of a module the stdlib still has but this catalog also defines is
reported as the hazard it becomes on the next move, without failing. Point
`--reprobuild` at the engine that will compile the recipes (for a promotion,
reprobuild's `agents`): the moved list is read from it.

Repositories outside the workspace that compile recipes with reprobuild (for
example agent-harbor) are added with `--also <checkout>`.

The scan is textual: string literals inside `uses:`, `buildDeps:`,
`nativeBuildDeps:` and `runtimeDeps:` blocks of git-tracked `.nim` files.
Test sources that write a recipe as a string are scanned too, deliberately --
a test that compiles such a recipe needs the catalog like any other consumer.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
import json
from pathlib import Path
import re
import subprocess
import sys


BLOCK = re.compile(r"^(?P<indent>\s*)(?P<kind>uses|buildDeps|nativeBuildDeps|runtimeDeps):\s*(?P<rest>.*)$")
LITERAL = re.compile(r'^\s*"(?P<value>[^"\\]+)"')
MOVED_LIST = re.compile(
    r"MovedToReprobuildPackages\*\s*:\s*seq\[string\]\s*=\s*@\[(?P<items>[^\]]*)\]")
BUNDLED_LIST = re.compile(
    r"proc isBundledStdlibSelector\(selector: string\): bool =.*?selector in \[(?P<items>.*?)\n\s*\]",
    re.DOTALL)
STDLIB_PACKAGE_IMPORT = "repro_dsl_stdlib/packages/"
IMPORT_STATEMENT = re.compile(r"^\s*(?:import|from)\s")
IMPORTED_MODULE = re.compile(
    r'repro_dsl_stdlib/packages/(?:\[(?P<group>[^\]]*)\]|(?P<single>[A-Za-z0-9_]+))')
SIBLING_ENTRY = re.compile(r"^\s*(?:[\w.-]+/)?reprobuild-packages\s*(?:!?=.*)?$")
ROOT_ENV = "REPROBUILD_PACKAGES_ROOT"
CATALOG_REPO = "reprobuild-packages"


@dataclass
class Use:
    name: str
    path: str
    line: int
    literal: str


@dataclass
class Import:
    """A direct import of a stdlib package module. `module` is the package
    name the module defines (the catalog's spelling) once matched."""
    module: str
    path: str
    line: int
    text: str


@dataclass
class Consumer:
    repo: str
    path: Path
    uses: list[Use] = field(default_factory=list)
    channels: list[str] = field(default_factory=list)
    imports: list[Import] = field(default_factory=list)


def catalog_names(catalog: Path) -> set[str]:
    interfaces = catalog / "packages" / "interfaces"
    if not interfaces.is_dir():
        return set()
    return {entry.name for entry in interfaces.iterdir()
            if (entry / "repro.nim").is_file()}


def stdlib_names(reprobuild: Path | None) -> set[str]:
    """The names the stdlib auto-imports for a plain `uses:` line; those never
    reach the catalog. This is the selector list in `usesImportCode`
    (`isBundledStdlibSelector`), not the set of files under
    `repro_dsl_stdlib/packages/`: a stdlib file that is not on the list (for
    example `patchelf`) is not imported for a `uses:` line, so the catalog is
    consulted for it."""
    if reprobuild is None:
        return set()
    source = (reprobuild / "libs" / "repro_project_dsl" / "src" / "repro_project_dsl" /
              "macros_a.nim")
    if not source.is_file():
        return set()
    match = BUNDLED_LIST.search(source.read_text(encoding="utf-8-sig"))
    if not match:
        return set()
    items = "\n".join(line.split("#", 1)[0] for line in match["items"].splitlines())
    return set(re.findall(r'"([^"]+)"', items))


def moved_names(reprobuild: Path | None) -> set[str]:
    """The engine's `MovedToReprobuildPackages`: a compile error without us."""
    if reprobuild is None:
        return set()
    source = (reprobuild / "libs" / "repro_project_dsl" / "src" / "repro_project_dsl" /
              "reprobuild_packages_catalog.nim")
    if not source.is_file():
        return set()
    match = MOVED_LIST.search(source.read_text(encoding="utf-8-sig"))
    if not match:
        return set()
    return set(re.findall(r'"([^"]+)"', match["items"]))


def dependency_literals(text: str) -> list[tuple[int, str]]:
    """(line number, literal) for every string in a dependency block."""
    found = []
    lines = text.splitlines()
    index = 0
    while index < len(lines):
        match = BLOCK.match(lines[index])
        index += 1
        if not match:
            continue
        rest = match["rest"].split("#", 1)[0].strip()
        if rest:
            inline = LITERAL.match(rest)
            if inline:
                found.append((index, inline["value"]))
            continue
        base = len(match["indent"].expandtabs())
        while index < len(lines):
            line = lines[index]
            stripped = line.strip()
            if stripped and not stripped.startswith("#"):
                if len(line) - len(line.lstrip()) <= base:
                    break
                literal = LITERAL.match(line)
                if literal:
                    found.append((index + 1, literal["value"]))
            index += 1
    return found


def module_name(selector: str) -> str:
    """The stdlib module file a package selector lives in: `selectorModuleName`
    in reprobuild's `macros_a.nim` (`pkg-config` -> `pkg_config`)."""
    result = ""
    previous_was_word = False
    for ch in selector:
        if ch.isalnum():
            if ch.isupper() and previous_was_word and result and result[-1] != "_":
                result += "_"
            result += ch.lower()
            previous_was_word = True
        else:
            if result and result[-1] != "_":
                result += "_"
            previous_was_word = False
    return result.rstrip("_") or "package"


def stdlib_package_imports(text: str) -> list[tuple[int, str, str]]:
    """(line number, module name, statement) for every module of
    `repro_dsl_stdlib/packages/` an `import` or `from` statement names, in
    every spelling Nim accepts: a single module, a `[a, b]` group (also one
    spanning lines), an `as`/`except` suffix, or a quoted path. Comments are
    ignored."""
    found = []
    lines = text.splitlines()
    index = 0
    while index < len(lines):
        number = index + 1
        statement = lines[index].split("#", 1)[0]
        index += 1
        if not IMPORT_STATEMENT.match(statement) or STDLIB_PACKAGE_IMPORT not in statement:
            continue
        # A bracket group may continue on the following lines.
        while statement.count("[") > statement.count("]") and index < len(lines):
            statement += " " + lines[index].split("#", 1)[0].strip()
            index += 1
        for match in IMPORTED_MODULE.finditer(statement):
            if match["group"] is not None:
                names = [part.split()[0] for part in match["group"].split(",")
                         if part.strip()]
            else:
                names = [match["single"]]
            for name in names:
                found.append((number, name, " ".join(statement.split())))
    return found


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(["git", "-C", str(repo), *args], capture_output=True,
                            text=True, encoding="utf-8", errors="replace")
    return result.stdout if result.returncode == 0 else ""


def tracked(repo: Path, patterns: list[str]) -> list[str]:
    return [line for line in git(repo, "ls-files", "--", *patterns).splitlines() if line]


def scan(repo: Path, names: set[str], scan_imports: bool = True) -> tuple[
        list[Use], list[Import]]:
    """The dependency-block uses of `names`, and every direct stdlib package
    import, in the repository's tracked Nim sources. One `git grep` finds the
    candidate files for both."""
    pattern = r"(uses|buildDeps|nativeBuildDeps|runtimeDeps):"
    if scan_imports:
        pattern += "|" + re.escape(STDLIB_PACKAGE_IMPORT)
    candidates = git(repo, "grep", "-l", "-E", pattern, "--", "*.nim", "*.nims")
    uses = []
    imports = []
    for relative in candidates.splitlines():
        path = repo / relative
        try:
            text = path.read_text(encoding="utf-8-sig", errors="replace")
        except OSError:
            continue
        shown = relative.replace("\\", "/")
        for line, literal in dependency_literals(text):
            name = literal.split()[0] if literal.split() else ""
            if name in names:
                uses.append(Use(name, shown, line, literal))
        if scan_imports:
            for line, module, statement in stdlib_package_imports(text):
                imports.append(Import(module, shown, line, statement))
    return uses, imports


def channels(repo: Path) -> list[str]:
    found = []
    sibling_repos = repo / ".github" / "sibling-repos"
    if sibling_repos.is_file():
        for number, line in enumerate(
                sibling_repos.read_text(encoding="utf-8-sig").splitlines(), 1):
            if SIBLING_ENTRY.match(line.split("#", 1)[0]):
                found.append(f".github/sibling-repos:{number}: {line.strip()}")
    for relative in tracked(repo, ["*.nix", ".github/workflows/*.yml",
                                   ".github/workflows/*.yaml", ".github/actions/*"]):
        path = repo / relative
        try:
            text = path.read_text(encoding="utf-8-sig", errors="replace")
        except (OSError, IsADirectoryError):
            continue
        for number, line in enumerate(text.splitlines(), 1):
            if ROOT_ENV in line and not line.lstrip().startswith("#"):
                found.append(f"{relative}:{number}: {ROOT_ENV}")
                break
    if not found and not tracked(repo, [".github/workflows/*.yml",
                                        ".github/workflows/*.yaml"]):
        # Nothing to provision: the recipes are only ever compiled in a
        # workspace, where the sibling checkout is found. Said, not hidden, so
        # the day the repository grows CI the line reads as a to-do.
        found.append("no CI workflows: compiled only in a workspace, which "
                     "has the sibling checkout")
    return found


def repo_name(repo: Path) -> str:
    url = git(repo, "remote", "get-url", "origin").strip()
    return Path(url.removesuffix(".git")).name if url else repo.name


def workspace_repos(workspace: Path) -> list[Path]:
    """One checkout per repository: linked worktrees of a repo are skipped in
    favour of the checkout named after it."""
    groups: dict[str, list[Path]] = {}
    for entry in sorted(workspace.iterdir()):
        if not (entry / ".git").exists():
            continue
        common = git(entry, "rev-parse", "--path-format=absolute", "--git-common-dir").strip()
        if not common:
            continue
        groups.setdefault(common, []).append(entry)
    chosen = []
    for members in groups.values():
        preferred = [member for member in members if repo_name(member) == member.name]
        chosen.append((preferred or members)[0])
    return sorted(chosen)


def audit(repos: list[Path], catalog: Path, reprobuild: Path | None) -> tuple[
        list[Consumer], set[str], set[str]]:
    defined = catalog_names(catalog)
    names = defined - stdlib_names(reprobuild)
    moved = moved_names(reprobuild)
    # A direct import matters for any package this catalog defines (an import
    # of a moved one already fails to compile; any other is the same failure on
    # the next move) and for every moved name, defined here or not.
    watched = {module_name(name): name for name in defined | moved}
    consumers = []
    for repo in repos:
        if repo.resolve() == catalog.resolve() or repo_name(repo) == CATALOG_REPO:
            continue
        # The engine's own stdlib (with its one-release stubs and the tests that
        # import them) is not a consumer of its own modules.
        uses, imports = scan(repo, names,
                             scan_imports=repo_name(repo) != "reprobuild")
        imports = [found for found in imports if found.module in watched]
        for found in imports:
            found.module = watched[found.module]
        if uses or imports:
            consumers.append(Consumer(repo_name(repo), repo, uses,
                                      channels(repo) if uses else [], imports))
    return consumers, names, moved


def main() -> int:
    here = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n", 1)[0])
    parser.add_argument("--catalog", type=Path, default=here,
                        help="this catalog's checkout (default: %(default)s)")
    parser.add_argument("--workspace", type=Path, default=here.parent,
                        help="directory whose repository checkouts are scanned")
    parser.add_argument("--reprobuild", type=Path, default=None,
                        help="reprobuild checkout for the stdlib and moved lists "
                             "(default: <workspace>/reprobuild)")
    parser.add_argument("--repo", type=Path, action="append", default=[],
                        help="scan only these checkouts, inside the workspace "
                             "or not (repeatable)")
    parser.add_argument("--also", type=Path, action="append", default=[],
                        help="scan this checkout as well as the workspace, "
                             "typically one outside it such as agent-harbor "
                             "(repeatable)")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    reprobuild = args.reprobuild or args.workspace / "reprobuild"
    if not (reprobuild / "libs").is_dir():
        print(f"warning: no reprobuild checkout at {reprobuild}; stdlib-bundled "
              "names are not excluded and moved packages are not marked",
              file=sys.stderr)
        reprobuild = None
    for extra in args.repo + args.also:
        if not (extra / ".git").exists():
            print(f"{extra}: not a git checkout", file=sys.stderr)
            return 2
    repos = args.repo or workspace_repos(args.workspace)
    for extra in args.also:
        if all(extra.resolve() != repo.resolve() for repo in repos):
            repos.append(extra)
    consumers, names, moved = audit(repos, args.catalog, reprobuild)

    if not names:
        print(f"{args.catalog}: no catalog-only interfaces found", file=sys.stderr)
        return 1
    missing = [consumer for consumer in consumers
               if consumer.uses and not consumer.channels]
    moved_imports = [(consumer, found) for consumer in consumers
                     for found in consumer.imports if found.module in moved]
    if args.json:
        print(json.dumps({
            "catalogNames": sorted(names),
            "movedNames": sorted(moved),
            "scannedRepos": len(repos),
            "consumers": [{
                "repo": consumer.repo,
                "uses": [use.__dict__ for use in consumer.uses],
                "channels": consumer.channels,
                "stdlibImports": [{**found.__dict__, "moved": found.module in moved}
                                  for found in consumer.imports],
            } for consumer in consumers],
        }, indent=2))
    else:
        print(f"catalog-only names: {', '.join(sorted(names))}")
        print(f"moved from the stdlib (compile error without the catalog): "
              f"{', '.join(sorted(moved)) or '(unknown)'}")
        print(f"scanned {len(repos)} repositories; {len(consumers)} consume the catalog")
        for consumer in consumers:
            print(f"\n{consumer.repo}")
            for use in consumer.uses:
                marker = " [moved]" if use.name in moved else ""
                print(f"  uses {use.literal!r}{marker}  {use.path}:{use.line}")
            for found in consumer.imports:
                state = ("MOVED: no longer in the stdlib" if found.module in moved
                         else "still in the stdlib; breaks when it moves")
                print(f"  imports repro_dsl_stdlib/packages/{module_name(found.module)} "
                      f"[{state}]  {found.path}:{found.line}")
            if consumer.uses:
                for channel in consumer.channels or ["NO CHANNEL: CI cannot reach the catalog"]:
                    print(f"  provides: {channel}")
    failed = False
    if missing:
        print(f"\n{len(missing)} consumer(s) declare no way for CI to reach the "
              f"catalog: {', '.join(consumer.repo for consumer in missing)}.\n"
              f"Add `reprobuild-packages` to .github/sibling-repos, or export "
              f"{ROOT_ENV} from the Nix dev shell that compiles the recipe.",
              file=sys.stderr)
        failed = True
    if moved_imports:
        print(f"\n{len(moved_imports)} direct import(s) of a stdlib module that "
              f"moved to this catalog:", file=sys.stderr)
        for consumer, found in moved_imports:
            print(f"  {consumer.repo}: {found.path}:{found.line}: "
                  f"repro_dsl_stdlib/packages/{module_name(found.module)}",
                  file=sys.stderr)
        print("Such an import does not compile against an engine without the "
              "module. Drop it and rely on the package's `uses:` line, which "
              "resolves it from the catalog; land that with the engine change.",
              file=sys.stderr)
        failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())

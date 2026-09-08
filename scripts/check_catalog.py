"""Check source recipe layout and the catalog's existing identity policy."""

import argparse
from pathlib import Path
import re
import sys


PACKAGE = re.compile(r"^package\s+([A-Za-z0-9_`-]+):", re.MULTILINE)
PROVIDER_DEP = re.compile(r'^\s*"pkgconf(?:\s|")', re.MULTILINE)


def check_catalog(root: Path) -> tuple[int, list[str]]:
    if not root.is_dir():
        return 0, [f"{root}: missing source recipe directory"]
    recipes = sorted(
        path for path in root.iterdir() if path.is_dir() and path.name != "scripts"
    )
    failures = []
    if not recipes:
        failures.append(f"{root}: no source recipes found")
    for recipe in recipes:
        definition = recipe / "repro.nim"
        if not definition.is_file():
            failures.append(f"{recipe.name}: missing repro.nim")
            continue
        source = definition.read_text(encoding="utf-8-sig")
        if PROVIDER_DEP.search(source):
            failures.append(
                f"{recipe.name}: declare the pkg-config capability, not its pkgconf provider"
            )
        match = PACKAGE.search(source)
        if not match:
            failures.append(f"{recipe.name}: missing package declaration")
            continue
        package_name = match[1].strip("`")
        if recipe.name == "create-dmg":
            if package_name != "create-dmg":
                failures.append(
                    f"{recipe.name}: expected package identity create-dmg, got {package_name}"
                )
        elif not package_name.endswith("Source"):
            failures.append(
                f"{recipe.name}: private recipe package identity must end in Source, "
                f"got {package_name}"
            )
    return len(recipes), failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root", type=Path,
        default=Path(__file__).resolve().parents[1] / "packages" / "source",
    )
    count, failures = check_catalog(parser.parse_args().root)
    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1
    print(f"Validated {count} source recipes with private implementation identities.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

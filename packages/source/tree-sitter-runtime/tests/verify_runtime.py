"""Exercise the produced C runtime without ambient header/library fallbacks.

Run the normal source recipe first. This control compiles a real C client
using the compiler recorded by that build, then removes each required output
in turn and requires the same command to refuse it. Only this recipe's owned
outputs are renamed, and they are restored even when an assertion fails.
"""

import hashlib
import json
import os
import pathlib
import subprocess
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    root = pathlib.Path(__file__).resolve().parent.parent
    prefix = root / ".repro/output/install/usr"
    header = prefix / "include/tree_sitter/api.h"
    archive = prefix / "lib/libtree-sitter.a"
    cache = root / ".repro/build/tree-sitter-runtime/CMakeCache.txt"
    compiler = None
    for line in cache.read_text(encoding="utf-8").splitlines():
        if line.startswith(("CMAKE_C_COMPILER:FILEPATH=", "CMAKE_C_COMPILER:STRING=")):
            compiler = pathlib.Path(line.split("=", 1)[1])
    assert compiler and compiler.is_absolute() and compiler.is_file(), (
        "the normal producer must record its actual C compiler"
    )
    assert header.is_file() and archive.is_file(), "build the source recipe first"
    before = {str(path): digest(path) for path in (header, archive)}
    logs = root / "build/test-logs"
    logs.mkdir(parents=True, exist_ok=True)
    work = pathlib.Path(tempfile.mkdtemp(prefix="runtime-consumer-", dir=logs))
    binary = work / ("consumer.exe" if os.name == "nt" else "consumer")
    command = [
        str(compiler), "-std=c11",
        f'-DTREE_SITTER_HEADER="{header.as_posix()}"',
        str(root / "tests/runtime_consumer.c"), str(archive), "-o", str(binary),
    ]
    outcomes = []
    binary_digest = None

    def run(argv, name):
        log = work / (name + ".log")
        with log.open("wb") as stream:
            result = subprocess.run(argv, stdout=stream, stderr=subprocess.STDOUT,
                                    timeout=120, check=False)
        outcomes.append({"name": name, "argv": argv, "exitCode": result.returncode,
                         "log": str(log), "logSha256": digest(log)})
        return result.returncode, log.read_text(encoding="utf-8", errors="replace")

    try:
        code, _ = run(command, "compile-positive")
        assert code == 0, "real C client did not compile/link; see retained log"
        code, _ = run([str(binary)], "execute-positive")
        assert code == 0, "real parser allocation/deletion failed"
        binary_digest = digest(binary)
        for missing, name in [(header, "missing-header"), (archive, "missing-archive")]:
            held = missing.with_name(missing.name + ".control-held")
            assert not held.exists(), "refuse to overwrite another control's output"
            missing.rename(held)
            try:
                code, text = run(command, name)
                assert code != 0, f"missing produced {name} fell through to ambient inputs"
                assert missing.name in text, "failure did not identify the required output"
            finally:
                held.rename(missing)
        assert before == {str(path): digest(path) for path in (header, archive)}
    finally:
        receipt = {"compiler": str(compiler), "compilerSha256": digest(compiler),
                   "recipeSha256": digest(root / "repro.nim"),
                   "interfaceSha256": digest(root.parent.parent /
                                              "interfaces/tree-sitter-runtime/repro.nim"),
                   "cmakeCacheSha256": digest(cache),
                   "consumerSourceSha256": digest(root / "tests/runtime_consumer.c"),
                   "positiveBinarySha256": binary_digest,
                   "producedInputs": before, "commands": outcomes,
                   "limits": "Compiler entry file and host C control; no whole toolchain "
                             "image proof or Windows claim from a POSIX run."}
        (work / "qualification.json").write_text(
            json.dumps(receipt, indent=2) + "\n", encoding="utf-8"
        )
    print(work / "qualification.json")


if __name__ == "__main__":
    main()

## Gate: the kernel this repository builds really carries the symbols the
## attestation substrate needs — dm-verity, dm-crypt, TPM, and the
## guest-side confidential-compute knobs — in the configuration the build
## ACTUALLY ENDS UP WITH, not the one it asks for.
##
## ## Why "resolved" and not "requested" is the whole point
##
## The recipe configures the kernel in three steps: ``make defconfig``,
## then ``scripts/config --enable …`` over the list in ``repro.nim``, then
## ``make olddefconfig``. The third step is not a formality. Kconfig
## deletes any requested symbol whose dependencies are unmet, and it does
## so SILENTLY — no warning, no non-zero exit. Measured on this recipe's
## pinned source (Linux 6.6.142), a run that requests
##
##     CONFIG_SEV_GUEST=y
##     CONFIG_INTEL_TDX_GUEST=y
##     CONFIG_TDX_GUEST_DRIVER=y
##     CONFIG_TSM_REPORTS=y
##
## and does not also enable ``VIRT_DRIVERS`` (the ``menuconfig`` bool
## guarding all of ``drivers/virt``) and ``X86_X2APIC`` (a hard dependency
## of ``INTEL_TDX_GUEST``) produces a resolved ``.config`` in which all
## four lines are simply GONE. A gate that asserted the requested list
## would have been green for that build and the kernel would have shipped
## without a single confidential-compute driver in it.
##
## So this gate re-runs the recipe's own configuration phase against the
## recipe's own pinned source and asserts the RESOLVED ``.config``. Two of
## the symbols it demands — ``TCG_TIS_CORE`` and ``DM_BUFIO`` — are never
## requested at all; Kconfig ``select``s them. They are in the required
## set precisely because a check that finds them cannot have been reading
## a requested config.
##
## ## What this gate proves, and what it does not
##
## PROVES: for the pinned kernel version, the recipe's configuration
## phase yields a ``.config`` in which every required symbol is ``y``.
## That is the same phase, the same source, the same ``scripts/config``
## argument vector (rendered from the same constants) and the same
## ``olddefconfig`` the build runs — the configuration is fully decided
## by the end of this phase and compilation does not revisit it.
##
## DOES NOT PROVE: that the kernel then compiles and boots with those
## options, or that the resulting bzImage behaves. Compiling the kernel
## is a multi-hour job here. When a built kernel IS present, the last
## check below reads the config the build packaged
## (``usr/lib/reproos-kernel/config``) and asserts the same set over it,
## so the claim is upgraded from "the recipe resolves to this" to "the
## artifact on disk is this" the moment such an artifact exists.
##
## ## Mocking
##
## None. Real upstream kernel source (sha256-verified against the
## recipe's own ``fetch:`` pin), real ``make``, real ``scripts/config``,
## real ``olddefconfig``, real files on disk. No fixture config is ever
## substituted for a resolved one.
##
## ## Cost and caching
##
## ``defconfig`` + ``olddefconfig`` over a real 6.6 tree costs ~45 s on
## an unloaded machine. The source tree is looked up in this order and
## only fetched as a last resort:
##
##   1. ``$REPRO_KERNEL_SRC``
##   2. the recipe's own extracted tree, ``packages/source/kernel/src``
##   3. ``$XDG_CACHE_HOME/reprobuild-packages/kernel-src/linux-<version>``
##   4. a fresh download of the recipe's pinned tarball into (3),
##      sha256-verified against ``registeredFetchSpec("kernelSource")``
##
## ``flex``/``bison``/``bc`` are kbuild host-tool prerequisites of the
## configuration phase. If they are not on ``PATH`` the gate borrows them
## through ``nix shell`` rather than failing, which is what makes it
## runnable from an ambient workspace shell.

import std/[os, osproc, strutils, tables, unittest]

import repro_project_dsl

# Side-effect import: registers the fetch spec and versions this gate
# reads, and brings in the configuration constants the build uses.
import ./repro

const
  PackageName = "kernelSource"
  RecipeDir = currentSourcePath().parentDir()
  KernelSrcEnv = "REPRO_KERNEL_SRC"
  BuiltConfigEnv = "REPRO_KERNEL_CONFIG"
  BuiltConfigRelPath =
    ".repro/output/install/usr/lib/reproos-kernel/config"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

proc pinnedVersion(): string =
  let vs = registeredVersions(PackageName)
  doAssert vs.len == 1, "kernelSource must declare exactly one version"
  vs[0].version

proc versionAtLeast(version: string; major, minor: int): bool =
  let parts = version.split('.')
  doAssert parts.len >= 2, "unparseable kernel version: " & version
  let maj = parseInt(parts[0])
  let min = parseInt(parts[1])
  maj > major or (maj == major and min >= minor)

proc run(cmd: string): tuple[output: string, code: int] =
  let r = execCmdEx(cmd)
  (output: r.output, code: r.exitCode)

proc shellQuote(s: string): string =
  "'" & s.replace("'", "'\\''") & "'"

proc hostToolPrefix(): string =
  ## kbuild's configuration phase needs ``flex`` and ``bison`` to build
  ## ``scripts/kconfig/conf``, and ``bc`` for ``kernel/timeconst.bc``.
  ## Use them from ``PATH`` when they are there; otherwise borrow them,
  ## rather than turning a missing dev-shell entry into a red gate.
  if findExe("flex").len > 0 and findExe("bison").len > 0 and
     findExe("bc").len > 0:
    return ""
  let nix = findExe("nix")
  doAssert nix.len > 0,
    "the kernel configuration phase needs flex, bison and bc on PATH " &
    "(or `nix` available to borrow them). Remedy: enter a shell that " &
    "provides them, e.g. `nix shell nixpkgs#flex nixpkgs#bison nixpkgs#bc`."
  shellQuote(nix) & " shell nixpkgs#flex nixpkgs#bison nixpkgs#bc --command "

proc looksLikeKernelTree(dir: string): bool =
  dir.len > 0 and fileExists(dir / "Makefile") and
    dirExists(dir / "scripts" / "kconfig") and
    fileExists(dir / "scripts" / "config")

proc cacheRoot(): string =
  let xdg = getEnv("XDG_CACHE_HOME")
  let base = if xdg.len > 0: xdg else: getHomeDir() / ".cache"
  base / "reprobuild-packages" / "kernel-src"

proc fetchAndExtract(version: string): string =
  ## Last resort. Downloads the tarball the recipe pins, verifies its
  ## sha256 against the recipe's own ``fetch:`` block (so the gate can
  ## never be fed a different kernel than the build uses), and extracts
  ## it into the cache.
  let spec = registeredFetchSpec(PackageName)
  let root = cacheRoot()
  createDir(root)
  let tarball = root / "linux-" & version & ".tar.xz"
  if not fileExists(tarball):
    let curl = findExe("curl")
    doAssert curl.len > 0,
      "no kernel source found and `curl` is unavailable to fetch it. " &
      "Remedy: set " & KernelSrcEnv & "=<path-to-linux-" & version &
      "> to an extracted upstream tree."
    let part = tarball & ".part"
    removeFile(part)
    echo "[info] fetching ", spec.url
    let dl = run(shellQuote(curl) & " -fL --retry 3 -o " &
                 shellQuote(part) & " " & shellQuote(spec.url))
    doAssert dl.code == 0,
      "failed to fetch " & spec.url & ":\n" & dl.output
    moveFile(part, tarball)
  let sum = run("sha256sum " & shellQuote(tarball))
  doAssert sum.code == 0, "sha256sum failed:\n" & sum.output
  let got = sum.output.strip().split(' ')[0]
  doAssert got == spec.hashHex,
    "the cached kernel tarball does not match the recipe's pin.\n" &
    "  expected " & spec.hashHex & "\n  got      " & got & "\n" &
    "Remedy: delete " & tarball & " and re-run."
  let dest = root / "linux-" & version
  if not looksLikeKernelTree(dest):
    echo "[info] extracting ", tarball
    let ex = run("tar -x -f " & shellQuote(tarball) & " -C " &
                 shellQuote(root))
    doAssert ex.code == 0, "failed to extract " & tarball & ":\n" & ex.output
  dest

proc kernelSourceDir(version: string): string =
  let fromEnv = getEnv(KernelSrcEnv)
  if fromEnv.len > 0:
    doAssert looksLikeKernelTree(fromEnv),
      KernelSrcEnv & "=" & fromEnv & " is not a Linux source tree"
    return fromEnv
  let recipeSrc = RecipeDir / "src"
  if looksLikeKernelTree(recipeSrc):
    return recipeSrc
  let cached = cacheRoot() / "linux-" & version
  if looksLikeKernelTree(cached):
    return cached
  fetchAndExtract(version)

proc parseConfig(path: string): Table[string, string] =
  ## ``CONFIG_X=y`` -> ``"y"``; ``# CONFIG_X is not set`` -> ``"n"``.
  ## Symbols absent from the file are absent from the table, which is a
  ## THIRD state and the one ``olddefconfig`` leaves behind when it drops
  ## a symbol whose dependencies are unmet.
  result = initTable[string, string]()
  for rawLine in lines(path):
    let line = rawLine.strip()
    if line.startsWith("CONFIG_"):
      let eq = line.find('=')
      if eq > 0:
        result[line[7 ..< eq]] = line[eq + 1 .. ^1]
    elif line.startsWith("# CONFIG_") and line.endsWith(" is not set"):
      let name = line[9 ..< line.len - len(" is not set")]
      result[name] = "n"

proc describe(cfg: Table[string, string]; symbol: string): string =
  if cfg.hasKey(symbol): symbol & "=" & cfg[symbol]
  else: symbol & " ABSENT (dropped by olddefconfig or unknown to Kconfig)"

# ---------------------------------------------------------------------------
# Resolve the configuration the recipe's own phase produces
# ---------------------------------------------------------------------------

let version = pinnedVersion()
let srcDir = kernelSourceDir(version)
let workDir = getTempDir() / "repro-kernel-config-gate-" & $getCurrentProcessId()
removeDir(workDir)
createDir(workDir)

let prefix = hostToolPrefix()

proc kbuild(target: string): tuple[output: string, code: int] =
  run(prefix & "make -C " & shellQuote(srcDir) & " O=" &
      shellQuote(workDir) & " ARCH=x86_64 " & target)

echo "[info] kernel source: ", srcDir
echo "[info] resolving configuration in: ", workDir

let defconfig = kbuild("defconfig")
doAssert defconfig.code == 0, "make defconfig failed:\n" & defconfig.output

# The SAME rendering the build runs, from the SAME constants.
let cfgCmd = kernelConfigCommand(srcDir / "scripts" / "config",
                                 workDir / ".config")
let applied = run(cfgCmd)
doAssert applied.code == 0, "scripts/config failed:\n" & applied.output

let requestedPath = workDir / ".config.requested"
copyFile(workDir / ".config", requestedPath)

let olddefconfig = kbuild("olddefconfig")
doAssert olddefconfig.code == 0,
  "make olddefconfig failed:\n" & olddefconfig.output

let requested = parseConfig(requestedPath)
let resolved = parseConfig(workDir / ".config")

suite "kernel configuration carries the attestation knobs":

  test "every required symbol is y in the RESOLVED configuration":
    var missing: seq[string]
    for symbol in KernelAttestationSymbols:
      if resolved.getOrDefault(symbol, "") != "y":
        missing.add(describe(resolved, symbol))
    if missing.len > 0:
      for m in missing:
        echo "[diag] not built in: ", m
    check missing.len == 0

  test "the verdict was taken from the resolved config, not the requested one":
    # ``TCG_TIS_CORE`` and ``DM_BUFIO`` are never asked for: Kconfig
    # ``select``s them while resolving ``TCG_TIS`` and ``DM_VERITY``.
    # They are absent from the requested file and present in the resolved
    # one, so this pair is a direct witness of WHICH file was read. If
    # somebody rewrites this gate to assert the enable list instead, this
    # check goes red.
    for selected in ["TCG_TIS_CORE", "DM_BUFIO"]:
      check selected notin KernelConfigEnabled
      check not requested.hasKey(selected)
      check resolved.getOrDefault(selected, "") == "y"

  test "olddefconfig would drop an unsatisfiable request, and does not here":
    # The failure mode this gate exists for, exercised rather than
    # described: strip the two pure ENABLER symbols from the request and
    # the confidential-compute drivers vanish from the resolved config
    # even though they were asked for by name.
    let probeDir = workDir & "-probe"
    removeDir(probeDir)
    createDir(probeDir)

    let probeDefconfig = run(prefix & "make -C " & shellQuote(srcDir) &
      " O=" & shellQuote(probeDir) & " ARCH=x86_64 defconfig")
    check probeDefconfig.code == 0

    var args = @[shellQuote(srcDir / "scripts" / "config"),
                 "--file", shellQuote(probeDir / ".config")]
    for symbol in KernelConfigDisabled:
      args.add("--disable")
      args.add(symbol)
    for symbol in KernelConfigEnabled:
      if symbol in ["VIRT_DRIVERS", "X86_X2APIC"]:
        continue
      args.add("--enable")
      args.add(symbol)
    let probeApplied = run(args.join(" "))
    check probeApplied.code == 0

    let probeRequested = parseConfig(probeDir / ".config")
    let probeOld = run(prefix & "make -C " & shellQuote(srcDir) & " O=" &
      shellQuote(probeDir) & " ARCH=x86_64 olddefconfig")
    check probeOld.code == 0
    let probeResolved = parseConfig(probeDir / ".config")

    for dropped in ["SEV_GUEST", "INTEL_TDX_GUEST", "TDX_GUEST_DRIVER"]:
      # Requested by name…
      check probeRequested.getOrDefault(dropped, "") == "y"
      # …and gone, without a word, once Kconfig resolved it.
      check not probeResolved.hasKey(dropped)
      # …while the real configuration keeps it.
      check resolved.getOrDefault(dropped, "") == "y"
    removeDir(probeDir)

  test "the parser reports a disabled symbol as disabled":
    # Falsifiability floor: if ``parseConfig`` reported everything as
    # enabled, the check above would pass against anything.
    for symbol in KernelConfigDisabled:
      check resolved.getOrDefault(symbol, "n") != "y"

  test "the disable and enable lists do not contradict each other":
    for symbol in KernelConfigEnabled:
      check symbol notin KernelConfigDisabled

  test "the rendered scripts/config argv covers the whole declared list":
    let rendered = kernelConfigCommand("./src/scripts/config",
                                       "./src/.config")
    for symbol in KernelConfigDisabled:
      check rendered.contains(" --disable " & symbol & " ") or
            rendered.endsWith(" --disable " & symbol)
    for symbol in KernelConfigEnabled:
      check rendered.contains(" --enable " & symbol & " ") or
            rendered.endsWith(" --enable " & symbol)

  test "TSM_REPORTS is handled honestly for the pinned kernel version":
    # ``TSM_REPORTS`` (the unified configfs attestation-report ABI) is a
    # 6.7 symbol. On 6.6 it does not exist, so listing it would write a
    # line ``olddefconfig`` deletes in silence — the exact anti-pattern
    # this gate is about. Assert the reason rather than the omission: on
    # < 6.7 the symbol must genuinely be unknown to the tree, and on
    # >= 6.7 it must be in the enable list.
    if versionAtLeast(version, 6, 7):
      check "TSM_REPORTS" in KernelConfigEnabled
      check resolved.getOrDefault("TSM_REPORTS", "") == "y"
    else:
      check "TSM_REPORTS" notin KernelConfigEnabled
      let pattern =
        "^[[:space:]]*(menu)?config[[:space:]]+TSM_REPORTS[[:space:]]*$"
      let grep = run("grep -rlE --include='Kconfig*' " &
        shellQuote(pattern) & " " & shellQuote(srcDir))
      check grep.code != 0
      check grep.output.strip().len == 0

  test "the built kernel's packaged config carries the same symbols":
    # Upgrades the claim from "the recipe resolves to this" to "the
    # artifact on disk is this" — but only when such an artifact exists.
    # Building it is a multi-hour job, so its absence is reported as a
    # skip naming the remedy and never as a pass.
    var builtConfig = getEnv(BuiltConfigEnv)
    if builtConfig.len == 0:
      let fromMirror = RecipeDir / BuiltConfigRelPath
      if fileExists(fromMirror):
        builtConfig = fromMirror
    if builtConfig.len == 0 or not fileExists(builtConfig):
      echo "[skip] no built kernel config present. Build one with " &
        "`repro build kernelSource` (multi-hour) or point " &
        BuiltConfigEnv & "=<path to usr/lib/reproos-kernel/config> at " &
        "an existing one. Expected in-tree at " &
        RecipeDir / BuiltConfigRelPath
      skip()
    else:
      echo "[info] built kernel config: ", builtConfig
      let built = parseConfig(builtConfig)
      var missing: seq[string]
      for symbol in KernelAttestationSymbols:
        if built.getOrDefault(symbol, "") != "y":
          missing.add(describe(built, symbol))
      if missing.len > 0:
        for m in missing:
          echo "[diag] not built in (packaged config): ", m
      check missing.len == 0

removeDir(workDir)

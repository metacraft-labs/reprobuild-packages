## ``nim-fork`` -- the Nim fork reprobuild is compiled with (metacraft-labs/nim,
## branch ``codetracer``, Nim 2.3.1), built for the platform being built FOR.
##
## Why it is here: an installed reprobuild compiles providers and profiles
## itself, with the compiler it was built by, so the prefix
## ``repro build --target=<triple> .#prefix`` assembles carries this fork
## under ``nim/`` (reprobuild-pm Distribution-And-Packaging.md §5.3,
## decision N, approved by Zahary Karadjov, 2026-11-03).
##
## What it builds, and what it does not: ``compiler/nim.nim``, compiled by
## the BUILD host's fork with the flags of reprobuild's own derivation
## (``nix/pkgs/by-name/re/reprobuild/nim-fork.nix``: ``-d:release
## -d:nimKochBootstrap --skipUserCfg --skipParentCfg --noNimblePath``), for
## the target when one is active. The installation tree -- ``lib/``,
## ``config/`` and the vendored ``dist/`` -- is target-neutral and is copied
## from the sources. No csources stage 0: the build host's fork already is a
## compiler of this revision. No ``nimpretty``: an appliance formats nothing.
##
## The sources are the revisions reprobuild's ``flake.lock`` pins
## (``nim-fork-src`` and the five ``dist/`` inputs), as GitHub archives
## hashed when this recipe was written (2026-11-03). The prefix that bundles
## this recipe's output refuses it when its recorded revision is not the one
## reprobuild's ``flake.lock`` pins for ``nim-fork-src``: the fork binary
## records no revision of its own, and that pin is the fork the dev shell
## compiles reprobuild with.
##
## The compiler links ``libzstd`` (the CodeTracer trace writer) and loads
## ``libpcre.so.1`` when it starts; under ``--target`` the zstd it links is
## the sibling ``zstd`` recipe built for the target, and both libraries reach
## the prefix's ``lib/`` through its runtime closure, not through this
## recipe.

import std/[os, sequtils, strutils]

import repro_project_dsl
import repro_dsl_stdlib/active_context
import repro_dsl_stdlib/adapters/cross_zig
import repro_dsl_stdlib/operations/pinned_fetch
import repro_dsl_stdlib/operations/zig_c
import repro_dsl_stdlib/types/package_result

import ../source_recipe_paths

const
  NimForkRevision* = "8384ff3fecfdbd8772d46c79054967769915d6fd"
    ## reprobuild `flake.lock`, input `nim-fork-src`.
  NimForkVersion* = "2.3.1"
  NimForkSource* = PinnedArchive(name: "nim",
    url: "https://github.com/metacraft-labs/nim/archive/" & NimForkRevision &
      ".tar.gz",
    sha256: "c42b59b3bff8dfa3c56218362360c0b48074dfc9cc669fb46b16e6ed0fc26dd8",
    kind: pakTarball, stripComponents: 1)
  NimForkDist* = [
    ## `(dist/<directory>, archive)`: the trees the fork compiler imports,
    ## where its `compiler/nim.cfg` expects them.
    ("codetracer-trace-format-nim", PinnedArchive(
      name: "codetracer-trace-format-nim",
      url: "https://github.com/metacraft-labs/codetracer-trace-format-nim/" &
        "archive/31be9a10007c007af429951616c13bc275587c76.tar.gz",
      sha256: "c24e190d914d633ac90b29f4a6b4c663419c85c0a5e396eb86d7e464598c08ac",
      kind: pakTarball, stripComponents: 1)),
    ("nim-stew", PinnedArchive(name: "nim-stew",
      url: "https://github.com/status-im/nim-stew/archive/" &
        "83eb1157963b7f49351dbdd858355fa990bbe23c.tar.gz",
      sha256: "bd4c60b25f7e99497a59e8f4bf14178229d3597002fee85a4e15336a063819bf",
      kind: pakTarball, stripComponents: 1)),
    ("nim-results", PinnedArchive(name: "nim-results",
      url: "https://github.com/metacraft-labs/nim-result/archive/" &
        "df8113dda4c2d74d460a8fa98252b0b771bf1f27.tar.gz",
      sha256: "1ab32c75a64ec6322306cf9288cadaa05c36a9819313ef132c032cad69d335ba",
      kind: pakTarball, stripComponents: 1)),
    ("checksums", PinnedArchive(name: "checksums",
      url: "https://github.com/nim-lang/checksums/archive/" &
        "0b8e46379c5bc1bf73d8b3011908389c60fb9b98.tar.gz",
      sha256: "d40e093bd5e3a10a2ea597f4a23f39cad4ce384f1098b8439b4fd4d5fce1e132",
      kind: pakTarball, stripComponents: 1)),
    ("nimony", PinnedArchive(name: "nimony",
      url: "https://github.com/nim-lang/nimony/archive/" &
        "bbfb21529845567c55b67d176354daef0e7d6c29.tar.gz",
      sha256: "300e6a5dc2c967016f0d6b8ea51e8010183226d4317f7e47b8b9f2eda08b5aba",
      kind: pakTarball, stripComponents: 1)),
  ]
  NimForkRevisionFile* = ".nim-fork-revision"
    ## Written into the installed tree (`nim/.nim-fork-revision`): the
    ## revision the prefix compares with reprobuild's pin.
  SourcesDir = ".repro/nim-fork-sources"
    ## Where the six archives are unpacked, one directory each.

proc nimForkBuildScript*(buildDir, sourcesDir, nimcache: string;
                         crossArgs: seq[string]; zstdPrefix: string): string =
  ## The build edge's program: assemble the source tree, compile the
  ## compiler, and stage the installation tree under
  ## `<buildDir>/destdir/usr/nim`. Exposed for the tests.
  proc q(value: string): string =
    "'" & value.replace("'", "'\\''") & "'"
  let tree = buildDir / "tree"
  let dest = buildDir / "destdir" / "usr" / "nim"
  result = "set -e; "
  result.add("rm -rf " & q(buildDir) & "; mkdir -p " & q(tree / "dist") & "; ")
  result.add("cp -a " & q(sourcesDir / NimForkSource.name) & "/. " & q(tree) &
    "/; ")
  for (dir, archive) in NimForkDist:
    result.add("cp -a " & q(sourcesDir / archive.name) & " " &
      q(tree / "dist" / dir) & "; ")
  var nimArgs = @["nim", "c", "-d:release", "-d:nimKochBootstrap",
    "--skipUserCfg", "--skipParentCfg", "--noNimblePath",
    "--warning:BareExcept:off", "--warning:UnusedImport:off",
    "--hints:off", "--nimcache:" & nimcache,
    # The fork hashes a type by the absolute path of its defining file
    # (metacraft-labs/nim 9a49ee3c): the build tree hashes as `/nim/`, so
    # the compiler is the same bytes from any checkout (measured different
    # from two paths, 2026-11-04).
    "--typeHashPathMap:" & tree & "/=/nim/"]
  nimArgs.add(crossArgs)
  if zstdPrefix.len > 0:
    nimArgs.add("--passC:-I" & zstdPrefix / "include")
    nimArgs.add("--passL:-L" & zstdPrefix / "lib")
  nimArgs.add(@["-o:bin/nim", "compiler/nim.nim"])
  var line = ""
  for arg in nimArgs:
    line.add(q(arg) & " ")
  result.add("(cd " & q(tree) & " && " & line & "); ")
  result.add("mkdir -p " & q(dest / "bin") & "; ")
  result.add("cp " & q(tree / "bin" / "nim") & " " & q(dest / "bin" / "nim") &
    "; ")
  result.add("cp -a " & q(tree / "lib") & " " & q(tree / "config") & " " &
    q(tree / "dist") & " " & q(dest) & "/; ")
  # The vendored trees carry dev-only symlinks that dangle outside their
  # repositories (nim-fork.nix prunes them the same way).
  result.add("find " & q(dest) & " -xtype l -delete; ")
  result.add("printf '%s\\n' " & q(NimForkRevision) & " > " &
    q(dest / NimForkRevisionFile))

package nimForkSource:
  versions:
    "2.3.1":
      sourceRevision = NimForkRevision
      sourceUrl = NimForkSource.url
      sourceRepository = "https://github.com/metacraft-labs/nim"

  nativeBuildDeps:
    ## The build host's fork compiles the compiler, natively or for a target.
    "nim >=2.3"
    "gcc >=11"
    ## zig is the C toolchain of a cross build (`cross_zig`).
    "zig >=0.13 <0.14"
    "cp"
    "find"
    "mkdir"
    "rm"
    ## What the six pinned fetches run (`operations/pinned_fetch`): a
    ## recipe's own `fetch:` block brings its fetch tools, a pinned fetch
    ## does not, and an undeclared tool is not on the edge's PATH.
    "curl"
    "sha256sum"
    "tar"
    "gzip"
    "mv"

  buildDeps:
    ## What the compiler links: the CodeTracer trace writer's zstd, built for
    ## the same target by the sibling recipe.
    "zstd"

  config:
    discard

  executable nim:
    discard

  build:
    setCurrentOwningPackageOverride("nimForkSource")
    try:
      let root = activeProviderProjectRoot()
      let sources = root / SourcesDir
      var fetches: seq[BuildActionDef]
      fetches.add(emitPinnedFetchAction(root, "nim-fork", NimForkSource,
        sources / NimForkSource.name))
      for (_, archive) in NimForkDist:
        fetches.add(emitPinnedFetchAction(root, "nim-fork", archive,
          sources / archive.name))
      let zigTarget = activeZigCrossTarget()
      var crossArgs: seq[string]
      var after = fetches
      var tools = @["sh", "nim", "cp", "find", "mkdir", "rm"]
      if zigTarget != nil:
        let cross = zigNimCross(zigTarget, "nim-fork")
        crossArgs = @["--cpu:" & cross.cpu, "--os:" & cross.os, "--cc:clang",
          "--clang.exe:" & cross.ccExe, "--clang.linkerexe:" & cross.ccExe,
          # No path of this build host in an image an installed prefix
          # ships (Distribution-And-Packaging §5.3, the builder-path gate).
          "--filenames:canonical", "--passL:-Wl,--strip-debug"]
        after.add(cross.wrappers)
        tools.add("zig")
      else:
        requireCrossTargetConsulted("nim-fork")
        tools.add("gcc")
      let buildDir = targetKeyedDir(".repro/build/nim-fork")
      let zstdPrefix = sourcePackageInstallPath("zstd", "usr")
      let compile = buildAction(
        id = "nim-fork.compile" &
          (if zigTarget != nil: "@" & zigTarget.triple else: ""),
        call = inlineExecCall(@["sh", "-c", nimForkBuildScript(
          root / buildDir, sources, root / buildDir / "nimcache", crossArgs,
          zstdPrefix)], root),
        inputs = fetches.mapIt(it.outputs[0]),
        outputs = @[root / buildDir / "destdir" / "usr" / "nim" / "bin" / "nim"],
        deps = after.mapIt(it.id),
        cacheable = true,
        dependencyPolicy = automaticMonitorPolicy(),
        commandStatsId = "nim-fork.compile",
        toolIdentityRefs = tools)
      emitInstallTreeMirror(compile, buildDir, "destdir", "nimForkSource",
        "custom")
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    discard

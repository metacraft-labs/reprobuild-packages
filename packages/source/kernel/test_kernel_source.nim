## Metadata regression checks for the source-built Linux kernel.
## Covers native build tools, the pinned upstream fetch, artifact kinds,
## and version metadata without compiling or booting the kernel.

import std/[sequtils, unittest]

import repro_project_dsl

# Side-effect import: triggers the package macro which registers
# fetch spec + make flags + executable + files artifacts under
# ``kernelSource`` at module init time.
import ./repro

const ExpectedUrl =
  "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.142.tar.xz"

const ExpectedHash =
  "b2f6607a75cd27b2e368cf2d25e1637e1e0da9dfed4cda536658879eee6f2b70"

suite "kernelSource — from-source recipe smoke test":

  test "kbuild tools are explicit build-platform requirements":
    let packages = registeredPackages().filterIt(it.packageName == "kernelSource")
    check packages.len == 1
    if packages.len == 1:
      let pkg = packages[0]
      for name in ["binutils", "sed", "awk", "grep", "find", "bc", "cmp", "gzip"]:
        let uses = pkg.nativeBuildDeps.filterIt(it.packageSelector == name)
        check uses.len == 1
        if uses.len == 1:
          check uses[0].depKind == DepKindNative
      check pkg.toolUses.filterIt(it.packageSelector == "bc").len == 0

  test "fetch spec carries the upstream URL verbatim":
    # M9.H registry round-trip — URL is recorded exactly as declared.
    let spec = registeredFetchSpec("kernelSource")
    check spec.packageName == "kernelSource"
    check spec.url == ExpectedUrl

  test "fetch spec hash is a 64-char sha256 hex string":
    # sha256 over the vendored 140,641,384-byte tarball; length check
    # guards against a future bump that forgets to widen the hash
    # alongside the URL.
    let spec = registeredFetchSpec("kernelSource")
    check spec.hashHex.len == 64
    check spec.hashHex == ExpectedHash
    check spec.hashAlg == dshaSha256

  test "fetch spec is the tarball variant with extractStrip = 1":
    # Tarball vs git-archive discriminant + the canonical
    # ``--strip-components=1`` convention upstream uses for
    # cdn.kernel.org tarballs (the top-level dir inside is
    # ``linux-<version>/`` which we strip).
    let spec = registeredFetchSpec("kernelSource")
    check spec.kind == dfkTarball
    check spec.extractStrip == 1

  test "artifacts register the bzImage as dakExecutable":
    # M3 artifact registry: bzImage must be tagged
    # ``dakExecutable`` because it is the BOOTABLE kernel image.
    # A regression that mis-tagged it as ``dakFiles`` would route
    # the binary under ``share/`` instead of ``bin/`` / ``boot/``,
    # breaking the activation layer's bootloader-menu generator.
    let arts = registeredArtifacts("kernelSource")
    check arts.len == 4
    var seenBzImage = false
    for art in arts:
      check art.packageName == "kernelSource"
      if art.artifactName == "bzImage":
        check art.kind == dakExecutable
        seenBzImage = true
    check seenBzImage

  test "artifacts register vmlinux / systemMap / kernelRelease as dakFiles":
    # M3 artifact registry: the three non-bootable outputs must all
    # be tagged ``dakFiles``. A regression that flattened the
    # discriminator (e.g. labelling them all as executable) would
    # mis-route them on install.
    let arts = registeredArtifacts("kernelSource")
    var seenVmlinux = false
    var seenSystemMap = false
    var seenKernelRelease = false
    for art in arts:
      case art.artifactName
      of "vmlinux":
        check art.kind == dakFiles
        seenVmlinux = true
      of "systemMap":
        check art.kind == dakFiles
        seenSystemMap = true
      of "kernelRelease":
        check art.kind == dakFiles
        seenKernelRelease = true
      else: discard
    check seenVmlinux
    check seenSystemMap
    check seenKernelRelease

  test "versions block records the upstream tag + URL + repository":
    # M2 versions registry: the upstream cdn.kernel.org tag is
    # recorded for ``repro update-source`` even though the live
    # fetch points at the vendored copy. The repository points at
    # the canonical Linus tree on git.kernel.org.
    let vs = registeredVersions("kernelSource")
    check vs.len == 1
    check vs[0].version == "6.6.142"
    check vs[0].sourceRevision == "v6.6.142"
    check vs[0].sourceUrl ==
      "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.142.tar.xz"
    check vs[0].sourceRepository ==
      "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"

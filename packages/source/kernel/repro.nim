## From-source Linux kernel recipe — the SIXTH real from-source
## production recipe and the FIRST consumer of the M9.I
## ``makeFlags:`` channel.
##
## Follows the dbus-broker / libdrm / Wayland / wlroots / Sway
## precedents (all meson/ninja), but the Linux kernel uses
## ``make``/kbuild as its build system, so this recipe is the FIRST
## in the from-source cohort to exercise the ``c_cpp_make`` Tier-2b
## convention (M9.K's sibling of ``c_cpp_meson``) and the M9.I
## ``makeFlags:`` block that feeds variables / job-count flags to
## ``make``. The fetch path stays identical to the meson siblings —
## a vendored upstream tarball whose sha256 is pinned here for
## deterministic offline test reproduction.
##
## ## Why this recipe is the c_cpp_make consumer
##
## The five prior from-source recipes all build under ``meson setup``
## + ``ninja``; the M9.K convention layer's ``c_cpp_meson`` lowering
## consumes the M9.I ``mesonOptions:`` channel. The kernel by contrast
## drives ``make`` against the kbuild Makefile graph at the top of the
## extracted source tree (``arch/$(SRCARCH)/Makefile`` +
## ``scripts/Makefile.build``), and the canonical flag-injection
## point is ``make ARCH=x86_64 LOCALVERSION= KBUILD_BUILD_USER=... -j1``
## — i.e. variable overrides + ``-jN`` go on the ``make`` argv. The
## ``c_cpp_make`` convention's configure-action lowering will read the
## M9.I ``makeFlags:`` channel (via ``registeredBuildFlags(pkg, "",
## "make")``) and pass every entry through to ``make`` in declared
## order; M9.L closes the spawn + install glue. This recipe declares
## the surface so the convention layer's M9.K bridge can lower it.
##
## ## Why this recipe COMPLEMENTS the existing NDE-E reproosKernel
##
## ``recipes/packages/de-foundation/kernel/repro.nim`` (the NDE-E
## ``reproosKernel`` package) owns the kernel-related ``fs.*`` outputs
## that the activation layer reads — ``/build/config-used`` (the
## .config snapshot of the 6 spec'd CONFIG_X knobs),
## ``/build/bzImage`` (a v1 STUB text marker the bootloader-menu
## generator references), ``/build/System.map``, and
## ``/build/KERNELRELEASE``. That recipe declares the DECLARATIVE
## front end with M9.F cross-artifact wiring; the real kernel
## compilation back end is deferred there (see honest-deferrals
## comment block).
##
## This recipe (``kernelSource``) is the COMPLEMENT — it provides the
## upstream-source side: a separate package that fetches the kernel
## tarball, exposes its build via ``c_cpp_make`` + ``makeFlags:``,
## and records the artifacts the kernel build emits. The two recipes
## live at different paths so the NDE-E config-emission cache key is
## isolated from the upstream tarball sha256 (a 6.6.142 → 6.6.143
## bump invalidates only ``kernelSource``, not the unit-file
## emissions; flipping ``reproosKernel.enableHypervDrm`` invalidates
## the NDE-E artifacts, not the upstream tarball cache).
##
## A future milestone will wire the two together: the NDE-E
## ``bzImage`` artifact's ``toolBuild("kernelCompile", ...)`` call
## becomes a real build-action edge into ``kernelSource``'s
## ``bzImage`` executable, replacing the v1 text stub with the actual
## kernel image bytes. The DECLARATIVE shape on both sides is what
## makes that swap a one-line change at the consumer site.
##
## ## sha256 strategy
##
## We vendor the upstream stable-line tarball at
## ``recipes/packages/source/kernel/vendor/linux-6.6.142.tar.xz`` and
## reference it via a ``file://`` URL. The upstream cdn.kernel.org
## URL is recorded as ``sourceUrl`` in the ``versions:`` block for
## documentation and future-bump purposes, but the live ``fetch:``
## block points at the vendored copy so the convention layer's
## emitted fetch action is offline-reproducible.
##
## ## Version choice — 6.6.142 (LTS line, matches reproosKernel)
##
## The 6.6.x line is the current Linux LTS series; 6.6.142 is the
## latest stable point release as of the recipe landing. The version
## ALSO matches the NDE-E ``reproosKernel.kernelVersion`` default
## ("6.6.142") — that alignment is intentional so a future swap of
## the NDE-E bzImage stub for a real ``toolBuild`` edge into this
## recipe consumes the same kernel-source pin without a version
## reconciliation step.
##
## The published sha256 is
## ``b2f6607a75cd27b2e368cf2d25e1637e1e0da9dfed4cda536658879eee6f2b70``
## (from cdn.kernel.org's ``sha256sums.asc`` for
## ``linux-6.6.142.tar.xz``); we re-computed it locally over the
## vendored 140,641,384-byte tarball as a defence against vendor
## tampering and a future-maintainer's accidental re-download from a
## mirror with a different artifact. Both values match.
##
## ## sha256 cross-check vs nixpkgs
##
## nixpkgs's ``pkgs/os-specific/linux/kernel/linux-6.6.nix`` consumes
## the same ``cdn.kernel.org`` tarball via ``fetchurl``, so the version
## cross-check holds when nixpkgs's pin matches ours; cross-checking
## sha256 against nixpkgs's at-the-same-version pin is a useful
## sanity check (their fetcher records the upstream hash verbatim).
##
## ## Build shape
##
## The build action fetches the pinned kernel source, creates an x86-64
## defconfig, applies the boot-critical ReproOS configuration, and runs
## kbuild through the standard package constructor. A dedicated install
## target mirrors the kernel image, configuration, symbol map, release,
## and module tree under ``usr/lib``. ReproOS stages that install mirror
## directly and copies the same vmlinuz into ``/boot``.
##
## ## Artifacts
##
## The kernel build produces four load-bearing outputs at the
## standard kbuild paths:
##
##   * ``bzImage`` — the bootable kernel image; the activation
##     layer's bootloader-menu generator points GRUB / systemd-boot
##     at this file. Path: ``arch/x86/boot/bzImage`` inside the
##     build tree.
##   * ``vmlinux`` — the unstripped ELF kernel with debug symbols;
##     consumed by perf / crash / live-kernel-debug tooling. Path:
##     ``vmlinux`` at the build-tree root.
##   * ``systemMap`` — the kernel symbol table (``System.map``)
##     paired with the bzImage at the same release. Used by
##     ``perf`` / ``kgdb`` / ``kallsyms`` for symbol resolution
##     when the kernel hasn't loaded its own kallsyms table yet.
##     Path: ``System.map`` at the build-tree root.
##   * ``kernelRelease`` — the KERNELRELEASE text file kbuild
##     emits at ``include/config/kernel.release``. The activation
##     layer reads this to discover the kernel release string
##     without re-parsing bzImage. Single-line content like
##     ``6.6.142`` (no LOCALVERSION suffix because the
##     ``makeFlags:`` block pins ``LOCALVERSION=``).
##
## The bzImage is the M3 ``dakExecutable`` artifact (it is
## bootable / loadable); the other three are M3 ``dakFiles``
## artifacts (data files consumed by downstream actions).

import std/strutils

import repro_project_dsl
import repro_dsl_stdlib/constructors
import repro_dsl_stdlib/types/package_result

# ---------------------------------------------------------------------------
# Kernel configuration — the single source of truth
# ---------------------------------------------------------------------------
#
# The three sequences below are the ONLY place the image kernel's
# configuration is written down. ``kernelConfigCommand`` renders them into
# the ``scripts/config`` invocation the ``build:`` block runs between
# ``defconfig`` and ``olddefconfig``, and the recipe's tests read the same
# constants, so a symbol cannot be gated in one place and configured in
# another. There is no second kernel recipe in this repository to drift
# against: ``packages/source/kernel`` is the only one, and the Hyper-V
# bootstrap kernel fragments that used to sit beside it live in the legacy
# pre-extraction tree, which this repository supersedes.

const KernelConfigDisabled*: seq[string] = @[
  # Symbols forced off. Debug info and BTF are dropped because they
  # dominate build time and image size for a boot kernel; module signing
  # and the trusted/revocation keyrings are dropped because the recipe
  # has no signing key; ORC unwinding is traded for frame pointers so the
  # build does not need objtool's stack validation.
  "DEBUG_INFO",
  "DEBUG_INFO_BTF",
  "DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT",
  "MODULE_SIG",
  "SYSTEM_TRUSTED_KEYS",
  "SYSTEM_REVOCATION_KEYS",
  "STACK_VALIDATION",
  "UNWINDER_ORC",
]

const KernelConfigEnabled*: seq[string] = @[
  # Symbols forced on, on top of ``x86_64 defconfig``.
  #
  # Boot and console.
  "UNWINDER_FRAME_POINTER",
  "BLK_DEV_INITRD",
  "DEVTMPFS",
  "DEVTMPFS_MOUNT",
  # virtio transports and devices (QEMU/KVM).
  "VIRTIO",
  "VIRTIO_PCI",
  "VIRTIO_BLK",
  "VIRTIO_NET",
  "VIRTIO_CONSOLE",
  # Hyper-V enlightenments (Windows hosts).
  "HYPERV",
  "HYPERV_STORAGE",
  "HYPERV_NET",
  "HYPERV_KEYBOARD",
  "HID_HYPERV_MOUSE",
  "HYPERV_BALLOON",
  # Display.
  "DRM",
  "DRM_VIRTIO_GPU",
  "DRM_HYPERV",
  "DRM_SIMPLEDRM",
  # Filesystems and block.
  "EXT4_FS",
  "VFAT_FS",
  "TMPFS",
  "OVERLAY_FS",
  "SQUASHFS",
  "SQUASHFS_XZ",
  "BLK_DEV_LOOP",
  # Firmware.
  "EFI",
  "EFI_STUB",
  #
  # --- Attestation substrate -------------------------------------------
  #
  # Device mapper. ``BLK_DEV_DM`` is already ``y`` in x86_64 defconfig,
  # but it is named here so the two targets below cannot silently become
  # modules if a future defconfig demotes it: ``scripts/config --enable``
  # writes ``=y``, and ``olddefconfig`` rewrites a ``=y`` tristate back
  # down to ``=m`` when its dependency is modular.
  "BLK_DEV_DM",
  # Read-only integrity-checked root. The dm-verity target is what the
  # attested image's root filesystem is activated through, and it must be
  # available before any root filesystem is mounted, hence built-in.
  "DM_VERITY",
  # Encrypted volumes (LUKS state partitions).
  "DM_CRYPT",
  # TPM. ``TCG_TPM`` is the core chip driver; ``TCG_TIS`` the
  # memory-mapped TIS/PTP-FIFO interface every x86 vTPM (QEMU's
  # ``tpm-tis``, Hyper-V's vTPM) presents; ``TCG_CRB`` the ACPI
  # command-response-buffer interface that AMD fTPMs and several
  # cloud vTPMs present INSTEAD of TIS, so that one kernel really
  # does serve every host rather than only the ones this repository
  # happens to test on; and ``HW_RANDOM_TPM`` feeds the TPM's RNG
  # into ``/dev/hwrng``. ``TCG_TIS_CORE`` and ``CRYPTO_HASH_INFO``
  # come along as Kconfig ``select``s.
  "TCG_TPM",
  "TCG_TIS",
  "TCG_CRB",
  "HW_RANDOM_TPM",
  # Pseudo-filesystems the attestation plane reads and writes:
  # ``configfs`` is where the TSM report interface is driven from on
  # kernels that carry it, ``securityfs`` is where the TPM's binary
  # measurement log (``/sys/kernel/security/tpm0/binary_bios_measurements``)
  # appears.
  "CONFIGFS_FS",
  "SECURITYFS",
  # Guest-side confidential compute, so ONE kernel serves all tiers.
  #
  # ``AMD_MEM_ENCRYPT`` brings up SME/SEV/SEV-ES/SEV-SNP guest support;
  # ``SEV_GUEST`` is the driver that talks to the PSP for an SNP
  # attestation report. ``INTEL_TDX_GUEST`` brings up TDX guest support
  # and ``TDX_GUEST_DRIVER`` exposes the TDX report ioctl.
  #
  # Two entries here are pure ENABLERS and exist because
  # ``olddefconfig`` silently drops a requested symbol whose dependency
  # is unmet, rather than failing:
  #
  #   * ``VIRT_DRIVERS`` is the ``menuconfig`` bool that guards the whole
  #     of ``drivers/virt``. It is OFF in x86_64 defconfig, and without
  #     it both ``SEV_GUEST`` and ``TDX_GUEST_DRIVER`` vanish from the
  #     resolved config even though they were requested.
  #   * ``X86_X2APIC`` is a hard dependency of ``INTEL_TDX_GUEST`` and is
  #     likewise off in defconfig; without it ``INTEL_TDX_GUEST`` and,
  #     transitively, ``TDX_GUEST_DRIVER`` vanish too.
  #
  # ``TSM_REPORTS`` — the unified ``configfs`` attestation-report ABI —
  # is deliberately NOT listed: it does not exist in Linux 6.6, having
  # been introduced in 6.7. Requesting it here would write a line
  # ``olddefconfig`` deletes without a word. On 6.6 the per-tier drivers
  # above carry their own report ioctls, which is what the attestation
  # agent uses. A version bump to >= 6.7 must add it.
  "AMD_MEM_ENCRYPT",
  "VIRT_DRIVERS",
  "SEV_GUEST",
  "X86_X2APIC",
  "INTEL_TDX_GUEST",
  "TDX_GUEST_DRIVER",
]

const KernelAttestationSymbols*: seq[string] = @[
  # The subset of the resolved configuration the attestation campaign
  # depends on, as it must appear in the BUILT kernel's ``.config``
  # after ``olddefconfig`` — not as requested.
  #
  # ``TCG_TIS_CORE`` and ``DM_BUFIO`` are not in ``KernelConfigEnabled``:
  # Kconfig ``select``s them. They are listed because they are what
  # actually carries the TIS transport and dm-verity's block cache, and
  # because a check that finds them can only have read a config that was
  # resolved rather than one that was requested.
  "BLK_DEV_DM",
  "DM_BUFIO",
  "DM_VERITY",
  "DM_CRYPT",
  "TCG_TPM",
  "TCG_TIS",
  "TCG_TIS_CORE",
  "TCG_CRB",
  "HW_RANDOM_TPM",
  "CONFIGFS_FS",
  "SECURITYFS",
  "AMD_MEM_ENCRYPT",
  "SEV_GUEST",
  "INTEL_TDX_GUEST",
  "TDX_GUEST_DRIVER",
]

func kernelConfigCommand*(configScript, configFile: string): string =
  ## Render the ``scripts/config`` invocation that turns a fresh
  ## ``defconfig`` into the ReproOS kernel configuration. Rendered rather
  ## than written out so the build and the tests cannot disagree.
  var parts = @[configScript, "--file", configFile]
  for symbol in KernelConfigDisabled:
    parts.add("--disable")
    parts.add(symbol)
  for symbol in KernelConfigEnabled:
    parts.add("--enable")
    parts.add(symbol)
  parts.join(" ")

# ---------------------------------------------------------------------------
# Package declaration
# ---------------------------------------------------------------------------

package kernelSource:
  ## From-source Linux kernel — SIXTH M9.H/I/K production recipe and
  ## FIRST consumer of the M9.I ``makeFlags:`` channel.
  ##
  ## Tier-2b c_cpp_make convention consumer: the convention layer
  ## reads the ``fetch:`` block (registered via ``registeredFetchSpec``)
  ## and the ``makeFlags:`` block (registered via
  ## ``registeredBuildFlags`` on the ``"make"`` channel) and lowers
  ## them into fetch + make BuildActions wired with the right URL +
  ## hash + flags. Complements the NDE-E ``reproosKernel`` package
  ## (config-emitting front end) with the upstream-source back end.

  versions:
    ## Pinned upstream stable-line release. ``sourceUrl`` records the
    ## canonical cdn.kernel.org URL so a future maintainer running
    ## ``repro update-source`` can re-fetch from upstream; the live
    ## ``fetch:`` block below points at the vendored copy for
    ## deterministic offline test reproduction.
    ##
    ## ``sourceRepository`` points at the canonical Linus tree on
    ## git.kernel.org — the from-source authority for the Linux
    ## kernel.
    "6.6.142":
      sourceRevision = "v6.6.142"
      sourceUrl = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.142.tar.xz"
      sourceRepository = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"

  fetch:
    ## Upstream cdn.kernel.org URL — out-of-band fetch on first
    ## build, then cached by the M9.K fetch action keyed on
    ## (url, sha256, extractStrip). Matches the R4-R9 bootstrap
    ## chain pattern of NOT vendoring large kernel tarballs into
    ## the git repo (the 140-MB linux-6.6.142.tar.xz exceeds
    ## GitHub's 100-MB single-file ceiling).
    ##
    ## sha256 was computed over the 140,641,384-byte tarball
    ## downloaded once from this URL. The published value on
    ## cdn.kernel.org's ``sha256sums.asc`` matches; we
    ## re-computed locally as a defence against mirror-fetched
    ## artifacts diverging.
    url: "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.142.tar.xz"
    sha256: "b2f6607a75cd27b2e368cf2d25e1637e1e0da9dfed4cda536658879eee6f2b70"
    extractStrip: 1

  nativeBuildDeps:
    ## gcc is the host C toolchain — kbuild assumes a C11-capable gcc
    ## for kernel 6.x. R8 Tier-2 reference uses jammy gcc 11.4.
    ##
    "gcc >=12"
    ## Kbuild invokes these directly; a compiler driver's own dependencies
    ## are not a declaration of the kernel's assembler/linker requirements.
    "binutils >=2.39"
    ## scripts/config, compiler probes, and generated-header/install rules.
    "sed"
    "awk"
    "grep"
    "find"
    "bc"
    "cmp"
    ## The x86 defconfig compresses the boot image with CONFIG_KERNEL_GZIP.
    "gzip"
    ## make is the kbuild driver — the c_cpp_make convention's
    ## compile action invokes ``make`` against the extracted source
    ## tree. ``make >=4.3`` is needed for kbuild's grouped-targets
    ## feature.
    "make >=4.3"
    ## bison is the parser generator kbuild's ``scripts/dtc`` uses to
    ## compile devicetree-source files when CONFIG_OF=y.
    "bison >=3.6"
    ## flex is the lexer generator paired with bison in
    ## ``scripts/dtc``.
    "flex >=2.6"
    ## perl is invoked by ``scripts/checkpatch.pl`` (build-time
    ## lint, optional) and a handful of code-generation scripts in
    ## ``scripts/`` that emit C source files consumed by the build.
    "perl >=5.32"

  buildDeps:
    ## libelf is consumed by kbuild's ``objtool`` (in tools/objtool);
    ## kbuild's own configure probe wants it present even though the
    ## ``build:`` block disables ``STACK_VALIDATION``.
    "libelf >=0.187"
    ## The host-side extract-cert helper is compiled even when module signing
    ## and trusted key embedding are disabled.
    "openssl >=3.0"
    ## libelf's shared library uses these codecs internally. They must be
    ## present while kbuild links the host-side objtool executable.
    "zlib >=1.2"
    "zstd >=1.5"
    "xz >=5.4"
    "bzip2 >=1.0"
    ##
    ## Deliberately NOT declared, because the ``build:`` block's
    ## configuration never reaches the code paths that would need them:
    ##
    ##   * ``kmod`` — the ``repro_install`` target passes ``DEPMOD=true``,
    ##     so ``modules_install`` never shells out to ``depmod``.
    ##   * ``rsync`` — ``make headers_install`` is not part of the
    ##     install target.

  config:
    ## No prefix lifted from `makeFlags:`; flags inlined in the `build:` block.
    discard
  executable bzImage:
    ## ``arch/x86/boot/bzImage`` — the bootable kernel image; the
    ## activation layer's bootloader-menu generator (NDEM1) points
    ## GRUB / systemd-boot at this file. The ``executable`` artifact
    ## kind (``dakExecutable``) routes the harvested binary under
    ## ``bin/`` / ``boot/`` in the package's output tree (M9.L
    ## install policy decides which); ``files`` would route under
    ## ``share/`` which is wrong for the kernel image.
    ## v1 records the artifact only; the per-artifact build body
    ## lands in M9.L when the convention's make-spawn + install
    ## glue closes (and the ``.config`` pre-build hook is wired —
    ## see honest-deferrals).
    discard

  files vmlinux:
    ## The unstripped ELF kernel with debug symbols. Consumed by
    ## perf / crash / live-kernel-debug tooling; emitted at the
    ## build-tree root (path ``vmlinux``). The ``files`` artifact
    ## kind (``dakFiles``) routes it under ``share/`` / ``lib/`` —
    ## it's not a directly-bootable file, just data that downstream
    ## actions consume.
    discard

  files systemMap:
    ## ``System.map`` — the kernel symbol table paired with the
    ## bzImage at the same release. Used by ``perf`` / ``kgdb`` /
    ## ``kallsyms`` for symbol resolution when the kernel hasn't
    ## loaded its own kallsyms table yet. Emitted at the build-tree
    ## root.
    discard

  files kernelRelease:
    ## ``include/config/kernel.release`` — the KERNELRELEASE text
    ## file kbuild emits during compile. Single-line content like
    ## ``6.6.142`` (no LOCALVERSION suffix because the
    ## ``makeFlags:`` block pins ``LOCALVERSION=``). The activation
    ## layer reads this to discover the kernel release string
    ## without re-parsing bzImage; the NDE-E ``reproosKernel``
    ## ``kernelRelease`` artifact uses the same path semantics so
    ## a future ``toolBuild`` edge can swap one for the other.
    discard

  build:
    setCurrentOwningPackageOverride("kernelSource")
    try:
      let opts = @[
        "ARCH=x86_64",
        "LOCALVERSION=",
        "KBUILD_BUILD_USER=reprobuild",
        "KBUILD_BUILD_HOST=reprobuild",
        "KBUILD_BUILD_TIMESTAMP=@1577836800",
      ]
      let patches = @[
        ## BTF is disabled for the boot image, but Kconfig still asks the
        ## helper for a version. Return a stable zero without launching pahole.
        "printf '#!/bin/sh\\necho 0\\n' > ./src/scripts/pahole-version.sh",
        "make -C ./src ARCH=x86_64 defconfig",
        kernelConfigCommand("./src/scripts/config", "./src/.config"),
        "make -C ./src ARCH=x86_64 olddefconfig",
        "printf '\\n.PHONY: repro_install\\nrepro_install:\\n\t$(MAKE) ARCH=x86_64 INSTALL_MOD_PATH=$(DESTDIR) DEPMOD=true modules_install\\n\tmkdir -p $(DESTDIR)/usr/lib/reproos-kernel\\n\tcp arch/x86/boot/bzImage $(DESTDIR)/usr/lib/reproos-kernel/vmlinuz\\n\tcp System.map $(DESTDIR)/usr/lib/reproos-kernel/System.map\\n\tcp .config $(DESTDIR)/usr/lib/reproos-kernel/config\\n\t$(MAKE) -s ARCH=x86_64 kernelrelease > $(DESTDIR)/usr/lib/reproos-kernel/kernel.release\\n' >> ./src/Makefile",
      ]
      let pkg = autotools_package(
        srcDir = "./src",
        configureOptions = opts,
        skipConfigure = true,
        installTarget = "repro_install",
        srcPatches = patches,
      )
      pkg.installTreeMirror()
    finally:
      clearCurrentOwningPackageOverride()

  runtimeDeps:
    ## TODO(M9.R.5b): derive runtime closure from pkg-config /
    ## DT_NEEDED inspection of the linked artifacts. Empty until
    ## the M9.R.5b per-recipe pass populates per-output ELF
    ## interrogation.
    discard

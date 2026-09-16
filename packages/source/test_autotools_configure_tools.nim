import std/unittest
import repro_project_dsl
import ./libxau/repro
import ./libxdmcp/repro
import ./libxcb/repro
import ./libx11/repro
import ./libxext/repro
import ./libxfixes/repro
import ./libxfont2/repro
import ./libxkbfile/repro
import ./libxrandr/repro
import ./libxrender/repro
import ./libxshmfence/repro
import ./libfontenc/repro
import "./xcb-proto/repro"
import ./xtrans/repro
import "./xcb-util/repro"
import "./xcb-util-image/repro"
import "./xcb-util-renderutil/repro"
import "./xcb-util-cursor/repro"
import "./xcb-util-keysyms/repro"
import "./xcb-util-wm/repro"
import ./xkbcomp/repro
import "./util-linux/repro"
import ./kmod/repro
import ./sudo/repro
import ./e2fsprogs/repro
import ./dosfstools/repro
import "./btrfs-progs/repro"
import "./shadow-utils/repro"
import ./parted/repro
import ./lvm2/repro
import ./popt/repro
import "./libgpg-error/repro"
import ./libgcrypt/repro
import ./less/repro
import ./strace/repro
import ./nano/repro
import ./kbd/repro
import "./libcap-ng/repro"
import ./openssh/repro
import ./fontconfig/repro
import ./gmp/repro
import ./lzo/repro
import ./libmd/repro
import ./mpc/repro
import ./mpfr/repro
import ./ncurses/repro
import ./nettle/repro
import ./pam/repro
import ./pcre2/repro
import ./libpng/repro
import ./readline/repro
import ./sqlite/repro
import ./mtdev/repro
import ./libbsd/repro
import ./bash/repro
import ./gawk/repro
import ./grep/repro
import ./python3/repro
import ./grub/repro
import ./libxcrypt/repro
import "./util-macros/repro"
import "./font-util/repro"
import ./cryptsetup/repro
import ./procps/repro
import ./audit/repro
import ./freetype/repro
import ./icu/repro

when defined(reproProviderMode):
  import std/[os, sets]
  import repro_core

  proc emittedActions(name, selector: string,
                      body: proc() {.closure.}): seq[BuildActionDef] =
    let projectRoot = currentSourcePath.parentDir / selector
    let package = PackageDef(
      packageName: name, sourceFile: projectRoot / "repro.nim",
      hasDevEnv: false, devEnvBodyHash: "", toolUses: @[])
    let request = ProviderGraphRequest(
      kind: prkGraphInvocation, providerArtifactId: "test-provider",
      entryPointId: name & ".root", entryPointBodyHash: "test-body",
      reason: girExplicitUserRequest, arguments: projectRoot,
      namespace: "project")
    let fragment = buildPackageFragment(package, request, body,
      includeDefault = false)
    for node in fragment.nodes:
      if node.kind == gnkAction:
        result.add(decodeBuildActionPayload(toBytes(node.payload)))

template checkRecipe(selector, name: string, emit: untyped,
                     requiredTools: untyped = ["awk", "cmp", "diff"],
                     buildDirs: untyped = ["build"]) =
  suite selector & " configure tools":
    test "configuration utilities are build-machine dependencies only":
      for tool in requiredTools:
        check tool in registeredAuthoredNativeBuildDeps(name)
        check tool notin registeredBuildDeps(name)
        check tool notin registeredRuntimeDeps(name)

    when defined(reproProviderMode):
      test "configure make and install carry native utility identities":
        var expectedMakeActions = initHashSet[string]()
        for dir in buildDirs:
          expectedMakeActions.incl("autotools-make-build-" & name & "-" & dir)
          expectedMakeActions.incl("autotools-make-install-" & name & "-" & dir)
        var configureCount = 0
        for action in emittedActions(name, selector, proc() = emit):
          if action.commandStatsId == "autotools_package.configure" or
              action.id in expectedMakeActions:
            require action.toolIdentityRefKinds.len == action.toolIdentityRefs.len
            for tool in requiredTools:
              let index = action.toolIdentityRefs.find(tool)
              require index >= 0
              check action.toolIdentityRefKinds[index] == tirkNative
            if action.commandStatsId == "autotools_package.configure":
              inc configureCount
            else:
              expectedMakeActions.excl(action.id)
        check configureCount == buildDirs.len
        check expectedMakeActions.len == 0

checkRecipe("libxau", "libxauSource", buildLibxauSourcePackage())
checkRecipe("libxdmcp", "libxdmcpSource", buildLibxdmcpSourcePackage())
checkRecipe("libxcb", "libxcbSource", buildLibxcbSourcePackage())
checkRecipe("libx11", "libx11Source", buildLibx11SourcePackage())
checkRecipe("libxext", "libxextSource", buildLibxextSourcePackage())
checkRecipe("libxfixes", "libxfixesSource", buildLibxfixesSourcePackage())
checkRecipe("libxfont2", "libxfont2Source", buildLibxfont2SourcePackage())
checkRecipe("libxkbfile", "libxkbfileSource", buildLibxkbfileSourcePackage())
checkRecipe("libxrandr", "libxrandrSource", buildLibxrandrSourcePackage())
checkRecipe("libxrender", "libxrenderSource", buildLibxrenderSourcePackage())
checkRecipe("libxshmfence", "libxshmfenceSource", buildLibxshmfenceSourcePackage())
checkRecipe("libfontenc", "libfontencSource", buildLibfontencSourcePackage())
checkRecipe("xcb-proto", "xcbProtoSource", buildXcbProtoSourcePackage(), ["awk"])
checkRecipe("xtrans", "xtransSource", buildXtransSourcePackage(), ["awk", "diff"])
checkRecipe("xcb-util", "xcbUtilSource", buildXcbUtilSourcePackage())
checkRecipe("xcb-util-image", "xcbUtilImageSource", buildXcbUtilImageSourcePackage())
checkRecipe("xcb-util-renderutil", "xcbUtilRenderutilSource", buildXcbUtilRenderutilSourcePackage())
checkRecipe("xcb-util-cursor", "xcbUtilCursorSource", buildXcbUtilCursorSourcePackage())
checkRecipe("xcb-util-keysyms", "xcbUtilKeysymsSource", buildXcbUtilKeysymsSourcePackage())
checkRecipe("xcb-util-wm", "xcbUtilWmSource", buildXcbUtilWmSourcePackage())
checkRecipe("xkbcomp", "xkbcompSource", buildXkbcompSourcePackage(), ["awk", "diff"])

# Utilities used by the checksum-pinned release configure/config.status scripts.
checkRecipe("util-linux", "utilLinuxSource", buildUtilLinuxSourcePackage())
checkRecipe("kmod", "kmodSource", buildKmodSourcePackage())
checkRecipe("sudo", "sudoSource", buildSudoSourcePackage())
checkRecipe("e2fsprogs", "e2fsprogsSource", buildE2fsprogsSourcePackage(), ["awk", "diff"])
checkRecipe("dosfstools", "dosfstoolsSource", buildDosfstoolsSourcePackage(), ["awk", "diff"])
checkRecipe("btrfs-progs", "btrfsProgsSource", buildBtrfsProgsSourcePackage(),
  ["awk", "diff"], ["src"])
checkRecipe("shadow-utils", "shadowUtilsSource", buildShadowUtilsSourcePackage())
checkRecipe("parted", "partedSource", buildPartedSourcePackage())
checkRecipe("lvm2", "lvm2Source", buildLvm2SourcePackage(), ["awk", "diff"])
checkRecipe("popt", "poptSource", buildPoptSourcePackage())
checkRecipe("libgpg-error", "libgpgErrorSource", buildLibgpgErrorSourcePackage())
checkRecipe("libgcrypt", "libgcryptSource", buildLibgcryptSourcePackage(), ["awk", "diff"])
checkRecipe("less", "lessSource", buildLessSourcePackage(), ["awk"])
checkRecipe("strace", "straceSource", buildStraceSourcePackage(), ["awk", "diff"])
checkRecipe("nano", "nanoSource", buildNanoSourcePackage(), ["awk", "diff"])
checkRecipe("kbd", "kbdSource", buildKbdSourcePackage())
checkRecipe("libcap-ng", "libcapNgSource", buildLibcapNgSourcePackage())
checkRecipe("openssh", "opensshSource", buildOpensshSourcePackage(), ["awk", "diff"])
checkRecipe("fontconfig", "fontconfigSource", buildFontconfigSourcePackage())
checkRecipe("gmp", "gmpSource", buildGmpSourcePackage())
checkRecipe("lzo", "lzoSource", buildLzoSourcePackage(), ["awk", "diff"])
checkRecipe("libmd", "libmdSource", buildLibmdSourcePackage())
checkRecipe("mpc", "mpcSource", buildMpcSourcePackage())
checkRecipe("mpfr", "mpfrSource", buildMpfrSourcePackage())
checkRecipe("ncurses", "ncursesSource", buildNcursesSourcePackage(), ["awk", "cmp"])
checkRecipe("nettle", "nettleSource", buildNettleSourcePackage(), ["awk", "diff"])
checkRecipe("pam", "pamSource", buildPamSourcePackage())
checkRecipe("pcre2", "pcre2Source", buildPcre2SourcePackage(), ["cmp"])
checkRecipe("libpng", "libpngSource", buildLibpngSourcePackage())
checkRecipe("readline", "readlineSource", buildReadlineSourcePackage(), ["awk", "diff"])
checkRecipe("sqlite", "sqliteSource", buildSqliteSourcePackage())
checkRecipe("mtdev", "mtdevSource", buildMtdevSourcePackage())
checkRecipe("libbsd", "libbsdSource", buildLibbsdSourcePackage())
checkRecipe("bash", "bashSource", buildBashSourcePackage(), ["diff"])
checkRecipe("gawk", "gawkSource", buildGawkSourcePackage(), ["awk", "diff"])
checkRecipe("grep", "grepSource", buildGrepSourcePackage(), ["diff"])
checkRecipe("python3", "python3Source", buildPython3SourcePackage(), ["awk", "diff"])
checkRecipe("grub", "grubSource", buildGrubSourcePackage(),
  ["awk", "cmp", "diff"], ["build-grub-bios", "build-grub-efi"])
checkRecipe("libxcrypt", "libxcryptSource", buildLibxcryptSourcePackage())

checkRecipe("util-macros", "utilMacrosSource", buildUtilMacrosSourcePackage(), ["awk"])
checkRecipe("font-util", "fontUtilSource", buildFontUtilSourcePackage(), ["awk", "diff"])
checkRecipe("cryptsetup", "cryptsetupSource", buildCryptsetupSourcePackage())
checkRecipe("procps", "procpsSource", buildProcpsSourcePackage(),
  ["awk", "cmp", "diff"], ["src"])
checkRecipe("audit", "auditSource", buildAuditSourcePackage())
checkRecipe("freetype", "freetypeSource", buildFreetypeSourcePackage())
checkRecipe("icu", "icuSource", buildIcuSourcePackage(), ["awk", "diff"])

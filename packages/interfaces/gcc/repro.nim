## gcc -- the GNU C/C++ compiler, as a provisioning definition.
##
## Windows x86_64 is the one realization this definition carries: the WinLibs
## MinGW-w64 build the fleet pins for Windows (`config/windows-pins.json`,
## the `gcc` entry; `GCC_WINLIBS_RELEASE` in reprobuild's
## `windows/toolchain-versions.env`). That is the toolchain Windows CI
## consumers need when `--tool-provisioning=path` is not in use, so a
## `uses: "gcc >=12"` edge can be realized from the archive. The archive is
## additive: a consumer that does not select tarball provisioning for `gcc`
## never reads this block, so PATH-mode consumers are unaffected.
##
## The archive's root is the `mingw64/` directory, so the executable is
## `mingw64/bin/gcc.exe`. The SHA-256 is the one `config/windows-pins.json`
## records for this asset; it was not recomputed here.
##
## Windows arm64 is NOT declared: no pinned llvm-mingw release is recorded
## for it yet, and a digest must not be invented.

import repro_project_dsl

const
  GccVersion = "16.1.0"
  GccWinlibsTag = "16.1.0posix-14.0.0-ucrt-r2"

package gcc:
  provisioning:
    tarball url = "https://github.com/brechtsanders/winlibs_mingw/releases/download/" &
      GccWinlibsTag &
      "/winlibs-x86_64-posix-seh-gcc-16.1.0-mingw-w64ucrt-14.0.0-r2.zip",
      sha256 = "78eff1e2e804b6a6320c713f084b8f820c662104a24cea6a3bfcab82032bdd60",
      archiveType = "zip",
      executablePath = "mingw64/bin/gcc.exe",
      packageId = "gcc@" & GccVersion,
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:gcc@" & GccVersion &
        ":windows-x86_64:sha256:78eff1e2e804b6a6320c713f084b8f820c662104a24cea6a3bfcab82032bdd60"

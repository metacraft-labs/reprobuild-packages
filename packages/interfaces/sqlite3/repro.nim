## sqlite3 — the SQLite command-line shell.
##
## Moved here from reprobuild's bundled stdlib
## (`repro_dsl_stdlib/packages/sqlite3.nim`), which declared only a Nix
## realization. A plain `uses: "sqlite3"` still reaches this module: the engine
## looks a name up in this catalog when its stdlib does not bundle it.
##
## The release archives are sqlite.org's precompiled command-line tools for
## 3.53.4. Each zip holds `sqlite3`, `sqldiff`, `sqlite3_analyzer` and
## `sqlite3_rsync` at its root, so nothing is stripped. sqlite.org publishes
## SHA3-256 digests; the SHA-256 digests below were computed over the same
## downloads after checking each one's size and SHA3-256 against
## sqlite.org/download.html (2026-09-24).
##
## The from-source realization is `packages/source/sqlite` (`sqlite3Cli`).

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

package sqlite3:
  provisioning:
    nixPackage "nixpkgs#sqlite", executablePath = "bin/sqlite3",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash
    tarball url = "https://sqlite.org/2026/sqlite-tools-win-x64-3530400.zip",
      sha256 = "f46ee2475de4cbe287e6e5f7d43c838796b14e7379cd216bdbb28d391429f9fc",
      archiveType = "zip",
      executablePath = "sqlite3.exe",
      packageId = "sqlite3@3.53.4",
      cpu = "x86_64",
      os = "windows",
      lockIdentity = "tarball:sqlite3@3.53.4:windows-x86_64:sha256:f46ee2475de4cbe287e6e5f7d43c838796b14e7379cd216bdbb28d391429f9fc"
    tarball url = "https://sqlite.org/2026/sqlite-tools-win-arm64-3530400.zip",
      sha256 = "8a7c30165f6e9b054fbbe5ba6048acf23c967fd76955f7a5d66dc519542d3393",
      archiveType = "zip",
      executablePath = "sqlite3.exe",
      packageId = "sqlite3@3.53.4",
      cpu = "aarch64",
      os = "windows",
      lockIdentity = "tarball:sqlite3@3.53.4:windows-aarch64:sha256:8a7c30165f6e9b054fbbe5ba6048acf23c967fd76955f7a5d66dc519542d3393"
    tarball url = "https://sqlite.org/2026/sqlite-tools-linux-x64-3530400.zip",
      sha256 = "7a6f4d1720e4bc13faa3d934bfce37b816a496c0a2480deacd64cfd8be6cf224",
      archiveType = "zip",
      executablePath = "sqlite3",
      packageId = "sqlite3@3.53.4",
      cpu = "x86_64",
      os = "linux",
      lockIdentity = "tarball:sqlite3@3.53.4:linux-x86_64:sha256:7a6f4d1720e4bc13faa3d934bfce37b816a496c0a2480deacd64cfd8be6cf224"
    tarball url = "https://sqlite.org/2026/sqlite-tools-osx-arm64-3530400.zip",
      sha256 = "e56768d61017ab3dbd9ff5690b5551846d9945830fdc0b8a9610df722f05e33b",
      archiveType = "zip",
      executablePath = "sqlite3",
      packageId = "sqlite3@3.53.4",
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:sqlite3@3.53.4:macos-aarch64:sha256:e56768d61017ab3dbd9ff5690b5551846d9945830fdc0b8a9610df722f05e33b"
    tarball url = "https://sqlite.org/2026/sqlite-tools-osx-x64-3530400.zip",
      sha256 = "76c187f19990c4a6fe9a4f8d01de038a63fc339aaf9d491202c9c56d058cb110",
      archiveType = "zip",
      executablePath = "sqlite3",
      packageId = "sqlite3@3.53.4",
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:sqlite3@3.53.4:macos-x86_64:sha256:76c187f19990c4a6fe9a4f8d01de038a63fc339aaf9d491202c9c56d058cb110"

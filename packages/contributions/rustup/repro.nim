## The official rustup binary selects its manager CLI when named rustup.exe.
## Raw realization only verifies and places that executable; it never runs the
## installer, installs a toolchain, changes PATH, or configures a default.
## https://github.com/rust-lang/rustup/blob/1.29.1/src/bin/rustup-init.rs
import repro_project_dsl
import repro_dsl_stdlib/packages/rustup

const RustupVersion* = "1.29.1"
const RustupInterfaceFingerprint* =
  "a5cadf5264dd8dc88afa6cb7b1cf8c9659ffeb19d3be9b91736b1a49b41746f4"
const RustupWindowsX64Sha256* =
  "6f4bef66261261fcb43131be8720bab817d403a09edec7455c371974b90bdb7e"
const RustupWindowsX64Url* = "https://static.rust-lang.org/rustup/archive/" &
  RustupVersion & "/x86_64-pc-windows-msvc/rustup-init.exe"

provisioningFor "rustup":
  interfaceFingerprint "a5cadf5264dd8dc88afa6cb7b1cf8c9659ffeb19d3be9b91736b1a49b41746f4"
  contributor "github:metacraft-labs/reprobuild-packages"

  tarball url = RustupWindowsX64Url,
    sha256 = RustupWindowsX64Sha256,
    archiveType = "raw",
    executablePath = "bin/rustup.exe",
    version = RustupVersion,
    packageId = "rustup@" & RustupVersion,
    cpu = "x86_64",
    os = "windows",
    lockIdentity = "tarball:rustup@" & RustupVersion &
      ":windows-x86_64:sha256:" & RustupWindowsX64Sha256

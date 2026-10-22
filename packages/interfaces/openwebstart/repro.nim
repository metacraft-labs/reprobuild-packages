## openwebstart — OpenWebStart, the JNLP launcher (macOS application).
##
## AN INSTALLER APPLICATION. On macOS upstream ships only an install4j
## installer application (`OpenWebStart Installer.app`) on a disk image per
## CPU; its payload is in install4j's own `.dat` format inside the installer
## bundle, so the product exists only after that installer runs. Each record
## is `installMethod = "installer-silent"` with `installerApp`: the home
## archive realizer copies the installer out of the image, verifies it
## (signature, team, Developer ID, notarization), runs it unattended under
## `sandbox-exec` into the staging prefix (`-q -dir ${install_dir}/OpenWebStart`;
## writes outside the prefix, preference writes and the network are denied)
## and verifies the product before publishing the prefix. Activation places
## the whole `OpenWebStart` folder in `~/Applications`. The record shape is
## Store-And-Installation-Layout.md § macOS Application Bundles (reprobuild-pm
## spec), "Installer applications".
##
## Measured on m1 (aarch64-darwin, macOS 26.5.2), 2026-10-15. `sha256` with
## `shasum -a 256`; the installer was run CONFINED (reprobuild's own
## `runConfinedInstaller`; the x86_64 one under Rosetta) and the identities
## read off what it installed (`Info.plist`, `codesign -dv`):
##
## * Installers: `OpenWebStart Installer.app`, signed "Developer ID
##   Application: Karakun AG (M975RKD6AX)", notarized (aarch64
##   `com.install4j.9615-4721-3936-4657.2505`, x86_64 `...2499`). The
##   installer declares no identifier or version in the record: its bytes
##   are pinned by the image's sha256.
## * Product, both CPUs: `OpenWebStart/` holding `OpenWebStart javaws.app`
##   (`com.install4j.9615-4721-3936-4657.313`, 1.14.0, the record's
##   bundle), `OpenWebStart Settings.app` (`...216`), `OpenWebStart
##   Uninstaller.app` (`...uninstaller`), `.install4j/OpenWebStart
##   Update.app` (`...1462`), `openwebstart.jar` and install4j's
##   `.install4j/jre.bundle`. Every bundle team M975RKD6AX, passes
##   `codesign --verify --deep --strict`, and Gatekeeper assesses it as
##   `source=Notarized Developer ID`. The x86_64 product's executables are
##   x86_64 Mach-O (the x86_64 identifiers were measured by running the
##   x86_64 installer, confined, under Rosetta 2, not read from its payload).
## * Relocatable: install4j records the install directory only in its own
##   bookkeeping under `.install4j/`; the launchers find `.install4j/jre.bundle`
##   and `openwebstart.jar` relative to the installation, and a copy at
##   another path launched with that path's runtime and jar. The vendor's
##   updater and uninstaller in the placed copy are not supported: Reprobuild
##   owns the installation's lifecycle.
## * install4j given a `-dir` it cannot write falls back to
##   `~/Applications/OpenWebStart` and still exits 0; the realizer creates
##   the staging prefix first and refuses a prefix without `appBundle`.

import std/strutils

import repro_project_dsl

const
  OpenWebStartVersion = "1.14.0"

package openwebstart:
  provisioning:
    tarball url = "https://github.com/karakun/OpenWebStart/releases/download/v" & OpenWebStartVersion & "/OpenWebStart_macos-aarch64_" & OpenWebStartVersion.replace('.', '_') & ".dmg",
      sha256 = "f085f2fce8099119ac15b9db92b8fd6d07ef1e13062a3b2db299429f82c2d2b8",
      archiveType = "dmg",
      installMethod = "installer-silent",
      installerApp = "OpenWebStart Installer.app",
      installerArg = "-q",
      installerArg = "-dir",
      installerArg = "${install_dir}/OpenWebStart",
      appBundle = "OpenWebStart/OpenWebStart javaws.app",
      bundleId = "com.install4j.9615-4721-3936-4657.313",
      teamId = "M975RKD6AX",
      version = OpenWebStartVersion,
      executablePath = "OpenWebStart/OpenWebStart javaws.app/Contents/MacOS/JavaApplicationStub",
      packageId = "openwebstart@" & OpenWebStartVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:openwebstart@" & OpenWebStartVersion &
        ":macos-aarch64:sha256:f085f2fce8099119ac15b9db92b8fd6d07ef1e13062a3b2db299429f82c2d2b8"

    tarball url = "https://github.com/karakun/OpenWebStart/releases/download/v" & OpenWebStartVersion & "/OpenWebStart_macos-x64_" & OpenWebStartVersion.replace('.', '_') & ".dmg",
      sha256 = "9554f92784641f8063611113874b6d446b0ba138130e2c43e8b7d86df1b9ce40",
      archiveType = "dmg",
      installMethod = "installer-silent",
      installerApp = "OpenWebStart Installer.app",
      installerArg = "-q",
      installerArg = "-dir",
      installerArg = "${install_dir}/OpenWebStart",
      appBundle = "OpenWebStart/OpenWebStart javaws.app",
      bundleId = "com.install4j.9615-4721-3936-4657.313",
      teamId = "M975RKD6AX",
      version = OpenWebStartVersion,
      executablePath = "OpenWebStart/OpenWebStart javaws.app/Contents/MacOS/JavaApplicationStub",
      packageId = "openwebstart@" & OpenWebStartVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:openwebstart@" & OpenWebStartVersion &
        ":macos-x86_64:sha256:9554f92784641f8063611113874b6d446b0ba138130e2c43e8b7d86df1b9ce40"

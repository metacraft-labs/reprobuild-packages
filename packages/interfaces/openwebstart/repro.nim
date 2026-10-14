## openwebstart — OpenWebStart, the JNLP launcher (macOS application).
##
## NOT REALIZABLE BY A HOME PROFILE. On macOS upstream ships only an install4j
## INSTALLER application (`OpenWebStart Installer.app`) on a disk image per CPU;
## the product (`/Applications/OpenWebStart/...`) exists only after that
## installer runs, and its payload sits in install4j's own `.dat` format inside
## the installer bundle. There is no archive of the installed product to copy.
## The record declares the vendor shape, `installMethod = "installer-silent"`
## (install4j's unattended mode is `-q`), which the home archive realizer
## refuses on macOS: no realizer runs macOS installer applications yet. The
## bundle facts below describe the installer application, which is what is
## signed.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: OpenWebStart Installer.app, signed "Developer ID Application: Karakun AG (M975RKD6AX)".
## * x86_64: OpenWebStart Installer.app, signed "Developer ID Application: Karakun AG (M975RKD6AX)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs), "Shapes this does not cover".

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
      installerArg = "-q",
      appBundle = "OpenWebStart Installer.app",
      bundleId = "com.install4j.9615-4721-3936-4657.2505",
      teamId = "M975RKD6AX",
      version = OpenWebStartVersion,
      executablePath = "OpenWebStart Installer.app/Contents/MacOS/JavaApplicationStub",
      packageId = "openwebstart@" & OpenWebStartVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:openwebstart@" & OpenWebStartVersion &
        ":macos-aarch64:sha256:f085f2fce8099119ac15b9db92b8fd6d07ef1e13062a3b2db299429f82c2d2b8"

    tarball url = "https://github.com/karakun/OpenWebStart/releases/download/v" & OpenWebStartVersion & "/OpenWebStart_macos-x64_" & OpenWebStartVersion.replace('.', '_') & ".dmg",
      sha256 = "9554f92784641f8063611113874b6d446b0ba138130e2c43e8b7d86df1b9ce40",
      archiveType = "dmg",
      installMethod = "installer-silent",
      installerArg = "-q",
      appBundle = "OpenWebStart Installer.app",
      bundleId = "com.install4j.9615-4721-3936-4657.2499",
      teamId = "M975RKD6AX",
      version = OpenWebStartVersion,
      executablePath = "OpenWebStart Installer.app/Contents/MacOS/JavaApplicationStub",
      packageId = "openwebstart@" & OpenWebStartVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:openwebstart@" & OpenWebStartVersion &
        ":macos-x86_64:sha256:9554f92784641f8063611113874b6d446b0ba138130e2c43e8b7d86df1b9ce40"

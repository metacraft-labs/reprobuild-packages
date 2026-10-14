## karabiner-elements — Karabiner-Elements, the keyboard remapper (macOS application).
##
## NOT REALIZABLE BY A HOME PROFILE. Upstream ships one shape: a notarized
## installer package (`Karabiner-Elements.pkg`, signed "Developer ID Installer:
## Fumihiko Takayama (G43BCU2T37)") on a disk image. Both of its component
## packages carry root `preinstall` / `postinstall` scripts, and one installs
## `.Karabiner-VirtualHIDDevice-Manager.app` with the DriverKit system extension
## `org.pqrs.Karabiner-DriverKit-VirtualHIDDevice.dext` into /Applications --
## the virtual HID device that lets it remap the built-in keyboard. Copying
## `Karabiner-Elements.app` out of the payload would place a settings app with
## nothing behind it. That is a system-scope installation (`installer -pkg` as
## root, spec P3), so the record declares `installMethod = "pkg-install"` and
## the home archive realizer refuses it at plan time; no system-scope package
## realizer exists yet.
##
## The record still pins the artifact and the identity of the application it
## installs, so the system-scope realizer has nothing left to discover.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * any: Karabiner-Elements.app, signed "Developer ID Application: Fumihiko Takayama (G43BCU2T37)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs), "Shapes this does not cover".

import repro_project_dsl

const
  KarabinerVersion = "16.3.0"

package `karabiner-elements`:
  provisioning:
    tarball url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v" & KarabinerVersion & "/Karabiner-Elements-" & KarabinerVersion & ".dmg",
      sha256 = "19cce7bed3d48a722242ca683bd1bae406b6a87fed520728d1c91dee175b75e4",
      archiveType = "dmg",
      installMethod = "pkg-install",
      appBundle = "Karabiner-Elements.pkg/Installer.pkg/Payload/Applications/Karabiner-Elements.app",
      bundleId = "org.pqrs.Karabiner-Elements.Settings",
      teamId = "G43BCU2T37",
      version = KarabinerVersion,
      executablePath = "Karabiner-Elements.app/Contents/MacOS/Karabiner-Elements",
      packageId = "karabiner-elements@" & KarabinerVersion,
      cpu = "any",
      os = "macos",
      lockIdentity = "tarball:karabiner-elements@" & KarabinerVersion &
        ":macos-any:sha256:19cce7bed3d48a722242ca683bd1bae406b6a87fed520728d1c91dee175b75e4"

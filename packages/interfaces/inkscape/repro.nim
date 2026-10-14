## inkscape — Inkscape, the vector graphics editor (macOS application).
##
## Upstream publishes one notarized disk image per CPU (thin arm64 and thin
## x86_64 bundles) from media.inkscape.org; both file names carry the version.
##
## Each record was read off the downloaded artifact on m1 (aarch64-darwin),
## 2026-10-14: `sha256` with `shasum -a 256`, the bundle identifier and
## version from its `Info.plist`, the team with `codesign -dv`. Every bundle
## passed `codesign --verify --deep --strict` and Gatekeeper assessed it as
## `source=Notarized Developer ID`:
##
## * aarch64: Inkscape.app, signed "Developer ID Application: Rene de Hesselle (SW3D6BB6A6)".
## * x86_64: Inkscape.app, signed "Developer ID Application: Rene de Hesselle (SW3D6BB6A6)".
##
## The record shape is Store-And-Installation-Layout.md § macOS Application
## Bundles (reprobuild-specs): `installMethod = "app-bundle"` places the
## bundle in `~/Applications` after the trust checks pass.

import repro_project_dsl

const
  InkscapeVersion = "1.4.4"

package inkscape:
  provisioning:
    tarball url = "https://media.inkscape.org/dl/resources/file/Inkscape-" & InkscapeVersion & "_arm64.dmg",
      sha256 = "eacca94ab01e59467cdd5452a2867c3734450f9a4cfb3346956cc9b07f34f3f1",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Inkscape.app",
      bundleId = "org.inkscape.Inkscape",
      teamId = "SW3D6BB6A6",
      version = InkscapeVersion,
      executablePath = "Inkscape.app/Contents/MacOS/inkscape",
      packageId = "inkscape@" & InkscapeVersion,
      cpu = "aarch64",
      os = "macos",
      lockIdentity = "tarball:inkscape@" & InkscapeVersion &
        ":macos-aarch64:sha256:eacca94ab01e59467cdd5452a2867c3734450f9a4cfb3346956cc9b07f34f3f1"

    tarball url = "https://media.inkscape.org/dl/resources/file/Inkscape-" & InkscapeVersion & "_x86_64.dmg",
      sha256 = "17ff9f49b60115237cad9b60605950e26b11b04600e726a4513224aa373aee11",
      archiveType = "dmg",
      installMethod = "app-bundle",
      appBundle = "Inkscape.app",
      bundleId = "org.inkscape.Inkscape",
      teamId = "SW3D6BB6A6",
      version = InkscapeVersion,
      executablePath = "Inkscape.app/Contents/MacOS/inkscape",
      packageId = "inkscape@" & InkscapeVersion,
      cpu = "x86_64",
      os = "macos",
      lockIdentity = "tarball:inkscape@" & InkscapeVersion &
        ":macos-x86_64:sha256:17ff9f49b60115237cad9b60605950e26b11b04600e726a4513224aa373aee11"

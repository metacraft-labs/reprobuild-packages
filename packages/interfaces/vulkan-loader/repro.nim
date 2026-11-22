## vulkan-loader -- the Khronos Vulkan ICD loader, `libvulkan`
## (KhronosGroup/Vulkan-Loader).
##
## What a Vulkan client links (`-lvulkan`) and loads at run time; the loader
## then finds the installed drivers (ICDs) through the standard
## `VK_DRIVER_FILES` / `/run/opengl-driver` search, which this package does
## not provide. The headers are the separate `vulkan-headers` package.
##
## Realization: nixpkgs' `vulkan-loader`, at the pinned nixpkgs. The anchor
## is the shared library in its `out` output, so the resolver threads that
## `lib` directory onto `LIBRARY_PATH` for linking and onto the run-time
## library path of a consumer's actions. No release archive is pinned:
## upstream publishes source tags only, and on Windows `vulkan-1` ships with
## the LunarG SDK and the GPU driver.
##
## The anchor is the host's library name, `libvulkan.so` on Linux and
## `libvulkan.dylib` on macOS (`VulkanLoaderAnchor`); the same nixpkgs
## attribute builds both. On macOS the loader is the one a Vulkan client
## links; MoltenVK is its driver, found through MoltenVK's ICD manifest at
## run time, and is not part of this package. A `when` statement inside
## `provisioning:` is not read by the DSL (it collects only the realization
## calls), so the platform choice is an expression on the one realization.
##
## First consumer: codetracer-visual-replay, whose Vulkan executor links
## `-lvulkan` on Linux and macOS.

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

# The shared library in nixpkgs' `vulkan-loader` `out` output, by host.
# Checked against the pinned nixpkgs' builds on 2026-11-22: the
# aarch64-darwin output holds `lib/libvulkan.dylib` (and `libvulkan.1.dylib`),
# the x86_64-linux one `lib/libvulkan.so`.
const VulkanLoaderAnchor =
  when defined(macosx): "lib/libvulkan.dylib"
  else: "lib/libvulkan.so"

package `vulkan-loader`:
  provisioning:
    nixPackage "nixpkgs#vulkan-loader", executablePath = VulkanLoaderAnchor,
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

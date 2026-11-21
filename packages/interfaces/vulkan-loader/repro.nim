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
## the LunarG SDK and the GPU driver. The anchor is the Linux library name;
## a macOS consumer needs a realization anchored on `libvulkan.dylib` first.
##
## First consumer: codetracer-visual-replay, whose Vulkan executor links
## `-lvulkan` on Linux.

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

package `vulkan-loader`:
  provisioning:
    nixPackage "nixpkgs#vulkan-loader", executablePath = "lib/libvulkan.so",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

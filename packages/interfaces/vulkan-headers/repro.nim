## vulkan-headers -- the Khronos Vulkan API headers (KhronosGroup/Vulkan-Headers).
##
## A header-only package: `vulkan/vulkan.h` and the rest of the `vulkan/`
## include tree that a C or C++ Vulkan client compiles against. A consumer
## that also links the API needs `vulkan-loader`, which provides
## `libvulkan`. The two are separate upstream projects and separate nixpkgs
## attributes, so they are separate packages here.
##
## Realization: nixpkgs' `vulkan-headers`, at the pinned nixpkgs. The anchor
## is the umbrella header, so the resolver threads the package's `include`
## directory onto the compiler's search path (`CPATH`) for every action of a
## consumer that declares it in `uses:`. No release archive is pinned:
## upstream publishes source tags only, and on Windows the headers ship with
## the LunarG SDK, which a consumer locates itself.
##
## First consumer: codetracer-visual-replay, whose Vulkan executor
## (`src/player/vk_executor.c`) includes `vulkan/vulkan.h`.

import repro_project_dsl
import repro_dsl_stdlib/nixpkgs_pin

package `vulkan-headers`:
  provisioning:
    nixPackage "nixpkgs#vulkan-headers", executablePath = "include/vulkan/vulkan.h",
      nixpkgsRev = CanonicalNixpkgsRev,
      nixpkgsNarHash = CanonicalNixpkgsNarHash

# Vulkan migration

Vulkan is the graphics target for Xbox Linux and its title projects. The runtime
must use it for both Xbox GPU command execution and host presentation; merely
asking SDL to create a Vulkan window is not a completed migration.

## Current baseline

The Linux D3D8 compatibility layer uses OpenGL. The title-specific NV2A
pushbuffer executor applies fixed-function transforms and rasterizes guest
triangles on the CPU into the Xbox framebuffer. The SDL presenter then displays
that memory-backed image. This baseline is useful as a diagnostic oracle, but
it is not Vulkan rendering and its current menu output is visibly incorrect.

## Migration stages

1. **Build and device baseline.** Make Vulkan SDK headers, loader, shader
   compiler, and validation layers available in the reproducible development
   shell. Record physical-device, driver, and validation-layer details in
   diagnostic bundles. Keep a software Vulkan implementation available for
   headless CI where possible.
2. **Vulkan presentation (initial implementation).** The Linux presenter now
   tries an SDL Vulkan surface, swapchain, and explicit frame synchronization
   first. It uploads the 640x480 framebuffer and scales it to the swapchain
   with a nearest-neighbor Vulkan image blit, rather than expanding every
   output pixel on the CPU. It falls back to SDL's
   renderer if Vulkan setup fails. This isolates window, synchronization, and
   color-format issues from GPU emulation; resize recovery and validation-layer
   checks remain to be completed. Set `RECOMP_PRESENT_BACKEND=sdl` for a
   comparison run using the former SDL renderer.
3. **NV2A command translation.** Implement the methods used by the title as
   Vulkan pipeline state and commands. Preserve register/pushbuffer traces and
   framebuffer captures so Vulkan output can be compared with the CPU baseline
   and known Xbox screenshots. Translate fixed-function state to explicit
   Vulkan pipelines; do not silently ignore unknown methods.
4. **Textures and shaders.** Add NV2A texture addressing/swizzling and formats,
   combiner behavior, vertex programs, blending, depth, and viewport semantics
   as Vulkan resources, descriptors, and shaders. Track support by method and
   title test scene.
5. **Retire the temporary backend.** Keep the CPU path selectable until the
   Vulkan renderer passes title startup, menu, gameplay, and save/load gates.
   Then make Vulkan the default and retain the CPU path only if it remains
   useful for targeted tests.

## Acceptance gates

- Validation layers report no Vulkan lifetime, synchronization, or descriptor
  errors during a diagnostic run.
- The first presentation-only stage reproduces the CPU framebuffer without
  clipping, gamma, orientation, or stale-frame differences.
- Obi-Wan renders its splash and menu legibly, accepts Start/A input, and
  advances to gameplay; visual comparisons include both the SDL window and
  guest framebuffer.
- UC2 and later titles use the shared Vulkan runtime rather than carrying
  separate graphics backends.
- Logs list unsupported NV2A methods and counters so an apparently rendered
  frame cannot be mistaken for full GPU compatibility.

The current Obi-Wan captures establish that boot and splash rendering work, but
the menu image is nearly black and clipped. Vulkan is the chosen destination;
it does not guarantee a fix by itself. Missing NV2A semantics still need to be
implemented and checked against title behavior.

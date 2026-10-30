# Native runtime build verification

The shared runtime is fetched from the exact upstream revision in `toolchain.json`; the Linux patch is applied locally by `tools/toolchain.py`. The Nix development shell supplies the compiler, CMake/Ninja, SDL2, OpenSSL, and graphics dependencies.

A successful runtime build verifies compilation and archive creation only. It does not establish compatibility with any game. Each title's runtime progress, missing behavior, screenshots, and executable-specific findings belong in that title's own repository.

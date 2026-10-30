# Xbox Linux

A reusable Linux runtime and bring-up toolchain for recompiling Original Xbox executables. This repository owns the shared host/runtime work only; title-specific recompiler projects live in separate repositories:

- [Star Wars: Obi-Wan Recomp](https://github.com/soltros/obiwan-recomp)
- [Unreal Championship 2 Recomp Research](https://github.com/soltros/uc2-recomp)

Each title project can consume this runtime as an external dependency. Neither title's source, hashes, extracted files, generated translation, or diagnostic captures belong in this repository. The runtime does not bundle game code or content.

## License boundaries

Original project code in this repository is GPL-3.0-only; see [LICENSE](LICENSE). The runtime source is fetched from the upstream xboxrecomp repository at the revision in `toolchain.json`, which retains its own license. No game executables, extracted assets, saves, or game-specific generated code are included.

## Runtime setup

On x86-64 Linux with Nix:

```sh
nix develop
python3 tools/toolchain.py check
python3 tools/toolchain.py fetch
cmake -S third_party/xboxrecomp -B build/runtime -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build/runtime
```

`tools/toolchain.py fetch` retrieves the pinned upstream revision and applies this repository's Linux runtime patch. Runtime checkout and build products are local and ignored. `tools/toolchain.py check` reports host prerequisites; it does not claim that any title is compatible or playable.

Title projects may use the checkout directly by setting `XBOXRECOMP_DIR=/path/to/xbox-linux/third_party/xboxrecomp`. They remain separate repositories and can use another compatible runtime if their build configuration allows it.

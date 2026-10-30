#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

command -v nix >/dev/null 2>&1 || {
    echo "nix is required; install Nix with flakes enabled, then rerun this script." >&2
    exit 1
}

nix develop --command python3 tools/toolchain.py fetch
nix develop --command cmake -S third_party/xboxrecomp -B build/runtime \
    -G Ninja -DCMAKE_BUILD_TYPE=Debug
nix develop --command cmake --build build/runtime --parallel "${JOBS:-4}"

printf '\nXbox Linux runtime is ready at %s/third_party/xboxrecomp\n' "$ROOT"

#!/usr/bin/env bash
set -euo pipefail

# Installs a workspace-local Ghidra + XboxDev XBE loader setup. This helper is
# kept with the reusable Xbox runtime tools, not either title-specific repo.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/tools/xbox-re-tools"
GHIDRA_VERSION="12.1.4"
GHIDRA_ARCHIVE="ghidra_12.1.4_PUBLIC_20260921.zip"
GHIDRA_SHA256="ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db"
XBE_EXTENSION="ghidra_12.1.4_PUBLIC_20261016_ghidra-xbe.zip"
XBE_EXTENSION_SHA256="339b2f67563bbb8b5217740319b7f3eae9e9bbacf1f3a8aa29151f7ecb7d5152"

if [[ "${XBOX_RETOOLS_NIX_ENV:-}" != 1 ]]; then
    command -v nix >/dev/null || { echo "Nix is required." >&2; exit 1; }
    exec nix shell nixpkgs#jdk21 nixpkgs#curl nixpkgs#unzip --command \
        env XBOX_RETOOLS_NIX_ENV=1 bash "$0" "$@"
fi

mkdir -p "$TOOLS/downloads" "$TOOLS/ghidra-xbe"
GHIDRA_ZIP="$TOOLS/downloads/$GHIDRA_ARCHIVE"
EXTENSION_ZIP="$TOOLS/ghidra-xbe/$XBE_EXTENSION"
GHIDRA_DIR="$TOOLS/ghidra_$GHIDRA_VERSION"

fetch_checked() {
    local url="$1" dest="$2" expected="$3"
    if [[ ! -f "$dest" ]] || [[ "$(sha256sum "$dest" | cut -d' ' -f1)" != "$expected" ]]; then
        rm -f "$dest.part"
        echo "Downloading $(basename "$dest")"
        curl --fail --location --retry 3 --output "$dest.part" "$url"
        echo "$expected  $dest.part" | sha256sum --check --status || {
            rm -f "$dest.part"
            echo "SHA-256 verification failed for $(basename "$dest")." >&2
            exit 1
        }
        mv "$dest.part" "$dest"
    else
        echo "Verified cached $(basename "$dest")"
    fi
}

fetch_checked \
    "https://downloads.sourceforge.net/project/ghidra/Ghidra_12.1.4_build/$GHIDRA_ARCHIVE" \
    "$GHIDRA_ZIP" "$GHIDRA_SHA256"
fetch_checked \
    "https://github.com/XboxDev/ghidra-xbe/releases/download/build-202610161023/$XBE_EXTENSION" \
    "$EXTENSION_ZIP" "$XBE_EXTENSION_SHA256"

if [[ ! -x "$GHIDRA_DIR/ghidraRun" ]]; then
    TMP="$TOOLS/.ghidra-unpack"
    rm -rf "$TMP"
    mkdir -p "$TMP"
    unzip -q "$GHIDRA_ZIP" -d "$TMP"
    FOUND="$(find "$TMP" -maxdepth 1 -type d -name 'ghidra_*_PUBLIC' -print -quit)"
    [[ -n "$FOUND" ]] || { echo "Could not find Ghidra directory in archive." >&2; exit 1; }
    rm -rf "$GHIDRA_DIR"
    mv "$FOUND" "$GHIDRA_DIR"
    rm -rf "$TMP"
fi

mkdir -p "$GHIDRA_DIR/Extensions/Ghidra"
cp -f "$EXTENSION_ZIP" "$GHIDRA_DIR/Extensions/Ghidra/$XBE_EXTENSION"

cat > "$TOOLS/ghidra-xbe/open-ghidra.sh" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec nix shell nixpkgs#jdk21 --command "$HERE/ghidra_12.1.4/ghidraRun" "$@"
LAUNCHER
chmod +x "$TOOLS/ghidra-xbe/open-ghidra.sh"

echo
echo "Ghidra $GHIDRA_VERSION and the matching XboxDev XBE loader are ready."
echo "Launch: $TOOLS/ghidra-xbe/open-ghidra.sh"
echo "In Ghidra, open File > Install Extensions, select XboxExecutableLoader,"
echo "enable it, restart Ghidra, then import each game's default.xbe."

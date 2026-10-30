#!/usr/bin/env bash
# Convenient Obi-Wan entry point for the shared diagnostic runner.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
game=${OBIWAN_GAME_DIR:-"$root/../Star Wars - Obi-Wan (USA)"}
save=${OBIWAN_SAVE_DIR:-"$root/diagnostics/obiwan-save"}

if [[ -n ${OBIWAN_EXECUTABLE:-} ]]; then
    exe=$OBIWAN_EXECUTABLE
else
    exe=
    for candidate in \
        "$root/../obiwan-recomp/build/obiwan/obiwan_recomp" \
        "$root/../obiwan-recomp/build/obiwan_recomp" \
        "$root/build/obiwan/obiwan_recomp" \
        "$root/build/obiwan_recomp"; do
        if [[ -x $candidate ]]; then exe=$candidate; break; fi
    done
    if [[ -z $exe ]]; then
        cat >&2 <<EOF
Could not find the Obi-Wan launcher. Build the title project or set:
  OBIWAN_EXECUTABLE=/path/to/obiwan_recomp

Default locations checked:
  ../obiwan-recomp/build/obiwan/obiwan_recomp
  ../obiwan-recomp/build/obiwan_recomp
  build/obiwan/obiwan_recomp
  build/obiwan_recomp
EOF
        exit 2
    fi
fi

if [[ ! -d $game ]]; then
    echo "Extracted Obi-Wan game directory not found: $game" >&2
    echo 'Set OBIWAN_GAME_DIR=/path/to/extracted/game to override it.' >&2
    exit 2
fi

exec "$root/tools/run_diagnostics.sh" "$exe" "$game" "$save" "$@"

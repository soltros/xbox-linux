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

# Match the known-good Obi-Wan launcher defaults so the diagnostic run creates
# its framebuffer window and services the title's startup device/event paths.
export RECOMP_FB_WINDOW=${RECOMP_FB_WINDOW:-1}
export RECOMP_TITLE_KEVENTS=${RECOMP_TITLE_KEVENTS:-1}
export RECOMP_VBLANK=${RECOMP_VBLANK:-paced}
export RECOMP_PB_EXEC=${RECOMP_PB_EXEC:-1}
export RECOMP_USB=${RECOMP_USB:-1}
export RECOMP_WATCHDOG_SECS=${RECOMP_WATCHDOG_SECS:-28}
export RECOMP_PAD_SCRIPT=${RECOMP_PAD_SCRIPT:-6000:start,9000:a}
# Capture enough graphics context in the standard Obi-Wan bundle to diagnose
# missing or malformed UI without requiring a second diagnostic run.
export DIAG_DUMP_TEXTURES=${DIAG_DUMP_TEXTURES:-1}

exec "$root/tools/run_diagnostics.sh" "$exe" "$game" "$save" "$@"

#!/usr/bin/env bash
# Capture one title run into a shareable, title-independent diagnostic bundle.
set -uo pipefail

usage() {
    echo "Usage: $0 TITLE_EXECUTABLE GAME_DIRECTORY SAVE_DIRECTORY [TITLE_ARGS...]" >&2
    echo "Optional: DIAG_DIR, DIAG_TIMEOUT_SECS (default 45), RECOMP_WATCHDOG_SECS (default 20)" >&2
}

if [[ $# -lt 3 ]]; then usage; exit 2; fi
exe=$1 game_dir=$2 save_dir=$3
shift 3
if [[ ! -x "$exe" ]]; then echo "not an executable: $exe" >&2; exit 2; fi
if [[ ! -d "$game_dir" ]]; then echo "game directory not found: $game_dir" >&2; exit 2; fi
mkdir -p "$save_dir"
if ! command -v timeout >/dev/null || ! command -v tee >/dev/null; then
    echo "GNU timeout and tee are required" >&2; exit 2
fi

stamp=$(date -u +%Y%m%dT%H%M%SZ)
out=${DIAG_DIR:-"$PWD/diagnostics/$stamp"}
mkdir -p "$out"
out=$(cd "$out" && pwd)
log="$out/runtime.log"
meta="$out/run-info.txt"
watchdog=${RECOMP_WATCHDOG_SECS:-20}
limit=${DIAG_TIMEOUT_SECS:-45}
export RECOMP_FB_DUMP=${RECOMP_FB_DUMP:-"$out/frame-"}
if [[ ${DIAG_DUMP_TEXTURES:-0} == 1 ]]; then
    export RECOMP_TEX_DUMP=${RECOMP_TEX_DUMP:-"$out/texture-"}
fi

{
    printf 'started_utc=%s\n' "$stamp"
    printf 'executable=%s\n' "$(realpath "$exe")"
    printf 'game_directory=%s\n' "$(realpath "$game_dir")"
    printf 'save_directory=%s\n' "$(realpath "$save_dir")"
    printf 'title_arguments='; printf ' %q' "$@"; printf '\n'
    printf 'watchdog_seconds=%s\nexternal_timeout_seconds=%s\n' "$watchdog" "$limit"
    printf 'kernel=%s\n' "$(uname -a)"
    printf 'display=%s\nwayland_display=%s\nx_display=%s\n' \
        "${XDG_SESSION_TYPE:-unset}" "${WAYLAND_DISPLAY:-unset}" "${DISPLAY:-unset}"
    printf 'graphics_devices:\n'
    if command -v lspci >/dev/null; then lspci 2>/dev/null | grep -Ei 'vga|3d|display' || true
    else echo 'lspci unavailable'; fi
    printf 'selected_environment:\n'
    for name in RECOMP_FB_WINDOW RECOMP_FB_DUMP RECOMP_TEX_DUMP RECOMP_TITLE_KEVENTS \
                RECOMP_VBLANK RECOMP_PB_EXEC RECOMP_USB RECOMP_WATCHDOG_SECS \
                RECOMP_PAD_SCRIPT RECOMP_THREAD_TRACE RECOMP_DPC_TRACE; do
        if [[ -v $name ]]; then printf '%s=%s\n' "$name" "${!name}"; fi
    done
} >"$meta"

echo "Capturing runtime diagnostics in: $out"
echo "Close the game normally if possible; hard timeout is ${limit}s."
set +e
timeout --signal=INT --kill-after=5s "${limit}s" \
    env RECOMP_WATCHDOG_SECS="$watchdog" "$exe" "$game_dir" "$save_dir" "$@" \
    2>&1 | tee "$log"
run_status=${PIPESTATUS[0]}
set -e

case $run_status in
    0) outcome=exited_normally ;;
    124) outcome=external_timeout ;;
    130|143) outcome=interrupted_or_closed ;;
    *) outcome=exit_status_$run_status ;;
esac
if [[ $run_status -eq 3 ]] && grep -q '\[WATCHDOG\]' "$log"; then
    outcome=runtime_watchdog
fi
{
    printf '\noutcome=%s\nprocess_status=%s\n' "$outcome" "$run_status"
    printf 'log_bytes=%s\n' "$(wc -c <"$log")"
    printf 'diagnostic_lines:\n'
    grep -E '^[[:space:]]*\[BOOT\]|\[AV\] SetDisplayMode|^[[:space:]]*\[GPU\] ([0-9.]+ fps|surface |draws |brightest |[0-9]+ pixels written|rasterised |vertex programs:|fixed-function transform:|batches:)|\[TEXUSE\]|\[TEXDUMP\]|\[(FATAL|WATCHDOG|UNIMPL|NV2A)\]|\[FILE\].*(fonts/.*\.laf|FAILED)|missing at watchdog|native_backtrace|fault_address=' "$log" \
        | tail -n 100 || true
    printf 'capture_files:\n'
    captures=$(find "$out" -maxdepth 1 -type f \( -name '*.bmp' -o -name '*.png' \) \
        -printf '  %f (%s bytes)\n')
    if [[ -n $captures ]]; then printf '%s\n' "$captures"; else echo '  none'; fi
} >"$out/summary.txt"

tar -czf "$out.tar.gz" -C "$(dirname "$out")" "$(basename "$out")"
echo "Run ended as $outcome (status $run_status). Bundle: $out.tar.gz"
exit 0

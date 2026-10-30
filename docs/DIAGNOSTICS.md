# Capturing a title run

Use the shared diagnostic wrapper when a title starts, hangs, renders incorrectly, or exits unexpectedly. It records the complete console log, launch arguments, host/display/GPU basics, selected `RECOMP_*` settings, and a filtered summary. It packages these files into a `.tar.gz` bundle without copying game files or save data.

From the runtime checkout, run:

```sh
./tools/run_diagnostics.sh \
  /path/to/title_recomp \
  "/path/to/extracted/game" \
  "$PWD/diagnostics/obiwan-save"
```

The wrapper creates the save directory if needed. The title opens its normal window. Close it normally when you have captured the behavior you want; otherwise the wrapper sends an interrupt after 45 seconds, allows five seconds for shutdown, then kills a process that remains. The runtime watchdog defaults to 20 seconds. The wrapper itself exits successfully after collecting the run; check `summary.txt` for the game's actual exit outcome.

Each run creates `diagnostics/<UTC timestamp>/` with `runtime.log`, `run-info.txt`, and `summary.txt`, plus a sibling `<UTC timestamp>.tar.gz`. Set `DIAG_DIR=/some/path` to select a different output directory, `DIAG_TIMEOUT_SECS=90` to extend the external limit, or `RECOMP_WATCHDOG_SECS=30` to change the runtime watchdog. The timeout should be longer than the watchdog so the runtime can emit its own guest-state report.

The archive contains no screenshots. Capture the game window separately using your desktop screenshot tool and share it alongside the archive when investigating visual issues. Review `run-info.txt` before sharing: it includes local executable, game, and save paths, plus selected diagnostic environment values.

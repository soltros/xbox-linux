# Capturing a title run

Use the shared diagnostic wrapper when a title starts, hangs, renders incorrectly, or exits unexpectedly. It records the complete console log, launch arguments, host/display/GPU basics, selected `RECOMP_*` settings, and a filtered summary. It packages these files into a `.tar.gz` bundle without copying game files or save data. For the Obi-Wan checkout layout, the repository-root `./diagnostic.sh` supplies the usual title paths automatically.

From the runtime checkout, run:

```sh
./tools/run_diagnostics.sh \
  /path/to/title_recomp \
  "/path/to/extracted/game" \
  "$PWD/diagnostics/obiwan-save"
```

For Obi-Wan, the short form is:

```sh
./diagnostic.sh
```

It checks the sibling `obiwan-recomp/build/` locations for the title executable, expects the extracted game at `../Star Wars - Obi-Wan (USA)`, and stores saves under `xbox-linux/diagnostics/obiwan-save`. It also enables the known Obi-Wan startup settings (`RECOMP_FB_WINDOW`, title events, paced vblank, pushbuffer execution, and USB) and uses a 28-second runtime watchdog. Override any path with `OBIWAN_EXECUTABLE`, `OBIWAN_GAME_DIR`, or `OBIWAN_SAVE_DIR`, and override any runtime setting by exporting its `RECOMP_*` variable before launch.

The wrapper creates the save directory if needed. The title opens its normal window. Close it normally when you have captured the behavior you want; otherwise the wrapper sends an interrupt after 45 seconds, allows five seconds for shutdown, then kills a process that remains. The runtime watchdog defaults to 20 seconds. The wrapper itself exits successfully after collecting the run; check `summary.txt` for the game's actual exit outcome.

Each run creates `diagnostics/<UTC timestamp>/` with `runtime.log`, `run-info.txt`, and `summary.txt`, plus a sibling `<UTC timestamp>.tar.gz`. Set `DIAG_DIR=/some/path` to select a different output directory, `DIAG_TIMEOUT_SECS=90` to extend the external limit, or `RECOMP_WATCHDOG_SECS=30` to change the runtime watchdog. The timeout should be longer than the watchdog so the runtime can emit its own guest-state report.

The archive contains no screenshots. Capture the game window separately using your desktop screenshot tool and share it alongside the archive when investigating visual issues. Review `run-info.txt` before sharing: it includes local executable, game, and save paths, plus selected diagnostic environment values. A runtime exit with status 3 and a `[WATCHDOG]` log line is labeled `runtime_watchdog` in the summary; that means the guest failed to exit before the configured watchdog, not that the game completed startup successfully.

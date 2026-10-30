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

It checks the sibling `obiwan-recomp/build/` locations for the title executable, expects the extracted game at `../Star Wars - Obi-Wan (USA)`, and stores saves under `xbox-linux/diagnostics/obiwan-save`. It also enables the known Obi-Wan startup settings (`RECOMP_FB_WINDOW`, title events, paced vblank, pushbuffer execution, USB, and a Start/A input script at 6/9 seconds) and uses a 28-second runtime watchdog. Override any path with `OBIWAN_EXECUTABLE`, `OBIWAN_GAME_DIR`, or `OBIWAN_SAVE_DIR`, and override any runtime setting by exporting its `RECOMP_*` variable before launch. Set `RECOMP_PAD_SCRIPT=` to disable scripted input.

The wrapper creates the save directory if needed. The title opens its normal window. Close it normally when you have captured the behavior you want; otherwise the wrapper sends an interrupt after 45 seconds, allows five seconds for shutdown, then kills a process that remains. The runtime watchdog defaults to 20 seconds. The wrapper itself exits successfully after collecting the run; check `summary.txt` for the game's actual exit outcome.

Each run creates `diagnostics/<UTC timestamp>/` with `runtime.log`, `run-info.txt`, and `summary.txt`, plus a sibling `<UTC timestamp>.tar.gz`. It asks the framebuffer window to save the screen it is actually showing every 30 runtime frames, so a visible capture is available even in short watchdog-limited runs. The NV2A executor also writes intermediate draw-surface BMPs; those may differ from the window image when the game uses multiple buffers. The summary calls out display mode, rendering totals, texture use, font opens, watchdog/fault state, and image files included. Set `DIAG_DIR=/some/path` to select a different output directory, `DIAG_TIMEOUT_SECS=90` to extend the external limit, or `RECOMP_WATCHDOG_SECS=30` to change the runtime watchdog. The timeout should be longer than the watchdog so the runtime can emit its own guest-state report.

The Obi-Wan shortcut also includes texture atlas BMPs by default to help diagnose UI and font rendering. Turn them off with `DIAG_DUMP_TEXTURES=0 ./diagnostic.sh`. When calling the generic runner directly, texture dumps remain opt-in with `DIAG_DUMP_TEXTURES=1`.

The archive includes the runtime's visible framebuffer capture and any intermediate surface or texture BMPs produced during the run. These are diagnostic images, not a substitute for a desktop screenshot if you need to show window decorations or desktop behavior. Review `run-info.txt` before sharing: it includes local executable, game, and save paths, plus selected diagnostic environment values. A runtime exit with status 3 and a `[WATCHDOG]` log line is labeled `runtime_watchdog` in the summary; that means the guest failed to exit before the configured watchdog, not that the game completed startup successfully.

# Xbox executable analysis tools

Run `./tools/setup-xbox-re-tools.sh` from the `xbox-linux` repository. It uses
a temporary Nix shell for Java 21, curl, and unzip; no system profile is changed.
The downloaded tools live under `tools/xbox-re-tools/` (ignored by git). Ghidra
is about 570 MB and needs around 1.5 GB of disk space after extraction.

After setup, launch `tools/xbox-re-tools/ghidra-xbe/open-ghidra.sh` and import
the game's `default.xbe`. The setup script installs `XboxExecutableLoader`
directly into Ghidra, including for headless analysis. This XboxDev extension
loads the XBE format and provides Xbox type definitions and library-signature
matching.

The archives are pinned to matching Ghidra and extension versions and verified
with SHA-256. Ghidra 12.1.4 is used because the published XboxDev extension
build targets that version.

Other relevant XboxDev tools:

- [xbedump](https://github.com/XboxDev/xbedump) displays XBE headers and checks
  section hashes. Our existing inspection tooling already handles those tasks.
- [pyxbe](https://github.com/XboxDev/pyxbe) reads and writes XBE files; useful
  for future automated edits, but not needed for current runtime diagnosis.
- [xtlid](https://github.com/XboxDev/xtlid) maps `.XTLID` identifiers to
  function names; useful if the titles contain that section.
- [extract-xiso](https://github.com/XboxDev/extract-xiso) extracts and creates
  XISO images. Our game directories are already extracted.
- [nv2a-trace](https://github.com/XboxDev/nv2a-trace) captures GPU traces; it
  needs a trace source and does not analyze an XBE on its own.

The [Reddit thread](https://www.reddit.com/r/originalxbox/comments/kluxkt/is_it_possible_to_rip_the_assets_from_an_xbe/)
is broadly right that an XBE mostly contains executable code, while game assets
usually live in separate files. For assets, our file inspection and runtime
file-open/read logs are more useful; Ghidra is for understanding code paths,
library calls, and runtime stalls.

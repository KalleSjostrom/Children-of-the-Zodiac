# Children of the Zodiac — Godot 4.7 port

A port of Kalle Sjöström's Java/JOGL RPG *Children of the Zodiac* to Godot 4.7
(GDScript). The game logic is translated file by file from the last version of
the original that compiled and ran: commit `a28bc8b` of
https://github.com/KalleSjostrom/Children-of-the-Zodiac (the later
commits were an unfinished OpenGL 4 / village art rework). That source is kept
in `_java_reference/src/` for comparison (Godot ignores it).

## Running

Open the folder in Godot 4.7 and press Play (main scene `main/Main.tscn`), or:

```
Godot_v4.7-stable_win64.exe --path "C:/Users/c06ks/Work/Children of the Zodiac"
```

Controls (as in the original, PlayStation-style buttons):

| Key | Button | Use |
|---|---|---|
| Arrow keys | D-pad | move / navigate |
| S | Cross | confirm / interact |
| D | Circle | back / cancel; hold to sprint in villages and to run cutscenes at 3× speed |
| W | Triangle | open the menu |
| A | Square | |
| Q / E | L1 / R1 | |
| 1 / 3 | L2 / R2 | |
| Enter | Start | pause |
| Space | Select | (Space + Down opens the developer "Cheater" menu) |
| F | | toggle full screen |
| Esc | | quit |
| 6 / 7 / 8 | | emergency save to slots E1–E3 |

A game pad works too (PlayStation layout: cross = bottom face button).

Developer options (after `--` on the command line):

* `--start=<place>`: start at a place from `maps/Main/main.bank`
  (e.g. `--start=Prolog`).
* `--load=<slot>`: load a saved game. An absolute path to a `.sav` file
  (without the extension) loads that file, e.g. a save attached to a ticket.
* `--mute`: no music.
* `--autoplay=<file> --shots=<dir>`: scripted input and screenshots, see
  `src/main/AutoPlay.gd`.
* `--seed=<n>` (deterministic run), `--fixed-step`, `--uncapped`,
  `--legacy=<subsystems>`, `--bridge-test`: for parity testing, see
  `docs/ARCHITECTURE.md` section 7 and `tools/parity/parity.sh`.

Saves are written to Godot's user folder (`user://saves/`).

## How the port is organized

* `src/<package>/<Class>.gd` mirrors `_java_reference/src/<package>/<Class>.java`;
  class names are listed in `docs/class_map.tsv`.
* `src/graphics/Graphics.gd` + `GLBackend.gd` emulate the OpenGL 2 immediate
  mode API the original used (2D in a 1024×768 orthographic space, 3D with
  `gluPerspective(45°, 4:3, 1, 75)`), rendering 2D through canvas items and 3D
  through sub-viewports, in the original draw order.
* `src/main/Main.gd` is the game loop (input → update(ms) → draw at 60 FPS).
* `res/` (images, sounds, music, fonts) and `maps/` (text data: villages,
  labyrinths, story scripts, enemies, banks) are the original assets.
  `file_index.txt` lists them for case-insensitive lookup; regenerate it with
  `python tools/gen_file_index.py` after adding files.
* `docs/PORTING.md` describes the Java → GDScript conventions;
  `docs/port_notes/` has per-package notes. New (non-legacy) code follows
  `docs/ARCHITECTURE.md`; the modernization plan is
  `docs/MODERNIZATION_PLAN.md`.
* Difficulty levels and their balancing: `docs/DIFFICULTY.md`.
* `tools/check.sh [folders]` compiles all scripts headlessly and prints errors.

## Exporting

`export_presets.cfg` has a Windows preset that includes the non-resource
data (`maps/*`, `file_index.txt`). Install the 4.7 export templates first
(Editor → Manage Export Templates).

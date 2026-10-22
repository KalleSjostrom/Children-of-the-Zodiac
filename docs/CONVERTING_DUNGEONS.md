# Converting dungeon floors

Phase 2 of `docs/MODERNIZATION_PLAN.md` (dungeons as scenes). All 80 floors
of `maps/Labyrinth` are converted through steps A and B: the pilot (Forest of
Reil, The Great Mine--Tunnel, plan 7.7) and the rollout (the other 77, plan
7.8). The conventions are in `docs/ARCHITECTURE.md` section 10. This is the
procedure for a `.map` file that changes, a new floor, or a converter
change. Run everything from bash in the project root, Godot with
`< /dev/null`; close the Godot editor first (it reimports the `.import` files
the converter changes, and a new run's window takes the focus: do not type
while a recording runs).

## 1. Parity coverage first (on the code you start from)

Record the cases before the change (`tools/parity/parity.sh record golden
--jobs=8`; 12 logical cores take 8 jobs), so that the goldens show the
drawing before it. 336 cases take about 35 minutes.

* **Tours** (group `dungeon_tour_*`, script `tools/autoplay/dungeon_tour.txt`):
  one script for every floor, no route per floor: the fade-in, a settled
  shot, then a fixed sequence of steps (UP, DOWN backwards) and turns both
  ways with shots in the middle of a step and of a turn, `pos` lines, the
  minimap and the menu thumbnail. A step into a wall does nothing. One line
  per floor and save in `tools/parity/cases.txt`:
  `dungeon_tour_<area>_<floor>[_start]  dungeon_tour --load=<save> --start="<place>" --no-encounters`.
  `--start=<Area>--<Floor>-mark<n>` (main.bank, mode 4) starts at the n-th
  door or hinder door of the `.map` file (both count, in file order), facing
  away from it; `-save` starts at the save point. Take the place names from
  main.bank: a few write the floor with underscores
  (`East Passage--East_Mountain-mark0`, `Forest of Bri--West_Forest-mark0`).
  A tour that starts at a trigger door (Central Pass--West Part, Grivera--First
  Floor) or walks onto a save point (Menthu's Lair--Hall of Memories) stays in
  that dialog: its keys only page it. Kept, as content.
* **`--no-encounters`** (dev only, `src/main/Main.gd`) switches random
  battles off for walks (`Labyrinth.noEncounters`; the steps are still
  counted). Battles get cases of their own.
* **`--start-node=<address>:<direction>`** (dev only) starts the floor at a
  node and facing (0 UP, 1 RIGHT, 2 DOWN, 3 LEFT), as a game saved there
  does (`Load.labyrinthPosition`, COTZ-005): a case starts in front of the
  object it uses, no route needed. `--status=<name>:<value>,…` presets the
  objects' Database statuses (database names `<area>--<floor>.map<kind><cell>`,
  lowercase, `_` for spaces).
* **Hand-written cases**, by shared script (`tools/autoplay/`):

  | Script | From | Shows |
  |---|---|---|
  | `dungeon_door` | the cell before a door, facing it (`--start-node`) | a step onto the door's cell (a ladder blocks it: it is climbed from there), CROSS, the next floor's fade-in, the menu (the mode switch that frees the floor left), back through the door the player arrived at, the menu |
  | `dungeon_use` | the cell before an object, facing it | CROSS, the animation, CROSS until no dialog shows (`loopuntil !dialog`), a look away and back, the menu |
  | `dungeon_step_on` | the cell before a floor button or save point | the step onto it, its dialog paged, a turn, a step back |
  | `dungeon_trigger` | a trigger door's mark (`--load=Start`) | its arrival dialogs |
  | `dungeon_riddle_cross` / `_circle` / `_triangle` | the cell before a riddle | the riddle opened, the cursor moved, left with the key its class leaves with (CROSS: RiddleGame, GriveraRiddle, AegisRiddle; CIRCLE: HateRiddle and the puzzles; TRIANGLE: CesadurRiddle) |
  | `dungeon_battle` | a cell with three free cells ahead | steps forward and back until a battle starts (`Labyrinth.checkEnterBattle` wants two free cells ahead), a round, the console's `kill`, the result screens |
  | `dungeon_boss` | `--load="Slot 1"` (the boss alive) | the console's `boss` (next to it), a step, the boss's dialog paged, `kill`, what the boss leads to |
  | `dungeon_map_page` | mark0 | a walk, the menu's map page |
  | `dungeon_save_load` | mark0 | the console's `save 2` away from the save point, the title, Continue, the floor at the saved node |
  | `dungeon_console_goto` | a village | the console's `goto`, `teleport`, `savepoint` |

* **Planning a case.** `pos` prints `node=<address> dir=<0-3> cam=<x>,<z>
  angle=<degrees>`. Directions: UP is address +1, RIGHT -16, DOWN -1, LEFT
  +16 (a turn LEFT is dir - 1). A step or a turn takes 500 ms: `tap`, then
  `wait 700`. A chest, lever, button, villager, riddle or ladder is used from
  the cell before it (CROSS facing it); a door from its own cell, facing its
  wall (from the cell before it, CROSS does nothing: COTZ-010). The object
  and its cell are the `inv` line's first numbers; Inventory.dir is the
  opposite of the line's direction. Probe a route headless:
  `Godot --headless --path . --fixed-fps 60 -- --mute --seed=1 --uncapped --load="Slot 1" --start="<place>" --start-node=<a>:<d> --no-encounters --autoplay=<probe.txt>`.
  `loopuntil` also matches `dialog` while the labyrinth shows one (not
  printed in the state lines): `mark`, `tap CROSS`, `wait 900`,
  `loopuntil !dialog <ms>` pages any dialog.
* **Saves:** "Slot 1" (saved in Menthu's Lair) has used the objects of most
  floors up to the Temple of Aegis: chests open, levers pulled, villagers
  rescued, bombs and mission chests done, most hinder doors open; none of
  the Ice Cavern, Empyrian Temple, Silent Ruin, Frozen Forest or Menthu's
  Lair (their statuses are unset, as in a new game), and the bosses alive
  but Taur. "Start" (the beginning) has used nothing; it opens some hinder
  doors (Pensara Prison, The Sewers, The Great Mine, Mt. Cesadur--Basement)
  and has the Ice Cavern's Menthu1 dead. The other states only `--status`
  reaches (the Ice Cavern combo, the riddle door, the Hall of Wind's
  additive door). A floor's statuses: `grep -i "<area>--<floor>" maps/Banks/*.sav`.
* Content quirks are kept and noted in the case's comment, not fixed: see
  plan 7.8 for the list (doors and levers whose links name nothing, the
  Silent Ruin door that leads to a mark main.bank lacks, a riddle that
  solves itself, floors without floor textures or enemy groups).
* Record the new cases a second time (`record golden2 'dungeon_*'`) and
  `compare golden golden2 'dungeon_*'`: must be identical. A shot of the
  title's Continue list is not: it shows each slot's file time.

## 2. Convert

```
tools/import/map_to_scene.sh "<Area>--<Floor>" ...   # or --all (all 80 floors: about 20 s)
```

It writes `resources/dungeon_layouts/<Area>--<Floor>.tres`, the style
(`resources/dungeon_styles/<Area>.tres`, the look most floors of the area
share; `<Area>--<Floor>.tres` for a floor whose look differs: 23 floors),
`resources/sprite_frames/labyrinth/<folder>/<image>.tres` (the object image
series) and `scenes/dungeons/<Area>/<Floor>.tscn`, and sets
`detect_3d/compress_to=0` in the `.import` files of the textures the floor
uses (else the editor VRAM-compresses a texture it sees on a 3D material,
which would change the legacy drawing too; the imported pixels do not
change: only a flag in the `.ctex` header does). Read its output (all 80
files: 134 warnings, none an error):

* `unknown command ... ignored`: what the legacy loader ignores too (every
  file has a `mapSize` line; 36 an `end` line).
* `repeated link 'dir ...'`: a `dir` line given twice; the legacy loader
  counts it as a neighbour again (Frozen Forest--Forest Passage, 8 lines).
  Kept (`DungeonCell.extra_links`).
* `NUL byte in the line`: 10 hinder door lines of The Great Mine--The Hall
  (69), The Sewers--South East (84, 86, 87, 89) and The Sewers--South (99,
  100, 101, 104, 105) write the link name as `mark<NUL><n>`.
  `GameResourceLoader` drops NUL bytes when it reads a file, so the legacy
  loader and the scene read `mark<n>`; the Java kept the NUL and
  `Organizer.convert` dropped it wherever the name was looked up, so the
  doors lead to `<n>` in both (`dungeon_door_nul_name`).
* `'<token>' is not an integer`, `unknown key`, `missing texture`,
  `missing image`, `on node ..., which no dir line has`: what the legacy
  loader misreads or stops on (none in the 80 files).

Run it twice: the second run must not change any file (hash the output
folders and `res/Labyrinth`, or `git status`). Then `tools/check.sh`: it
imports the changed files.

## 3. Check the data (step A)

```
Godot --headless --path . --script res://tools/import/verify_dungeons.gd -- --save="Slot 1" --save=Start "<Area>--<Floor>" ...   # or --all: 160 builds, about 30 s
Godot --path . --script res://tools/import/verify_dungeons.gd -- --meshes --all   # windowed: also the walls' and the sky's meshes
```

Every floor must PASS with both saves. A FAIL names the field path
(`map.nodes[7].walls[1]: 1 vs 2`). `--meshes` also compiles the legacy
display list and compares its parts (the sky in eye space, then the walls)
with `DungeonFloor.build` (its sky and walls meshes), surface by surface
and array by array. A dry run without touching the project:
`tools/import/map_to_scene.sh --data-only --out=<dir> --all`, then
`verify_dungeons.gd -- --scenes=<dir>/scenes --all`. `tools/check.sh` must
report 0 failed.

## 4. Look at it

Open the scene in the editor (the floor builds itself, the sky in front of
the Rig's camera; objects show their image and a label, doors their mark),
or render it:

```
Godot --path . --script res://tools/import/dungeon_preview.gd -- "res://scenes/dungeons/<Area>/<Floor>.tscn" out
```

It writes `out_rig.png` (from the first door, the legacy projection) and
`out_top.png` (from above). `tools/parity/contact_sheet.gd` puts many side
by side. Five demon floors (Grivera--Corridor of Agony, Menthu's
Lair--Hall of Memories and --Throne of Serpents, Mt. Cesadur--Mountain Top,
Temple of Aegis--Top Floor) have no floor or roof texture: their walls stand
in black. Boss--Test has no textures at all.

## 5. Parity

```
tools/parity/parity.sh record afterA --jobs=8 --args="--legacy=dungeon_drawing"; tools/parity/parity.sh compare golden afterA   # step A
tools/parity/parity.sh ab "--legacy=dungeons" "" --ignore-world --jobs=8 'dungeon_*' bridge_test battle newgame_to_forest story_having_fun story_meanwhile_in_zazo story_menthu_kills_teo story_senate_of_pensara   # step B
```

`--legacy=dungeon_drawing` (dev) builds converted floors from their scenes
but draws them the legacy way: step A on its own must give identical shots
and logs for every case (`--ignore-world` for the cases whose floor was a
scene in the golden). Step B, legacy vs. scene on the dungeon cases and the
cases that pass through floors, at tolerance 0: see plan 7.8 for what it
gives and why (the legacy vertices, the walls as one instance with the
display list's surfaces, the objects batched as GLBackend batches them;
what remains is Godot's rounding of 1/255 where legacy drawing, the
minimap above all, blends over the floor: tolerance 1). The other cases: `compare golden
after`, identical. Each floor left prints `Labyrinth: freed <floor>` and
`DungeonScene: freed <floor>.map` at the next mode switch; the floor that is
current when the game quits only the second (Main frees its scene).

## 6. Commit

The layouts, styles, SpriteFrames, scenes and the changed `.import` files,
the AutoPlay scripts and cases. Keep the `.map` files until decision 5
(plan section 13): the converter, the data check and `--legacy=dungeons`
read them.

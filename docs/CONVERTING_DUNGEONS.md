# Converting dungeon floors

Phase 2 of `docs/MODERNIZATION_PLAN.md` (dungeons as scenes). The pilot
converted Forest of Reil (Forest Path, Deep Forest) and The Great Mine--Tunnel
through steps A and B; the other 77 floors of `maps/Labyrinth` pass the
converter and the data check in a dry run. The conventions are in
`docs/ARCHITECTURE.md` section 10. This is the procedure for the next floors,
a `.map` file that changes, or a converter change. Run everything from bash in
the project root, Godot with `< /dev/null`.

## 1. Parity coverage first (on unconverted code)

Record the cases before the change, on the code you start from
(`tools/parity/parity.sh record golden --jobs=5`), so that the goldens show
the legacy drawing.

* **Tours** (group `dungeon_tour_*`, script `tools/autoplay/dungeon_tour.txt`):
  one script for every floor, no route per floor: the fade-in, a settled
  shot, then a fixed sequence of steps (UP, DOWN backwards) and turns both
  ways with shots in the middle of a step and of a turn, `pos` lines, the
  minimap and the menu thumbnail. A step into a wall does nothing. Add a
  line per floor and save to `tools/parity/cases.txt`:
  `dungeon_tour_<floor>[_start]  dungeon_tour --load=<save> --start="<Area>--<Floor>-mark0" --no-encounters`.
  `--start=<Area>--<Floor>-mark<n>` (main.bank, mode 4) starts at the n-th
  door or hinder door of the `.map` file (both count, in file order), facing
  away from it; `-save` starts at the save point.
* **`--no-encounters`** (dev only, `src/main/Main.gd`) switches random
  battles off for walks (`Labyrinth.noEncounters`; the steps are still
  counted, so the random numbers are those of a normal walk until a battle
  would start). Battles get cases of their own: `tools/autoplay/battle.txt`
  walks until one starts and fights it (`battle`: Forest Path in the rain;
  `dungeon_tunnel_battle`: no weather).
* **Hand-written cases** for what a tour does not show: a door, hinder door,
  chest, lever, save point, villager or mission of the floor (opened, pulled,
  talked to), leaving through a door (the fade-out), the menu's map page
  after a walk, entering from the world map. Plan routes with `pos` in a
  headless run:
  `Godot --headless --path . --fixed-fps 60 -- --mute --seed=1 --uncapped --load="Slot 1" --start="<Area>--<Floor>-mark0" --no-encounters --autoplay=<probe.txt>`.
  `pos` prints `node=<address> dir=<0-3> cam=<x>,<z> angle=<degrees>`.
  Directions: UP is address +1, RIGHT -16, DOWN -1, LEFT +16 (a turn LEFT
  is dir - 1). A step or a turn takes 500 ms; `tap` then `wait 700`. A
  chest, lever or villager is used from the cell before it (CROSS facing
  it); a door from its own cell, facing its wall. CROSS also closes a
  dialog, and then uses what is ahead: plan for it.
* **Saves:** "Slot 1" is late in the game (most objects of the early floors
  used), "Start" the beginning (none used). The statuses of a floor:
  `grep -i "<area>--<floor>" maps/Banks/*.sav` (database names are
  `<area>--<floor>.map<kind><cell>`, lowercase). `--status=<name>:<value>`
  sets more.
* Content quirks are kept and noted in the case's comment, not fixed (see
  `docs/ARCHITECTURE.md` section 10 for the ones met so far: the minimap's
  yellow on the objects, the sky colour on the walls, the black streaks while
  turning).
* Record the new cases a second time (`record golden2 'dungeon_*'`) and
  `compare golden golden2 'dungeon_*'`: must be identical.

## 2. Convert

```
tools/import/map_to_scene.sh "<Area>--<Floor>" ...   # or --all
```

It writes `resources/dungeon_layouts/<Area>--<Floor>.tres`, the style
(`resources/dungeon_styles/<Area>.tres`, the look most floors of the area
share; `<Area>--<Floor>.tres` for a floor whose look differs),
`resources/sprite_frames/labyrinth/<folder>/<image>.tres` (the object image
series) and `scenes/dungeons/<Area>/<Floor>.tscn`, and sets
`detect_3d/compress_to=0` in the `.import` files of the textures the floor
uses (else the editor VRAM-compresses a texture it sees on a 3D material,
which would change the legacy drawing too; the imported pixels do not
change: only a flag in the `.ctex` header does). Read its output:

* `unknown command ... ignored`: what the legacy loader ignores too (every
  file has a `mapSize` line; some an `end` line).
* `repeated link 'dir ...'`: a `dir` line given twice; the legacy loader
  counts it as a neighbour again (Frozen Forest--Forest Passage). Kept
  (`DungeonCell.extra_links`).
* `'<token>' is not an integer`, `unknown key`, `missing texture`,
  `missing image`, `on node ..., which no dir line has`: what the legacy
  loader misreads or stops on (none in the 80 files so far).

Run it twice: the second run must not change any file (hash the output
folders, or `git status`).

## 3. Check the data (step A)

```
Godot --headless --path . --script res://tools/import/verify_dungeons.gd -- --save="Slot 1" --save=Start "<Area>--<Floor>" ...   # or --all
Godot --path . --script res://tools/import/verify_dungeons.gd -- --meshes --all   # windowed: also the walls' mesh
```

Every floor must PASS with both saves. A FAIL names the field path
(`map.nodes[7].walls[1]: 1 vs 2`). `--meshes` also compiles the legacy
display list and compares it with `DungeonFloor.build`, surface by surface
and array by array. A dry run without touching the project:
`tools/import/map_to_scene.sh --data-only --out=<dir> --all`, then
`verify_dungeons.gd -- --scenes=<dir>/scenes --all`. `tools/check.sh` must
report 0 failed.

## 4. Look at it

Open the scene in the editor (the floor builds itself; objects show their
image and a label, doors their mark), or render it:

```
Godot --path . --script res://tools/import/dungeon_preview.gd -- "res://scenes/dungeons/<Area>/<Floor>.tscn" out
```

It writes `out_rig.png` (from the first door, the legacy projection) and
`out_top.png` (from above).

## 5. Parity

```
tools/parity/parity.sh record after --jobs=5; tools/parity/parity.sh compare golden after          # step A: identical
tools/parity/parity.sh ab "--legacy=dungeons" "" --ignore-world --jobs=5 'dungeon_*' battle newgame_to_forest   # step B
```

Step A must give identical shots and logs for every case. Step B, legacy
vs. scene on the floor's cases, was identical to the pixel for the pilot
(tolerance 0); a difference is a bug in the bridge code (see
`docs/ARCHITECTURE.md` section 10 for what mattered: the legacy vertices,
the walls as one instance with the display list's surfaces, the objects
batched as GLBackend batches them). The other cases: `compare golden after`,
identical.

## 6. Commit

The layouts, styles, SpriteFrames, scenes and the changed `.import` files,
the new `.uid` files, the AutoPlay scripts and cases. Keep the `.map` files
until decision 5 (plan section 13): the converter, the data check and
`--legacy=dungeons` read them.

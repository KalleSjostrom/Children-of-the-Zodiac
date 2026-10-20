# How to convert the next village

Phase 1 of `docs/MODERNIZATION_PLAN.md` (villages as scenes). The pilot,
Zazo (four `.vil` variants) and "Zazo - Miner's Home", went through steps A
and B; the conventions are in `docs/ARCHITECTURE.md` section 9. Run
everything from bash in the project root, Godot with `< /dev/null`.

## 1. Parity coverage first (on unconverted code)

1. Write an AutoPlay script for each variant (`tools/autoplay/<place>.txt`)
   and add it to `tools/parity/cases.txt`. The shots must show the fade-in,
   scrolling on both axes, the player under a roof or treetop, the particle
   systems, a dialog with a villager, entering and leaving a building, the
   menu thumbnail, and the place's cutscenes (actors moving, a dialog, any
   zoom, image mode or colour tint).
2. Plan routes with `pos` (prints the player's village position and the
   scroll) in a headless probe run:
   `Godot --headless --path . --fixed-fps 60 -- --mute --seed=1 --uncapped --load="Slot 1" --start=<Place> --autoplay=<probe.txt>`.
   The player moves 200 px/s; obstacles are inflated around the player's
   anchor (its sprite's top-left): up by 56 px, left by 27, right by 8 and
   down by 39 (`ObstacleHandler.addObstacle`), so a bridge can be a narrow
   corridor. Villagers walk: two scripts that differ by one `wait` can take
   different routes.
3. Reach variants with the shipped saves (`--load=`, statuses: `grep status
   maps/Banks/*.sav`) and `--start=`; otherwise with the dev options
   `--start-time=night` and `--status=<name>:<value>` (`src/main/Main.gd`).
   Some variants are broken content (Zazo at Night - 0 quits the game unless
   its loot is taken; the night stores have no images): note it in the case.
4. `tools/parity/parity.sh record golden <cases>`, then `record golden2
   <cases>` and `compare golden golden2 <cases>`: must be identical.

## 2. Convert

```
tools/import/vil_to_scene.sh "<Place>" ["<Place> - <interior>" ...]
```

It writes `scenes/villages/<Place>/` (base scene, one inherited scene per
`.vil` file, stitched background PNG with its `.import`) and
`resources/sprite_frames/<folder>/`. Read its output:

* `unknown command ... ignored` lines are what the legacy loader ignores too
  (typos such as `doorSignFL`, `sigin`, stray text lines). Do not fix them
  in the scene; the data check compares with the `.vil` file.
* `missing image` / `tile ... missing` lines: art the legacy code cannot draw
  either.

Run it twice: the second run must not change any file (`git status`).

## 3. Check the data (step A)

```
Godot --headless --path . --script res://tools/import/verify_villages.gd -- --save="Slot 1" --save=Start "<Place>" ...
```

Every variant and start position must PASS. A FAIL names the field path
(`doors[1].pos[0]: 332 vs 333`). `tools/check.sh` must report 0 failed.

## 4. Look at it

Open the scenes in the editor, or render them:

```
Godot --path . --debug-collisions --script res://tools/import/scene_preview.gd -- "res://scenes/villages/<Place>/<variant>.tscn" out.png 0.5
```

Check the background, the roofs and treetops, the night layer, the villager
previews and the markers (doors blue, hole doors cyan, signs green, loot
yellow, spawns white, particle emitters orange, obstacles as collision
shapes).

## 5. Parity of the drawing (step B)

```
tools/parity/parity.sh ab "--legacy=villages" "--legacy=village_top_layer" --ignore-world <cases>
tools/parity/parity.sh ab "--legacy=villages" "" --ignore-world <cases>
tools/parity/parity.sh record after <other cases>; tools/parity/parity.sh compare golden after <other cases>
```

* The first must be identical, shot for shot: the scene draws exactly what the
  legacy code draws when it keeps the legacy rule for the top layer (a piece
  only where a sprite overlaps it).
* The second (the default: the top layer always drawn, plan 6.1) differs only
  inside top-layer pieces that no sprite overlaps, where the PNG piece is
  drawn over the JPEG background. Look at every `.diff.png`; cutscenes must
  be identical (their legacy code draws every piece).
* `--ignore-world`: only the scene run logs `world=<scene>`.

## 6. Commit

The scenes, the stitched PNGs with their `.import` files, the SpriteFrames,
the new `.uid` files, the AutoPlay scripts and cases. Keep the `.vil` files
until decision 5 (plan section 13): the data check reads them.

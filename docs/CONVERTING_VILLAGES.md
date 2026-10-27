# Converting villages

Phase 1 of `docs/MODERNIZATION_PLAN.md` (villages as scenes). Every place
of `maps/Village` is converted: the pilot (Zazo, "Zazo - Miner's Home") and
the rollout (the other 61 places). The conventions are in
`docs/ARCHITECTURE.md` section 9. This is the procedure, for a place whose
`.vil` files change, a new place, or a converter change. Run everything from
bash in the project root, Godot with `< /dev/null`.

## 1. Parity coverage first (on unconverted code)

Record the cases before the change, on the code you start from
(`tools/parity/parity.sh record golden --jobs=5`), so that the goldens show
the legacy drawing.

* **Tours** (group `tour_*`, script `tools/autoplay/village_tour.txt`): one
  case per variant that a main.bank place reaches. No route per place: the
  walk goes ahead (the start facing, which points into the place), left,
  right, the menu, then back. `guard 24` lets go of a direction before the
  player would leave the place (its edge, or a hole door that opens that
  way): an interior started with `--start` has no town to go back to, and
  its exit door would load the town at start -1 (no player, errors every
  update). Add a line to `tools/parity/cases.txt`:
  `tour_<place>_<n>  village_tour --load="Slot 1" --start="<Place>" --status="<Place>:<n>" [--start-time=night]`.
* **Hand-written cases** for what a tour does not show: particle systems
  out of the tour's view (`particles_*`), cutscenes (`story_*`, script
  `story_tour.txt`: a shot every 1.5 s, CROSS every 0.5 s, up to 180 s;
  `story_prolog.txt` for the 270 s Prolog, `story_circle.txt` for Circle
  held). A cutscene starts with `--start=<story>` (its main.bank name) and
  builds its own village from the story's `info` line.
* Plan routes with `pos` (prints the player's position and the scroll) in a
  headless run:
  `Godot --headless --path . --fixed-fps 60 -- --mute --seed=1 --uncapped --load="Slot 1" --start=<Place> --autoplay=<probe.txt>`.
  The player moves 200 px/s; obstacles are inflated around the player's
  anchor (its sprite's top-left): up by 56 px, left by 27, right by 8 and
  down by 39 (`ObstacleHandler.addObstacle`), so a road can be a narrow
  corridor and lamp posts block it. Villagers walk: two scripts that differ
  by one `wait` can take different routes.
* Reach variants with the shipped saves (`--load=`; their statuses:
  `grep -i "^status <place> " maps/Banks/*.sav`), `--start=`, and the dev
  options `--status=<place>:<n>` and `--start-time=night`
  (`src/main/Main.gd`). "Slot 1" reaches Dellna 1, Parasne 1, Port of
  Alares 1, The Ship Cabin 1 and Zazo 1; "Start" The Prison Cell 1; no save
  reaches the other non-zero statuses. "Slot 2" and "Slot 3" are an older
  data version (their labyrinth nodes no longer exist: loading them asserts
  for each, 22 for "Slot 2").
  Pick a save whose party the cutscene names (`actor name="Kin"` etc.):
  "Start demon1" (Kin, Celis), "Start demon2" (+ Borealis), "Start Menthu1"
  (+ Zalzi), "Slot 1" (Kin, Celis, Zalzi).
* Places only cutscenes reach (no main.bank place): Alares - Celis,
  Dellna - Ana's Home Memory, Home of Celis - Memory, No Place (day and
  night), The Senate, The Ship Cabin - Story, Zazo - Teo (day and night).
  Dorma's Tranquility and Menthu Battle, reached by nothing (no place,
  story, door or world map node), were removed in COTZ-034.
* Content quirks are kept and noted in the case's comment, not fixed:
  "Zazo at Night - 0" asserts unless its loot is taken (Java quit the
  game); Zazo - Tent has no villager images; the night stores of Zazo name
  images that do not exist. `tickets/triage.md` lists all known quirks.
* Record the new cases a second time (`record golden2`) and
  `compare golden golden2`: must be identical.

## 2. Convert

```
tools/import/vil_to_scene.sh "<Place>" ["<Place> - <interior>" ...]   # or --all
```

It writes `scenes/villages/<Place>/` (base scene, one inherited scene per
`.vil` file, stitched background PNGs with their `.import`) and
`resources/sprite_frames/<folder>/`. Read its output:

* `unknown command ... ignored`: what the legacy loader ignores too (the
  `name` and `end` lines, typos such as `doorSignFL`, `sigin`, stray text).
  Do not fix them in the scene; the data check compares with the `.vil`
  file.
* `'<token>' is not an integer, read as 0`: a door line with `true` where
  the fade mode goes, a loot line without its directions. The legacy loader
  reads them the same way.
* `missing image` / `tile ... missing`: art the legacy code cannot draw
  either.

The art the converter writes is what `DoubleBackground` draws: the tiles of
`x<i>y<j>` up to the `as=` size (`as=1:1`: only `x0y0`), PNG tiles with
their alpha; a background without a tile folder is used as the image itself
(`cutImage2` cuts it in memory); a night variant with its own images uses
them ("<Place> at Night.jpg" / "at Nightfolder", "<Place> at Night - 1.png",
which scrolls with the village). The base scene holds the background most
variants draw; a variant with another one (Dellna2, Parasne1, Port of Alares
- With Boat, its own night image) overrides the base's `Background` node.
A background from another place's folder (No Place at Night uses Zazo -
Teo's) is stitched into that place's folder.

Run it twice: the second run must not change any file (`git status`).

## 3. Check the data (step A)

```
Godot --headless --path . --script res://tools/import/verify_villages.gd -- --save="Slot 1" --save=Start "<Place>" ...   # or --all
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
tools/parity/parity.sh ab "--legacy=villages" "--legacy=village_top_layer" --ignore-world --jobs=5 <cases>
tools/parity/parity.sh ab "--legacy=villages" "" --ignore-world --jobs=5 <cases>
tools/parity/parity.sh record after --jobs=5 <other cases>; tools/parity/parity.sh compare golden after <other cases>
```

* The first must be identical, shot for shot, except the frames of a
  cutscene zoom (the legacy tile seams and bilinear rounding; see
  `docs/MODERNIZATION_PLAN.md` 6.7 and 6.8): the scene draws exactly what
  the legacy code draws when it keeps the legacy rule for the top layer (a
  piece only where a sprite overlaps it). The scene run's log names the
  zoomed shots (`[zoom] <shot> scale=<s>`); check every other differing
  shot. Scaled cutscene images (Ending - Part 3) differ by 1/255 at most.
* The second (the default: the top layer always drawn, decision 7) differs
  only inside top-layer pieces that no sprite overlaps, where the PNG piece
  is drawn over the JPEG background. Look at every `.diff.png`; cutscenes
  must be identical (their legacy code draws every piece).
* `--ignore-world`: only the scene run logs `world=<scene>`.

## 6. Commit

The scenes, the stitched PNGs with their `.import` files, the SpriteFrames,
the new `.uid` files, the AutoPlay scripts and cases. Keep the `.vil` files
until decision 5 (plan section 13): the data check, the converter and
`--legacy=villages` read them.

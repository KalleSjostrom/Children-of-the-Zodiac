# Architecture: conventions for new code

This document is for code written during the modernization
(`docs/MODERNIZATION_PLAN.md`): scenes, resources, converters, tools and the
glue between them and the ported game. It does not replace
`docs/PORTING.md`, which still applies to the legacy code.

## 1. Two kinds of code

| | Legacy code | New code |
|---|---|---|
| What | The file-by-file port of the Java game: everything under `src/` that has a Java counterpart in `_java_reference/src/`, plus the framework files listed in PORTING.md section 1 | Scenes, resources, converters, parity tools and the scripts beside them |
| Rules | `docs/PORTING.md`: Java names (camelCase), Java structure, no redesign | This document |
| Future | Shrinks phase by phase; deleted in phase 5 | Stays |

When you change a legacy file, keep its Java names and structure. Members you
add to a legacy class *for the bridge to new code* use snake_case, so they are
recognizable as new API (`GameMode.scene_root`, `GameMode.create_scene()`,
`Main.is_legacy()`). Determinism hooks in framework files
(`J.setDeterministic`, `Scheduler.processTimers`) follow the file's existing
style.

## 2. Folder layout

```
main/Main.tscn            the tree in section 4
scenes/
  common/                 VillageDoor, VillageSign, VillageLoot, VillageSpawn, ActorView,
                          StoryImage (.tscn + .gd each), alpha_test.gdshader; Difficulty +
                          DifficultyLevel, SaveSlots (docs/DIFFICULTY.md)
  common/particles/       LegacyParticles2D (a system's slot in a village), VillageParticles2D
                          (a GPU system), the particle shaders (<class>_particle.gdshader,
                          particles.gdshaderinc, distance_fade.gdshaderinc)
  common/particles/systems/  one generated scene per system of particleSystems.info
                          (<system>.tscn, <system>_points.png for an image shape)
  villages/               VillageScene.tscn + .gd (the layout every village inherits),
                          VillageBuilding.gd (resource)
  villages/<Place>/       <Place>.tscn (shared base) + one inherited scene per .vil variant,
                          named after it ("Zazo - 0.tscn"); the stitched background PNG
  dungeons/               DungeonScene.tscn + .gd (the layout every floor inherits),
                          DungeonFloor.gd (@tool, builds the walls), DungeonLayout.gd,
                          DungeonCell.gd, DungeonStyle.gd (resources), DungeonMaterials.gd,
                          dungeon_gl.gdshaderinc (decision 2's shader), DungeonWeather.gd
                          (interim weather), DungeonQuads.gd (records legacy quads)
  dungeons/<Area>/        <Floor>.tscn, one per .map file ("The Great Mine/Tunnel.tscn")
  dungeon_objects/        DungeonObject.gd (base) and one scene per object kind:
                          DungeonChest, DungeonDoor, DungeonHinderDoor, DungeonButton,
                          DungeonSavePoint, DungeonVillager … (.tscn + .gd each)
  ui/                     Dialog.tscn, SignBox.tscn, menu pages
  debug/                  DebugConsole (built in code, added by Main in debug builds),
                          DebugCommands (registry, completion), GameCommands
resources/
  sprite_frames/<folder>/<image>.tres          (SpriteFrames per villager image set, generated)
  sprite_frames/<folder>/animobj/<name>.tres   (per animObj series, generated)
  sprite_frames/labyrinth/<folder>/<image>.tres (per dungeon object image series, generated)
  dungeon_layouts/<Area>--<Floor>.tres   (DungeonLayout, generated)
  dungeon_styles/<Area>.tres             (DungeonStyle: textures, material, light, fog, sky,
                                          weather; <Area>--<Floor>.tres for a floor whose look
                                          differs from the area's)
  difficulty/*.tres           (DifficultyLevel: the balancing of each difficulty level)
  theme/game_theme.tres
src/                      legacy code (shrinks over time)
tools/import/             converters and their checks (headless `--script`): vil_to_scene.gd
                          (+ vil_to_scene.sh), verify_villages.gd, scene_preview.gd (windowed);
                          map_to_scene.gd (+ map_to_scene.sh), verify_dungeons.gd,
                          dungeon_preview.gd (windowed); particles_to_scenes.gd (+ .sh)
tools/parity/             screenshot comparison (section 7), contact_sheet.gd
tools/bridge_test/        the phase 0 bridge test scene (dev only)
```

New scene types are named for what they are in their subsystem when the
plain name is taken by a legacy class (`Sign`, `Loot`, `Obstacle`,
`Building` and `Actor` are legacy `class_name`s): `VillageSign`,
`VillageLoot`, `VillageBuilding`. The dungeon types are all `Dungeon…`
(`Chest`, `HinderDoor`, `Riddle` and most other object kinds are legacy
`class_name`s).

A scene's script lives next to the scene and has the same PascalCase name
(`scenes/common/Door.tscn` + `scenes/common/Door.gd`, as in the plan and in
`src/`). Scripts that are not attached to a scene (headless tools,
converters) are snake_case (`tools/parity/diff_shots.gd`,
`tools/import/vil_to_scene.gd`). Generated files (`.tres` from converters) are committed like hand-made
ones; the converter that made them is the documentation of their format.

## 3. GDScript style for new code

Follow the official Godot GDScript style guide. In particular:

* **Typed everything.** Typed members, locals, parameters and return values
  (`var speed: float = 0.0`, `var nodes: Array[Node2D] = []`,
  `func cell_at(address: int) -> DungeonCell:`). Use `:=` only where the
  type is obvious from the right-hand side.
* **Names.** snake_case for functions, variables, signals and standalone
  script files; PascalCase for `class_name`, node names, scene files and the
  scripts attached to them;
  CONSTANT_CASE for constants; `_leading_underscore` for private members.
  `class_name` only for types that other code refers to by name.
* **One scene per concept.** A door, a sign, an actor, a dialog: each is its
  own scene with its own script, instanced where it is used. A scene exposes
  its configuration as `@export` properties, so it can be edited in the
  inspector, and it works when opened on its own in the editor.
* **Signals up, calls down.** A node calls methods on its children and
  emits signals for its parent (`interacted`, `opened`, `finished`). It does
  not reach up the tree (`get_parent().get_parent()…`) or into siblings.
* **Data in resources.** Content that a designer would edit (frames,
  layouts, styles, presets) goes into `.tres` resources or exported scene
  properties, not into code.
* **No `J.*` helpers.** `J` reproduces Java library semantics for the port.
  New code uses Godot's API directly: `String.split`, `Array`/`Dictionary`
  methods, `roundi`, `randi_range`, `PackedStringArray`, … The same goes for
  `JRandom`, `JColor` (use `Color`) and `StringTokenizer`. The exception
  is code that must read a legacy text format exactly as the legacy loader
  does (the converters in `tools/import/`): it uses the legacy tokenizer
  (`AbstractMapLoader`, `StringTokenizer`) and parsers (`J.parseInt`,
  `J.split`, …), so that every quirk of the format reads the same.
* **Time.** Animate and simulate with `delta` in `_process`/`_physics_process`,
  Tweens, AnimationPlayer or Timers, never by reading the wall clock
  (`Time.get_ticks_msec()`) for game logic. That keeps new code deterministic
  in parity runs (section 7) and frame-rate independent.
* **Randomness.** Use Godot's global functions (`randf()`, `randi_range()`)
  or a `RandomNumberGenerator` seeded with `randi()`. Main seeds the global
  generator in deterministic mode; do not call `randomize()`.
* `##` doc comments on every script and on public members, as in the legacy
  code.

## 4. The main scene and the bridge

```
Main (Node, src/main/Main.gd)
├── World (Node)                    the current game mode's scene, if it has one
├── LegacyLayer (CanvasLayer 1)
│   └── Canvas (Node2D)             parent of GLBackend's canvas items (all legacy 2D drawing
│                                   and the composited 3D chunks)
├── UI (CanvasLayer 2)              empty in phase 0 (Dialog, SignBox, HUD, menu pages later)
├── Transition (CanvasLayer 3)      empty in phase 0 (fades later)
├── Audio (Node, created by Main)   music and sound effect players
└── SubViewport × n (GLBackend)     the legacy 3D chunks
```

Everything a legacy `draw(g)` draws lands on `LegacyLayer`, above `World`. A
`Camera2D` in a scene under `World` moves only the default canvas, so it never
moves legacy drawing, and the legacy fade quad (`GameMode.draw` →
`fadeOldSchool`) covers the scene.

**A game mode owns a scene** (`src/organizer/GameMode.gd`):

* `func create_scene() -> Node` returns a new scene for the mode, or `null`
  (the default) for a legacy mode. Main calls it once per mode
  (`GameMode.ensure_scene()`), the first time the mode is current and has
  finished loading, so the scene can read the loaded legacy state.
* `var scene_root: Node` holds that scene. A mode may also set it while it
  loads, when the scene is its data source too (a converted village,
  section 9); `create_scene()` then returns it.
* `func shown_scene() -> Node` is the scene Main shows while the mode is
  current: `ensure_scene()` by default. A mode that presents another mode's
  scene overrides it: `VillageStory` shows its `Village`'s scene, which the
  village keeps owning (only `scene_root` is freed, so a scene has one
  owner).
* Main syncs `World` at the end of every frame (`Main._sync_world`):
  * `World` contains the current mode's `shown_scene()` only while the mode
    exists and is not loading (`isLoading()`). During the black loading
    screen nothing is shown.
  * The scene of a mode that stops being current (suspended for a store,
    the menu or a battle mode; or the previous mode) is removed from the
    tree but not freed. Its state survives; it does not get `_process`
    calls while it is out of the tree.
  * When the scene changes, the viewport's canvas transform is reset, so a
    `Camera2D` of the old scene does not leave the canvas scrolled.
* **Lifetime.** Game modes are `RefCounted` and are never freed explicitly:
  the Organizer drops them. When the last reference goes,
  `GameMode._notification(NOTIFICATION_PREDELETE)` frees `scene_root`. A mode
  stays referenced as `Organizer.previousGameMode` until the next mode
  switch, so its scene is freed one switch after the mode was left.
* **No strong references from a scene to its mode.** The mode holds its
  scene; if the scene (or anything under it, including signal connections
  with bound arguments and lambdas that capture the mode) held the mode, the
  pair would form a reference cycle that is never freed. Push data from the
  mode into the scene (the mode calls the scene's methods in its `update`),
  or keep a `WeakRef` (`weakref(mode)`) when the scene must call back.
* A scene-backed mode's `draw(g)` keeps drawing only what is not yet in the
  scene (the overlays: dialogs, emotions, fades), on `LegacyLayer`. Where it
  used to draw the rest, it now hands that state to the scene (step B,
  section 5): the scene shows what the legacy drawing would have drawn in
  that frame. Do this inside `draw(g)`, at the same point as the drawing it
  replaces, and keep every state change that drawing made (see section 9:
  a mode's `update` can run in a frame without `draw`).
* `Graphics.copyFrame` (the menu thumbnail) reads the main viewport, so it
  includes `World`.
* **A 3D scene** under `World` (a converted dungeon floor, section 10)
  renders in the main viewport with its own camera, below every
  `CanvasLayer`, so the legacy 2D overlays on `LegacyLayer` stay on top; the
  canvas transform reset touches only 2D. The frame's legacy 3D drawing
  that comes before any 2D drawing goes into that scene's 3D world instead
  of a SubViewport chunk (`GLBackend.scene_3d`, section 10): it shares the
  depth buffer and the blending with the scene, as it shared one chunk with
  the legacy walls.
* The Organizer is unchanged in phase 0: the loading gate, exit-after-fade,
  the suspended stack and the previous/current pair work as before. The
  bridge only adds and removes nodes.

## 5. Data → presentation → logic

Each subsystem is converted in three steps (plan section 3). Each step is
verified on its own before the next starts.

1. **A (data).** Move the content into scenes and resources (with a
   converter in `tools/import/`). The unchanged legacy logic reads its data
   from them instead of from the text files. Verify with a data check that
   compares the objects built both ways, for every file.
2. **B (presentation).** Replace `draw(g)` with nodes that *mirror* the
   legacy state every frame (positions, frames, scroll). The legacy objects
   stay in charge. Keep the old drawing path behind `--legacy=<subsystem>`
   and verify with screenshot parity (section 7).
3. **C (logic).** Only then make the logic idiomatic (physics, signals,
   `_process(delta)`, Tweens). This changes feel and timing, so it needs a
   decision (plan section 13) and playtesting.

Do not mix steps: a step-B change that also "fixes" logic cannot be checked
with parity.

## 6. Calling between new and legacy code

**New → legacy.** Call the legacy API by its Java names (`getPlayer()`,
`getPos()[Values.X]`, `Database.getStatusFor(name)`); see
`docs/class_map.tsv` and `docs/skeleton_report.md` for the GDScript names of
Java classes and the renamed members. Legacy values are mostly untyped and
use Java conventions (positions as `[y, x]` arrays from
`Values.createNormalPoint`, milliseconds, `JColor`). Convert them at the
boundary, in one place per subsystem (a small adapter function or the
mirroring node), into typed Godot values (`Vector2`, seconds, `Color`). Do
not rename legacy members to suit new code.

**Legacy → new.** Legacy code calls only small, documented entry points:
`GameMode.create_scene()`, `scene_root`, `shown_scene()`,
`Main.is_legacy("<subsystem>")`, `Main.bridge_test`, `Main.no_encounters`,
`MapLoader.dungeon_scene_for`, `Graphics.use_scene_3d`, `Main.hide_particles`,
`BodiesParticleSystem.gpu_path()`, the snake_case
methods of the scenes it owns (`VillageScene.load_into`, `show_*`;
`DungeonScene.load_into`, `show_floor`, `show_view`, `show_object` …) and the
difficulty (`Difficulty.scale_experience`, `scale_enemy_damage`,
`scale_ally_damage`, `start_with`, `lower_to`; docs/DIFFICULTY.md) and the
save slots (`SaveSlots`). Keep
these calls few and obvious; they are the seams that later phases cut
along. Bridge methods added to legacy classes so that new code can read
their state are snake_case too (`Sprite.place_view`,
`Graphics.alpha_threshold`, `Village.update_draw_state`,
`Inventory.place_view`, `WeatherSystem.place_particles`,
`Graphics.render_state_3d`, `BodiesParticleSystem.gpu_view`); refactors of a
legacy method's own code keep Java style (`Village.sortSprites`).

**Flags in legacy code.** A subsystem being converted keeps its old path for
parity runs:

```gdscript
func create_scene() -> Node:
	if Main.is_legacy("villages"):
		return null
	return load(scene_path).instantiate()
```

`Main.is_legacy(name)` is true when `--legacy=` lists `name` (or `all`).
Remove the flag and the old path when the phase's exit criteria are met.

## 7. Flags, determinism and the parity workflow

Game options go after `--` on the command line (see the header of
`src/main/Main.gd`):

| Flag | Effect |
|---|---|
| `--fixed-step` | The game advances exactly 1000/60 ms per frame, whatever the real frame time. |
| `--seed=<n>` | Deterministic run (implies `--fixed-step`): every random generator (`J`, every `JRandom`, Godot's global one) is seeded from `n`; `J.currentTimeMillis()`, `Scheduler` and `GameAction` read a game clock advanced by the elapsed game time instead of the wall clock; saves are read from the shipped files and written to `user://saves_deterministic/` (emptied at start), never to the player's `user://saves/`; no game pad is read (`GameCore.init2`: an idle pad releases AutoPlay's buttons every 40 ms). Two runs of an AutoPlay script then produce the same frames. |
| `--uncapped` | No 60 FPS cap and no vsync. With `--seed` the result is the same, only faster. |
| `--legacy=<a,b,…>` | Keep the legacy path of the listed subsystems (`Main.is_legacy`). `all` keeps every one. `villages`: converted places are read from their `.vil` files and drawn by the legacy code (section 9). `village_top_layer`: the scene draws a roof or treetop only where a sprite overlaps it, as the legacy code does (for parity; by default it always draws them). `dungeons`: converted floors are read from their `.map` files and drawn by the legacy code (section 10). `dungeon_drawing` (dev): floors are built from their scenes (step A) and drawn by the legacy code, for checking step A on its own. `particles`: the village and cutscene particle systems run the legacy simulation and `LegacyParticles2D` draws its quads (section 9; `villages` implies it). |
| `--hide-particles` | Dev only: the village and cutscene particle systems draw nothing, in both paths (`Main.hide_particles`; they still run), for parity runs that compare everything else. |
| `--no-encounters` | Dev only: labyrinths start no random battles (`Labyrinth.noEncounters`, which nothing else sets; the steps are still counted), for parity tours of dungeon floors. |
| `--start-node=<address>:<direction>` | Dev only: a labyrinth `--start` place starts at this node and facing (0-3), as a game saved there does (`Load.labyrinthPosition`, COTZ-005), not at its door: parity cases start in front of the object they use. |
| `--bridge-test` | Dev only: the world map shows `tools/bridge_test/BridgeTest.tscn` instead of its background tiles (section 8). |
| `--start-time=<day\|night>` | Dev only: the first place starts at this time of day (its info `time`): villages load their "at Night" variant, which no story reaches for most places. |
| `--status=<name>:<value>,…` | Dev only: Database statuses set after the save is loaded, before the first mode (`_` stands for a space), e.g. a village status for a story the shipped saves cannot reach. |

Engine option: the parity tool also passes `--fixed-fps 60` (before `--`),
which gives every node `_process` a fixed `delta` of 1/60 s and steps
SceneTree timers, Tweens and particles by it. Scene-based code (section 3,
"Time") is deterministic through this. The GPU particle systems run for the
game time their legacy system was updated for (`speed_scale` = that time
over the frame's delta), with a fixed seed drawn from the particles'
generator: with `--seed` and `--fixed-fps` two runs draw the same particles.

Normal play uses none of these flags and behaves exactly as before.

**Parity tool** (`tools/parity/parity.sh`, run from bash in the project
root). Cases (AutoPlay script + game arguments) are listed in
`tools/parity/cases.txt`; output goes to `tools/parity/out/` (ignored by git
and by Godot's importer).

```
tools/parity/parity.sh record golden --jobs=5       # all cases, current code
tools/parity/parity.sh record after 'tour_*'        # a group, after a change
tools/parity/parity.sh compare golden after         # diff images + summary
tools/parity/parity.sh ab "--legacy=villages" "" village village_walk
```

* `record <set> [case…]` runs each case windowed (screenshots need a
  renderer; never `--headless`) and keeps the shots and the log. A case
  name may be a pattern (`'tour_*'`, `'story_*'`: the groups of
  `cases.txt`). `--jobs=<n>` runs n cases at a time, each job with its own
  user data folder (`APPDATA` = `out/.userdata/<set>-job<k>`), so that the
  deterministic saves of concurrent runs do not mix; the shots are the same
  as from one job at a time (checked: Zazo's 113 shots). The keyboard still
  reaches a run's window when it has the focus (a new window takes it):
  do not type while recording.
* `compare <a> <b> [case…]` compares the shots pixel by pixel
  (`tools/parity/diff_shots.gd`, headless Godot, no Python needed) and the
  AutoPlay state lines of the logs (mode, sub mode, place; fps removed).
  It writes `out/diff-<a>-vs-<b>/summary.txt` and, for every shot that is
  not identical, a `.diff.png` (A in gray, differences over the tolerance in
  red, smaller ones in yellow). Exit code 0 means everything passed.
* `--tolerance=<0-255>` ignores per-channel differences up to that value;
  `--max-pixels=<n>` lets a shot have up to n pixels over it. Both default
  to 0: a self-diff of the legacy renderer is exact.
* `--ignore-world` compares the logs without AutoPlay's `world=<scene>`:
  in a legacy vs. scene comparison only the scene run shows a scene.
* `ab "<args a>" "<args b>" [case…]` records and compares in one go.
* AutoPlay's `pos [text]` prints the player's village position, facing and
  the background scroll (village pixels), for planning routes; in a
  labyrinth the node address, the facing and the camera's location and
  angle (`node=<a> dir=<d> cam=<x>,<z> angle=<a>`); it adds its own log
  lines and leaves the others unchanged. `loopuntil` also matches `dialog`
  while a labyrinth shows a dialog (not printed: the state lines stay
  comparable with older runs). `heading` remembers the
  player's facing for the buttons `AHEAD`, `BEHIND`, `ALEFT`, `ARIGHT`, and
  `guard <px>` lets go of a held direction before the player would leave
  the village (its edge, or a hole door that opens that way): together they
  give one walk for every village (`tools/autoplay/village_tour.txt`).
  A shot taken while a cutscene zoom is applied also prints
  `[zoom] <shot> scale=<s>` (not compared): the shots a zoom resamples,
  where the legacy drawing magnifies each 256 px tile on its own.
* `tools/parity/contact_sheet.gd` puts shots (or `.diff.png` files) side
  by side in one image, for looking at a set.

Workflow for a change that must not alter the picture:

1. Before touching the code: `record golden` (or reuse a golden set
   recorded on the commit you start from).
2. Make the change; `tools/check.sh` must report 0 failed.
3. `record after`, then `compare golden after`. Every difference must be
   explained (and is then either fixed or accepted with a written reason).

For a conversion step B, run `ab "--legacy=<subsystem>" ""` on the cases
that cover the subsystem and choose the tolerance deliberately (resampling
and blending differences are expected to be small and local; layout or
ordering differences are not).

Goldens are only valid for the machine, GPU, driver and window size they
were recorded with; record both sides of a comparison on the same machine.

## 8. The bridge test

`--bridge-test` (with `--load="Slot 1" --start=landAlares`, script
`tools/autoplay/bridge_test.txt`, parity case `bridge_test`) makes
`Landscape.create_scene()` return `tools/bridge_test/BridgeTest.tscn`: a
full-screen panel with a grid, a label counting the frames the node has
processed, and a current `Camera2D` with offset (48, 32). The world map
then skips only its background tiles; the roads, nodes, player, top layer,
node name and fades are still drawn by legacy code, on top. The script
walks a road, opens the menu (the scene leaves the tree and keeps its
state), comes back (the counter continues), enters Grivera (the fade-out
covers the scene) and opens the menu in the labyrinth: that mode switch
drops the world map, which frees the scene ("BridgeTest: freed" in the
log). It is the regression test for the bridge: run it after changing
Main, GameMode, GLBackend or the Organizer.

The test used Alares until phase 1; since every village has its own scene,
it uses the world map, which stays legacy until phase 4.1. Freeing needed a
port fix: `LandscapeLoader` kept its map loader, which refers back to it,
and that reference cycle kept every world map mode alive after it was left
(`AirLandscapeLoader` has the same cycle; not fixed, the airship has no
scene). Phase 2 found the same for the labyrinth (its graph, player and
battle refer back to it: every floor visited stayed in memory, and a
converted floor's scene with it); `Labyrinth.finishOff` (not when it is
only suspended for the menu) and the debug console's jump drop those
references. Main frees, when the game quits, the scenes of modes that are
not in the tree (suspended or previous), so the renderer reports no leaks.
Grivera--First Floor, which the test enters, is a scene since the phase 2
rollout; the test passes legacy vs. scene (plan 7.8).

## 9. Villages as scenes (phase 1)

Every place of `maps/Village` (63 places, 89 `.vil` variants) is converted
through steps A and B: the pilot (Zazo, "Zazo - Miner's Home") and the
rollout. The `.vil` files stay (decision 5): the converter, the data check
and `--legacy=villages` read them. How to convert a place again:
`docs/CONVERTING_VILLAGES.md`.

**Layout.** Every village scene inherits `scenes/villages/VillageScene.tscn`
(root script `VillageScene.gd`). Its children, in draw order:

| Node | Content |
|---|---|
| `Ground` | bottom-layer particle systems (`LegacyParticles2D`); the legacy code draws them before the tiles, so they only show through transparent parts of the background |
| `Background` | `Sprite2D`, the stitched background (`<Place>/<image>.png`, at the `offset` line's shift), or the image itself when it has no tile folder |
| `Actors` | `ActorView`s (villagers, animated objects; party members and cutscene actors are added at run time), villager-layer `LegacyParticles2D`, the cutscene `StoryImage` |
| `Overhead` | one `Sprite2D` per `top/top.info` line, in file order; the node's material is the 0.9 alpha test |
| `Night` | the night layer (`Sprite2D`, scale 2, alpha test 0); `night_screen_fixed` for `standardOvernight.png` |
| `Effects` | upper and weather `LegacyParticles2D` |
| `Obstacles` | `StaticBody2D` (collision layer and mask 0) with one `CollisionShape2D` per `o` line, not inflated |
| `Spawns`, `Doors`, `Signs`, `Loot` | `VillageSpawn`, `VillageDoor`, `VillageSign`, `VillageLoot` in file order (the first door or sign in range wins) |
| `Camera` | `Camera2D`, top-left anchor |

`<Place>/<Place>.tscn` (base) inherits the template and holds what the
variants share: the root values they agree on, the background most of them
draw, the top layer when all have the same, the obstacles all of them have
(as a multiset) and the spawns when they are identical. One scene per `.vil`
file inherits the base, named like it (`Zazo at Night - 1.tscn`), and adds
the rest; a variant that draws another background (Dellna2, Parasne1, Port
of Alares - With Boat, a night image of its own) overrides the inherited
`Background` node, and one with another top layer adds its own pieces. `VillageScene.path_for(vil)` maps a `.vil` file to its scene.
Markers (doors, signs, loot, spawns, particle emitters) draw in the editor
and with `--debug-collisions`.

**Converter** (`tools/import/vil_to_scene.gd`, run through
`tools/import/vil_to_scene.sh`): reads each `.vil` with the legacy
tokenizer and parsers, records every command into typed node properties
(text lines exactly as the legacy loader cuts them, floats as 64-bit
values), and writes:

* the art stage: the stitched backgrounds (the tiles `DoubleBackground`
  draws: `x<i>y<j>` up to the `back … as=` size, PNG tiles with their alpha;
  tile pixels as imported, saved as PNG with an `.import` file: lossless,
  no mipmaps, no alpha-border fix, kept when it already has these settings;
  a background from another place's art folder goes into that place's
  folder, so it is stitched once; a background without a tile folder is
  not copied: the scene uses the image, which `DoubleBackground.cutImage2`
  cuts in memory) and one `SpriteFrames` per villager image set (`up`,
  `right`, `down`, `left`, 4 images each, 150 ms) and per `animObj` series
  (`default`);
* Godot's import of the new images (`--import`);
* the scene stage: inherited scenes are built from a bootstrap file that
  names the base (`[node … instance=ExtResource(base)]`), instanced with an
  edit state (`PackedScene.GEN_EDIT_STATE_MAIN`) so that `pack()` keeps the
  inheritance; every node gets `owner = root`; `PackedScene.pack()` +
  `ResourceSaver.save()`. Godot 4.7 writes a random `unique_id` per node
  (and `parent_id_path`s made of them); the converter removes them, the
  node paths link the scenes as in older files. Converting twice writes the
  same files.

**Step A.** `VillageLoader.load` instantiates the variant's scene
(`VillageLoader.village_scene_for`) and `VillageScene.load_into(loader)`
builds the legacy objects from the nodes, replaying each command's legacy
semantics in the order every `.vil` file has (background, back, offset,
start, o, wind, particlesystem, then the rest): the same constructors, the
same Database reads and writes, the same random numbers. Two orders are
data in the scene: `Actors` children are the order of the legacy sprite map
(villagers, animated objects, villager-layer systems), and
`LegacyParticles2D.build_order` / `line` are the order the systems are
built in and the `particlesystem` line (one `SystemLoader` per line: the
systems of a line share its settings objects). `tools/import/verify_villages.gd`
builds each variant both ways and compares everything field by field.
`--legacy=villages` reads the `.vil` file.

**Step B.** The scene the village was built from stays its `scene_root` and
draws it; the legacy objects stay in charge.

* Where `Village.draw` drew the world, it now calls
  `update_draw_state()` (the state changes of `drawBottom` and `drawTop`:
  the sort, the villagers' `drawX`/`drawY`, the emotion bubble positions,
  the particle systems' positions, textures and particle lives, the party
  members' positions in the top-layer overlap test) and `draw_scene(g)`,
  which hands the scene `show_view`, `show_bottom`, `show_actors`,
  `show_top`. Each class's `place_view` / `place_sprite` /
  `place_particles` / `place_quad` is its `draw` without the drawing: same
  arithmetic (the legacy `int()` and `J.round` of positions), same state
  changes, and it returns what it would draw.
* This happens inside `draw`, not in `update`, on purpose: in the frame in
  which the Organizer leaves a mode, its `update` runs but its `draw` does
  not, and those state changes (smoke particles' lives, the unstable sort's
  history) must not run there either.
* `Village.SceneGLState` follows the GL state through the world drawing
  (glColor, the alpha test; particle systems leave blending on, alpha test
  0.1 and colour 1, the top layer alpha test 0) and gives each node its
  colour (`modulate`) and alpha test (`VillageScene.alpha_material`), then
  leaves the same state on `Graphics` for the legacy overlays and the next
  frame. `Graphics.alpha_threshold()` reads the current alpha test.
* `Actors` does not y-sort while it mirrors: `show_actors` orders the
  children as the legacy sort did (equal y, the special sort keys of
  particle systems and cutscene props). A sprite the legacy code draws
  twice in a frame gets a second view: a cutscene prop that the timeline
  adds to the village's layers (`addspritetobottomlayer` /
  `addspritetotoplayer`, "Arrival at the Port Town of Parasne") is drawn
  among the village's sprites and again as an actor.
* The camera's position is the negated scroll; a cutscene zoom around a
  static position is the camera zoom with position
  `-scroll + center * (1 - 1 / zoom)`. Screen-space legacy images (the
  standard night layer, cutscene images) are placed at `screen - scroll`.
* The top layer is always drawn (plan 6.1). The legacy code draws a piece
  only where a sprite overlaps it, and the pieces are not identical to the
  JPEG background under them; `--legacy=village_top_layer` keeps the
  legacy rule, so a parity run can show that everything else is identical.
* Cutscenes: `VillageStory.shown_scene()` shows the village's scene;
  `VillageStoryTimeLine.draw_scene` adds the image modes drawn under the
  actors (`StoryImage`: backflash, translucent under actor), the actors,
  the zoom and the `setFadeColor` tint. The image modes drawn over the
  emotion bubbles (cover-all, story image, village image, translucent over
  actor) stay in the legacy overlay, as do emotions, dialogs, texts and
  fades. A scaled image covers the rectangle the legacy drawing covers
  (`GameTexture.drawPart` truncates its far corner to whole pixels), so its
  scale is per axis (`VillageStoryTimeLine.image_entry`).
* A cutscene zoom resamples the frame: the legacy drawing magnifies each
  256 px tile on its own (seams show), the scene magnifies the stitched
  background, so zoomed frames differ by bilinear rounding (plan 6.7, 6.8).
  After a zoom out the scale stays 1.00007, so the rest of such a cutscene
  differs slightly too; AutoPlay's `[zoom]` lines name these shots.
* Particle systems: see "Particles" below.

**Particles (the particles phase, plan 6.10).** Every system of
`maps/ParticleSystems/particleSystems.info` is a generated scene,
`scenes/common/particles/systems/<system>.tscn` (how to regenerate and tune
them: `docs/CONVERTING_PARTICLES.md`; the `.info` file stays the source):

```
<system> (VillageParticles2D: GPUParticles2D, local coordinates, amount, lifetime,
│         preprocess, texture, CanvasItemMaterial ADD for additive systems; process
│         material: the particle class's shader with the system's settings as uniforms)
├── Background (Sprite2D)       a background= image, drawn behind the particles
└── <slave> (VillageParticles2D) a master/slave emitter's slave system (Pass to Zazo)
```

* Shaders (`shader_type particles`), one per particle class:
  `fire_particle`, `rainbow_particle` (both `distance_fade.gdshaderinc`),
  `smoke_particle`, `snow_particle`, `star_particle`, with the shapes, the
  emit force and the random numbers in `particles.gdshaderinc`. Each runs
  its class's legacy laws, every per-step law as a per-second rate at the
  legacy 30 steps a second (decision 6), integrated with each frame's
  delta; `start()` also does the emission's own step. Image shapes emit
  from baked points (the legacy alpha raster, `<system>_points.png`).
* The generator, `tools/import/particles_to_scenes.gd`, reads the file
  through `SystemLoader` and the legacy classes; it estimates each system's
  lives by stepping single legacy particles and takes the rate both legacy
  limits allow (the emitter's time step and the pool of `nrParticles`):
  `amount = rate × lifetime`.
* Step B. The legacy objects stay in charge: `VillageScene.load_into`, the
  `.vil` loader and the cutscene timeline build the same
  `BodiesParticleSystem`s (which systems, layers, start state and
  activation status, the sort key `getY`, the emitter a cutscene actor
  moves, the emitter fade of a timeline event). On the GPU path
  (`BodiesParticleSystem.gpu_path()`: not `--legacy=particles` or
  `--legacy=villages`) a system builds no bodies and runs no simulation:
  `update` adds the game time (`gpu_run`: also the emitter's clock,
  `AbstractEmitter.advance`, and the shared wind's turbulence,
  `WindCommand.drift`), `warmUp` and the master/slave warm-up add warm-up
  time (`gpu_warm`), and `place_particles`, where the legacy draw would draw,
  returns the state (`gpu_view`). `LegacyParticles2D.show_systems` instances
  the system's scene (by its definition's name, also for cutscene actors'
  runtime nodes), places it so that its local coordinates are the legacy body
  coordinates (the village's origin, or the screen's for stars and cutscene
  actors, whose particles the legacy draws in screen space) and hands it the
  state (`VillageParticles2D.show_state`): it runs for that game time, starts
  with the legacy warm-up as `preprocess` (a warm-up shape: to the steady
  state), follows the emitter's position and time step and the wind, and
  hides while the legacy system is inactive. The village's GL state
  (`Village.SceneGLState`) changes as before: an active system's view is
  not empty.
* `--legacy=particles` keeps the legacy simulation and `LegacyParticles2D`'s
  quads; `--hide-particles` hides both paths.

## 10. Dungeons as scenes (phase 2)

All 80 floors of `maps/Labyrinth` are converted through steps A and B: the
pilot (Forest of Reil--Forest Path and --Deep Forest, The Great Mine--Tunnel;
plan 7.7) and the rollout (the other 77; plan 7.8). The `.map` files stay
(decision 5): the converter, the data check and `--legacy=dungeons` read
them. How to convert a floor again: `docs/CONVERTING_DUNGEONS.md`.

**Layout.** Every floor scene, `scenes/dungeons/<Area>/<Floor>.tscn`,
inherits `scenes/dungeons/DungeonScene.tscn` (root script
`DungeonScene.gd`):

| Node | Content |
|---|---|
| `Layout` | `DungeonFloor` (`@tool`): builds the walls, floors and roofs from its `DungeonLayout` and the style's textures with SurfaceTool, in the editor and at run time; one instance, one surface per material in the legacy display list's order; on a floor with a sky also `Sky` (top level, in the camera's space: renderSky's gradient, drawn first) |
| `Environment` | `WorldEnvironment`: the clear colour background, linear tonemapping, as GLBackend's chunks; no Godot fog or light (the dungeon shader does them) |
| `Objects` | the `inv` lines in file order, one `DungeonObject` scene per line (`scenes/dungeon_objects/Dungeon<Kind>.tscn`): the order the legacy loader created them in (door indices, links, Database reads) |
| `Weather` | `DungeonWeather`: the rain or snow, interim |
| `Rig` / `Camera` | `Camera3D`, fov 45, near 1, far 75, keep height (GLBackend's projection); in the editor at the first door (mark 0) |

The root exports `map_name` (the `.map` name the Database names start
with), `style`, `steps_to_battle` (min, max), `battle_music`, and the
mission (`has_mission`, `mission_kind`, `mission_name`, `mission_entries`
as MapLoader keeps them). Units are the legacy dungeon units: 4 per cell, a
cell's centre at `DungeonCell.center` (x = address / 16 · 4 + 2, z =
(address % 16 − 15) · 4 − 2), floors at y −2, roofs at +2.

* `DungeonLayout` (`resources/dungeon_layouts/<Area>--<Floor>.tres`): the
  `size` and `mapPos` lines, and the cells in the legacy node order (first
  appearance in the `dir` lines): `DungeonCell` with its address, the
  neighbour in each direction, the texture slot of each wall (−1: none),
  the floor and roof slots, the carpet (slot, rotation) and `extra_links`
  (repeated `dir` lines, which the legacy loader counts as neighbours).
  These are the values after the whole parse (mapEnd's sort, the `wall`,
  `floor` and `roof` lines, the pillar walls' slots).
* `DungeonStyle` (`resources/dungeon_styles/`): the texture slots (names as
  the `.map` writes them, and the textures), the slot ranges of the five
  passes, the carpet and pillar flags, light0 and light1, material and
  invMaterial (parsed, never applied by the legacy code), fog, sky, the
  enemy colour and the weather flags. Floors of an area share a style where
  all these agree (`<Area>.tres`: the look most floors of the area have, ties
  to the first by name); a floor that differs has `<Area>--<Floor>.tres`.
  Colours and vectors are float32; the `.map` values have at most 4
  decimals, so `DungeonStyle.legacy_float` reads them back as the float64
  the legacy loader parsed.
* Objects: `DungeonObject` (base) exports `kind` (the `.map` command:
  `door--up` …), `cell`, `facing` (the legacy `Inventory.dir`), `image` and
  `database_name` (`<map>.<kind><cell>`, lowercase: saves, links across
  floors, the console and AutoPlay use it); each kind's script exports its
  legacy constructor's arguments, typed (frames, contents, next places,
  village start, hinders, dialogs …); doors and hinder doors export their
  `mark` (door index). A `View` (AnimatedSprite3D with the image series'
  SpriteFrames, `resources/sprite_frames/labyrinth/`) shows the object in
  the editor; labels mark kinds, cells and marks.

**Converter** (`tools/import/map_to_scene.gd`, through `map_to_scene.sh`):
reads each `.map` with a subclass of MapLoader itself (`MapReader`:
MapLoader parses, the reader records the `inv` lines and their legacy
objects, the enemy colour and the warnings), so every value is the legacy
loader's; parses each `inv` line's tokens as `Inventory.createInventory`
consumes them into the kind's exports; computes the area's shared style
from all its `.map` files; writes the layout, style, SpriteFrames and the
inherited scene (bootstrap file, edit state, `unique_id`s removed: as the
village converter, section 9); sets `detect_3d/compress_to=0` in the used
textures' `.import` files. Converting twice writes the same files.

**Step A.** `MapLoader._init` asks `dungeon_scene_for(name)` (null with
`--legacy=dungeons` or for a floor without a scene; the converter's and the
data check's subclasses override it) and lets the scene fill it
(`DungeonScene.load_into`): the nodes in the layout's order with their
links, walls, floors, roofs and carpets; the textures, slot ranges
(`MapLoader.textureNorm`), settings and values from the style; steps,
battle music, mission; the static enemy colour when the floor sets one and
`PillarWalls.node`; then each object's `create_inventory` in file order (the
same constructor with the same arguments, the same database name and status
reads). This covers `Labyrinth.init` and Load's saved floor maps (`labmap`).
`tools/import/verify_dungeons.gd` builds each floor both ways and compares
everything field by field (also the Graph, the renderer, the weather
system, the mission and the Database afterwards); `--meshes` also compares
the walls' and the sky's meshes with the legacy display list's parts.
`--legacy=dungeon_drawing` (dev) keeps the legacy drawing of floors built
from their scenes, so that a parity run checks step A on its own.

**Step B.** `Labyrinth.create_scene()` returns a new instance of the floor's
scene (null with `--legacy=dungeons`); `Labyrinth.draw` asks for it in the
floor's first frame (`ensure_scene`), before Main adds it to `World`. Where
`draw` drew, it now hands the scene what that drawing would have drawn:

* the first frame: `init_scene_3d` instead of `init3D`: the same GL state
  (lights, material, fog, the clear colour, the textures, and what the
  display list's compile leaves: current colour, normal, texture coordinate
  and texture, the enabled caps), the objects' and minimap's set-up; the
  scene builds the walls in the GL state the list would have been compiled
  in (`show_floor` → `DungeonFloor.build`). No display list.
* every frame: `show_scene`: `Graphics.use_scene_3d` (the 3D bridge, below),
  `show_view` with the legacy modelview (`Camera.lookAt`: the interpolated
  position and angle, the battle's shake), and `Graph.show_inventory`: each
  object's draw without the drawing (`place_view`: the same checks and GL
  state changes; `HinderDoor` reads its status there, a save point moves its
  particles there), handed to the scene in the legacy draw order. No
  `Graph.drawInventory`.
* the weather: `WeatherSystem.place_particles` (draw without the drawing:
  the same GL state changes, the front list, the particles' cached view
  values) for the back pass and, unless a battle or riddle runs, the front
  pass; over a battle the legacy front pass draws (into the scene, after the
  battle, as before).

Decisions that make the scene draw the legacy pixels to the bit (legacy
vs. scene: identical at tolerance 0 on every pilot case, and on 2,962 of
the rollout's 3,046 dungeon shots; the other 84 differ by 1/255 at most,
plan 7.8):

* Decision 2: the dungeon shader (`dungeon_gl.gdshaderinc`) is GLBackend's
  spatial shader with material uniforms; `DungeonMaterials` makes its
  render-mode variants from GL render states and sets the uniforms from the
  style as `addLight`, `setMaterial` and `addFog` set the GL state.
* The camera stays at the origin and `Layout` and `Objects` get the legacy
  modelview as their transform, as GLBackend draws (its SubViewport camera
  at the origin, the display list with the modelview): the walls go through
  Godot's own transform with the same matrices, and the eye-space meshes
  (the legacy batches, the objects' quads, the weather) need a camera at
  the origin to be drawn as they are. A camera moving by the inverse view
  would round both differently. Step C turns this around.
* The walls are one instance with the display list's surfaces (one instance
  per surface drew some pixels differently: the order Godot's unstable sort
  gives equal-depth surfaces then changes). That order still decides where
  two of them blend: before the rollout's fix of the look (below) the walls
  of the floors with a translucent sky were drawn at alpha 0.8 and the sky
  quad without depth test was one of them, and the two paths differed by up
  to 111/255 there (plan 7.8). The sky is now an instance of its own, drawn
  first, and the walls are opaque.
* Objects draw the legacy quads: `DungeonQuads` stands in for Graphics in
  the legacy geometry code (`Inventory._drawQuad`, `LabyrinthNode.drawOneWall`
  and `drawOneFloor`), records the vertices and passes the state on; their
  eye-space vertices are drawn at the origin. A hinder door lies in its
  wall's plane, and which shows is decided by depth rounding: Sprite3D's
  own vertices lost that z-fight in some turns (the door vanished). The
  quads are batched as GLBackend batches them (a quad with the previous
  one's material extends that batch): one instance per object changed some
  wall pixels by 1/255 (the Tunnel with the "Start" save; the mechanism in
  the renderer was not found). So at run time the Views only mirror their
  frame and stay hidden.
* The weather and the save point's particles are eye-space meshes drawn at
  the origin, one per pass (and per save point) and frame.

The look follows OpenGL 2, in both paths (fixed in the phase 2 rollout,
plan 7.5 and 7.8; until then GLBackend multiplied lit vertices by the
current glColor and baked the sky into the walls' world space):

* A lit vertex takes the material's colours and its diffuse alpha, not the
  current colour (OpenGL 2 ignores glColor while lighting is on unless
  `GL_COLOR_MATERIAL` is enabled, which the original never does): GLBackend's
  spatial shader and `dungeon_gl.gdshaderinc` alike. Objects are no longer
  tinted by the minimap arrow's yellow, the walls of a floor with a sky no
  longer take its bottom colour (Deep Forest's are opaque: no walls seen
  through walls; Empyrian Temple--Dark's are not black). Lighting is on only
  while a labyrinth draws its walls and objects and in the Demolish card's
  lit spheres (`SphereParticleSystem`), so nothing else changed.
* A display list records the matrix calls: what follows a glLoadIdentity
  inside the list is in eye space when the list is called
  (`Graphics.DisplayList.parts`). renderSky's gradient fills the top of the
  view behind the walls, as in the original.
* Still not emulated: the specular term (Fire Cavern--Blazing Maze and the
  Grivera floors have a specular light and material, a highlight of up to
  0.2 is missing), and the black streaks while turning in the rain (not
  explained).

**The 3D bridge.** While a dungeon scene is shown, `GLBackend.scene_3d` (set
by `Graphics.use_scene_3d`, cleared every frame) makes the frame's first 3D
chunk, when nothing 2D was drawn before it, a `SceneChunk`: its batches are
MeshInstance3D children of the scene's `Legacy` node, with GLBackend's
materials, drawn after the scene's instances (sorting offsets from 1e6). So
the legacy 3D of a labyrinth frame (a battle, the weather's front pass over
it, the minimap, drawn with the depth test off) shares the depth buffer and
the linear blending with the scene, as it shared one SubViewport with the
walls. Composited as a separate transparent SubViewport it would blend in
sRGB over the scene (the minimap's disk darker) and the battle would lose
the walls' depth. Later 3D chunks (after 2D) stay SubViewports.

**Lifetime.** The scene is the Labyrinth's `scene_root` and is freed with
it; the Labyrinth is freed since phase 2 (section 8). Each logs it
(`Labyrinth: freed <floor>`, `DungeonScene: freed <floor>.map`): a floor
left is freed at the next mode switch (it stays the Organizer's previous
mode until then); Main frees the scene of the floor still current when the
game quits.

**Objects in the rollout.** Every kind of `inv` line is a `DungeonObject`
scene; how each is used, from where, and what the rollout's cases show of
it, is in `docs/CONVERTING_DUNGEONS.md`. Riddles draw nothing in 3D (their
`draw` is empty): all of a riddle is its top layer, 2D after the minimap,
so the front weather pass before it stays in the scene's chunk. A boss
battle runs inside the labyrinth's frame (`Labyrinth.enterBattle`, its sub
game mode); what a boss leads to after the win (another boss's
`BossBattleArea`, a story, the world map) is a mode of its own.

**Still legacy** in Labyrinth's frame: the minimap (`MapRenderer`, 3D, in
the scene's chunk), the mission display, dialogs and card info, the top
layer (tutorials), the fade; battles and riddles (`labDrawable`); the
weather and save point simulations (GDScript).

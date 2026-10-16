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
  common/                 Door.tscn, Sign.tscn, Loot.tscn, ActorView.tscn, particles/*.tscn
  villages/<Place>/       <Place>.tscn (shared base) + one inherited scene per .vil variant
  dungeons/<Area>/        <Floor>.tscn
  dungeon_objects/        Chest.tscn, Door.tscn, HinderDoor.tscn, Lever.tscn, SavePoint.tscn …
  ui/                     Dialog.tscn, SignBox.tscn, menu pages
resources/
  sprite_frames/<Name>.tres   (SpriteFrames, generated)
  dungeon_layouts/*.tres      (DungeonLayout, generated)
  dungeon_styles/*.tres       (textures, materials, light, fog per area)
  theme/game_theme.tres
src/                      legacy code (shrinks over time)
tools/import/             converters (headless `--script`)
tools/parity/             screenshot comparison (section 7)
tools/bridge_test/        the phase 0 bridge test scene (dev only)
```

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
  `JRandom`, `JColor` (use `Color`) and `StringTokenizer`.
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
* `var scene_root: Node` holds that scene.
* Main syncs `World` at the end of every frame (`Main._sync_world`):
  * `World` contains the current mode's `scene_root` only while the mode
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
  scene (the overlays: dialogs, emotions, fades), on `LegacyLayer`.
* `Graphics.copyFrame` (the menu thumbnail) reads the main viewport, so it
  includes `World`.
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
`GameMode.create_scene()`, `scene_root`, `Main.is_legacy("<subsystem>")`,
`Main.bridge_test`, and the snake_case methods of the scenes it owns
(called from the mode's `update`). Keep these calls few and obvious; they
are the seams that later phases cut along.

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
| `--seed=<n>` | Deterministic run (implies `--fixed-step`): every random generator (`J`, every `JRandom`, Godot's global one) is seeded from `n`; `J.currentTimeMillis()`, `Scheduler` and `GameAction` read a game clock advanced by the elapsed game time instead of the wall clock; saves are read from the shipped files and written to `user://saves_deterministic/` (emptied at start), never to the player's `user://saves/`. Two runs of an AutoPlay script then produce the same frames. |
| `--uncapped` | No 60 FPS cap and no vsync. With `--seed` the result is the same, only faster. |
| `--legacy=<a,b,…>` | Keep the legacy path of the listed subsystems (`Main.is_legacy`). `all` keeps every one. Unused in phase 0. |
| `--bridge-test` | Dev only: villages show `tools/bridge_test/BridgeTest.tscn` instead of their background tiles (section 8). |

Engine option: the parity tool also passes `--fixed-fps 60` (before `--`),
which gives every node `_process` a fixed `delta` of 1/60 s and steps
SceneTree timers, Tweens and particles by it. Scene-based code (section 3,
"Time") is deterministic through this.

Normal play uses none of these flags and behaves exactly as before.

**Parity tool** (`tools/parity/parity.sh`, run from bash in the project
root). Cases (AutoPlay script + game arguments) are listed in
`tools/parity/cases.txt`; output goes to `tools/parity/out/` (ignored by git
and by Godot's importer).

```
tools/parity/parity.sh record golden               # all cases, current code
tools/parity/parity.sh record after                # after a change
tools/parity/parity.sh compare golden after        # diff images + summary
tools/parity/parity.sh ab "--legacy=villages" "" village village_walk
```

* `record <set> [case…]` runs each case windowed (screenshots need a
  renderer; never `--headless`) and keeps the shots and the log.
* `compare <a> <b> [case…]` compares the shots pixel by pixel
  (`tools/parity/diff_shots.gd`, headless Godot, no Python needed) and the
  AutoPlay state lines of the logs (mode, sub mode, place; fps removed).
  It writes `out/diff-<a>-vs-<b>/summary.txt` and, for every shot that is
  not identical, a `.diff.png` (A in gray, differences over the tolerance in
  red, smaller ones in yellow). Exit code 0 means everything passed.
* `--tolerance=<0-255>` ignores per-channel differences up to that value;
  `--max-pixels=<n>` lets a shot have up to n pixels over it. Both default
  to 0: a self-diff of the legacy renderer is exact.
* `ab "<args a>" "<args b>" [case…]` records and compares in one go.

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

`--bridge-test` (with `--load="Slot 1" --start=Alares`, script
`tools/autoplay/bridge_test.txt`, parity case `bridge_test`) makes
`Village.create_scene()` return `tools/bridge_test/BridgeTest.tscn`: a
full-screen panel with a grid, a label counting the frames the node has
processed, and a current `Camera2D` with offset (48, 32). The village then
skips only its background tiles; sprites, roofs and treetops, the particle
systems, emotions, dialogs and fades are still drawn by legacy code, on top.
It is the template for phase 1's village scenes and the regression test for
the bridge: run it after changing Main, GameMode, GLBackend or the
Organizer.

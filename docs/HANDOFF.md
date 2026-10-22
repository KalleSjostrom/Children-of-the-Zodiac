# Handoff: state of the Godot port (2026-10-22, after steps 1–3, modernization phase 0, phase 1 steps A and B, and phase 2 steps A and B)

Conventions: legacy (ported) code follows `docs/PORTING.md`; new code
(scenes, resources, tools, bridge) follows `docs/ARCHITECTURE.md`. The
modernization plan is `docs/MODERNIZATION_PLAN.md`.

## Done

**Source decision.** The downloaded `Children-of-the-Zodiac-master` is an
unfinished refactor (its last commits say "THIS DOESN'T COMPILE"). The port
uses the first commit `a28bc8b` of github.com/KalleSjostrom/Children-of-the-Zodiac,
the last version that ran (OpenGL 2). Its Java source is in
`_java_reference/src/` (UTF-8, ignored by Godot); its assets are in `res/`,
data files in `maps/` (all imported, `file_index.txt` indexes them).

**Framework (hand written, tested):**
- `src/graphics/Graphics.gd` + `GLBackend.gd`: OpenGL 2 emulation (immediate
  mode, matrix stack, glColor/blend/alpha test/depth/cull, lights, fog, display
  lists, gluDisk/gluSphere, original text API with the game's TTF fonts).
  2D → ordered canvas items, 3D → SubViewports with gluPerspective(45, 4/3, 1, 75).
- `GameTexture`, `ImageHandler`, `GraphicHelp`, `ImageGraphics`, `JColor`,
  `Utils3D`, `Object2D`, `TimeHideable`, `battle/Hideable`, `src/organizer/*`,
  `src/input/*`, `src/sound/*`, `src/info/{Values, BattleValues, SoundMap}`,
  `src/story/Fadeable`, `src/util/*`, `src/main/{Main, AutoPlay}.gd`.

**Step 1, package ports: complete.** All 334 classes are ported; no file
starts with `## SKELETON`. Each unit's notes are in `docs/port_notes/<unit>.md`
(factories-landscape, particles-system, particles-bodies, villages, story,
menu, labyrinth, inventory-weather, battle-core, battle-parts, battle-actors,
cards-magic, cards-store; cheater-minigames was ported earlier without notes).

**Step 2, integration: complete.** `tools/check.sh` → `CHECKED 375 scripts,
0 failed`. Cross-unit call sites were checked with new static checks
(`tools/port/calllint.py`, `superinit.py`, `staticinit.py`, `constcheck.py`),
all at 0 issues. Details, fixes and two GDScript-vs-Java pitfalls
(constructors do not chain implicitly; static init runs at load) are in
`docs/port_notes/integration.md`.

**Step 3, runtime testing: main paths work.** Title → new game → story →
first labyrinth, villages, random battles with result screens, a boss battle,
world map, airship, all menu pages, all four building types, a village story,
the game over screen and save/load all run without script errors
(screenshots checked). The test
matrix and commands are in `docs/port_notes/integration.md`; the scripts are
in `tools/autoplay/`.

**Modernization phase 0 (groundwork): done** (`docs/MODERNIZATION_PLAN.md`
section 5; conventions and workflow in `docs/ARCHITECTURE.md`):
- Deterministic runs: `-- --seed=<n>` seeds `J`, every `JRandom` and Godot's
  global generator from one seed; `J.currentTimeMillis()`, `Scheduler`
  (`after`, `sleep`), `GameAction` (key repeat) and `GameCore.enterCheat`
  read a game clock advanced by Main's elapsed time; it implies
  `--fixed-step`; saves come only from the shipped files and go to
  `user://saves_deterministic/`. `--uncapped` drops the 60 FPS cap.
- Parity tool `tools/parity/parity.sh` (+ `diff_shots.gd`, `cases.txt`):
  record AutoPlay screenshot sets, compare them pixel by pixel and compare
  the AutoPlay state logs. Goldens of all 10 cases (176 shots) are in
  `tools/parity/out/golden` (git-ignored; machine specific). A second run
  (`golden2`) and the run after the bridge (`after`) are identical to them,
  shot for shot and log for log.
- Bridge: `main/Main.tscn` is `Main` (Node) → `World`, `LegacyLayer`
  (CanvasLayer 1) / `Canvas` (GLBackend's canvas items), `UI` (2),
  `Transition` (3). `GameMode.create_scene()` / `scene_root`; Main shows the
  current mode's scene under `World` while it is not loading, removes it
  (without freeing) when the mode is suspended or left, and `GameMode` frees
  it in `NOTIFICATION_PREDELETE`. `--legacy=<a,b>` + `Main.is_legacy()` are
  in place for later phases (unused).
- Bridge test: `--bridge-test` + `tools/autoplay/bridge_test.txt` (parity case
  `bridge_test`) shows `tools/bridge_test/BridgeTest.tscn` instead of the
  world map's background tiles (Alares until the phase 1 rollout), through
  fade-in, walking a road, the menu (thumbnail), entering a labyrinth and
  the menu there (the scene is freed at that mode switch).

**Modernization phase 1 (villages as scenes): steps A and B done** for all
63 places and 89 `.vil` variants: the pilot (Zazo, "Zazo - Miner's Home",
plan 6.7) and the rollout (the other 61 places, plan 6.8); conventions in
`docs/ARCHITECTURE.md` section 9, the procedure in
`docs/CONVERTING_VILLAGES.md`:
- Scenes: `scenes/villages/VillageScene.tscn` (layout), one folder per place
  in `scenes/villages/` (base + one inherited scene per `.vil`, stitched
  background PNGs), shared types in `scenes/common/`, SpriteFrames in
  `resources/sprite_frames/`. Made by `tools/import/vil_to_scene.sh --all`
  (deterministic: converting twice changes no file).
- Step A: `VillageLoader.load` builds every place from its scene
  (`VillageScene.load_into`); `tools/import/verify_villages.gd --all` with
  the saves "Slot 1" and "Start": 240 builds, all pass.
- Step B: the scene draws the world (background, actors, top layer, night,
  particles via `LegacyParticles2D`), also in cutscenes (camera zoom, tint,
  under-actor images); emotions, dialogs, signs, fades and the over-actor
  cutscene images stay legacy overlays. `--legacy=villages` keeps the old
  path; `--legacy=village_top_layer` the legacy top-layer rule. Parity:
  identical except cutscene zooms (tile seams, rounding) and, by default,
  the always-drawn top layer (decision 7); plan 6.8.
- Parity coverage: 117 cases (`tools/parity/cases.txt`): the 17 older ones,
  a tour of every variant a main.bank place reaches (`tour_*`), four
  particle cases and 24 cutscenes (`story_*`). `parity.sh --jobs=<n>` and
  case patterns make a full run about 40 minutes.
- The `.vil` files stay (decision 5); closing the phase is prepared in plan
  6.9 (what removing the legacy village path deletes, and what keeps the
  exit criteria from being met).
- Dev options: `--start-time=night`, `--status=<name>:<value>`, AutoPlay
  `pos`, `heading`, `guard`, the relative buttons `AHEAD`/`BEHIND`/`ALEFT`/
  `ARIGHT`, `[zoom]` lines; parity `--ignore-world`, `--jobs`; `--seed` runs
  read no game pad; `tools/check.sh` also compiles `scenes/` and `tools/`.

**Modernization phase 2 (dungeons as scenes): steps A and B done** for all
80 floors of `maps/Labyrinth`: the pilot (Forest of Reil--Forest Path and
--Deep Forest, The Great Mine--Tunnel; plan 7.7) and the rollout (the other
77; plan 7.8); conventions in `docs/ARCHITECTURE.md` section 10, the
procedure in `docs/CONVERTING_DUNGEONS.md`:
- Scenes: `scenes/dungeons/DungeonScene.tscn` (layout: `Layout`
  (`DungeonFloor`, builds the walls and, on a floor with a sky, the `Sky`),
  `Environment`, `Objects`, `Weather`, `Rig/Camera`), one inherited scene
  per floor in `scenes/dungeons/<Area>/`, one scene per object kind in
  `scenes/dungeon_objects/`, layouts in `resources/dungeon_layouts/`, styles
  in `resources/dungeon_styles/` (20 area styles, 23 floors with their
  own), SpriteFrames in `resources/sprite_frames/labyrinth/`. Made by
  `tools/import/map_to_scene.sh --all` (deterministic; 134 warnings, none an
  error, among them 10 hinder door links with a NUL byte in their `.map`
  line).
- Step A: `MapLoader` builds every floor from its scene
  (`DungeonScene.load_into`), also for Load's saved floor maps;
  `verify_dungeons.gd --all` with "Slot 1" and "Start": 160 builds pass,
  `--meshes` 80. `--legacy=dungeon_drawing` (dev) checks step A on its own:
  identical to the golden.
- Step B: the scene draws the walls, objects, save point particles and the
  weather (the legacy simulation's quads); the 3D bridge
  (`GLBackend.scene_3d`) draws the labyrinth's legacy 3D (battles, the front
  weather pass over them, the minimap) into the scene's World3D.
  Legacy vs. scene on the 226 cases through floors: all logs identical,
  2,962 of 3,046 shots identical, the others within 1/255 (Godot's
  rounding where legacy drawing blends over the floor; plan 7.8).
  `--legacy=dungeons` keeps the old path.
- The look follows OpenGL 2 in both paths since the rollout: a lit vertex
  ignores glColor (no walls seen through walls in Deep Forest, Empyrian
  Temple--Dark's walls not black, objects not yellow) and renderSky's
  gradient fills the top of the view (the emulated display list records its
  glLoadIdentity). Still missing: the specular term.
- Fixed on the way: the Labyrinth game mode leaked (pilot); COTZ-010 had
  made every ladder unusable (rollout: a ladder is climbed from the cell
  before it again). Each floor left logs `Labyrinth: freed` and
  `DungeonScene: freed`.
- The weather bridge (`WeatherSystem.place_particles`) is about 20 %
  cheaper (rollout): Forest Path 33 → 36 FPS, Ice Cavern--Frozen Field 41
  → 47.
- Parity coverage: 336 cases (`tools/parity/cases.txt`, 5,690 shots): the
  205 new `dungeon_*` cases are a tour of every floor with both saves and 53
  hand-written cases (doors and floor changes, every object kind, riddles of
  every class, battles under snow and rain and with enemy colours, bosses,
  saving and loading on a floor, the console). Dev options: `--no-encounters`,
  `--start-node=<address>:<direction>`, AutoPlay `pos` in labyrinths and
  `loopuntil … dialog`, `tools/parity/contact_sheet.gd`.
- Closing the phase is prepared in plan 7.9 (what removing the legacy
  dungeon path deletes, and what keeps the exit criteria from being met).

## Plan (what is left)

0. **Modernization:** closing phase 1 (plan 6.9) needs decision 5 (delete
   the `.vil` files) and the removal of the legacy village path; GPU
   particle presets need decision 6 (time base). Closing phase 2 (plan
   7.9) needs decision 5 and the 1/255 tolerance accepted; the weather and
   the save points stay the legacy simulation until decision 6. Phase 3 can
   start. Record goldens before each change.

1. **Performance (top priority):** labyrinths with rain/snow run at 36–48
   FPS with the scene (Forest Path 36, Ice Cavern--Frozen Field 47; 10 000
   weather particles per frame through GDScript in `src/weather`: in Forest
   Path the simulation takes ≈10 ms of a frame and placing the back pass's
   quads ≈9 ms since the rollout, ≈11 ms before; plan 7.7, 7.8). Loading
   the largest floor takes ≈180 ms with the scene, 5 ms from its `.map`
   (plan 7.8).
   Villages: Dellna's snow
   runs at 12 FPS in the legacy path and 18 with the scene, Home of the Gods
   at 6 FPS once its 12 god systems are active (the GDScript particle
   simulation; plan 6.8). The other villages measured run at 60 FPS.
   Per-frame fades assume 60 FPS. Options: GPU particles for the weather
   (decision 6), or a faster simulation and view test (the per-particle
   loops of `WeatherSystem.update` and `_place_pass`). Measure with the `fps=` value
   that AutoPlay prints with every `log`/`shot`, in normal runs.
2. **More runtime coverage:** level-up screen, riddle mini-games
   (`src/miniGames`), buying/selling/merging cards, inn rest, the later
   chapters and their bosses. Compare look and timing with the original
   logic.
3. **Polish (former step 4):** fades at 60 FPS, music transitions (all tests
   so far ran with `--mute`), saves in `user://saves/`, export (install the
   4.7 templates; `export_presets.cfg` already includes `maps/*`).

## Useful facts

- Godot: `C:\Users\c06ks\Work\Godot\Godot_v4.7-stable_win64_console.exe`.
- `tools/check.sh [paths]`: import pass + compile (default: `src/`, `scenes/`,
  `tools/`), prints only errors (locked for concurrent use). Run Godot with
  `< /dev/null` from bash.
- Run a test: `Godot --path . -- --mute [--load="Slot 1"] [--start=<place>]
  --autoplay=tools/autoplay/<script>.txt --shots=<dir>` (add `--headless` for
  a run without screenshots). AutoPlay prints `mode=<game mode> sub=<battle>
  battlemode=<n> enemies=<names> place=<place> fps=<n>` at every `log`/`shot`;
  scripts can loop (nested) with `mark` … `loopuntil [!]<text> <ms>` (see the
  header of `src/main/AutoPlay.gd` and `tools/autoplay/battle.txt`).
- Use the shipped `Slot 1` (or `Start`) save with `--start`; the saves in
  `maps/Banks/testStarts/` are from an older data version. Note that a normal
  run reads `user://saves/<slot>.sav` first when it exists (a slot you saved
  in the game shadows the shipped one); deterministic runs (`--seed`) read
  only the shipped saves.
- Parity: `tools/parity/parity.sh record <set>` / `compare <a> <b>` /
  `ab "<args a>" "<args b>" [case…]`, see `docs/ARCHITECTURE.md` section 7.
  Runs are windowed (screenshots need a renderer); all 336 cases take about
  35 minutes with `--jobs=8` on 12 logical cores (`--uncapped`; the weather
  floors are bound by the weather, `particles_hotg` by its particles at
  ~6 FPS). The `fps=` values of parity runs are meaningless;
  measure performance in normal runs. Do not type while a recording runs (a
  new run's window takes the focus).
- The developer console (§ / ` / F1 in debug builds, README) jumps to any
  place (`goto`). It replaces the Cheater (formerly SELECT + DOWN, i.e.
  Space + Down), whose menu of places, stories and buildings its `cheater`
  command still opens; `tools/autoplay/stores.txt` shows how to drive it.
- Time units: `update(elapsedTime)` in **ms**; `draw(g)` per frame at 60 FPS.
- The original really ran at ≈30 FPS, not `Values.FPS = 60`: its
  `organizer/FPSAnimator` sleeps a fixed 23 ms after every vsynced frame.
  Anything that changes per update instead of per ms runs twice as fast in the
  port. The particles that fade per update but move per ms (village systems in
  `bodies/system/ParticleSystem.update`, card/enemy effects in
  `particleSystem/ParticleSystemPacket.update`) are stepped by
  `Values.originalFrameStep` for this reason. The purely per-frame ones
  (labyrinth weather, save points, battle background snow) still run at 60
  updates per second.
- Positions from `Values.createNormalPoint(x, y)` are `[y, x]`.
- Content quirks met in phase 1 (kept; all of them, with the dungeons', are
  in `tickets/triage.md`): "Zazo at Night - 0" asserts (Java quit the game)
  unless its loot `Zazoname` is taken (equipment "2"); the Zazo night stores
  name images that do not exist (`inn.jpg`, `burt.png`); no story reaches
  Zazo, Pass to Zazo or Port of Zazo at night (`--start-time=night`);
  "Pensara - The North District - Farmer House" quit the game on entry
  until COTZ-023 (villager Dido's patrol was not closed; `Instructions.check`
  now has the villager assert instead); Berca - 1
  names a villager Herman without a `.char` file; Zazo - Tent has no
  villager images; Podd's image path (Civil House) cannot resolve; a
  Berca - 1 loot line lacks its directions; Alares - 1, Dellna - 2,
  Parasne - 2, Kin's Place, Zazo - Farl's House and several night variants
  have no obstacles (Zazonode2's timeline was commented out, restored
  in COTZ-016); Tutorial1,
  Dorma's Tranquility and Menthu Battle are reached by nothing. Saves:
  "Start demon1" has Kin and Celis, "Start demon2" adds Borealis, "Start
  Menthu1" and "Start d3" add Zalzi; "Slot 2" and "Slot 3" are an older
  data version (loading them asserts for each missing labyrinth node).
- The game's code never quits: Java's `System.exit` checks are `assert`s
  (the editor's debugger stops there; a console run prints a SCRIPT ERROR
  and goes on), and `GameCore.exitGame()` is only the player's Escape.
- GDScript gotchas met so far: unqualified calls to methods named like builtins
  (`load()`) hit the builtin → use `self.load()`; inner classes may not shadow
  global/native class names; overrides need ≥ parent parameter count with extras
  defaulted; never put NUL bytes in strings; subclass `_init` must call
  `super(...)`; static initializers must not read other classes' statics;
  functions typed `-> String`/`-> Dictionary` cannot return null.

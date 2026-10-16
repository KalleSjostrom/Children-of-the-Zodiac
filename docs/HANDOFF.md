# Handoff: state of the Godot port (2026-10-16, after steps 1–3 and modernization phase 0)

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
  Alares background tiles, through fade-in, walking, a dialog, a store round
  trip, the menu (thumbnail) and leaving to the world map (the scene is freed
  at the next mode switch).

## Plan (what is left)

0. **Modernization:** phase 1 (villages as scenes) can start; see the plan
   (section 6) and its open decisions (section 13). Record goldens before
   each change (`tools/parity/parity.sh record golden`).

1. **Performance (top priority):** labyrinths with rain/snow run at ≈30 FPS,
   battles there at 20–28 FPS (10 000 weather particles per frame through
   GDScript + the GL emulation in `src/weather`). Everything else measured
   runs at 60 FPS. Per-frame fades assume 60 FPS. Options: batch particle quads
   into one mesh per frame in `GLBackend`, or tighten the weather loops.
   Measure with the `fps=` value that AutoPlay prints with every `log`/`shot`.
2. **More runtime coverage:** level-up screen, riddle mini-games
   (`src/miniGames`), buying/selling/merging cards, inn rest, the later
   chapters and their bosses. Compare look and timing with the original
   logic.
3. **Polish (former step 4):** fades at 60 FPS, music transitions (all tests
   so far ran with `--mute`), saves in `user://saves/`, export (install the
   4.7 templates; `export_presets.cfg` already includes `maps/*`).

## Useful facts

- Godot: `C:\Users\c06ks\Work\Godot\Godot_v4.7-stable_win64_console.exe`.
- `tools/check.sh [paths]`: import pass + compile, prints only errors (locked
  for concurrent use). Run Godot with `< /dev/null` from bash.
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
  Runs are windowed (screenshots need a renderer) and take about 4 minutes
  for all cases (`--uncapped`; battles are bound by the weather at ~26 FPS).
  The `fps=` values of parity runs are meaningless; measure performance in
  normal runs.
- The developer Cheater (SELECT + DOWN, i.e. Space + Down) jumps to any place
  or building; `tools/autoplay/stores.txt` shows how to drive it.
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
- GDScript gotchas met so far: unqualified calls to methods named like builtins
  (`load()`) hit the builtin → use `self.load()`; inner classes may not shadow
  global/native class names; overrides need ≥ parent parameter count with extras
  defaulted; never put NUL bytes in strings; subclass `_init` must call
  `super(...)`; static initializers must not read other classes' statics;
  functions typed `-> String`/`-> Dictionary` cannot return null.

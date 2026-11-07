# Handoff: state of the Godot port (2026-11-06, after steps 1–3, modernization phase 0, phases 1, 2, 3 and 4.1 done and closed, the particles phases P and P2, phase 4.2's pilot, its menu and its stores through step B, the character sprite sheets)

Conventions: legacy (ported) code follows `docs/PORTING.md`; new code
(scenes, resources, tools, bridge) follows `docs/ARCHITECTURE.md`. The
modernization plan is `docs/MODERNIZATION_PLAN.md`.

## Done

The entries below are in the order the work was done. The `--legacy=`
flags they name for phases 1 to 4.1 (and the particles phases' `particles`
and `dungeon_particles`), the converters and data checks, the `.vil` and
`.map` files and the bridge test are removed since those phases closed
(last entry of the modernization, "Closing phases 1 to 4.1").

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
- Bridge test (deleted when phase 4.1 closed, 2026-11-06): `--bridge-test`
  + `tools/autoplay/bridge_test.txt` (parity case `bridge_test`) showed
  `tools/bridge_test/BridgeTest.tscn` instead of the world map's background
  tiles (Alares until the phase 1 rollout), through fade-in, walking a road,
  the menu (thumbnail), entering a labyrinth and the menu there (the scene
  was freed at that mode switch).

**Modernization phase 1 (villages as scenes): steps A and B done** for all
63 places and 89 `.vil` variants: the pilot (Zazo, "Zazo - Miner's Home",
plan 6.7) and the rollout (the other 61 places, plan 6.8); conventions in
`docs/ARCHITECTURE.md` section 9. The legacy path is removed (plan 6.9):
the scenes are the village data, edited in Godot.
- Scenes: `scenes/villages/VillageScene.tscn` (layout), one folder per place
  in `scenes/villages/` (base + one inherited scene per `.vil`, stitched
  background PNGs), shared types in `scenes/common/`, SpriteFrames in
  `resources/sprite_frames/`. The converter that made them
  (`tools/import/vil_to_scene.sh`), the data check (`verify_villages.gd`),
  `docs/CONVERTING_VILLAGES.md` and the background tiles are removed (git
  history up to 1e0229df).
- Step A: `VillageLoader.load` builds every place from its scene
  (`VillageScene.load_into`); no `.vil` file is read.
- Step B: the scene draws the world (background, actors, top layer, night,
  particles via `LegacyParticles2D`), also in cutscenes (camera zoom, tint,
  under-actor images); emotions, dialogs, signs, fades and the over-actor
  cutscene images are phase 3's UI nodes. There is no legacy village
  drawing any more (`--legacy=villages` and `--legacy=village_top_layer`
  are gone). Parity against the legacy drawing was identical except
  cutscene zooms (tile seams, rounding) and the always-drawn top layer
  (decision 7); plan 6.8.
- Parity coverage: 117 cases (`tools/parity/cases.txt`): the 17 older ones,
  a tour of every variant a main.bank place reaches (`tour_*`), four
  particle cases and 24 cutscenes (`story_*`). `parity.sh --jobs=<n>` and
  case patterns make a full run about 40 minutes.
- The `.vil` files are deleted (decision 5, 2026-11-06); their names still
  name the variants. Plan 6.9 has what closing the phase removed.
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
- Parity coverage: 336 cases at the end of phase 2 (`tools/parity/cases.txt`, 5,690 shots; 347 cases and 5,984 shots since the particles phase, 362 and 6,858 since P2): the
  205 new `dungeon_*` cases are a tour of every floor with both saves and 53
  hand-written cases (doors and floor changes, every object kind, riddles of
  every class, battles under snow and rain and with enemy colours, bosses,
  saving and loading on a floor, the console). Dev options: `--no-encounters`,
  `--start-node=<address>:<direction>`, AutoPlay `pos` in labyrinths and
  `loopuntil … dialog`, `tools/parity/contact_sheet.gd`.
- Closing the phase is prepared in plan 7.9 (what removing the legacy
  dungeon path deletes, and what keeps the exit criteria from being met).

**Modernization particles phase (village and cutscene particles on the
GPU): done** (plan 6.10, `docs/particles_prompt.md`; conventions in
`docs/ARCHITECTURE.md` section 9 "Particles", the procedure in
`docs/CONVERTING_PARTICLES.md`):
- Every system of `maps/ParticleSystems/particleSystems.info` is a generated
  `VillageParticles2D` scene (`scenes/common/particles/systems/`, 51 systems;
  `tools/import/particles_to_scenes.sh`, deterministic), whose particle
  shader runs its class's legacy laws as per-second rates at 30 steps a
  second (decision 6). The additive systems start softer (intensity 0.6;
  snow and stars 0.85); `intensity`, `size_scale` and `amount` are tunable
  per scene.
- Step B: the legacy `BodiesParticleSystem`s stay in charge but build no
  bodies and run no simulation (`gpu_path()`); `LegacyParticles2D`
  instances the scenes and hands them the legacy state every frame.
  `--legacy=particles` keeps the legacy simulation; `--hide-particles`
  (dev) hides the particles in both paths.
- The particles draw from their own generator (`BodiesParticleSystem.rand`,
  a port deviation), so seeded runs no longer shift when they change.
- Dellna's snow and wind are back. Normal runs, legacy -> GPU: Home of the
  Gods with all 12 god systems 8 -> 60 FPS, Dellna with snow 18 -> 60, the
  Menthu cutscene 18 -> 60; loading Home of the Gods 1.84 -> 0.60 s, Dellna
  1.67 -> 0.46 s (plan 6.10).
- Parity: with the particles hidden, every case is identical to the goldens
  recorded before the change (all 347 cases, logs too); the GPU path
  recorded twice is identical; `--legacy=particles` equals the unconverted
  drawing. Five new particle cases (`particles_*`).
- Prepared and done in P2 (below): the dungeon weather, the save points and
  the card and enemy effects.

**Modernization P2 (the dungeon weather, the save points and the card and
enemy effects on the GPU): done** (plan 6.12; conventions in
`docs/ARCHITECTURE.md` section 10 "Dungeon particles" and section 11, tuning
and checking in `docs/CONVERTING_PARTICLES.md` sections 4 and 5):
- The rain and snow (`WeatherParticles3D`: `Rain.tscn`, `Snow.tscn`, two
  passes) and the save points (`SaveParticles3D.tscn`) run the legacy laws
  in particle shaders at 60 steps a second as per-second rates; the card and
  enemy effects drawn as particles (`EffectParticles3D`, one per legacy
  system, in the frame's 3D chunk: `Graphics.show_node`) at 30 steps a
  second. The spheres, the image and slow systems and the enemy colour stay
  legacy.
- Step B: the legacy systems stay in charge without particles (the weather,
  the save points) or with a pool of at most 64 particles whose counts
  decide the battle's waits (the effects; within about 0.1 s of the legacy
  waits). `--legacy=dungeon_particles`, `--legacy=battle_effects` keep the
  legacy paths; `--legacy=effect_waits` (dev) the legacy waits on the GPU
  path; `--hide-particles` hides all particles.
- The rain's initial heights and the effects draw from their own generators
  (`WeatherParticle.rand`, `ParticleSystem.rand`; port deviations).
- Normal runs, legacy -> GPU: Forest Path (rain) 35 -> 60 FPS, Frozen Field
  (snow) 50 -> 60; Wind 3 7 -> 59 FPS at its worst, Tornado 3 25 -> 60;
  Menthu's Flame no longer stops the game for 10.5 s; a floor with a save
  point loads about 0.4 s faster (plan 6.12).
- Parity: with the particles hidden every case is identical to the goldens
  recorded before the change except battle shots that the effects' waits
  move (52 of 6,858); with `--legacy=effect_waits` the battles are identical
  too; the legacy paths equal the unconverted drawing; the GPU path recorded
  twice is identical. 15 new cases (`effects_*`, `particles_save_*`) and the
  console's `cast` (cards played on a party member's turn, `--casts=`).

**Modernization phase 3 (shared UI and transitions): steps A and B done**
for the overlays of villages, labyrinths and cutscenes: the pilot (plan 8.1)
and the rollout (plan 8.3); conventions in `docs/ARCHITECTURE.md` section 12,
the procedure in `docs/CONVERTING_UI.md`:
- The Theme (`resources/theme/game_theme.tres`): the game's two fonts with a
  size per role and `Text20` … `Text50`, the papers and the card info's menu
  piece as StyleBoxTextures; nothing restyled.
- Step B for the dialog family and the fade: `scenes/ui/Dialog.tscn` (the
  dialog box: papers, name, lines, questions and the hand, the input
  question, a shown image), `SignBox.tscn` (signs, loot and gift lines),
  `CardInfo.tscn` (the card info popup, also in the card store and on the
  menu's deck page) on the UI layer, `Fade.tscn` (the mode fade and a
  cutscene's own) on Transition; text through `BaselineLabel` (placed by its
  baseline, drawn with the legacy text's `draw_string`). The legacy Dialog,
  DialogSequence and Fadeable stay in charge; their draw methods hand the
  nodes what they drew (twins with the same state changes).
- A UI node takes its place in the legacy frame (`Graphics.show_ui`):
  GLBackend orders its canvas items and the nodes with one counter, and the
  legacy 2D drawn after a node goes to that node's layer, after it.
  `--legacy=dialog` and `--legacy=fades` keep the legacy drawing.
- Parity: legacy vs. node identical at tolerance 0 on every case, golden vs.
  node too (6,999 shots, logs identical; plan 8.1); nine new cases
  (`dialog_*`): 370 cases and `bridge_test` in all.
- Found on the way: the 1/255 of plan 7.8 comes from the minimap's batches in
  the floor's world (without the minimap those shots are identical); the
  labyrinth's and boss area's card info after the dialog never shows (nothing
  sets their `card`, as in the Java); no case reaches an image fade
  (`Menthu1/2.kill`).
- Rollout (plan 8.3), step B for the rest: the emotion bubbles (World: the
  village scene's `Emotions` layer, `scenes/common/EmotionBubble`, zoomed by
  the cutscene camera), the mission display (`scenes/ui/MissionDisplay`),
  "Paused" and "game pad lost" (`Paused`, `PadLost`, their dims Fade nodes),
  the cutscene images over the actors with the text back (`CutsceneImage`,
  under the zoom's modelview), the story texts and the credits (`StoryText`,
  `ScrollText`), the tutorials' top layer wherever it is drawn (`Tutorial`:
  trigger doors, battles, stores, the menu) and the minimap
  (`scenes/dungeons/MinimapPart`: the legacy `MapRenderer` still makes the
  geometry, captured instead of drawn, and each batch is a node in the
  frame's 3D chunk). Flags `--legacy=emotions`, `mission`, `pause`,
  `story_images`, `story_texts`, `tutorials`, `minimap`.
- Coverage: 12 new cases (382 and `bridge_test` in all, 7,225 shots): village
  emotions at night over treetops (the console's new dev-only `emotion`),
  "Paused" in a village, a labyrinth and a cutscene, "game pad lost" with
  its menu moved (the console's new dev-only `padlost`), the prison's
  "Time's up!", the tutorials of a trigger door, a battle, the stores and the
  menu paged through, the ending's black texts, an image fade (Menthu1's
  defeat). `tools/parity/probe.sh` and `probe_report.py` run the coverage
  probe.
- Parity (plan 8.3; tolerance 0, 382 cases and `bridge_test`, 7,225 shots):
  golden vs. nodes identical (logs too); `--legacy=<overlay>` vs. nodes on
  each overlay's cases identical; every phase 3 flag vs. nodes and vs. the
  golden identical; the bridge test passes. On the way: the credits' lines
  at the screen's edges were culled (`BaselineLabel` now clears its
  Control's culling rect), and the bubbles under a cutscene zoom rounded
  differently as nodes in `World` or under a Node2D transform (they draw the
  legacy quad now).
- Frame rate (normal runs): the credits 587–631 → 1,260–1,323 FPS uncapped;
  a cutscene with images and texts, the Sewers' mission and a village with
  bubbles within the noise; 60 capped everywhere.
- Left: the minimap is still the 3D bridge's batches. Its node
  (`--minimap-node`, dev: `MinimapPart`) draws every floor frame to the bit
  but changes later battle frames by 1/255 (41 shots), so it is not the
  default; the 1/255 of plan 7.8 stays as it was. Closing the phase is
  prepared in plan 8.4.

**Modernization phase 4.1 (the world map and the airship): steps A and B
done** (plan 9.1; conventions and how to convert a map again in
`docs/ARCHITECTURE.md` section 13):
- Scenes: `scenes/world_map/WorldMapScene.tscn` (layout: `Background`,
  `Roads` (`WorldMapRoad`, a Path2D per road with its `co` points and its
  move dots), `Nodes` (`WorldMapNode` / `AirshipNode`, Marker2D),
  `Player` (ActorView), `Overhead`, `Night`), one scene per `.map` file
  (`world0`–`world2`, `land1`, `land2`), the stitched backgrounds, and the
  node index `resources/world_map/place_index.tres`. Made by
  `tools/import/world_to_scene.sh --all` (deterministic); the stitching is
  `tools/import/tile_art.gd`, shared with the village converter.
- Step A: `LandscapeLoader` and `AirLandscapeLoader` build the maps from the
  scenes, `createMap` reads the index; `verify_world_map.gd` with "Slot 1"
  and "Start": 196 builds pass.
- Step B: the scene draws the map (tiles, visited roads' dots and nodes,
  Kin or the airship, top layer, the night layer when the map loaded at
  night); the name plate is the UI node `scenes/ui/NamePlate` (theme roles
  `NamePlate`, `NamePlateName`). The legacy objects keep the state, the
  input and the timing. `--legacy=world_map` and `--legacy=airship` keep
  the old path; `--bridge-test` implies `--legacy=world_map`.
- Port fix: the airship's map loader kept every airship mode alive (a
  reference cycle, as `LandscapeLoader`'s was); each map scene now logs
  `WorldMapScene: freed`.
- Parity (tolerance 0, 392 cases and `bridge_test`, 7,292 shots): golden vs.
  step A and vs. step B identical (logs too, with `--ignore-world` for the
  21 cases that show a map); legacy vs. scene on those 21 cases identical;
  the bridge test passes. Ten new cases (`world_*`, `airship_*`: each map
  by day, the first visit and closed roads, West at night, East at night
  (dev only), the airship's wraps, plate, menu, map page and landing);
  AutoPlay's `pos` covers the world map and the airship.
- Frame rate (normal runs, uncapped, legacy → scene): walking on West 424 →
  1,926 FPS, flying the airship 1,713 → 2,280; 60 capped either way.
- Quirks found (kept, `tickets/triage.md` W1–W4): SQUARE on a crossroad
  boards an airship with no node (script errors); East and North at night
  would need a missing image (no data goes there); a visited closed road
  keeps its dots; Empyrian Temple's airship node leads into the labyrinth.
- Closing the phase is prepared in plan 9.1 ("Closing phase 4.1").

**Modernization phase 4.2's pilot (the title, the game over, the menu
list): step B done** (plan 9.2; conventions in `docs/ARCHITECTURE.md`
section 14, the procedure for whole 2D modes in `docs/CONVERTING_UI.md`
section 5):
- Where a mode's nodes live when its whole frame is 2D: UI nodes in the
  frame's order (`Graphics.show_ui`), not the mode's scene under `World`
  (the stores and the menu pages draw legacy parts and phase 3's nodes
  between their own parts; `World` is under all of it).
- Nodes (`scenes/ui/`): `Title` (the background and the logo, its alpha the
  legacy fade-in's index), `MenuList` (a `MenuNode` list: choices and hand),
  `ShadowText` (`drawWithShadow`: the difficulty's description),
  `SlotDates` (the Continue list's dates), `GameOverScreen` (the party's
  image); theme roles `MenuChoice24`, `MenuChoice20`, `DifficultyInfo`,
  `SaveSlotDate`. The legacy `TitleScreen`, `GameOver` and `MenuNode` keep
  the state, the input and the timing; their draws run twins. The game pad
  lost overlay's menu is a `MenuList` too.
- Flags `--legacy=title`, `game_over`, `menu_list`; all three draw exactly
  as before.
- Dev only: seeded runs date a slot saved in the run by the game clock
  (`SaveSlots.note_saved`), so the Continue list with an autosave can be
  shot.
- Coverage: nine new cases (`title_*`, `game_over*`: 401 cases and
  `bridge_test` in all, 7,361 shots): the title's fade-in, logo, menus,
  description and dates, a new game and a load through the fade-out; the
  game over with each party's image, its fade-in, "Paused", CROSS and the
  22 s timeout.
- Parity (tolerance 0, 401 cases and `bridge_test`, 7,361 shots): golden
  vs. nodes identical (logs too); the legacy flags vs. nodes on the cases
  that show the title, the game over or the game pad lost menu identical,
  together and one by one; every flag on vs. the golden identical; the
  bridge test passes. Frame rate the same (60 capped; about 2,350 FPS
  uncapped on the title, 2,450 on the game over, either way).
- Prepared (plan 9.2): the rollout to the menu (two sessions), the stores
  (one or two; none of their sub-pages is covered by a case yet) and the
  mini-games (one; fix the riddle fade's port bug first, plan Appendix).
  None of them draws in 3D.

**Modernization phase 4.2's rollout, part 1 (the menu): step B done** (plan
9.2, "Results of the menu"; conventions in `docs/ARCHITECTURE.md` section
14, "The menu"; the procedure in `docs/CONVERTING_UI.md` section 5):
- `MainMenu` and its pages (start, equip, deck, map with the automap, help,
  tutorial) draw through UI nodes in the frame's order (`Graphics.show_ui`):
  `MenuBackground` (back.jpg and the layout's pieces), `MenuTitle`,
  `MenuInfo` (gold, steps, time), `MenuThumbnail`, `HelpLine` (the button
  icons and labels; the pages' `drawHelp` run against a `HelpLineCapture`),
  `MenuText`, `MenuBox` (the saving box), `MenuList` with its variants
  (numbers, equipment with `down`, price, the bounding box with its
  `PageScrollBar`, an active child's list as several nodes, the dimmed
  hand), `StatusLine`, `EquipStatus`, `EquipItem`, `DeckView` and
  `CardView` (also a flying card), `Automap` (`AutomapFloor`: the floor's
  names, its cells as TextureRects under a `Zoom` with the overview's
  modelview: exact). The legacy pages, `MenuNode`, `GameAction`, the
  deck page's `Animator` and the saving box's timers keep the state, the
  input and the timing; the twins keep every state change of the drawing.
- Built for the stores, not yet used by them: the pieces with a store's
  mask, the info lines, the price variant, the confirm box, the deck's card
  store branches (numbers, grey cards), `CardView` for the merge preview
  (plan 9.2's stores entry tells how each store shows them).
- Flags `--legacy=menu_frame`, `menu_list` (now also the menu's lists),
  `menu_text`, `status`, `deck`, `automap`; with the pilot's `title` and
  `game_over` the frame is drawn exactly as before phase 4.2.
- Dev only: the console's `give <item|equipment> <name> [number]` (more
  key items and equipment than the shipped saves have, for the lists that
  scroll).
- Coverage: six new cases (`menu_*`: the Save list before and after a save
  with the saving box, the character select moved, "Paused" over the menu,
  Key Items scrolled with numbers, the equip page's lists scrolled with the
  comparisons, both decks edited with cards flying both ways, the
  difficulty list with grey levels, the tutorial list scrolled): 407 cases
  and `bridge_test` in all, 7,447 shots.
- Parity (tolerance 0, 407 cases and `bridge_test`, 7,447 shots): golden
  vs. nodes identical (logs and error lines too); this task's flags vs.
  nodes on the 285 cases that draw the menu identical, each flag alone on
  its cases too; every phase 4.2 flag vs. the golden identical; the bridge
  test passes. Fixed on the way: a theme role lookup that cannot fail
  (`has_theme_font_size` is true for any type while the theme has a default
  size: the deck page's help line came out at 24; `MenuText.role`).
- Frame rate (normal runs): 60 capped either way; uncapped, legacy → nodes,
  the start page 759 → 1,608 FPS, the deck page while editing 345 → 839,
  the map page's five-floor overview 1,123 → 1,755.
- Prepared (plan 9.2): the stores (one or two sessions; their cases first),
  then the mini-games.

**Modernization phase 4.2's rollout, part 2 (the stores): step B done**
(plan 9.2, "Results of the stores"; conventions in `docs/ARCHITECTURE.md`
section 14, "The stores"; the procedure in `docs/CONVERTING_UI.md` section
5):
- The Weapon Store, the card store, the Inn and the Church draw through UI
  nodes in the frame's order: the menu's `MenuBackground` (the store's
  background; then the keeper and the masked pieces after the keeper's
  dialog), `MenuList` (every list: price, price + `down`, the bounding boxes
  of the sell and trade lists), `MenuTitle`, `MenuInfo` (the stores' own
  lines too), `EquipStatus`/`EquipItem`, `DeckView`/`CardView` (the stock,
  the merge deck with its numbers, the merge preview at the next level),
  `PageScrollBar`, `MenuText`, `MenuBox` (the confirm boxes), `SlotDates`,
  `HelpLine`; the confirm dim is the Fade node on the UI layer; new:
  `LevelBar` (`LevelUpBar`'s image parts, drawn as the legacy quads: an
  AtlasTexture region was up to 5/255 off), `BlessPage` and `BlessRow` (the Church's bless page: costs,
  bars, the two-colour markers, the help text's rows, the total). The
  stores keep the state, the input and the timing; the twins keep every
  state change of the drawing (the Church's `totalCost` and markers, the
  cursor fix-up, the dim's colour, the scroll bars' init).
- Flags: the menu's (`menu_frame`, `menu_list`, `menu_text`, `status`,
  `deck`) for the parts the stores share, and `--legacy=dim` (the confirm
  dims) and `bless` (the bless page); with every phase 4.2 flag the frame is
  drawn exactly as before phase 4.2.
- Dev only: the console's `gold [amount]` and `give card <card>[:<level>]
  [number]`.
- Coverage: eight new cases (`store_*`: the Weapon Store's buy and sell
  pages with their confirms, "Paused"; the card store's buy page scrolled
  with grey cards, the merge page scrolled with level 1 and 2 previews, the
  empty merge page; the Inn's rest, trade list, prize and night; the
  Church's save list before and after a save, its levels tutorial, the
  bless tutorial and page with the blessing); 417 cases in all, 7,817
  shots.
- Parity (tolerance 0; 417 cases, 7,817 shots; golden `st1gold`, nodes
  `st2node`): golden vs. nodes identical (logs and error lines too); the
  stores' flags vs. nodes on the 14 store cases (222 shots) identical, each
  flag alone too; every phase 4.2 flag vs. the golden identical; the new
  cases recorded twice identical; no new exit leak report. The first
  `LevelBar` (AtlasTexture regions) was the one difference on the way.
  Afterwards every older set was deleted (2026-11-07, about 285 GB):
  `tools/parity/out` keeps only `st2node` (and `_work`, the helper
  scripts); record a new baseline before the next change.
- Frame rate (normal runs): 60 capped either way; uncapped, legacy →
  nodes, the Weapon Store's weapons with the comparison 858 → 1,526 FPS,
  the card store's buy page 585 → 1,211, the Church's bless page 459 →
  863.
- Found: selling the last weapon of a sell list reads past the list's end
  (two script errors; the Java threw: plan Appendix); "Can't merge that
  card." is unreachable; project copies in the scratchpad lose their old
  files to Windows' temp cleanup when the disk is full (copy to
  `tools/parity/out/_<name>`, plan 12).
- Prepared (plan 9.2): the mini-games (one session, the fade's port bug
  first; `docs/phase4_2_minigames_prompt.md`).

**Character sprite sheets (2026-11-03): plans A and B done**
(`docs/VILLAGER_SPRITES_PLAN.md`, "As built"; conventions in
`docs/ARCHITECTURE.md` section 9, "Character frames and sheets"):
- A: every frame of a walking character is 36×56 (106 sets of 36×55 padded
  at the bottom, the five sitting villagers at the right and bottom;
  `tools/art/pad_character_frames.gd`). The two unreferenced 128×192 sheets
  `Characters/Kin.png` and `Celis.png` are deleted.
- B: each of the 198 walking sets is one sheet `<Name>_sheet.png` (4×4
  cells of 36×56 at a 40×60 pitch, the gutter filled with the cells'
  extruded edges; `CharacterSheet`, `tools/art/pack_character_sheets.gd`);
  its 16 frame files and `.import` files are deleted (3,168 of each). The
  legacy code keeps its frame paths: `ImageHandler._loadTexture` turns a
  frame path without a file into an AtlasTexture of its sheet's cell
  (`CharacterSheet.frame_texture`), `ActorView` looks frames up by atlas
  and region, `GameTexture.getImageTexCoords` gives the legacy drawing the
  cell's coordinates. The 152 village SpriteFrames with such frames hold
  AtlasTexture sub-resources (`tools/art/rewrite_sprite_frames.gd`).
  Single frames (36×56 villagers, sitting villagers, zodiac images, `ball`,
  `Characters/Animation`, props) stay single images.
- Not `filter_clip` (as the plan had it): with it a cell's last row and
  column differ by up to 3/255 even unzoomed; the extruded gutter keeps a
  1:1 frame identical (plan B, "Layout").
- Coverage: two new cases, `sprites_villager_walk` (all 16 frames and two
  standing poses of Flog, 36×56, in Alares) and `sprites_party_walk` (all
  16 frames of Kin, Celis and Zalzi in Berca): 409 cases and `bridge_test`,
  7,685 shots. The other frames the change touches were already in cases
  (`tools/parity/cases.txt` says which).
- Parity (tolerance 0; sets `sbase` before, `spadA` after A, `spB`/`spB2`
  after B; machine-specific, in `tools/parity/out/`): same exit codes,
  shot counts and error lines throughout (apart from WASAPI audio device
  lines); B's self-diff identical. Only zoomed cutscene shots differ: A in
  106 shots (the padded edge of the 36×55 frames with pixels in their last
  row and of the sitting villagers, up to 65/255, and 1/255 rounding),
  B in 300 more (1–2/255 rounding with the sheet's size, 5 alpha-test
  flips). Every differing pixel is on a changed sprite (plan, "As built").
- Checks beyond parity: an export (a village and a cutscene run without
  errors), full screen (no frame edge shows), the editor's previews
  (identical), Parasne's first load about halved (512–632 → 254–397 ms).
- Content quirks found on the way: `tickets/triage.md` C1–C7 (two more
  invisible villagers, Storygroup's empty frames, KinSmall, the
  unreferenced and duplicate sets).

**Closing phases 1 to 4.1 (2026-11-06): done** (plan 6.9, 7.9, 8.4, 9.1;
decision 5 decided in plan section 13):
- Deleted: the 86 `.vil` and 85 `.map` files (80 floors, 5 world and
  airship maps), their parsers (`MapLoader`'s, `MenuMapLoader`,
  `PillarWalls`, the world map loaders' inner classes), the converters and
  data checks (`map_to_scene`, `world_to_scene`, `tile_art`,
  `verify_dungeons`, `verify_world_map`), `docs/CONVERTING_DUNGEONS.md`, the
  bridge test, the display lists and every legacy drawing those phases kept
  (the floor, the objects, the weather and save points, the village and
  cutscene particles, the dialog family, fades, emotions, mission, pause
  overlays, cutscene images and texts, tutorials, the world map and the
  airship), with their flags. The git history up to aab714c9 has them.
- The legacy code still names places by their `.vil` and `.map` names:
  `VillageScene.path_for` and `DungeonScene.path_for` resolve the scenes
  through `file_index.txt` without regard to case (`tools/gen_file_index.py`
  lists the village and dungeon scenes for it). The debug console reads the
  floors from the scenes; the remake tool's obstacle groups are in
  `tools/village_remake/obstacle_groups.json`. The scenes are edited by hand.
- Kept: the battle effects' `--legacy=battle_effects` and `effect_waits`
  (phase 4.4), phase 4.2's flags, the minimap on the 3D bridge (8.4).
- Parity (tolerance 0; sets `cbase` on aab714c9 and `cafter2`, 409 cases,
  7,674 shots): identical shots, logs and per-case error and leak lines;
  `cbase` also equals the leak cleanup's `leakfinal`. An export runs a
  village, a floor, the world map and a cutscene.
- The open tickets that name `.vil` or `.map` lines say where the data is now.

## Plan (what is left)

0. **Modernization:** phases 1 to 4.1 are closed (2026-11-06). Next: the
   last part of phase 4.2's rollout (plan 9.2: the mini-games, which reuse
   the stores' dim, box, hands and help line,
   `docs/phase4_2_minigames_prompt.md`; then closing phase 4.2; battles
   still draw overlays of their own, phase 4.4). The minimap stays
   the 3D bridge's until the battles leave the bridge (plan 8.4). Record
   goldens before each change.

1. **Performance:** since P2 the labyrinths with rain or snow run at 60 FPS
   (Forest Path was 35, Ice Cavern--Frozen Field 50; plan 6.12), and since
   the particles phase every village measured (plan 6.10). The card effects
   no longer stall battles (Wind 3 dropped to 7 FPS, Menthu's Flame stopped
   the game for 10.5 s); the first effect of a battle compiles its shaders
   (one frame of about 0.1 s). Loading the largest floor takes ≈180 ms with
   the scene, 5 ms from its `.map` (plan 7.8); a save point no longer adds
   ≈0.4 s. Per-frame fades assume 60 FPS. Measure with the `fps=` value
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
  Runs are windowed (screenshots need a renderer); all 417 cases take
  about 19 minutes with `--jobs=5` (14-15 with `--jobs=8` when 10 GB are
  free at idle; check first: with 7 GB free, 8 jobs crashed runs) on 12
  logical cores (run nothing beside them, not even a headless compare:
  16 GB run out, plan 12); a compare of two full sets takes about 5
  minutes; a full set is about 5.5 GB (the disk was 96% full) since
  the particles run on the GPU (60-70 minutes before P2; `--uncapped`; with
  `--legacy=battle_effects` or `effect_waits` Menthu's Flame takes 10 s of
  real time). Recording from a
  copy of the project (without `.git` and `tools/parity/out`, about 2.4 GB)
  keeps the tree free for edits meanwhile; move the set back into `out/`.
  The `fps=` values of parity runs are meaningless; measure performance in
  normal runs. Do not type while a recording runs (a new run's window takes
  the focus).
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
  `Values.originalFrameStep` for this reason (the card effects' legacy
  systems still step, with a smaller pool, for the waits; the village
  systems' legacy simulation is removed: the GPU systems run the same laws
  as per-second rates every frame).
  The purely per-frame ones (labyrinth weather, save points) run their laws
  as per-second rates at 60 steps a second since P2; the battle background
  snow (dead code) still runs at 60 updates per second.
- Positions from `Values.createNormalPoint(x, y)` are `[y, x]`.
- Content quirks met in phase 1 (kept; all of them, with the dungeons', are
  in `tickets/triage.md`): "Zazo at Night - 0" asserts (Java quit the game)
  unless its loot `Zazoname` is taken (equipment "2"); the Zazo night stores
  name images that do not exist (`inn.jpg`, `burt.png`); no story reaches
  Zazo, Pass to Zazo or Port of Zazo at night (`--start-time=night`);
  "Pensara - The North District - Farmer House" quit the game on entry
  until COTZ-023 (villager Dido's patrol was not closed; `Instructions.check`
  now has the villager assert instead); Berca - 1 named a villager Herman
  without a `.char` file and had a loot line without its directions (an
  unreachable draft, replaced by Berca - 2 in COTZ-027); Zazo - Tent has no
  villager images; Podd's image path (Civil House) cannot resolve;
  Alares - 1, Dellna - 2,
  Parasne - 2, Kin's Place, Zazo - Farl's House and several night variants
  have no obstacles (Zazonode2's timeline was commented out, restored
  in COTZ-016); Tutorial1, Dorma's Tranquility and Menthu Battle were
  reached by nothing (removed in COTZ-034). Saves:
  "Start demon1" has Kin and Celis, "Start demon2" adds Borealis, "Start
  Menthu1" and "Start d3" add Zalzi; "Slot 2" and "Slot 3" are an older
  data version (loading them asserts for each missing labyrinth node).
- Project copies for recordings: `robocopy <project>
  <project>\tools\parity\out\_gold /E /XD <project>\.git
  <project>\tools\parity\out /MT:16` (~20 s, 2.4 GB; exit code 1 means
  copied), then the copy's own `tools/parity/parity.sh`; move its sets into
  `out/`. Not in the session scratchpad (`%TEMP%`): Windows' temp cleanup
  deletes the copies' old files when the disk is full (2026-11-07: a
  recording failed half-way); `tar` keeps the old times too.
- The game's code never quits: Java's `System.exit` checks are `assert`s
  (the editor's debugger stops there; a console run prints a SCRIPT ERROR
  and goes on), and `GameCore.exitGame()` is only the player's Escape.
- GDScript gotchas met so far: unqualified calls to methods named like builtins
  (`load()`) hit the builtin → use `self.load()`; inner classes may not shadow
  global/native class names; overrides need ≥ parent parameter count with extras
  defaulted; never put NUL bytes in strings; subclass `_init` must call
  `super(...)`; static initializers must not read other classes' statics;
  functions typed `-> String`/`-> Dictionary` cannot return null.

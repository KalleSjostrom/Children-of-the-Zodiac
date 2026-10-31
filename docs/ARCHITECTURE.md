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
                          particles.gdshaderinc, distance_fade.gdshaderinc, random.gdshaderinc);
                          the dungeon's GPU particles (section 10): QuadParticles3D (base),
                          WeatherParticles3D with Rain.tscn and Snow.tscn, SaveParticles3D.tscn,
                          weather_particle, save_particle and quad_particle_3d.gdshader; the
                          battle effects (section 11): EffectParticles3D, effect_particle.gdshader,
                          effect_draw.gdshaderinc
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
                          (interim weather), DungeonQuads.gd (records legacy quads),
                          MinimapPart.gd (a batch of the minimap; dev, section 12)
  dungeons/<Area>/        <Floor>.tscn, one per .map file ("The Great Mine/Tunnel.tscn")
  dungeon_objects/        DungeonObject.gd (base) and one scene per object kind:
                          DungeonChest, DungeonDoor, DungeonHinderDoor, DungeonButton,
                          DungeonSavePoint, DungeonVillager … (.tscn + .gd each)
  ui/                     the shared UI (section 12): Dialog, SignBox, CardInfo, Fade,
                          EmotionBubble, MissionDisplay, Paused, PadLost, CutsceneImage, StoryText,
                          ScrollText, Tutorial, NamePlate (section 13); the title and the game over
                          (section 14): Title, MenuList, ShadowText, SlotDates, GameOverScreen; the
                          menu (section 14): MenuBackground, MenuTitle, MenuInfo, MenuThumbnail,
                          HelpLine, MenuText, MenuBox, PageScrollBar, StatusLine, EquipStatus,
                          EquipItem, DeckView, CardView, Automap, AutomapFloor (.tscn + .gd each);
                          BaselineLabel.gd (a line of text placed by its baseline), LabelList.gd
                          (pooled lines), ImageList.gd (pooled images), HelpLineCapture.gd
                          (stands in for Graphics in drawHelp); the stores later
  world_map/              WorldMapScene.tscn + .gd (the layout every world map and airship map
                          inherits), WorldMapRoad, WorldMapNode, AirshipNode (.tscn + .gd each),
                          WorldMapIndex.gd (resource); one scene per maps/Landscape file
                          (world0.tscn West, world1.tscn East, world2.tscn North, land1.tscn,
                          land2.tscn) and the stitched backgrounds (West.png, East.png, North.png,
                          World1.png, World2.png); section 13
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
  theme/game_theme.tres       (the game's fonts and the papers and menu pieces of the UI, section 12)
  world_map/place_index.tres  (WorldMapIndex: the world map of every world map node, generated;
                               section 13)
src/                      legacy code (shrinks over time)
tools/import/             converters and their checks (headless `--script`): vil_to_scene.gd
                          (+ vil_to_scene.sh), verify_villages.gd, scene_preview.gd (windowed);
                          world_to_scene.gd (+ world_to_scene.sh), verify_world_map.gd;
                          tile_art.gd (the stitched backgrounds and top layers, shared by
                          vil_to_scene.gd and world_to_scene.gd);
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
├── UI (CanvasLayer 2)              the dialog box, the message box, the card info popup, the
│                                   emotion bubbles, the mission display, the cutscene images,
│                                   the tutorials, the world map's and the airship's name plate
│                                   (section 12); the title's, the game over's and the menu
│                                   pages' nodes and the menu lists (section 14; the stores later)
├── Transition (CanvasLayer 3)      the fade, the cutscene texts and the image over the
│                                   actors, "Paused", "game pad lost" and its menu (sections 12, 14)
├── Audio (Node, created by Main)   music and sound effect players
└── SubViewport × n (GLBackend)     the legacy 3D chunks
```

Everything a legacy `draw(g)` draws lands on `LegacyLayer`, above `World`. A
`Camera2D` in a scene under `World` moves only the default canvas, so it never
moves legacy drawing, and the fade (`GameMode.draw`, the Transition layer's
Fade node since phase 3) covers the scene. A node of new code on UI or
Transition takes its place in the order of a frame's legacy drawing; the
legacy 2D drawn after it is drawn over it (section 12).

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
  scene, on `LegacyLayer` (since phase 3 the overlays are nodes on UI and
  Transition, section 12). Where it
  used to draw the rest, it now hands that state to the scene (step B,
  section 5): the scene shows what the legacy drawing would have drawn in
  that frame. Do this inside `draw(g)`, at the same point as the drawing it
  replaces, and keep every state change that drawing made (see section 9:
  a mode's `update` can run in a frame without `draw`).
* `Graphics.copyFrame` (the menu thumbnail) reads the main viewport, so it
  includes `World` and the UI and Transition layers.
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
`BodiesParticleSystem.gpu_path()`, `WeatherSystem.gpu_path()`, `ParticleSystem.gpu_path()`,
`Graphics.reserve_scene_slot`, `Graphics.show_node`, `Graphics.show_ui`,
`Graphics.show_fade` (section 12), the snake_case
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
`Graphics.render_state_3d`, `BodiesParticleSystem.gpu_view`, `WeatherSystem.place_gpu`,
`SaveSystem.place_gpu`, `ParticleSystem.gpu_state`, `Graphics.canvas_material`,
`Graphics.skip_image`, `Graphics.text_color`, `text_alpha`, `font_bold`,
`AbstractCard.place_card`, `DeckPage.show_card_info`, the rollout's twins
of section 12, `Graphics.modelview_2d`, `screen_points`, `begin_capture_3d`,
`end_capture_3d`; phase 4.1's `LandscapeLoader.world_scene_for`, `place_index`,
`AirLandscapeLoader.airship_scene_for`, `WorldMapScene.load_into`, `show_*`,
`LandPlayer.place_view`, `Landscape.draw_scene`, `scene_bottom`, `scene_player`,
`scene_top`, `show_name_plate`: section 13; phase 4.2's `MenuNode.show_all_children`,
`Graphics.place_with_shadow`, `SaveSlots.show_dates_beside`, `note_saved`, the twins of
`TitleScreen` and `GameOver`; its menu rollout's `MenuNode.place_children`,
`show_children_freely`, `show_children`, `Graphics.place_image`, `place_centered_image`,
`MenuScrollBar.place_bar`, `show_bar`, `AbstractPage.show_standard`,
`place_menu_background_static`, `draw_title`, `draw_list`, `draw_help`, `show_lines`,
`StartPage.draw_screen_shot`, `draw_info`, `StatusPage.place_top`, `show_top`, `draw_top`,
`place_attributes`, `place_slots`, `show_equip`, `EquipPage.show_status`, `show_equip`,
`Deck.place_deck`, `show_deck`, `AbstractCard.place_at`, `LabyrinthMap.place_map`,
`LabyrinthNode.place_in_map`, `SaveSlots.show_dates_under` and the pages' twins: section
14); refactors of a
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
| `--seed=<n>` | Deterministic run (implies `--fixed-step`): every random generator (`J`, every `JRandom`, Godot's global one) is seeded from `n`; `J.currentTimeMillis()`, `Scheduler` and `GameAction` read a game clock advanced by the elapsed game time instead of the wall clock; saves are read from the shipped files and written to `user://saves_deterministic/` (emptied at start), never to the player's `user://saves/`; the slot lists date a slot saved in the run by the game clock from 1 Jan 2000, 00:00 (`SaveSlots.note_saved`; a file's time is wall-clock time, phase 4.2); no game pad is read (`GameCore.init2`: an idle pad releases AutoPlay's buttons every 40 ms). Two runs of an AutoPlay script then produce the same frames. |
| `--uncapped` | No 60 FPS cap and no vsync. With `--seed` the result is the same, only faster. |
| `--legacy=<a,b,…>` | Keep the legacy path of the listed subsystems (`Main.is_legacy`). `all` keeps every one. `villages`: converted places are read from their `.vil` files and drawn by the legacy code (section 9). `village_top_layer`: the scene draws a roof or treetop only where a sprite overlaps it, as the legacy code does (for parity; by default it always draws them). `dungeons`: converted floors are read from their `.map` files and drawn by the legacy code (section 10). `dungeon_drawing` (dev): floors are built from their scenes (step A) and drawn by the legacy code, for checking step A on its own. `particles`: the village and cutscene particle systems run the legacy simulation and `LegacyParticles2D` draws its quads (section 9; `villages` implies it). `dungeon_particles`: the dungeon weather and the save points run the legacy simulation and the floor's scene draws its quads (section 10; `dungeons` and `dungeon_drawing` imply it). `battle_effects`: the card and enemy effects run the legacy simulation and draw its quads (section 11). `effect_waits` (dev): the GPU effects' legacy systems keep their whole pool, so the legacy particle counts decide when a battle goes on, as before (for parity runs with `--hide-particles`; section 11). `dialog`: the dialog box, the message box and the card info popup are drawn by the legacy code, not by their UI nodes (section 12). `fades`: the fade quads of `GameMode.draw` and of a cutscene are drawn by the legacy code, not by the Transition layer's Fade node (section 12). The phase 3 rollout's overlays (section 12), each drawn by the legacy code instead of its nodes: `emotions` (the emotion bubbles), `mission` (the labyrinth's mission display), `pause` ("Paused" and "game pad lost" with their dims), `story_images` (a cutscene's cover-all, story, village and translucent-over-actor images and the text back), `story_texts` (a cutscene's texts and scroll texts, the credits), `tutorials` (a tutorial's top layer, wherever it is drawn). Phase 4.1 (section 13): `world_map`: the world map is read from its `.map` file (and the node index from the three files) and drawn by the legacy code, name plate included; `airship`: the airship's map likewise. Phase 4.2 (section 14): `title`: the title's background, logo, difficulty description and slots' dates are drawn by the legacy code; `game_over`: the game over's image likewise; `menu_list`: the `MenuNode` lists that are `MenuList` nodes (the title's menus, the game pad lost overlay's, the menu pages' with their variants and their scroll bars) are drawn by the legacy code (`MenuNode.drawChildrenFreely`). Phase 4.2's menu (section 14), each the legacy drawing of its parts on the menu pages (the stores keep their legacy drawing until their part): `menu_frame`: the background and the layout's pieces (`drawStandard`), the title line, the info (gold, steps, time), the thumbnail and the help lines; `menu_text`: a page's own text and boxes (the Save list's dates, the saving box, the help page's difficulty text, the map page's "Explored"); `status`: the status line (`StatusPage.drawTop`), the equip page's status with the comparison (`EquipPage.drawStatus`) and its item (`StatusPage.drawEquip`); `deck`: the deck page's decks (`Deck.drawDeck`), their titles and scroll bars and the flying cards; `automap`: the map page's map (`LabyrinthMap.draw`). With all of them and the pilot's three the frame is drawn exactly as before phase 4.2. |
| `--hide-particles` | Dev only: the particles draw nothing, in both paths (`Main.hide_particles`; they still run): the village and cutscene systems, the dungeon weather and save points, the card and enemy effects drawn as particles (not the sphere, image, slow and enemy-colour systems), with the GL state their drawing leaves; for parity runs that compare everything else. |
| `--minimap-node` | Dev only: the labyrinth's minimap is drawn by `MinimapPart` nodes (`MapRenderer.show_map`) instead of the 3D bridge's batches; the floor's frames are the same to the bit, a battle's frames after them differ by 1/255 (plan 8.3), so it is not the default. |
| Console `padlost [on\|off]`, `emotion <who> <emotion\|off> [shake]` | Dev only (debug console, `scenes/debug/GameCommands.gd`; AutoPlay `console`): `padlost` makes `InputManagers.connectionLost` report a lost game pad (`lost_simulated`) until the overlay's menu is answered, for the "game pad lost" overlay without a pad (seeded runs read none); `emotion` sets a bubble on a party member or villager of the current village (`Sprite.setEmotion`, which only cutscenes call), for the emotions in a village frame. Parity cases `pad_lost`, `emotions_village`. |
| Console `give <item\|equipment> <name> [number]` | Dev only (phase 4.2's menu): gives the party a key item (`PartyItems.addItem`, any name) or a piece of equipment of `equipment.bank` (`Load.addEquipment`, as a chest gives one, number times); `_` stands for a space. The shipped saves have too few for the menu's lists that scroll in their bounding box (Key Items, the equip page's lists) and their "(n)" numbers. Parity cases `menu_key_items`, `menu_equip_list`. |
| `--casts=<round>/…` | Dev only: the rounds the console's `cast next` plays on the party's turns (cards `<card>[:<level>][:all]` joined by `+`; `scenes/debug/GameCommands.gd`), for the parity cases of the battle effects (`effects_*`). |
| `--no-encounters` | Dev only: labyrinths start no random battles (`Labyrinth.noEncounters`, which nothing else sets; the steps are still counted), for parity tours of dungeon floors. |
| `--start-node=<address>:<direction>` | Dev only: a labyrinth `--start` place starts at this node and facing (0-3), as a game saved there does (`Load.labyrinthPosition`, COTZ-005), not at its door: parity cases start in front of the object they use. |
| `--bridge-test` | Dev only: the world map shows `tools/bridge_test/BridgeTest.tscn` instead of its background tiles (section 8); implies `--legacy=world_map`. |
| `--start-time=<day\|night>` | Dev only: the first place starts at this time of day (its info `time`): villages load their "at Night" variant, which no story reaches for most places. |
| `--status=<name>:<value>,…` | Dev only: Database statuses set after the save is loaded, before the first mode (`_` stands for a space), e.g. a village status for a story the shipped saves cannot reach. |

Engine option: the parity tool also passes `--fixed-fps 60` (before `--`),
which gives every node `_process` a fixed `delta` of 1/60 s and steps
SceneTree timers, Tweens and particles by it. Scene-based code (section 3,
"Time") is deterministic through this. The GPU particle systems run for the
game time their legacy system was updated for (`speed_scale` = that time
over the frame's delta; the dungeon weather and save points: the frames
the legacy system was updated in), with a fixed seed drawn from the
particles' generators (the effects' from `ParticleSystem.gpu_rand`, which
Main seeds from a hash of the seed, not from J's seed sequence: a seed drawn
there shifts every later `JRandom`): with `--seed` and `--fixed-fps` two runs
draw the same particles.

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
  angle (`node=<a> dir=<d> cam=<x>,<z> angle=<a>`); on the world map the
  current node, the position, the last walked direction and the road
  walked (`node=<name> x=<x> y=<y> dir=<d> road=<address|->`), on the
  airship the position, facing, velocity and the node in range
  (`x=<x> y=<y> dir=<d> v=<v> node=<name|->`, screen pixels); it adds its own log
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
`tools/autoplay/bridge_test.txt`, parity case `bridge_test`) implies
`--legacy=world_map` and makes `Landscape.create_scene()` return
`tools/bridge_test/BridgeTest.tscn`: a
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
it uses the world map. Since phase 4.1 the world map has a scene too
(section 13); the test keeps the legacy world map (`--bridge-test` implies
`--legacy=world_map`: the `.map` file, the legacy drawing, BridgeTest in
place of the tiles), so it runs exactly as before and stays comparable with
its golden. Why this and not BridgeTest inside the map's scene: the test
checks the bridge (a scene a mode owns under `World` with legacy drawing
over it, kept while suspended, freed with the mode), not the world map, and
a legacy world map over it is what makes the scene's frames visible under
legacy drawing; the world map's scene has its own parity cases. Freeing
needed a port fix: `LandscapeLoader` kept its map loader, which refers back
to it, and that reference cycle kept every world map mode alive after it
was left; `AirLandscapeLoader` had the same cycle, fixed in phase 4.1. Phase 2 found the same for the labyrinth (its graph, player and
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
  actor), the emotion bubbles, dialogs, texts and fades are phase 3's UI
  nodes (section 12). A scaled image covers the rectangle the legacy drawing covers
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
| `Weather` | `DungeonWeather`: the rain or snow (two `WeatherParticles3D` passes on the GPU path) |
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
* the weather: `WeatherSystem.place_particles` for the back pass and the
  front pass (on the GPU path its state, `place_gpu`; see "Dungeon particles"
  below); over a battle or riddle the front pass takes its place among the
  3D bridge's batches (`Labyrinth.show_weather_over`).

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
* With `--legacy=dungeon_particles` the weather and the save point's
  particles are the legacy simulation's eye-space quads, drawn at the
  origin, one mesh per pass (and per save point) and frame.

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
the scene's chunk: plan 8.3 tells why it stays there), battles and riddles
(`labDrawable`, their top layers; their card and enemy effects are GPU
particles, section 11). The mission display, dialogs and card info, the top
layer (tutorials) and the fade are phase 3's nodes (section 12).

**Dungeon particles (the dungeon particles phase, plan 6.11).** The rain or
snow and the save points' particles run on the GPU: `QuadParticles3D`
(`scenes/common/particles/`, a GPUParticles3D) with a process shader that
runs the legacy laws (`weather_particle.gdshader`: `WeatherParticle`;
`save_particle.gdshader`: `SaveParticle`) and a draw pass
(`quad_particle_3d.gdshader`) that draws each particle as the legacy quad:
axis-aligned, in the x-y or z-y plane by the player's facing, its corner
where the legacy draw puts it, additive, depth tested and written, alpha
tested and in the floor's fog as the legacy GL state has it. The legacy
particles step once per frame and never had the 30 Hz correction, so every
per-step law is a per-second rate at 60 steps a second (decision 6: the look
of today's 60 FPS at any frame rate). The particles never die and are
emitted once; a particle restarts as its legacy particle does (the
weather's at the top of its column, a save point's at y -2 with a new
colour), so the node's lifetime is longer than any run.

```
Weather (DungeonWeather, the floor's modelview as its transform)
├── Back (WeatherParticles3D: an instance of Rain.tscn or Snow.tscn)   7.5 to 20 units ahead
└── Front (WeatherParticles3D, the same seed: the same particles)      3 to 7 units ahead
Objects/<save point> (DungeonSavePoint)
└── Particles (SaveParticles3D.tscn, at minus the node's position: floor units)
```

* Step B. The legacy objects stay in charge: `WeatherSystem` (made by the
  floor's renderer: rain or snow) and `SaveSystem` (one per `InventorySave`)
  are built, updated and asked for their drawing as before, but on the GPU
  path (`WeatherSystem.gpu_path()`: not `--legacy=dungeon_particles`,
  `dungeons` or `dungeon_drawing`) they build no particles (10,000 weather
  particles; 2,000 per save point with a 400-step warm-up each). `update`
  counts the legacy updates; `place_particles` makes the same GL state
  changes and returns the state (`place_gpu`): the seed, whether the system
  was updated since the last frame (the particles run for the frame's time,
  else they stand still), the player's location and integer facing, the GL
  render state. `Labyrinth.show_weather` hands the passes to the scene
  (`DungeonScene.show_weather` → `DungeonWeather.show_gpu`); the save
  point's `place_view` hands its particles to `DungeonSavePoint` (a slot
  among the objects' batches, where the legacy quads were).
* The two passes run in step (both take the back pass's "running"), so a
  particle crossing from one band to the other stays the same particle. The
  view test (the band ahead and the 30.7° cone) runs in the process shader:
  a particle the pass does not draw has a collapsed transform. The legacy
  view test used values cached while the player stood still (they lagged by
  the flakes' drift, at most 0.06 units a second); the GPU test is fresh.
* Over a battle or riddle the front pass draws where the legacy front pass
  drew, after the battle's batches and before the minimap: a batch slot of
  the 3D bridge's chunk (`Graphics.reserve_scene_slot`,
  `Chunk3D.reserve_slot`: the sorting offset the batch would have).
* `--hide-particles` hides the nodes (a hidden node is not processed; a
  visible node that draws nothing would still change Godot's transparent
  sort, 1/255 on weather floors).
* `--legacy=dungeon_particles` keeps the legacy simulation and its quads,
  drawn through `DungeonWeather.show_pass` and the objects' batches.

## 11. Battle effects on the GPU (the battle effects phase)

The card and enemy effects that the legacy code draws as particles
(`src/particleSystem`: `ParticleSystem.draw` and
`ShatterParticleSystem.draw`, with every emitter and vector equation) run on
the GPU: one `EffectParticles3D` (`scenes/common/particles/`, a
GPUParticles3D made in code) per legacy `ParticleSystem`. The sphere systems
(Demolish's lit spheres), the image and slow systems (Death, Slow: sprites)
and the enemy colour system (Elements) are not particles and stay legacy.

* The process shader (`effect_particle.gdshader`) runs the legacy laws:
  `Particle.update` (gravity with its per-step x jitter, a target point's
  spring, killed on arrival or sent back, the collision bounces, the fade
  growing with the distance to the body), `PointBody`, the emitters (at the
  body with noise; along the interpolating emitter's path with its vector
  equation; the Line equation; the flare's disc and reserve; the flame's and
  the shatter's image points; the demolish path) and the destroy events
  (`destroy`'s one-step kick and new fade and `DESTROY_ONCE`'s stop,
  `plainDestroy`'s new fade, `kill`). The legacy effects step 30 times a
  second (`Values.originalFrameStep`); every per-step law is a per-second
  rate at 30 steps a second, applied with each frame's delta (decision 6).
  The legacy pool (a slot is emitted once per time step while the pool has
  one, and again when it dies) becomes a schedule per slot: first at index
  × time step, then at the later of its death and its last emission + pool
  × time step. The draw pass (`effect_draw.gdshaderinc`) draws each
  particle as `drawCenteredCurrent2D` does (a quad of twice its size in the
  x-y plane of eye space, its texture one of the system's), in the legacy
  render state (blending, depth, the alpha test, GLBackend's fog uniforms),
  without face culling (the GL state culls back faces, which the legacy
  quads never are, but would cull the QuadMesh).
* Step B. The legacy `ParticleSystem` stays in charge: the cards build the
  same packets, the packets step their systems as before, and a system still
  moves, emits, is destroyed and triggers its shakes and slices. On the GPU
  path (`ParticleSystem.gpu_path()`: not `--legacy=battle_effects`) its pool
  is at most `GPU_WAIT_PARTICLES` (64) particles (`reduce_for_waits`: the
  same rate per slot and the same share of the pool for isDead's limit; not
  for the flare, whose emitter takes 400 of the pool, nor for a system that
  waits for its last particle and has at most 256): its particle counts
  decide `isDestroyed` (the flare's), `isReady` and `isDead`, so the battle
  waits within about 0.1 s of the legacy waits (measured on the `effects_*`
  cases, plan 6.11). Where its draw drew the quads it makes the same GL
  state changes (`Particle.place_particle`), asks GLBackend for its node in
  the frame's 3D chunk (`Graphics.show_node`: kept from frame to frame, in a
  batch slot among the legacy batches, freed at the end of a frame it was
  not shown in) and hands it its state (`ParticleSystem.gpu_state`): the
  settings at the first frame (the seed, the pool, the process shader's
  uniforms, the image points), then every frame the game time it ran (every
  frame, not in the 30 Hz steps), its body's position and velocity, its
  gravity, whether its emitter emits, an interpolating emitter's path time
  (its time counter, which lags while the pool is empty), its destroy,
  plain destroy and kill counts, the GL render state and textures. The node
  is in eye space: the battle draws with the identity modelview, and the
  chunk's camera is at the origin (a labyrinth battle's effects land in a
  SubViewport chunk, after the battle's 2D).
* The Flame's pre-run (200 steps of 3,000 particles when Menthu's frames
  preload it, 11 s in normal runs) is skipped; the GPU system warms up
  instead (`preprocess`).
* Seeds: `ParticleSystem.gpu_rand`, seeded from a hash of `--seed`; the
  legacy particles' own draws stay `ParticleSystem.rand`'s, so
  `--legacy=effect_waits` draws what the legacy drew.
* `--legacy=battle_effects` keeps the legacy simulation and quads;
  `--legacy=effect_waits` keeps the legacy pool on the GPU path (the legacy
  waits: with `--hide-particles` a battle is identical to the legacy one);
  `--hide-particles` shows no node.
* Coverage: the console's `cast` plays chosen cards on a party member's turn
  (`cast next`: the rounds of `--casts=`); parity cases `effects_*` (scripts
  `effects_boss`, `effects_area`, `effects_enemy`).

## 12. Shared UI and transitions (phase 3)

The pilot of phase 3 converts, through step B, the dialog family and the
fade (plan 8.1): the dialog box, the message box (signs, loot and gift
lines without a speaker), the card info popup, and the fade every mode draws
last (also a cutscene's own). The rollout (plan 8.3) converts the overlays
that villages, labyrinths and cutscenes still drew: the emotion bubbles, the
mission display, "Paused" and "game pad lost", the cutscene images drawn
over the actors, the story and scroll texts and the tutorials' top layer.
The minimap stays the 3D bridge's batches (a node for it exists behind the
dev flag `--minimap-node`; plan 8.3 tells why it is not the default). Still
legacy as well: a battle's and a riddle's top layer and the riddle's fade
(phase 4), the stores' menus (phase 4.2; the title, the game over and the menu
pages are done, section 14). The world map's
and the airship's name plate is a node since phase 4.1 (section 13). How to
convert an overlay: `docs/CONVERTING_UI.md`.

**Theme** (`resources/theme/game_theme.tres`). The game's two fonts
(`res/Main/font.ttf`, `boldfont.ttf`: `font` and `bold_font` of the type
`BaselineLabel`) with a font size per type variation: the roles of the
converted nodes (`DialogName` 30, `DialogLine` 30, `DialogWhisper` 24,
`DialogQuestion` 26, `SignLine` 28, `CardInfoName` 26, `CardInfoLine` 22,
`CardInfoEffect` 20; the rollout's `MissionLine` 40, `PausedTitle` 50,
`PadLostTitle` 50, `PadLostLine` 30, `PadLostNote` 20, `TutorialTitle` 34,
`TutorialWord` 26; phase 4.1's `NamePlateName` 30; phase 4.2's `MenuChoice24`,
`MenuChoice20`, `DifficultyInfo` 20, `SaveSlotDate` 20, and its menu's `MenuChoice22`,
`MenuText22`, `AutomapFloorName` 24, `AutomapFloorTitle` 34, `CardIndex` 26,
`CardIndexCurrent` 28, section 14) and `Text20` … `Text50`, the even sizes
`Graphics.setFontSize` allows, for text whose size is data (a cutscene's
texts: 40 or 50; the credits' lines; the menu after "game pad lost"'s lines
at the size they leave). StyleBoxTextures of
the papers and the menu piece the nodes draw (`Panel` variations without
margins, so a panel of the texture's size draws the texture as it is):
`DialogPaper` (dialog1.png), `DialogPaperSecond` (dialog2.png),
`CardInfoPanel` (Pieces/10.png), phase 4.1's `NamePlate` (Pieces/1.png). Nothing is
restyled. The root of each UI
scene sets the theme; the project theme stays Godot's (the debug console).

**Text.** `BaselineLabel` (`scenes/ui/BaselineLabel.gd`, a Control) draws
one line with its baseline at the node's position, with `draw_string`: the
call the legacy text goes through (`Graphics._drawText`, `Font.draw_string`
on a canvas item, after JOGL's TextRenderer, which placed text by its
baseline). A node at the legacy coordinates draws the same glyphs on the same
pixels. Its `oversampling` is 1: the glyphs are rasterized for the 1024 x
768 screen and the window's stretch scales them, as the legacy text's (0,
Godot's default for Controls, rasterizes them at the window's scale: sharper
in full screen, a look change; plan 8.1). A Label places text by its top and
the line's ascent and draws glyph by glyph, which would need a per-size
offset and is not known to round the same (not tried). Its `alignment`
places centred and right-aligned text as `Graphics.calcAlignCenter` and
`calcAlignRight` do: the node's position minus half (or all) of the line's
advance width rounded half up (`Font.get_string_size` in the font of `bold`).
Positions that the legacy code measures with JOGL's ink bounds
(`Graphics.getStringWidth`: the tutorials' words) are computed by the twin.
It clears its canvas item's custom rect (a Control's culling rect, its size
from its position: empty at the baseline), so a line whose baseline is off
the screen (the credits scrolling in and out) is culled by its glyphs, as
the legacy canvas items are.
`LabelList` (`scenes/ui/LabelList.gd`) shows a number of lines that changes
from frame to frame (a menu's choices, a tutorial page's words, the credits)
as pooled BaselineLabel children in the legacy order.

**Nodes** (`scenes/ui/`, a script beside each; positions are the legacy
screen pixels):

```
Dialog (Control, 1024 x 768)        the dialog box (legacy Dialog)
├── Image (TextureRect)             a shown image (a showImage line), centred at the top
├── Paper2 (Panel DialogPaperSecond, at 30, 50)
│   └── Name, FirstLine, SecondLine (BaselineLabel)   the answering side's speech
├── Paper1 (Panel DialogPaper, at 0, 20)
│   └── Name, FirstLine, SecondLine (BaselineLabel)   the speech of the side that starts
├── Question                        Alternative1 … 4 (BaselineLabel DialogQuestion)
├── InputQuestion                   Title, Digit1 … 4 (BaselineLabel DialogQuestion)
└── Hand (TextureRect, hand1.png)
SignBox (Control)                   the message box (Dialog.drawMessages)
└── Paper (Panel DialogPaper)       FirstLine, SecondLine (BaselineLabel SignLine)
CardInfo (Control, at the y it is given)   the card info popup (DeckPage.drawCardInfo)
├── Panel (Panel CardInfoPanel)
├── Picture (TextureRect)           Ball1 … 3 (TextureRect)
└── Name, Line1 … 3, Effect (BaselineLabel CardInfoName, CardInfoLine, CardInfoEffect)
Fade (Control, on Transition)       the fade's quad (Graphics.fadeOldSchool)
├── Colour (ColorRect)              a fade to black or white
└── Image (TextureRect)             a fade to the image of Graphics.setFadeImage
EmotionBubble (Control, on UI)      an emotion bubble (Sprite.drawEmotions): the legacy quad,
                                    its corners through the modelview (Graphics.screen_points)
MissionDisplay (Control, on UI)     the labyrinth's mission line (labyrinth.mission.*)
└── Line (BaselineLabel MissionLine, y 50; x moves with the slide)
Paused (Control, on Transition)     "Paused" (GameCore.testDraw); its dim is a Fade node
└── Title (BaselineLabel PausedTitle, centred at 512, 250)
PadLost (Control, on Transition)    "Connection to game pad lost"; its dim is a Fade node, its
│                                   menu a MenuList node after it (since phase 4.2, section 14)
└── Title, Line, Note (BaselineLabel PadLostTitle, PadLostLine, PadLostNote, centred)
CutsceneImage (Control, on UI; the translucent-over-actor mode's on Transition)
├── Zoom (Node2D)                   the cutscene's zoom: the legacy modelview as a Transform2D
│   └── Image (TextureRect, scaled) a cover-all, story, village or translucent image
└── TextBack (ColorRect, 0, 576)    a story image's text back (Graphics.textBack)
StoryText (Control, on Transition)  a cutscene's text (story.Text)
└── FirstLine, SecondLine (BaselineLabel Text<size>, centred at 512; 70 apart)
ScrollText (Control, on Transition) a scroll text, the credits (story.ScrollableTexts)
└── Lines (LabelList)
NamePlate (Control, on UI)          the world map's and the airship's name plate (section 13)
├── Plate (Panel NamePlate, at 379, 10)
└── Name (BaselineLabel NamePlateName, centred at 512, 60)
Tutorial (Control, on UI)           a tutorial's top layer (menu.tutorial.Tutorial)
├── Dim (ColorRect, black at 0.5)   fadeOldSchoolColor(1, 1, 1, .5)
├── Paper (TextureRect)             AbstractPage.images[15]
├── Title (BaselineLabel TutorialTitle, centred at 512, 310)
├── Words (LabelList)               the page's words (TutorialWord), a coloured word's shadow first
└── Icons                           TextureRects (scaled button icons and images)
```

Dev only (`--minimap-node`), in 3D:

```
MinimapPart × n (MeshInstance3D, scenes/dungeons/MinimapPart.gd)  the minimap's batches,
                                    in the frame's 3D chunk (Graphics.show_node)
```

The layout the legacy `Dialog` kept in its `xs`, `ys`, `handX` and `handY`
tables is the scene's: each paper holds its speech's places, the shifts of a
speech without a speaker and the hand's places are exported. The speaker's
paper is moved after the other one (the legacy draws it last). The papers,
images and the hand take the legacy colour as `self_modulate` (children keep
theirs); the text takes the legacy text colour.

**Step B.** The legacy objects stay in charge of the text, the choices, the
timing and the fade values; the modes' call sites are unchanged. Each
converted draw method runs a twin without the drawing where it drew
(`Dialog._show_dialog`, `_show_question`, `_show_input_question`,
`_show_image`, `_show_messages`, `DeckPage.show_card_info`,
`Graphics.show_fade`; the rollout's `Sprite.place_emotion` with
`Village.show_emotions`, `Mission.show_line`, `GameCore._show_paused`,
`_show_pad_lost` (its menu: `MenuNode.show_all_children` with
`place_children` and `MenuHand.place_hand`, section 14),
`VillageStoryTimeLine.show_image` with
`ImageSettings.place_image` and `place_text_back`, `Text.show_text`,
`ScrollableTexts.show_texts` with `ScrollableText.place_text`,
`Tutorial.show_page` with `Row.place_rows`, `place_words` and
`Icon.place_icon`; dev only `MapRenderer.show_map`), inside the modes' draw (the
Organizer's last frame of a mode runs its update but not its draw). A
twin:

* makes the drawing's state changes in the same order: the font sizes; the
  text colour; drawImage's texture bind and texture coordinate
  (`Graphics.skip_image`); drawString's `setColor(color)`; `startText` and
  `finishText`; the shown image's alpha step and the `isFinished()` it calls
  at 0; the fade's `glColor4f`; the rollout's: the emotion's shake counter,
  the mission's slide (`Hideable.update`), the time mission's clock and its
  "Time's up!" exit, `loadIdentity` before a story image's text back, the
  font (plain or bold) the credits' lines leave set, the menu's text colours and the
  pad-lost overlay's input, which stays between its texts and its menu;
* hands its node what would have been drawn, with the GL state as Godot
  values: the images' colour (`getCurrentColor` where each was drawn: the
  papers', the hand's after the text, the image's), the text's colour and
  alpha (`Graphics.text_color`, `text_alpha`: drawString's alpha is 1,
  drawMultiString's is `startText`'s, the current mode's fade value), the
  font (`Graphics.font_bold`) and the material of the 2D state
  (`Graphics.canvas_material`: GLBackend's own canvas material for that
  blending and alpha test, so an alpha test drops the same fragments: the
  message box draws with `setAlphaFunc(0.1)`), and for an image drawn under
  a cutscene's zoom the modelview (`CutsceneImage`'s `Zoom`).

The nodes keep no reference to a mode or to the legacy objects.

**The rollout's places in the frame** (plan 8.3 has the facts):

* Emotion bubbles: UI, the first 2D of a village's or a cutscene's frame
  (over the village scene: its actors, roofs, treetops, night layer and
  particles; under the dialog and the other overlays). `Village.drawOverlays`
  (a village's sprites, in the sprite map's order) and the cutscene's draw
  (its actors, also hidden ones) show one node per bubble
  (`Village.show_emotions`). A bubble draws the legacy quad: its corners
  through the modelview as `Graphics._emit2D` transforms them
  (`Graphics.screen_points`), as two triangles with the legacy call
  (`canvas_item_add_triangle_array`). Not a node in `World` (plan 8 item 2:
  children of their `ActorView`s): under a cutscene zoom the camera's
  transform rounds the bubble's corners differently (up to 2/255 on a few
  pixels in 36 of the 253 zoomed shots), and so does a TextureRect under the
  modelview as a Node2D transform (34); the order and the hidden actors'
  bubbles would have been kept with a layer of their own (plan 8.3).
* Mission display: UI, the first 2D of a labyrinth frame (after the minimap),
  before the dialog's slot; the legacy 2D after it (a battle's or riddle's
  top layer, the tutorials' node, the fade) is drawn over it.
* Cutscene images: UI for the cover-all, story and village images (before the
  dialog's slot), Transition for the translucent image over the actors
  (after the cutscene's texts). `show_ui` pools a scene per layer.
* Story and scroll texts: Transition, after the cutscene's own fade (a Fade
  node) and before the mode's.
* Tutorials: UI, where `Tutorial.drawTopLayer` was called: a labyrinth's top
  layer (after the dialog, a battle's top layer), a battle's
  (`Battle.drawTopLayer`), a store's menus, the menu's tutorial page.
* "Paused", "game pad lost": Transition, after the mode's fade; their dim is
  `Graphics.show_fade(0.5)` (a Fade node).
* Minimap: the 3D bridge's batches, as before. With `--minimap-node` (dev)
  `MapRenderer.show_map` runs the legacy drawing with its 3D primitives kept
  (`Graphics.begin_capture_3d`, `end_capture_3d`) and shows each batch as a
  `MinimapPart` in the frame's current 3D chunk (`Graphics.show_node`, keys
  `MapRenderer.PART_KEY` down): the floor's world (the 3D bridge's chunk,
  after the walls, objects, weather and a battle's 3D) or, at a battle's
  start, the SubViewport chunk after the battle's 2D, in the slots the legacy
  batches had. Every floor frame is drawn to the bit; a battle's frames after
  them differ by 1/255, because the bridge's pool instances that drew the
  minimap render a battle's batches 1/255 apart from new ones (plan 8.3).

**A UI node's place in the legacy frame** (`Graphics.show_ui(path, layer)` →
`GLBackend.show_ui`). A node of new code on UI or Transition takes a slot in
the frame's 2D order where the legacy drawing would have drawn, as
`GLBackend.show_node` keeps a node among the 3D batches:

* GLBackend's 2D canvas items get their draw index from one counter per
  frame, and so does the node's canvas item when it is shown (RenderingServer
  `canvas_item_set_draw_index`, over the index Godot gave it).
* The frame's 2D starts at level 0, LegacyLayer's `Canvas`. Showing a node of
  layer L raises the level to L: the legacy 2D drawn after it (in a canvas
  item of its own: the node ends the current one) is parented to that layer's
  canvas (`CanvasLayer.get_canvas()`), next to the node and after it by the
  same counter. Whatever the frame draws after the dialog (a store's keeper
  and menus, a battle's or riddle's top layer, the tutorials, a cutscene's
  texts) is drawn over it, as before; the fade on Transition covers all of
  it, and what GameCore draws after the mode ("Paused") is drawn over the
  fade.
* Nodes are pooled per scene, layer and occurrence in the frame (the frame's
  first dialog box is the pool's first; the card store draws its keeper's
  dialog under its menus and the card info over them in one frame; the Inn
  its keeper's dialog and a prize message), instanced into their layer the
  first time, kept, and hidden at the end of a frame they were not shown in
  (as GLBackend's canvas items are cleared). A glClear in the middle of a
  frame (`clear_frame`) hides the nodes shown before it.
* The levels only rise in a frame: a node of a lower layer than one shown
  before it would be drawn under that one (a warning, once). No converted
  call site does that: nothing of the UI layer is drawn after a fade.
* A 3D chunk after a node is a SubViewport composited at the current level;
  the 3D bridge's scene chunk (`GLBackend.scene_3d`) is used only when
  neither legacy 2D nor a node came before it in the frame.
* A frame without a node (every `--legacy=dialog,fades` frame) orders and
  parents its canvas items as before.
* Not chosen: a single split point (the card store needs two UI slots with
  legacy drawing between them in one frame); the nodes under LegacyLayer's
  canvas (they belong on UI and Transition when the legacy drawing is gone);
  turning what follows the dialog into nodes as well (stores and battles are
  phase 4).

**Layers and the window.** UI and Transition are CanvasLayers with the
identity transform, as LegacyLayer, so the stretch (`canvas_items`, 1024 x
768, aspect keep) scales and letterboxes them alike: a node at a legacy pixel
lands where the legacy drawing did at every window size. `Graphics.copyFrame`
(the menu's thumbnail) and AutoPlay's shots read the main viewport's texture:
World, LegacyLayer, UI and Transition (and the debug console when it is
open), as the frame before rendered them.

**The fades.** `GameMode.draw`'s fade and a cutscene's own fade
(`VillageStoryTimeLine.drawTop`: after the dialog, under the texts) are the
Transition layer's Fade node: the ColorRect for `FADE_TO_BLACK` and
`FADE_TO_WHITE` (the fade image's black or white times the colour: black, or
`setFadeColor`'s colour), the TextureRect for `setFadeImage(path)` (the image
tinted by the colour), at alpha 1 − fade value. The legacy `Fadeable` keeps
the fade value and its pace (0.03 per drawn frame; no Tween or Timer).
The dims of "Paused" and "game pad lost" (`fadeOldSchool(0.5)`) are Fade
nodes too (rollout). The tutorial's dim (`fadeOldSchoolColor`) is the
Tutorial node's `Dim`. Still legacy: the riddle's fade (`RiddleGame.drawTopLayer`,
the backdrop of its image: phase 4), the stores' dims behind their confirm
boxes and the battle's (result screens, an enemy's red flash); the menu
hand's dim is the tint of `MenuList`'s hand (section 14).

**Flags.** `--legacy=dialog` keeps the legacy drawing of the dialog box, the
message box and the card info popup; `--legacy=fades` keeps the legacy fade
quads. Both together draw exactly as before the conversion (plan 8.1). The
rollout's: `emotions`, `mission`, `pause`, `story_images`, `story_texts`,
`tutorials` (section 7). With all eight the frame is drawn exactly as before
phase 3 (plan 8.3).

## 13. The world map and the airship (phase 4.1)

The world map (`Landscape`: `world0.map` West, `world1.map` East,
`world2.map` North) and the airship (`AirLandscape`: `land1.map`,
`land2.map`, the map of the Database status `airship`) are converted
through steps A and B (plan 9.1). The `.map` files stay (decision 5): the
converter, the data check and `--legacy=world_map` / `--legacy=airship` read
them. Coordinates are screen pixels (the 1024 x 768 virtual screen): the
maps neither scroll nor zoom, and the legacy nodes, roads and sprites use
them. The legacy objects stay in charge of the state, the input and the
timing (step C is not done): `Road.movePlayer` walks its line of 7 steps
per segment, one per 40 ms of `J.currentTimeMillis()`; `AirShip` keeps its
velocity per update and its wrap 55 px past the screen edges; nothing moves
along the roads' curves.

**Layout.** Every map scene, `scenes/world_map/<file>.tscn` (`world0.tscn`
… `land2.tscn`), inherits `scenes/world_map/WorldMapScene.tscn` (root
script `WorldMapScene.gd`, exporting `map_file`, `background_name` and
`airship`). Its children, in draw order:

| Node | Content |
|---|---|
| `Background` | `Sprite2D`, the stitched 256 px tiles of `res/Landscape/<W>/<W>folder` (`<W>.png`: `West.png`, `East.png`, `North.png`; an airship map `World1.png`, `World2.png`) |
| `Roads` | one `WorldMapRoad` (`Path2D`) per `road` line, in file order: `address`, `source`, `direction_to_destination`, `destination`, `direction_to_source`, `has_oc` (the `oc` line); the curve's points are the `co` points exactly; it draws the move dots (`movedot.png`) at every point but the first and the last, as `Road.done` leaves the `MoveDot`s |
| `Nodes` | one `WorldMapNode` (`Marker2D`: `kind`, `node_name`; its `Marker` child is `crossroad.png` at (−2, −4), as `LandscapeNode.draw` draws every visited node) per `node` line, in file order (`getNode` finds the first of a name); on an airship map one `AirshipNode` (`Marker2D`: `kind`, `node_name` with its `land` prefix, `zone`: the `start west/east/north` line before it) per line, which draws nothing at run time |
| `Player` | `ActorView`: Kin on a world map, the airship on an airship map; no SpriteFrames (`show_frame` adds the images it is given) |
| `Overhead` | one `Sprite2D` per `top/top.info` line, in file order (West 2, East 1; North and the airship maps none) |
| `Night` | the night layer (`Sprite2D`, scale 2, hidden): `West at Night - 1.png` on `world0`; no texture on `world1` and `world2` (their legacy night layer, `res/Landscape/standardOvernight.png`, does not exist) and on the airship maps |

The night is a choice made at run time: one scene per map file, whose
`Night` layer shows when the mode loaded the map at night (the legacy
`DoubleBackground.nightTop`, set from `Landscape.isNight()` when the map
loads: any music mode but "normal", which only a `land::continue::` place
sets: Forest Path's door to Deep Forest, plan 9.1). Not a night variant per
file (decision 1's villages): no landscape has a night background (`<W> at
Night.jpg` or a night tile folder), so a variant would repeat the whole map
for one overlay, and the legacy decides it per load, not per file.

`resources/world_map/place_index.tres` (`WorldMapIndex`) is
`LandscapeLoader.PlaceMapLoader`'s index: the map file of every world map
node (`Organizer.convert` of each `node` line's last token, `world0.map`,
`world1.map` then `world2.map`). Godot's text format writes its keys
sorted; the index is only looked up (`checkPlace`).

**Converter** (`tools/import/world_to_scene.gd`, through
`tools/import/world_to_scene.sh`): reads each file with the legacy tokenizer
and parsers as `LandscapeLoaderMapLoader` (`background`, `node`, `road`,
`co`, `oc`) or `AirLandscapeLoaderMapLoader` (`start`, `node`) read it, and
PlaceMapLoader's name of each node line. It stops on what the scene cannot
hold as the legacy loader reads it (a road before its nodes, a node after
the roads, a second background, a `co` before any road or after its road's
`oc`) and warns about what the legacy loader reads in its own way (a second
road of an address, a second node of a name, a token that is no integer,
ignored commands). The art stage stitches the tiles
`DoubleBackground.setLandscapeImages` draws (`tools/import/tile_art.gd`,
shared with the village converter: lossless, no mipmaps, the tiles' import)
and reads the top layer the same way; the scene stage writes the inherited
scenes (bootstrap file, edit state, `unique_id`s removed: section 9) and the
index. Converting twice writes the same files.

**Step A.** `LandscapeLoader.init` asks `world_scene_for(file)` (null with
`--legacy=world_map` or for a file without a scene) and lets the scene fill
the loader (`WorldMapScene.load_into`): `Parser.reset()` as the parse
begins, `loadImages(background_name)` (the
player, the `DoubleBackground` with its tiles, top layer and night layer,
the name plate's image), the nodes, then the roads (the same `Road`
constructor with the Database read `road<address>`, `setRoad` on both ends,
`addCoordinates` per point, `done`), in the order the `.map` files have
them. `AirLandscapeLoader.init` asks
`airship_scene_for("land<status>.map")`: `loadImages(background_name)` (its
image `World/<name>`), then the nodes with their zones.
`LandscapeLoader.createMap` reads the index (`place_index`) unless
`--legacy=world_map`. `Landscape.init` then builds the state as before: the
Database's opened roads (`road<map>-<address>`), the save's visited nodes and
roads (`Visited`), the current node. `tools/import/verify_world_map.gd`
builds every map both ways from each of its nodes (a world map also at
night) with the saves "Slot 1" and "Start" and compares the modes field by
field, the Database and `Visited` afterwards, and the index.

**Step B.** The scene the map was built from stays the mode's `scene_root`
(`create_scene()` returns it) and draws it; `Landscape.draw` and
`AirLandscape.draw` hand it, where they drew, what they would have drawn:

* `draw_scene` (the world map; the airship calls the same static parts):
  `scene_bottom` (the tiles' binds, `show_background`), the visited roads'
  addresses in `visitedRoads`' order with their dots' binds (`show_roads`),
  each node's visited flag with the visited markers' binds (`show_nodes`),
  `scene_player` (`LandPlayer.place_view`: the image and `J.round(x − w/2)`,
  `J.round(y − 9h/10)` as `draw` places it, `show_player`), `scene_top`
  (the top pieces' binds, the alpha test 0 that `drawTop` sets, the night
  layer when `nightTop` is set and its image exists: `Graphics.skip_image`
  returns null, and prints the same error, for East's and North's missing
  image; `show_top`).
* Each part gets the colour and the material of the GL state where it was
  drawn (`Graphics.getCurrentColor`, `Graphics.canvas_material`: GLBackend's
  material for the blending and the alpha test), as `modulate` and
  `material` of its layer node; the children use their parent's material.
  The first frame after another mode keeps that mode's blending and alpha
  test, as the legacy drawing did.
* The name plate (`show_name_plate`, both modes): `scenes/ui/NamePlate.tscn`
  on UI (`Graphics.show_ui`), after the map's drawing and before the dialog
  ("We can't enter now!") and the fade: the plate (`Pieces/1.png`, a Panel
  with the theme's `NamePlate`, at 512 − half its width, y 10; its bind) is
  always drawn; the name (`BaselineLabel` `NamePlateName` 30, centred at
  512 on the baseline 60; `startText(1, 0)` and `finishText`, so the text
  colour, alpha and current colour the legacy name left behind) only when
  the player stands on a node that is not a crossroad (world map) or the
  airship is within 20 px of a node (`checkNode`), cut at the first "-"
  (and without "land" on the airship). The font is whatever `setFontSize`
  left (plain after the credits: no line of the ending is bold, plan 9.2).
  `BaselineLabel.oversampling` stays 1.

The scene keeps no reference to its mode. Each logs `WorldMapScene: freed
<file>` when its mode is freed (one mode switch after it was left, as
section 4 says); the airship needed the port fix of section 8.

**Flags.** `--legacy=world_map` (the world map and the node index) and
`--legacy=airship` read the `.map` files and draw through the legacy code,
name plate included; together they draw exactly as before phase 4.1.
`--bridge-test` implies `--legacy=world_map` (section 8).

**Still legacy:** the state, the input and the timing (above); the dialog
and the fade are phase 3's nodes; the menu and its map page (SQUARE on the
airship; phase 4.2's rollout, plan 9.2). `DoubleBackground`
still loads the tile textures the scene does not draw (as in villages).

### Converting a map again

For a changed `.map` file, a changed background or top layer, or a
converter change; from bash in the project root, Godot with `< /dev/null`,
the editor closed:

1. Before the change: goldens of the cases that show the map (`world_*`,
   `airship_*`, `landscape`, `dialog_world_map`, `dungeon_world_map_entry`;
   the coverage probe of `docs/CONVERTING_UI.md` finds others).
2. `tools/import/world_to_scene.sh --all` (or the files). Read its
   warnings; a file it does not convert names the line. Run it twice: the
   second run changes no file.
3. `Godot --headless --path . --script res://tools/import/verify_world_map.gd -- --save="Slot 1" --save=Start`:
   every build must PASS. `tools/check.sh` must report 0 failed.
4. Open the scenes in the editor (`scenes/world_map/<file>.tscn`): the
   background, the roads' curves and dots, the node markers, the top layer.
5. `tools/parity/parity.sh ab "--legacy=world_map,airship" "" --ignore-world <cases>`
   must be identical at tolerance 0; `record after` and `compare` the
   other cases against their goldens.
6. Commit the scenes, the stitched PNGs with their `.import` files, the
   index and the new `.uid` files.

## 14. Whole 2D modes: the title, the game over and the menu (phase 4.2)

The title (`TitleScreen`) and the game over screen (`GameOver`) are converted
through step B in the pilot (plan 9.2): the first modes whose whole frame is
UI, with no world under it. With them, the `MenuNode` list they draw is a node
(`MenuList`). The rollout's first part converts the menu (`MainMenu` and its
pages) through step B and builds the parts the stores reuse: the menu
pieces, `MenuList`'s variants and its scroll bar, the status helpers, the
deck of card images ("The menu" below). The legacy objects stay in charge of the
state, the input and the timing (step C is not done): the logo's fade-in
steps `TitleScreen.index` by .005 per update and CROSS skips it, the mode
fades step per drawn frame (`Fadeable`; the game over's fade-in speed .01),
the game over's 22 s are a `Scheduler` coroutine, `MenuNode` keeps the
cursor and `GameAction` the key repeat.

**Where a whole 2D mode's nodes live: UI nodes in the frame's order.** Each
drawing a twin replaces is a node of new code on the UI layer that
`Graphics.show_ui` puts in the frame's 2D order where the drawing was
(section 12), pooled per scene, layer and occurrence; not the mode's own
scene (`GameMode.scene_root`) under `World`. Why:

* `World` is under every CanvasLayer: whatever a frame draws through legacy
  code (LegacyLayer) and every UI node of phase 3 is drawn over all of it.
  The stores draw the keeper and their menus after the keeper's dialog (a UI
  node), the card store and the deck page draw text and hands after the card
  info (a UI node), and these modes will be converted part by part, with
  legacy parts between converted ones: in `World` the converted parts would
  fall under all of that. A UI node takes its slot, and what is drawn after
  it, legacy or node, stays over it.
* A scene in `World` stays shown while its mode is current and not loading;
  its twins would have to hide every part their frame did not draw (the
  logo while the title fades in, the menu while the logo fades). A UI node
  is hidden at the end of a frame it was not shown in, as GLBackend's canvas
  items are cleared.
* For the title and the game over alone `World` would have worked (nothing
  legacy and no other node comes between their parts and the fade); the rule
  is for the modes that follow.
* `Graphics.copyFrame` (the menu's thumbnail, taken in the mode the menu is
  opened from) and AutoPlay's shots read the main viewport: `World`, UI and
  Transition alike, as the frame before rendered them. The mode fade
  (Transition) covers both. Neither decides between them.
* The stores and the menu pages draw nothing in 3D: their cards are 2D
  images (`AbstractCard.drawCard`: `drawImage`). A 3D chunk after a UI node
  would be a SubViewport at that node's layer anyway (section 12).
* The cost: the pooled nodes belong to GLBackend, not to the mode. They are
  kept, hidden, after the mode is left, with the textures they were last
  given, until the game quits (the title's two pictures and the game over's
  image: about 7.5 MB); a mode is several scenes, not one to open in the
  editor (the title is Title, MenuList, ShadowText, SlotDates). A page or
  store node that holds large textures can release them when hidden
  (`NOTIFICATION_VISIBILITY_CHANGED`); not needed for these two.
* Plan 4 puts the menu pages on the UI layer; this is that, in the hybrid
  frame. When no legacy drawing is left in a mode (phase 5), its nodes can
  become one scene the mode owns.

**Nodes** (`scenes/ui/`, a script beside each; positions are the legacy
screen pixels):

```
Title (Control, on UI)              the title's picture (TitleScreen.draw, drawTitle)
├── Background (TextureRect, 78, 59)    res/Title/loggasten.png
└── Logo (TextureRect, 78, 59)          loggatext.png; its tint's alpha is TitleScreen.index
                                        while it fades in
MenuList (Control, on UI or Transition) a MenuNode list (MenuNode.drawAllChildren)
├── Choices (LabelList)             the choices (BaselineLabel MenuChoice<size>), each at its
│                                   baseline in the enabled or disabled colour
└── Hand (TextureRect)              MenuHand's image at its position; a dimmed hand's tint has
                                    alpha .3
ShadowText (Control, on UI)         a line over its shadow (Graphics.drawWithShadow)
├── Shadow (BaselineLabel, the line's position + (1, 1))   in black
└── Text (BaselineLabel)            in the line's colour
SlotDates (Control, on UI)          the slots' dates (SaveSlots.draw_dates_beside)
└── Dates (LabelList)               BaselineLabel SaveSlotDate, "1 Jan 2000, 00:00" or "Empty"
GameOverScreen (Control, on UI)     the game over's picture (GameOver.draw)
└── Image (TextureRect, 0, 0)       res/Title/GameOver<the party's names>.jpg
```

A title frame is `Title`, then `MenuList` once the logo is done, then
`ShadowText` (the difficulty list's description) or `SlotDates` (the
Continue list's dates), all on UI; then the mode's Fade on Transition (and,
while a game pad is lost, the PadLost overlay and its own `MenuList` on
Transition). A game over frame is `GameOverScreen` on UI, the Fade and
"Paused" on Transition. Theme roles: `MenuChoice24` (the title's lists),
`MenuChoice20` (the game pad lost menu, at the size its texts leave),
`DifficultyInfo` 20, `SaveSlotDate` 20; a list at a size without a
`MenuChoice<size>` role uses `Text<size>`. `BaselineLabel.oversampling`
stays 1.

**Step B.** The modes' draws are unchanged but for the twins, at the point
where each part was drawn:

* `TitleScreen._show_background` (the background's bind, `skip_image`, and
  the frame's `Title` node), `_show_logo` in `drawTitle` (after its
  `setColor(1, 1, 1, index)`; the node is the one `_show_background` got this
  frame), `MenuNode.show_all_children` where `drawAllChildren` was,
  `_show_difficulty_info` in `drawDifficultyInfo` (between its font sizes 20
  and 24; `Graphics.place_with_shadow`: black, `setColor(color)`, the line's
  colour, `setColor(color)`), `SaveSlots.show_dates_beside` (the font sizes
  20 and back, each date's `setColor(color)`).
* `GameOver._show_image`: the image's bind and the frame's `GameOverScreen`.
* `MenuNode.show_all_children(g, layer)`: `place_children` (the cursor's
  fix-up when it is past the last child, which is game state changed in a
  draw and plays the cursor sound; the text colours; each line's
  `setColor(color)`; `MenuHand.place_hand`: the dim and the bind; the
  menu's variants below), then the frame's next `MenuList` on that layer
  gets the lines with their font sizes and fonts, the hand and the
  material. `GameCore.testDraw` shows the
  game pad lost menu this way on Transition (before, `PadLost` drew it).
* Each node takes the colour (`getCurrentColor`, the text colour) and the
  material (`Graphics.canvas_material`) of the GL state where its part was
  drawn; the font is `Graphics.font_bold()`.

The nodes keep no reference to a mode or to the legacy objects; the title's
twin keeps the frame's `Title` node (`TitleScreen._title_view`) from the
background to the logo.

**The menu list's variants** (`MenuNode.draw`'s flags, as built in the
menu's rollout). `MenuNode.place_children` is `draw` without the drawing,
flag for flag (it replaced the pilot's `place_all_children`, which asserted a
plain list; the title and the game pad lost menu get the same entries
through it); each variant adds its entries in the legacy drawing order, and
`show_children_freely` shows them (`show_children` for `drawChildren`,
`show_all_children` for `drawAllChildren`):

| Variant | What the legacy draws | In the node |
|---|---|---|
| Plain (the title, game pad lost, the store menus, the deck, map, help and tutorial pages) | each name at (Xpos, Ypos + i × distance + bboffset), then the hand | a `Choices` line per name, `Hand` |
| Disabled children | the name in `disableColor` (DARK_GRAY, or what the page sets: Key Items' black), the text colour set back to `enableColor` after it | the line's colour |
| Price (`withPrice`, `down`) | the name, then "<price> gp" at size 20 right-aligned to 985 (25 px lower with `down`), the size set back to 22 | a second line per child: right-aligned at its end, at size 20 (`MenuChoice20`); for the stores |
| Number (`withNumber`: the start page's lists, the equip page's equipment list) | the name, then "(n)" at size 20 right-aligned to 980 when n > 1 ("" for 1: nothing drawn, but drawString's `setColor(color)`) | as the price |
| Equipment (`withEquipment`, `down`: the equip page's slots) | the equipped item's name at size 20 right-aligned to 985, 25 px lower with `down` | as the price |
| Active children (`allChildren`: the start page's character select) | an active child's own list (its names and hand) before that child's name | the list split into parts: the lines before the active child, the child's own list (recursively), the rest with the hand; one `MenuList` node per part that shows something, in that order |
| Bounding box (Key Items, the equip page's lists, the map page's labyrinths, the tutorial page) | only the names whose y is inside [bbMinY, bbMaxY]; the scroll bar (`MenuScrollBar.draw`: its lazy init, `loadIdentity`, three images at 0.4) after the hand when the list overflows | the y test kept; `MenuList`'s `ScrollBar` (a `PageScrollBar`) after `Hand`, from `MenuScrollBar.place_bar` |
| Dimmed hand (the deck page's Edit/Back while editing) | `dim(.3)`, the hand, `dim(1)` | the hand's tint (alpha .3) |
| "character" names | not drawn (no list in the title, stores or menu has one) | kept by `place_children` |

The cursor fix-up (`previousChild` when the cursor is past the last child,
with the cursor sound; an empty list keeps the cursor at −1) runs in
`place_children` as in `draw`; no probed frame fires it.

**Flags.** `--legacy=title` keeps the legacy drawing of the title's
background, logo, description and dates; `--legacy=game_over` the game
over's image; `--legacy=menu_list` the lists that are `MenuList` nodes (the
title's, the game pad lost overlay's, the menu pages'; `--legacy=pause` keeps
the game pad lost menu too). The menu's flags are below. All of them together
draw exactly as before phase 4.2.

**Dev only:** a deterministic run (`--seed`) dates a slot it saved by the
game clock from 1 Jan 2000 (`SaveSlots.note_saved`, called by
`Save.saveGame`), so a slot list with a saved slot or the autosave shows the
same dates in every run; normal runs show the file's local time as before.

### The menu (phase 4.2's rollout)

`MainMenu` and its pages (`StartPage`, `EquipPage`, `DeckPage`, `MapPage`,
`HelpPage`, `TutorialPage`) are converted through step B. `MainMenu.draw`
is unchanged (`setColor(1)`, `setAlphaFunc(.02)`: every node's material is
that alpha test's canvas material, size 22, the page's `draw3D`, the mode
fade); each page's `draw3D` shows, where it drew each part, the node of
that part (`Graphics.show_ui`, UI layer, pooled per scene and occurrence).
The legacy pages, `MenuNode` (the cursor), `GameAction` (the key repeat),
the deck page's `Animator` and the saving box's `Scheduler` timers stay in
charge. `StatusPage` and `BestiaryPage` are unreachable (plan Appendix):
their `draw3D` is legacy, `StatusPage`'s static helpers are converted.

**Nodes** (`scenes/ui/`; legacy screen pixels; the shared ones first):

```
MenuBackground (Control)            drawStandard: back.jpg, then the layout's pieces in its order
├── Back (TextureRect)              res/Menu/back.jpg (none for a store)
└── Pieces (ImageList)              res/Menu/Pieces/<n>.png at AbstractPage.pos[n]
MenuTitle (Control)                 a page's title line
└── Line (BaselineLabel MenuText22, at 800, 54)
MenuInfo (Control)                  StartPage.drawInfo: gold, steps, time (a store's own three lines)
└── First, Second, Third (BaselineLabel MenuText22, at 800, 648 / 689 / 730)
MenuThumbnail (Control)             StartPage.drawScreenShot
├── Shot (TextureRect, 800, 428)    the screenshot of the mode the menu was opened from (183 x 137)
└── Frame (TextureRect, 800, 428)   res/Menu/frame.png
HelpLine (Control)                  a page's drawHelp: icons (TextureRect) and labels (BaselineLabel)
                                    as children in the order drawn (HelpLineCapture records them)
MenuText (Control)                  a page's own lines (the deck titles, the difficulty text, "Explored")
└── Lines (LabelList)
MenuBox (Control)                   the saving box (drawConfirmBuyDialog; a store's confirm box later)
├── Piece (TextureRect)             res/Menu/Pieces/1.png
└── Lines (LabelList)
MenuList (Control)                  a MenuNode list and its variants (above)
├── Choices (LabelList)             names, prices, numbers, equipment (MenuChoice<size>)
├── Hand (TextureRect)
└── ScrollBar (PageScrollBar)       when the list overflows its bounding box
PageScrollBar (Control)             MenuScrollBar.draw (a list's; the deck page's two)
└── Top, Ball, Bottom (TextureRect, scaled 0.4)
StatusLine (Control, y = the line's offset)   StatusPage.drawTop; layout MenuValues.STATUS_X/Y
├── Portrait (TextureRect, 54, 28)
├── Name, Class, Level, Hp, OffLabel, DefLabel (BaselineLabel MenuText22)
└── OffSlots, DefSlots (ImageList, 307, 53 / 93; slot_distance 50)   in the comparison's tints
EquipStatus (Control)               EquipPage.drawStatus
├── Top (StatusLine)                compared with the item
├── Attributes                      twelve BaselineLabels at the table's places
└── Changes (LabelList)             "12 +3": black at the value, red or green 1 px up and left
EquipItem (Control, y = 324)        StatusPage.drawEquip: Picture, Name, OffLabel, DefLabel, Slots
                                    (the weapons' row or the other: slot_rows), Lines (eight)
DeckView (Control)                  Deck.drawDeck
├── Cards                           a CardView per card drawn (the current one last, larger)
└── Hand (TextureRect, hand2.png)
CardView (Control)                  AbstractCard.drawCard: a deck's card; a flying card on its own
├── Images (ImageList)              the picture (colour or grey) and the level's balls
└── Index (LabelList)               the card store's number over its shadow (CardIndex, CardIndexCurrent)
Automap (Control)                   LabyrinthMap.draw: one floor, or every floor of the overview
└── Floors                          an AutomapFloor per floor, in drawing order
AutomapFloor (Control)
├── Names (LabelList)               the floor's name, centred (AutomapFloorName 24, AutomapFloorTitle 34);
│                                   on the player's floor green over a black shadow
└── Zoom (Node2D)                   the modelview the floor is drawn under (the overview's third)
    └── Cells (ImageList)           the pieces, icons and arrow in the floor's space
```

**The frame of each page** (all UI; the mode fade and "Paused" after it on
Transition):

| Page | Nodes, in the frame's order |
|---|---|
| StartPage | MenuBackground, MenuList (the root, Key Items or the Save list; the character select as three: the root's lines before the active child, the character list (only its hand), the rest), MenuTitle, SlotDates (the Save list's dates under each slot: `SaveSlots.show_dates_under`), StatusLine per character, MenuThumbnail, MenuInfo, MenuBox (while saving) |
| EquipPage | MenuBackground, EquipStatus, EquipItem (the current item), MenuList (the slots), MenuList (the equipment list), MenuTitle, MenuInfo, HelpLine |
| DeckPage | MenuBackground, MenuText (the decks' titles, at startText's alpha), DeckView × 2 (the passive deck at alpha .5 while editing), MenuTitle, MenuList, CardInfo (phase 3) and a StatusLine when no card is current, PageScrollBar × 2, a CardView per flying card, HelpLine |
| MapPage | MenuBackground, MenuTitle, MenuList, Automap, HelpLine, MenuText ("Explored"), MenuThumbnail, MenuInfo |
| HelpPage | MenuBackground, MenuTitle, MenuList (the options or the difficulty list), MenuText (the difficulty's text), MenuInfo, HelpLine |
| TutorialPage | MenuBackground, MenuTitle, MenuList, StatusLine per character, MenuThumbnail, MenuInfo, Tutorial (phase 3) |

**Step B.** At each call site the page calls a twin (or, with its flag, the
legacy drawing): `AbstractPage.drawStandard` → `show_standard`
(`place_menu_background_static`), `draw_title`, `draw_list` (→
`MenuNode.show_children_freely`), `draw_help` (the page's own `drawHelp`
run against a `HelpLineCapture`, which stands in for Graphics as
`DungeonQuads` does: it makes the binds and `setColor(color)` on the real
Graphics and records the icons and labels), `show_lines`;
`StartPage.draw_screen_shot`, `draw_info`, `_show_saving_box`;
`StatusPage.draw_top` (`place_top`, `show_top`), `show_equip`;
`EquipPage.show_status`; `Deck.show_deck` (`place_deck`,
`AbstractCard.place_at`); `MenuScrollBar.show_bar` (`place_bar`);
`DeckPage.Animator.show_card`; `MapPage._show_all` and `_show_single`
(`LabyrinthMap.place_map`, `LabyrinthNode.place_in_map`);
`HelpPage._show_difficulty`; `SaveSlots.show_dates_under`. Images are placed
by `Graphics.place_image` (drawImage without the drawing: the bind, the
quad's rect as `GameTexture.drawPart` rounds it, the current colour),
centred ones by `place_centered_image`. Every state change of the drawing
is kept in its order (the facts are in plan 9.2): the cursor fix-up, the
text colours and sizes, drawString's `setColor(color)` (also for an empty
string), `StatusPage`'s static `y` shifted by the offset and replaced by its
copy, `isAlive`, the slots' image colours, `BUTTON_ICONS` loaded on first
use, the deck page's `setImageColor(.5)` until the title's drawString,
`drawDeck`'s bold font turned off, the automap's colours and font sizes and
a chest's first map image (a Database write), the overview's matrix calls,
the scroll bars' lazy init and `loadIdentity`, `startText`'s alpha.

**The automap's transform.** The overview draws every floor under the
page's modelview (`translate(25, 80)`, `scale(1/3)`, a translate per
floor): its images go through the modelview on the CPU
(`Graphics._emit2D`), its text does not. The cells are small textures (27
px at 1.4 times, at a third), the kind whose corners Godot's own transforms
rounded differently under a cutscene zoom (plan 12: the emotion bubbles).
Here they do not: the floor's images are `Graphics.place_image`'s rects in
the floor's space, as TextureRects under a `Node2D` (`Zoom`) whose
transform is the modelview (`Graphics.modelview_2d`, as `CutsceneImage`),
and every automap shot is identical (all six places of a floor in the
overview, and single floors). A version that drew each image as the legacy
quad (`Graphics.screen_points` and `canvas_item_add_triangle_array`, as
`EmotionBubble`) was identical too; the TextureRects are the scene a later
step can keep.

**The stores** (the rollout's next part) show the shared nodes with their
own state: `MenuBackground.show_background([], pieces, mat)` with
`AbstractPage.place_menu_background_static(g, store, menusUsed)` (their
mask), after the keeper's dialog (a node) and the keeper (an image);
`MenuTitle` for their titles (the same place); `MenuInfo` with their own
three lines (the Weapon Store's "Equipped/Total/Gold", the card store's
"Stocked/Price/Gold", the Inn's `StartPage.drawInfo`: `draw_info`, the
Church's copy of it); `MenuList` with the price variant (`withPrice`,
`down`: built, not yet shown by a case) and the bounding boxes of the sell
and trade lists; `EquipStatus` and `EquipItem` (`EquipPage.show_status`,
`show_equip`) in the Weapon Store; `DeckView` with the card store's map (the
numbers over their shadows: `Deck.place_deck`'s map and gold branches,
built, not yet shown by a case), `PageScrollBar` (`MenuScrollBar.show_bar`)
and `CardView` for the merge preview; `MenuBox` for the confirm boxes
(piece 14 or 3, the texts, the right-aligned price), after their dim (a
`show_fade(.5)`-like Fade node) and before their Yes/No `MenuList`;
`SlotDates` (`show_dates_under`) for the Church's save list; `HelpLine`
(`AbstractPage.draw_help`) for the Church's help line. Each store's call
sites then switch on the same flags (`menu_frame`, `menu_list`, `status`,
`deck`, `menu_text`).

**Flags** (section 7): `menu_frame`, `menu_list`, `menu_text`, `status`,
`deck`, `automap`, one per kind of part, so that the stores use the same
flags for the parts they share; with all of them (and the pilot's `title`
and `game_over`) the frame is drawn exactly as before phase 4.2.

**Still legacy** in the menu: the state, the input and the timing (step C:
decision 3, phase 4.3's input wrapper); the `draw(g)` methods themselves
(the twins run there); `StatusPage.draw3D` and `BestiaryPage.draw3D`
(unreachable); the mode fade, "Paused", the card info and the tutorials are
phase 3's nodes. Nothing of a menu page is drawn through `Graphics` with the
flags off. The pooled nodes keep their last textures after the menu is left
(back.jpg, the pieces and the cards are loaded permanently anyway; the
thumbnail is 183 x 137): nothing to release.

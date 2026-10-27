# Modernization plan: from the GL emulation to Godot scenes

Status: **phase 0 done** (2026-10-16); **phase 1 steps A and B done** for
all 63 places and 89 variants (pilot: Zazo and "Zazo - Miner's Home", 6.7;
rollout: the other 61 places, 6.8; closing the phase, 6.9); **phase 2
pilot done** (steps A and B for Forest of Reil and The Great Mine--Tunnel,
7.7; the other 77 floors pass the converter and the data check in a dry
run); phases 3–5 are proposals. The plan
assumes the state described in `docs/HANDOFF.md` (all classes ported, main
paths run). Conventions for new code: `docs/ARCHITECTURE.md`.

## 1. Goal

Today the game is a faithful file-by-file port of the Java/JOGL original.
Every object draws itself every frame through `src/graphics/Graphics.gd` +
`GLBackend.gd`, an emulation of OpenGL 2 immediate mode. Villages and dungeons
exist only as text files (`maps/Village/**/*.vil`, `maps/Labyrinth/*.map`) that
code turns into draw calls. `main/Main.tscn` is a single `Node2D`. Nothing about
a village or dungeon can be seen or edited in the Godot editor.

**Goal:** game content becomes Godot scenes (`.tscn`) and resources (`.tres`)
that can be opened and edited in the editor. Godot nodes render them
(`Sprite2D`, `Camera2D`, `AnimatedSprite2D`, `MeshInstance3D`, `GPUParticles*`,
`Control`), and the GL emulation is eventually deleted.

**Non-goals** (for this plan): changing gameplay, story or balance; new art;
widescreen (see section 13); rewriting the cutscene language.

## 2. Findings: how the game renders today

### 2.1 The frame

* `src/main/Main.gd` `_process`: input → `Scheduler`/music →
  `Organizer.update(ms)` → `backend.begin_frame()` →
  `organizer.testDraw(graphics)` → `backend.end_frame()`.
* `GLBackend` splits each frame into chunks in draw order. 2D chunks become
  pooled `RenderingServer` canvas items. 3D chunks become pooled `SubViewport`s,
  each with its own `World3D` and camera. Every 3D batch is rebuilt as an
  `ArrayMesh` every frame (`Viewport3D.end_frame`) and composited back as a
  texture rect. Only display lists (`compileDrawList`) survive between frames.
* Materials are generated from GL state keys (blend, depth, cull, alpha
  function, fog, lighting). A custom spatial shader emulates fixed-function
  lighting and fog through global shader uniforms.
* **Consequences:**
  * Nothing is visible in the editor.
  * The engine does no culling or batching, and none of Godot's lighting
    is used.
  * GDScript cost grows with everything drawn: weather runs at 20–30 FPS
    (HANDOFF, "Performance").
  * There are ordering artefacts: TODO "Some walls are seen through others".
    All 3D batches go through the transparent pipeline, ordered by
    `sorting_offset`.
  * Timing is tied to frames (`Values.originalFrameStep` workarounds).
* **Size:** ≈46,400 lines of GDScript in 375 scripts. 142 files define a
  `draw(...)` method. Raw GL calls (`glVertex*`, `beginQuads`, `callList`, …)
  are concentrated in `graphics`, `labyrinth`, `particleSystem` and `weather`.
  High-level `Graphics` calls (`drawImage`, `drawString`, …) are mostly in
  `menu`, `battle`, `store` and `villages`.

### 2.2 Villages (89 `.vil` files, 63 places)

* **Which file loads:** `maps/Village/<Place>/<Place>[ at Night] - <status>.vil`.
  `VillageLoader.load` chooses it from `Database.getStatusFor(place)` and the
  `time=night` flag. The variants are real content forks:
  * `Zazo - 0` vs `Zazo - 1` differ in villagers and door signs.
  * Zazo day vs night differ in doors, buildings, shopkeepers and villagers,
    while their obstacles differ by only 8 lines.
* **Commands** (`VillageLoaderMapLoader.executeCommand`):
  * `background`, `back w h [as=w:h | extra]`, `offset`, `inside`, `music`,
    `landname`, `villagerFolder`.
  * `start<N> x y dir`.
  * `o x1 y1 x2 y2`: 3,530 obstacle rectangles in 70 files.
  * `door` / `holeDoor` (+ `doorSignFl/Sl`) and `building`.
  * `sign` / `signL`, `loot` / `lootLine`.
  * `villager <name> [statuses]`, `animObj`.
  * `particlesystem name[:layer:active:status]`, `wind`.
* **Art:**
  * The background ships pre-cut into 256×256 tiles
    (`res/Village/<Place>/<Place>folder/xNyM.jpg`), up to 2820×1442 px.
    *Found in the rollout:* three places have one JPEG and no tile folder
    (Menthu Battle, Zazo - Farl's House, Pensara - The Trade District -
    Tower Prison; `DoubleBackground.cutImage2` cuts them in memory), Home
    of the Gods and No Place have PNG tiles with alpha, No Place's
    `as=1:1` draws one 1×1 tile, and Dorma's Tranquility had no art
    (Menthu Battle and Dorma's Tranquility were removed in COTZ-034).
  * The "top" pieces (roofs, treetops) are in `top/`, positioned by
    `top/top.info` (`name:x:y`).
  * Night overlay: `<Place> at Night - 1.png` or `standardOvernight.png`.
  * Animated objects use `animobj/` frame series.
  * The sibling folders `../originals` and `../Children-of-the-Zodiac-master`
    contain no uncut versions, so the tiles are the source art.
* **Rendering** (`DoubleBackground`, `Village.drawBottom/drawTop`):
  1. Draw the visible tiles at the scroll offset.
  2. Draw the sprites sorted by `y`.
  3. Redraw each top piece only if a sprite overlaps it, with alpha test 0.9.
     This is a hand-made occlusion trick.
  4. Draw the night layer, upper and weather particle systems, emotions and
     dialogs.
* **Scrolling:** the background scrolls while the player is inside the
  middle band (`ObstacleHandler.boundingLines/isInMiddle/getBackPos`,
  `BACK_POS`). That is exactly what a `Camera2D` with limits does.
* **Collision:** the player's anchor point is tested against obstacle
  rectangles. The rectangles are inflated by the player size at load
  (`ObstacleHandler.addObstacle`), and each step looks ahead (`Player.canGo`:
  ×1.5 vertically, ×2.5 horizontally). Villager collision is distance based
  (`Player.checkCollision`, < 30 px).
* **Movement** is a fixed step per update
  (`LOGIC_INTERVAL * VELOCITY * speed`), not per ms. This is related to the
  village speed items in `TODO.md`.
* **Villagers:** each villager has a `maps/Village/<Place>/villagers/<Name>.char`
  file with the image, start position, patrol instructions
  (`in angle distance stopped`), dialogs and triggers. Its frames are
  `res/Village/<Place>/villagers/<Name>/<Name>1..16.png`: 4 directions ×
  4 frames (`Sprite._moveImpl`: `ia[i + dir * size]`), 150 ms per frame,
  36×56 standard size. The position is the sprite's top-left corner, and the
  y sort uses it.
* **Cutscenes:** `maps/Story/Sequences/**/*.seq` is a timeline language
  (`actor name=… pos=x;y;dir`, `ins kind=dist|stop|emotion|screenzoom|music …`,
  `dialogsingle`, `dialogpacket`). It addresses actors in village pixel
  coordinates. **Constraint: the village coordinate space must not change.**

### 2.3 Dungeons (80 `.map` files)

* **Structure:** a first-person grid crawler. A floor is a graph of cells,
  numbered row by row on a 16-wide grid (`LabyrinthNode._init`:
  `address / 16`, `address % 16`). The links are given as
  `dir <from> <direction> <to>` (3,963 lines).
* **Geometry:**
  * Every cell is a 4×4×4 cube (`DISTANCE 4`, floor −2, roof +2).
  * There is a wall wherever a cell has no neighbour.
  * Textures are chosen per cell (`wall`, `floor`, `roof`, `normal` ranges;
    `wallTex/floorTex/roofTex` and the `S*` variants).
  * Special geometry: carpet floors (`Horizontal`) and pillar walls
    (`PillarWalls`).
* **Look per floor:** `light0`/`light1`, `material`, `invMaterial`, `fog`,
  `sky` (a gradient quad), `useSnow/useRain/useFire`, `enemyColor`,
  `battleMusic`, `steps`, `mission`. `light0 position=0;0;0;1` is set while
  the modelview is the identity, so it acts as a light at the camera.
* **Objects** ("inventory"): 564 `inv` lines of 25 kinds (counting the
  `--up/--down` variants):
  * `door` 137, `chest` 129, `hinderDoor` 88, `ladderDoor` 35, `button` 31,
    `save` 26, `riddle` 21.
  * Also `floorButton`, `iceButton`, `boss`, `villager`, `triggerDoor`,
    `missionChest`, `bomb` and others.
  * Each one is a flat textured quad facing one direction
    (`Inventory.draw` → `glVertex3f`).
* **Rendering:**
  * Walls, floors and roofs of all cells (no culling) are compiled once into
    a display list (`Labyrinth.init3D` → `LabyrinthRenderer.draw`).
  * Objects, weather (10,000 particles stepped in GDScript) and the minimap
    (`MapRenderer`, drawn in 3D) are resubmitted every frame.
  * The HUD and dialogs are drawn in 2D after `set2DNow`.
* **Movement:** `LabyrinthPlayer.moveTo/turnYTo` interpolates the camera
  between cells.
* **State:** `Database.getMap` → `LabyrinthInfo`/`LabyrinthMap` keeps the
  visited and seen cells and the inventory status, across visits and in
  saves. The keys are cell addresses and inventory database names, e.g.
  `The_Great_Mine--Tunnel.maphinderDoor51`. Buttons link to doors by these
  names, also across floors.

### 2.4 Other subsystems

| Subsystem | Files / lines | How it draws today | Data | Natural replacement |
|---|---|---|---|---|
| Organizer, game modes | 10 / 2,677 (Cheater 1,528) | fade quad, loading gate | `maps/Main/main.bank` (795 lines: 452 dungeon places, 84 story, 56 village, 6 boss, 3 world) | `Game` autoload with a place registry |
| Battle | 50 / 6,357 | camera-space 3D overlay inside the dungeon frame (eye-space z −2, enemies at their `depth`) | 44 `.enemy`, 10 `.script`, 193 enemy frames | `Battle.tscn`: AnimatedSprite3D enemies, card quads, Label3D, Control result screens |
| Cards + settings | 56 / 4,631 | 2D card pictures. Effects are built in code from `AnimationSettingsFactory` presets (no data files) | code only | `CardView.tscn`; one effect scene per card |
| Card/enemy particles | 31 / 1,952 | CPU simulation, additive quads, lit `gluSphere`s | 53 textures | GPUParticles3D / CPUParticles3D |
| Village particles (`bodies`, `commands`) | 32 / 1,975 | one 2D quad per body | `maps/ParticleSystems/particleSystems.info` (54 systems) | generated GPUParticles2D |
| Weather | 6 / 376 | 10,000 quads per frame, CPU view-cone test, extra "front" pass over battles | map flags | one GPUParticles3D |
| Sprites | 5 / 646 | `drawImage` of the current frame | `.char` files + frames | AnimatedSprite2D + SpriteFrames |
| World map + airship | 10 / 1,030 (+ `DoubleBackground` 505) | tiles + top layer like villages, road dots | 5 `.map` files (`node`, `road` + `co x y` points) | Node2D scene, Path2D roads |
| Menu | 21 / 3,024 | images + text at hard-coded 1024×768 positions | `Load`/`Database`; 10 tutorial files | Control pages + Theme; `.tut` → BBCode |
| Stores | 7 / 2,081 | 2D, menu pieces chosen by bitmask | `building` lines, `stores.bank`, `cardStores.bank` | one store scene template |
| Story texts, timelines | 6 / 1,219 (+ `villageStory` 5 files) | see 6.4 | 85 `.seq` (8,541 lines) | keep the parser; the runner drives nodes |
| Title, game over | 2 / 168 | images + fades | — | Control + Tween |
| Mini-games | 12 / 1,253 | 2D, started by dungeon `riddle` objects | 20 files in `maps/MiniGames` | Control scenes |
| Input | 6 / 584 | — | — | InputMap + a wrapper for the press-once/repeat behaviours |
| Sound | 3 / 335 | — | 179 `.wav`, 157 `.ogg` (intro + loop) | Music autoload, Music/SFX buses |
| Save/Load | 2 / 670 | — | line-based text (`Slot 1.sav`: 3,562 lines) | JSON or a Resource, plus a reader for the old format |

Couplings that matter for the plan:

* **Battles are not Organizer modes in dungeons.** `Labyrinth.enterBattle`
  makes `BattleManager` the `labDrawable`. The frame is then:
  1. walls;
  2. the weather back pass;
  3. the battle, in 3D, with the dungeon fog still on;
  4. the weather front pass;
  5. 2D result screens.

  Riddles are nested the same way.
* **Game logic waits on effects.** Damage is applied when a particle packet
  `isDestroyed()`, and the next card starts on `isReady()`
  (`battle/Animation.gd:154-163`). Enemy attacks are coroutines that walk
  their frames with `Scheduler.sleep`.
* **Several `draw()` methods change state:** `GLSlot.draw`,
  `BattleEnemy.draw`, `EnemySystem.draw`, `Creature3D.draw`, the
  `SlowParticleSystem`/`ImageParticleSystem` coroutines, and `drawEmotions`.
  Moving drawing to nodes must move these updates into `update`.
  *Found in phase 1:* the village drawing changes state too: the y-sort of
  `Village.elements` (Godot's sort is unstable, so its history matters),
  `Villager.drawX`/`drawY`, the emotion bubble positions (`drawSprite`),
  `ParticleSystem.position` and its texture init, `SmokeParticle.modifySize`
  (clamps the particle's life while drawing), `PartyMember.getMemberPos`
  in `DoubleBackground.drawTop`'s overlap test, the timeline's
  `elements` sort, and the GL state (colour, alpha test) the next drawing
  inherits. "Into `update`" is not equivalent while the frame order stays
  legacy: in the frame in which the Organizer leaves a mode, its `update`
  runs but its `draw` does not. Phase 1 therefore keeps these changes at
  draw time (`Village.update_draw_state`, docs/ARCHITECTURE.md section 9).
* **Saves store cards by Java class name** (`card cards.offense.BattleCard 2
  true`). The `ClassRegistry` names stay the stable IDs.

### 2.5 Time base

`update(ms)` passes milliseconds, but many systems step once per update or
once per draw, using the constant `LOGIC_INTERVAL = 1000/60`. The original
really ran at about 30 updates/s, so these run about twice as fast as
intended:

* `Fadeable` (0.03 per draw);
* the title logo, `AirShip`, `RiddleGame`, the Church blessing,
  `ScrollableTexts`;
* `DoubleBackground` camera moves and the village player step;
* `Hideable`, `FlatObj`, `GLCard`, `AttackText`, the enemy slice;
* weather and the save point particles.

Only the village/story particles and the card effects are corrected
(`Values.originalFrameStep`). Converting any motion to Godot nodes means
choosing per-second rates, so the target time base must be fixed first
(section 13).

## 3. Principles

1. **Strangler, not rewrite.** The game stays playable after every step.
   Legacy (`draw(g)`) modes and scene-backed modes coexist, and one game
   mode is converted at a time, villages first.
2. **Data → presentation → logic.** Each subsystem goes through three steps,
   each verifiable on its own:
   * **A (data):** move the content into scenes and resources. The
     unchanged legacy logic reads from them.
   * **B (presentation):** replace `draw(g)` with nodes that mirror the
     legacy state.
   * **C (logic):** only then make the logic idiomatic (physics, signals,
     `_process(delta)`).
3. **Keep the coordinate systems.** Village scenes use original pixels
   (1 unit = 1 px, origin at the background's top-left, y down). Dungeon
   scenes use the original units (4 per cell, same axes). Then `.seq`
   cutscenes, `.char` villagers, saves, Cheater jumps and AutoPlay scripts keep
   working unchanged.
4. **Scenes become the source of truth.** A converter (`.vil` → `.tscn`,
   `.map` → `.tscn`) runs once per place. When the place is verified, its text
   file is deleted (git keeps it). No round-tripping between formats.
5. **Measure parity.** Every conversion is checked in two ways:
   * AutoPlay screenshots, legacy renderer vs. scene renderer.
   * A data check that the scene yields the same obstacles, doors, signs, …
     as the old loader.
6. **New rules for new code.** `docs/PORTING.md` ("faithful, do not
   Godot-ify") stays valid for legacy files. New code follows a new
   `docs/ARCHITECTURE.md` (written in phase 0): typed GDScript, snake_case,
   one scene per concept, signals for events, no `J.*` helpers.

## 4. Target architecture

```
Main.tscn (Node)
├── World (Node)                    the active mode's scene: Village / Dungeon / Battle …
├── LegacyLayer (CanvasLayer 1)     GLBackend canvas items (under its Canvas Node2D) while legacy draw code remains
├── UI (CanvasLayer 2)              Dialog, SignBox, HUD, menu pages (Control + Theme)
└── Transition (CanvasLayer 3)      fades (ColorRect + Tween)

Autoloads (end state): Game (mode/scene switching; replaces Organizer +
GameModeQueue), GameState (Database + Load/party), Audio (music and effects
on buses), SaveSystem. Input through InputMap actions.
```

A `Camera2D` in a village scene moves the default canvas only. The
`CanvasLayer`s keep the legacy overlay, the UI and the fades fixed on screen.
Dungeon scenes render through the main viewport's own `Camera3D`, not through
GLBackend's per-chunk `SubViewport`s.

Folder layout:

```
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
src/                      legacy code (shrinks over time) + new scripts beside their scenes
tools/import/             converters (headless `--script`)
tools/parity/             screenshot comparison
```

## 5. Phase 0: groundwork

1. **Bridge: let a game mode own a scene.**
   * `GameMode` gets `var scene_root: Node` and
     `func create_scene() -> Node` (returns `null` for legacy modes).
   * When the Organizer activates a mode with a scene, Main adds it under
     `World`. When the mode is suspended (village → store/battle), it is
     removed from the tree but kept, so its state survives. When the mode is
     deleted, it is freed.
   * *As built:* Main creates the scene (`GameMode.ensure_scene()`) and
     shows it only once the mode is current and not loading, syncing at the
     end of every frame (the loading flag drops inside `Organizer.draw`).
     Modes are `RefCounted` and never freed explicitly, so "deleted" means
     the last reference went: a mode stays alive as
     `Organizer.previousGameMode` until the *next* mode switch, and its scene
     is freed then (`NOTIFICATION_PREDELETE`). Main also resets the
     viewport's canvas transform when the shown scene changes, because a
     `Camera2D` leaving the tree leaves its scroll behind.
   * GLBackend parents its canvas items to a `Node2D` under `LegacyLayer`
     instead of to Main. Legacy drawing (dialogs, fades, menus, HUD) then
     appears on top of the scene and is not moved by a scene's `Camera2D`.
   * For a scene-backed mode, `draw(g)` keeps only the overlays.
   * **Organizer semantics stay as they are** in this phase. The bridge
     only adds and removes nodes. The things it must not disturb:
     * The loading gate: no `update`/`draw` until `ImageHandler.load` is
       done and the mode sets `logicLoading = false`.
     * Exits are completed by the fade. `_fadeOutGameMode` advances inside
       `draw`, and `checkExit` fires on the next update. Entering the menu
       skips the fade.
     * The suspended-mode stack and the previous/current pair. The pair is
       used for music reuse, the menu thumbnail, `resumedFromMenu` and the
       save key.
     * Nested sub-modes that the Organizer never sees: `Labyrinth.labDrawable`
       runs battles and riddles inside the dungeon mode.
   * Fades and the pause overlay work unchanged, because the legacy
     full-screen fade quad (`GameMode.draw` → `fadeOldSchool`) is drawn on
     `LegacyLayer`, above the scene.
   * Frame captures need no change. `Graphics.copyFrame` (used by
     `enterMenu()` for the menu thumbnail) already reads the main viewport
     texture, so it includes scene content.
2. **Parity tooling** (`tools/parity/`).
   * Run an AutoPlay script twice, with `--legacy=<subsystem>` and without,
     then diff the screenshots with a tolerance and write diff images.
   * Golden runs are recorded before each phase.
   * First test: a self-diff of the current renderer must be 0.
   * *As built:* a self-diff is only 0 in a deterministic run
     (`--seed=<n>`, see `docs/ARCHITECTURE.md` section 7). Besides the
     seeds, it needed a game clock for `Scheduler` (its `sleep()` used
     SceneTree timers, i.e. real time), `GameAction` key repeat and
     `J.currentTimeMillis()`, and saves isolated from the player's: with
     `--load`, a slot saved in `user://saves/` shadows the shipped one.
     The tool also compares the AutoPlay state logs, and passes the engine
     option `--fixed-fps 60` so node `delta`, timers and Tweens are fixed too.
3. **Conventions.** Write `docs/ARCHITECTURE.md`. Point `PORTING.md` and
   `HANDOFF.md` to it.
4. **Pilot choice.** Zazo exercises almost everything: four variants
   (day/night × two statuses), particles, doors, signs, loot and cutscenes.
   Add one small interior next to it (e.g. `Zazo - Teo's House`).
   *As built:* the pilot interior is "Zazo - Miner's Home".

**Exit:** a test mode with a scene renders under the legacy overlays and
fades; the parity tool works.

## 6. Phase 1: villages as scenes

### 6.1 Scene layout (per place)

```
Zazo.tscn (Node2D, VillageScene.gd)   @export place_name, music, land_name, inside, wind, size, actual_size, offset
├── Background (Sprite2D, centered=false)   one texture stitched from the 256 px tiles (night: its own texture)
├── Ground (Node2D)                         bottom-layer particle systems
├── Actors (Node2D, y_sort_enabled)         villagers, animated objects, villager-layer particles; party added at runtime
├── Overhead (Node2D, z_index 10)           one Sprite2D per top.info piece (alpha scissor 0.9)
├── Night (Sprite2D)                        night overlay, when present
├── Effects (Node2D, z_index 20)            upper/weather-layer particle systems
├── Obstacles (StaticBody2D)                CollisionShape2D + RectangleShape2D per `o` line (original, un-inflated)
├── Spawns (Node2D)                         Marker2D start0, start1, … (facing as metadata)
├── Doors (Node2D)                          Door.tscn (Area2D): kind, target, rect, locked, fade, to_pos, sign lines, is_hole
├── Signs (Node2D)                          Sign.tscn (Area2D): lines, facing directions, width
├── Loot (Node2D)                           Loot.tscn: content, amount, statuses, lines
└── (buildings)                             Array[BuildingInfo] exported on the root
```

* **Variants.** `Zazo.tscn` holds what all variants share: the art, the top
  layer, and the obstacles they all agree on. Each `.vil` becomes an inherited
  scene (`Zazo - 1.tscn`, `Zazo at Night - 1.tscn`) that adds its own doors,
  villagers, signs, buildings, particles and extra obstacles.
  `VillageLoader.load` keeps its file-choice logic; it only points at a
  `.tscn` instead of a `.vil`. The alternative is one scene with a
  `statuses` filter per node; see section 13.
* **Order matters.** The converter keeps child order = file order. Doors and
  signs are searched in order, and the first one in range wins.
* **Top layer.** Always draw the pieces above the actors with alpha
  scissor 0.9. This matches the original: where no sprite overlaps a piece,
  the piece is identical to the background under it. A later improvement is
  to give the pieces a y-sort origin, so that actors can walk in front of
  their lower parts.
* **Actors.** An `ActorView` (`AnimatedSprite2D`, `centered = false`) has its
  origin at the legacy `pos` (top-left), so Godot's y sort orders actors
  exactly as `Village.drawBottom` does.
* *As built (pilot):* every place scene inherits a template,
  `scenes/villages/VillageScene.tscn`, so there are three levels (template,
  `<Place>.tscn`, variant). `Ground` comes before `Background`: the legacy
  code draws the bottom-layer systems before the tiles. The scene types are
  `VillageDoor`, `VillageSign`, `VillageLoot`, `VillageSpawn` (the plain
  names are legacy classes); buildings are `VillageBuilding` resources.
  Godot's y sort is *not* the legacy order: ties (party members stand on one
  spot; the legacy sort is unstable), the sort keys of particle systems
  (`-(emitter.y + 56)`) and cutscene props (±10000), and a cutscene draws its
  actors after the village's own sprites. Step B therefore orders the
  `Actors` children explicitly; y sort stays on for the editor.
* *As built:* **the top layer claim is wrong for Zazo.** The PNG pieces are
  not identical to the JPEG tiles under them (darker, crisper, up to 90/255
  per channel). In the original a treetop visibly changes when a sprite
  walks under it. Drawing the pieces always, as planned, makes them look the
  same everywhere, but no longer pixel-identical to the legacy picture where
  no sprite overlaps them; `--legacy=village_top_layer` keeps the legacy
  rule for parity runs. 43 of the 3,530 `o` rectangles have zero width or
  height; none are inverted.

### 6.2 Converter `tools/import/vil_to_scene.gd`

* Runs headless (`Godot --headless --script …`). It reads the `.vil` with
  the same `AbstractMapLoader` tokenizer and maps each command's tokens to
  typed, exported node properties.
* Stitches the tiles of each background (and night background) into one PNG.
  Import it lossless without mipmaps.
* Computes the base/variant split across a place's `.vil` files.
* Generates one `SpriteFrames` resource per villager image set (4 directions
  × 4 frames, 150 ms) and per `animObj` series.
* Writes scenes with `PackedScene.pack()` + `ResourceSaver.save()`. Every
  created node needs `owner = root`, or it is silently left out.
* *As built:* `pack()` cannot start an inherited scene by itself (the
  inherited state is only set when a scene that already inherits is
  instanced with an edit state): the converter writes a three-line bootstrap
  file naming the base, instances it with `GEN_EDIT_STATE_MAIN`, adds the
  nodes and packs. Godot 4.7 gives every node a random `unique_id`; the
  converter removes them so that converting twice writes the same files. It
  runs in two stages with Godot's `--import` between them (the scenes need
  the stitched PNGs imported). Each `particlesystem` line gets one
  `SystemLoader` (the legacy loader shares its settings objects between the
  systems of a line; Home of the Gods depends on it). Workflow:
  `docs/CONVERTING_VILLAGES.md`.

### 6.3 Step A: data from scenes, logic unchanged

* If `scenes/villages/<Place>/<file>.tscn` exists, `VillageLoader`
  instantiates it and builds the legacy objects from the nodes instead of
  parsing the `.vil`:
  * obstacles → `ObstacleHandler.addObstacle`, with the same inflation;
  * doors → `StoreDoor`; signs → `Sign`; loot → `Loot`;
  * villagers → `Villager`; particle names → `SystemLoader`.
* Gameplay is identical by construction.
* `tools/import/verify_villages.gd` builds every variant both ways and
  compares the resulting objects field by field.
* *As built:* the builder replays the commands in the order every `.vil`
  file has (background, back, offset, start, o, wind, particlesystem, then
  the rest; checked for all 89), so the Database writes, the random numbers
  of the particle warm-up and the sprite map order match. Quirks are data:
  a two-line sign is listed twice, a taken loot's `lootLine`s go to the
  previous loot, unknown commands (`doorSignFL`, `sigin`, stray text) are
  ignored. A dry run of all 89 files (data only) passes: 240 builds (every
  start position, saves "Slot 1" and "Start"). "Zazo at Night - 0" names an
  equipment "2" as loot, for which the original exits the game unless the
  loot is already taken.

### 6.4 Step B: nodes draw the village

* `VillageScene` is shown under `World`.
* A `Camera2D` mirrors the legacy scroll offset (`-DoubleBackground.pos`)
  every frame.
  * The legacy scroll logic stays in charge during step B: `BACK_POS`,
    `setDrawPos`, and the cutscene moves `moveTo/moveScreen/stopScreen`.
    Legacy overlays that are still drawn with that offset (emotion bubbles)
    therefore stay aligned with the scene.
  * The cutscene zoom (`screenzoom`) sets the camera zoom.
  * In step C, the `Camera2D` with limits = background size and following
    the player takes over. That is what the middle-band logic does today.
* `ActorView` nodes mirror each legacy sprite's position, direction and
  animation frame every frame. The legacy `Villager`, `PartyMember` and
  `AnimatedObjects` objects stay the logic.
* `Village.draw` keeps only emotions, dialogs and signs (legacy overlay)
  until phase 3.
* **Cutscenes switch in the same step.** `VillageStoryTimeLine` (815 lines)
  draws the village itself: bottom → actors sorted by y → top → emotions →
  dialog → fade → texts.
  * Its actors become `ActorView`s in the same `Actors` node.
  * Its image modes (backflash, translucent over/under actor, cover-all,
    story image; `VillageStoryTimeLine.gd:601-674`) become a `StoryImage`
    node placed under, inside or over the `Actors` layer.
  * Its zoom (`time / LOGIC_INTERVAL` steps per update) drives the
    `Camera2D` zoom.
  * The `.seq` parser and timeline stay as they are. Converting 85
    sequences (8,541 lines) to `AnimationPlayer` would be a poor fit: events
    wait for input, actor arrival and Database triggers.
* **Particles.** The 54 village and story systems in
  `maps/ParticleSystems/particleSystems.info` (+ `particles.var`, parsed by
  `SystemLoader`) are converted by a generator into `GPUParticles2D` scenes
  in `scenes/common/particles/`. The mapping:
  * Emitter shapes: line → thin rotated box, box → box, circle → ring,
    image → emission points baked from the alpha.
  * Forces: force → gravity or initial velocity; shared wind → turbulence.
  * Lifetime and size: fade → lifetime; smoke growth → scale curve.
  * Behaviour: master/slave (fire spawns smoke) → sub-emitter at end of
    life; `warmUp` → `preprocess`.
  * Drawing: additive → `CanvasItemMaterial` ADD; layer → which layer node
    the system goes in.

  The size and fade laws of the five particle classes need hand tuning
  against parity shots. Until a preset matches, an interim
  `LegacyParticles2D` node runs the legacy simulation and draws its quads in
  `_draw()`.
* `--legacy=villages` keeps the old path available for parity runs until
  the phase ends.
* *As built (pilot):* the village hands the scene what its legacy drawing
  would have drawn, at the point where it drew (in `draw`, see 2.4), with
  the GL colour and alpha test of each part: the sprites' soft edges are
  alpha tested (0.1 after the particle systems), so mirroring positions and
  frames alone is not pixel-exact. `LegacyParticles2D` draws the quads the
  legacy particle draw computes (it does not run the simulation, so no time
  base is needed). `StoryImage` only takes the image modes drawn under the
  actors (backflash, translucent under actor): the others are drawn over the
  emotion bubbles, which stay legacy until phase 3, so those images stay in
  the legacy overlay too. A cutscene shows its village's scene through
  `GameMode.shown_scene()`; the village keeps owning it. Details:
  docs/ARCHITECTURE.md section 9.

### 6.5 Step C: logic (optional, later)

* The player becomes a `CharacterBody2D` with a small foot collider against
  the un-inflated rectangles, moved with `move_and_slide()` per delta. This
  also fixes the fixed-step and diagonal speed issues in `TODO.md`.
* Doors, signs and loot use `Area2D` signals.
* Villagers become nodes that own their instruction follower.
* This changes how movement feels, so it needs playtesting. It is a separate
  decision (section 13).

### 6.6 Order and exit

* Order: Zazo (all four variants) → interiors (small, mostly one file each)
  → the remaining towns.
* Delete each `.vil` after its parity and data checks pass. The village
  paths in `DoubleBackground` go away with the last place; the world map still
  uses it (phase 4).
* **Exit:** all 89 variants load from scenes; `tools/autoplay/village*.txt`
  and the story scripts pass parity; `Village`/`VillageLoader` contain no
  world drawing.
* *As built:* the pilot did Zazo; the rollout converted the 36 interiors,
  then the 25 other places, in one session each (the converter is fast:
  about 20 s per batch). Steps A and B are done for all 89 variants (6.8).
  No `.vil` file is deleted (decision 5 is open), so `--legacy=villages`
  and the data check still work. What closing the phase needs is in 6.9.

### 6.7 Pilot results (Zazo, Zazo - Miner's Home)

* **Coverage:** six parity cases (`zazo_0`, `zazo_1`, `zazo_night_0`,
  `zazo_night_1`, `zazo_story_node1`, `zazo_story_gerbias`; 113 shots),
  recorded on unconverted code with the ten older cases (goldens of all 16);
  a second recording of the new cases is identical.
* **Step A:** golden vs. after step A: all 289 shots and all 16 logs
  identical. `verify_villages.gd`: the pilot (20 builds: 5 variants × their
  start positions × saves "Slot 1" and "Start") and a data-only dry run of
  all 89 `.vil` files (240 builds) pass.
* **Step B, other cases:** golden vs. after: 176 shots identical, logs
  identical. The bridge test (Alares, unconverted) is identical to its
  phase 0 recording.
* **Step B, Zazo, legacy vs. scene with `--legacy=village_top_layer`:** 100
  of 113 shots identical, logs identical. The 13 others are the frames of
  Zazonode1's zoom (2× around 512,768): the legacy code magnifies each
  256 px tile on its own, so its tile seams show; the stitched background
  has none (322–914 pixels per frame over 4/255, all on the seams), and the
  bilinear filtering of the magnified textures rounds differently (≤ 4/255,
  mostly 1, on 1–3 % of the pixels).
* **Step B, Zazo, default (top layer always drawn):** in addition, every
  village frame differs inside the top layer pieces that no sprite overlaps
  (the PNG pieces over the JPEG background, up to 90/255, 10–22 % of a
  frame); cutscene frames are identical except the zoom.
* **Frame rate** (normal runs, Zazo, `zazo_0` route): 60 FPS either way when
  capped; uncapped about 240–255 FPS legacy and 400–485 FPS with the scene.
* **Still legacy:** Village draws the emotion bubbles, dialogs, signs (and
  their card info), the fade and the menu thumbnail capture;
  VillageStoryTimeLine the emotions, dialogs, texts, scroll texts, fades and
  the cover-all, story, village and translucent-over-actor images. The
  `.vil` files stay (decision 5); the converter, the data check and
  `--legacy=villages` read them.

### 6.8 Rollout results (the other 61 places)

* **Baseline** (on the commit after the tickets COTZ-001 to 011): goldens of
  the 17 existing cases; a second recording of the six Zazo cases is
  identical (113 shots); the pilot's check (`ab "--legacy=villages"
  "--legacy=village_top_layer"` on the Zazo cases) gives exactly 6.7's
  result: 100 of 113 shots identical, the 13 others the frames of
  Zazonode1's zoom, with the same pixel counts. `story_long` no longer
  reached the opening story (its first CROSS came before the title menu
  took input, so it loaded a save into Menthu's Lair); fixed (first wait
  4 s), it shows the Prolog for 3 minutes.
* **Coverage:** 101 new cases (`tools/parity/cases.txt`), recorded on
  unconverted code: a tour of each of the 72 variants a main.bank place
  reaches (`tour_*`, one script for all: `village_tour.txt`), four particle
  cases (`particles_*`: Home of the Gods with every god system active,
  Dellna's snow and four smokes, Pensara North's wind -10 and turbulence 1,
  the Pass to Zazo fire sorted with the sprites) and 24 cutscenes
  (`story_*`: backflash, translucent under actor with the village
  background swap, colour tints, props on the bottom and top layers,
  cover-all and story images, scroll text, zooms, Circle held, and every
  place only cutscenes reach). A second recording of the 101 is identical
  (2,487 shots, logs identical). Two findings on the way: a game pad that
  connects during a deterministic run releases AutoPlay's buttons (fixed:
  `--seed` runs read no pad), and the world map mode leaked (fixed, 8).
* **Not reachable:** "Pensara - The North District - Farmer House" (quits
  the game on entry: a villager's patrol is not closed): data check and
  preview only. Dorma's Tranquility and Menthu Battle (no place, story, door
  or world map node names them) and Tutorial1 (no main.bank entry) were
  removed in COTZ-034.
  `fadeparticlesystem` and the rain/sand particles never run (appendix).
* **Converter:** the pilot's converter handled one-image backgrounds,
  PNG tiles with alpha, `as=1:1` and own night images already; the
  rollout added the base/variant split of the art (the background most
  variants draw goes into the base, the others override it; the top layer
  is shared on its own), stitching a background shared by two places once,
  `animObj` SpriteFrames (an untyped array broke them; the pilot had no
  `animObj`) and warnings for tokens that are no integers. Converting twice
  changes none of the 455 files; the pilot's scenes are unchanged.
* **Step A:** `verify_villages.gd --all` with the saves "Slot 1" and
  "Start": 240 builds (89 variants × their start positions × 2 saves), all
  pass.
* **Step B, legacy vs. scene with `--legacy=village_top_layer`** (the 113
  cases that show villages, 2,639 shots, `--ignore-world`): all logs
  identical; 2,213 shots identical: every tour, the particle cases, the
  Alares cases (`village`, `village_walk`, `stores`, `menu_pages`), the
  Prolog cases (`story_long`, `title_start`, `newgame_to_forest`) and every
  cutscene frame without a zoom. The 426 others:
  * 334 frames of cutscene zooms in nine stories and `zazo_story_node1`
    (each one confirmed by AutoPlay's `[zoom]` line): the legacy tile seams
    and the bilinear rounding of 6.7, up to 75/255 on 0.01–5 % of a frame.
    After a zoom out the timeline's scale stays at 1.00007 (its velocity sum
    is 79.994/80) and `scaling` is never reset, so every later frame of the
    cutscene is resampled too, with differences of 1–3/255.
  * 92 frames of "Ending - Part 3": its credit images are drawn at size
    0.65 under the actors (image mode 0, backflash); 1/255 on at most 212
    pixels (resampling rounding), after the fix below.
* **Step B, legacy vs. scene, default** (the top layer always drawn,
  decision 7): in addition, 1,090 shots differ, and exactly where the two
  scene runs differ (`compare stop sdef`): inside the roofs and treetops no
  sprite overlaps. No cutscene frame changes (the legacy cutscene draws
  every piece); the 24 such shots of story cases are taken in the village
  after the story.
* **Fixed in the bridge** (both in code the pilot never ran): a cutscene
  prop added to the village's layers is drawn twice by the legacy code
  (among the village sprites and again as an actor), so `show_actors` gives
  a repeated key a second view ("Arrival at the Port Town of Parasne");
  a scaled under-actor image covers the legacy's whole-pixel rectangle
  (`GameTexture.drawPart` truncates its far corner), so
  `VillageStoryTimeLine.image_entry` scales it per axis.
* **Cases that stay legacy** (`battle`, `boss`, `landscape`,
  `bridge_test`): golden vs. after differs in 51 of 131 shots, all from the
  game pad: golden was recorded while a DualSense was connected (PlayStation
  button hints in the battle help panel, the floor message's state in the
  bridge test's menu thumbnail), the runs after the pad fix show keyboard
  hints. The same cases recorded with `--legacy=villages` are identical to
  the run without it (131 of 131), so the conversion does not touch them.
  Likewise golden vs. the legacy run after the conversion
  (`--legacy=villages`): 2,516 of 2,526 shots identical; the others are the
  pad (9 `menu_pages` shots) and Zazo (already a scene in golden).
* **Frame rate** (normal runs, windowed, the tour or particle route; the
  median of the village frames, legacy (`--legacy=villages`) → scene):

  | Place | Capped | Uncapped |
  |---|---|---|
  | Alares | 60 → 60 | 401 → 738 |
  | Pensara - The Trade District | 60 → 60 | 292 → 471 |
  | Home of the Gods (stars, door systems) | 60 → 60 | 258 → 434 |
  | Home of the Gods, all 12 god systems active | 6 → 6–7 | 6 → 6 |
  | Dellna - 0 (snow) | 12 → 18 | 12 → 18 |

  The last two are bound by the particle simulation in GDScript (6,000 snow
  particles; 12 × 3,000 god particles), in both paths: the drawing is not
  the bottleneck there. This contradicts HANDOFF's "everything else runs
  at 60 FPS": Dellna's snow runs at 12 FPS in normal play. A GPU preset
  (6.4, after decision 6) is the way to remove it.

### 6.9 Closing phase 1 (prepared, not done)

Removing the legacy village path deletes or changes (line counts as of the
rollout, including doc comments):

| Part | Lines | Still used by |
|---|---|---|
| `.vil` loading: `VillageLoader.VillageLoaderMapLoader` (inner class) | 244 | `--legacy=villages`, `tools/import/verify_villages.gd` |
| `Door.getDoor` (a door line), `Loot.getLoot` (a loot line) | 40 + 25 | only `VillageLoaderMapLoader` |
| `VillageLoader.village_scene_for`'s `--legacy` check, `load`'s `.vil` branch | ~5 | — |
| `Village.drawBottom`, `drawTop` and the legacy branch of `draw` | 18 + 5 + 3 | `--legacy=villages`; `sortSprites` (15) and `drawOverlays` (15) stay (the scene path and the overlays use them) |
| `VillageStoryTimeLine.draw`'s legacy branch | ~25 of 47 | `--legacy=villages`; `draw_scene`, `sortActors`, `drawTop` (overlays) stay |
| `DoubleBackground`: `loadImages` (village tiles), `init`, `putextra` (dead while `USE_CUT`) | 24 + 19 + 2 | the scene path still builds a `DoubleBackground` per village (`load_into` → `loadImages`), for its scroll logic, particle system lists and top-layer list: it also loads the tile textures the scene does not draw (wasted texture memory until the scroll moves to the camera, step C) |
| `DoubleBackground`: `doit`, `cutImage`, `cutImage2`, `generateNames`, `doTopLayer`, `drawBottom`, `drawBottomLayer`, `drawTop`, `drawSystem` | 29+14+40+14+19+5+22+42+4 | stay: the world map and the airship (`setLandscapeImages`, `drawBottom`, `drawTop(g, false, null)`) until phase 4.1 |
| `DoubleBackground.overlapped_pieces` | 33 | stays while `PartyMember.getMemberPos` is updated there (a state change of the legacy `drawTop`) and for `--legacy=village_top_layer` |
| Sprite draws: `Villager.draw` 10, `PartyMember.draw` 6, `AnimatedObjects.draw` 6, `DefaultSprite.draw` 6, `Actor.draw` 5, `bodies.system.ParticleSystem.draw`/`drawIt` 31, `BodySystem.draw` 5, `Body.draw` 8 | 77 | `--legacy=villages` only; `Sprite.draw`/`drawSprite`/`drawAtPosition` stay (the world map's `LandPlayer`); the `place_*` twins stay (the scene path) |
| `--legacy=villages` and `--legacy=village_top_layer` (`Main.is_legacy` calls in `VillageLoader`, `Village.scene_top`) and the parity cases' legacy runs | ~10 | `Main.is_legacy` stays for later phases |
| `tools/import/verify_villages.gd` | 242 | needs `VillageLoaderMapLoader` and the `.vil` files |
| the 89 `.vil` files (decision 5) | 6,865 (132 KB) | the converter (`vil_to_scene.gd`, 911 lines), the data check, `--legacy=villages` |

What keeps the exit criteria of 6.6 from being met today:

* "All 89 variants load from scenes": met.
* "`village*.txt` and the story scripts pass parity": met except the frames
  of cutscene zooms, where the legacy drawing magnifies each 256 px tile on
  its own (seams) and rounds differently (6.7, 6.8); and by default the
  top layer is always drawn (decision 7). Closing needs these accepted as
  the expected differences (a tolerance or a list), not fixed.
* "`Village`/`VillageLoader` contain no world drawing": not met while
  `--legacy=villages` exists (`drawBottom`, `drawTop`, the legacy branch of
  `VillageStoryTimeLine.draw`).
* "Delete each `.vil`": decision 5 is open.
* Particles are still `LegacyParticles2D` (the legacy simulation's quads):
  a GPU preset needs decision 6 (time base). The exit criteria do not
  require it, 6.4 does.
* The emotion bubbles, dialogs, signs, fades and the cover-all/story/
  translucent-over-actor cutscene images are legacy overlays until phase 3
  (not part of the exit criteria).

## 7. Phase 2: dungeons as scenes

### 7.1 Representation

Options considered:

* **`GridMap` + `MeshLibrary`:** fits floors and roofs, but walls sit on cell
  edges. That needs rotated variants per texture and several GridMaps per
  floor.
* **A baked mesh in the scene:** fast, but the layout is no longer editable.
* **Chosen: a `DungeonFloor` `@tool` node + a `DungeonLayout` resource.** The
  resource holds the cells (address → neighbours), per-cell texture choices
  and carpet/pillar flags. The node builds the mesh (one surface per texture,
  with `SurfaceTool`) both in the editor and at runtime, so the floor can be
  seen and edited in the editor. The geometry code is a mechanical port of
  `LabyrinthNode.draw/drawOneWall`, `Horizontal` and `PillarWalls` from
  `glVertex3f` to `SurfaceTool`. A later editor plugin can toggle
  connections by clicking cell edges.
* *As built (pilot, 7.7):* as chosen, with one surface per material of the
  legacy display list (a texture with its GL state), in the list's order
  (the passes floor, roof, wall, carpet, pillar; materials by first
  appearance), all in one MeshInstance3D. No editor plugin yet.

### 7.2 Scene layout

```
dungeons/The Great Mine/Tunnel.tscn (Node3D, DungeonScene.gd)
│   @export map_pos, steps_to_battle, battle_music, mission, enemy_color, style
├── Layout (DungeonFloor @tool)          layout: Tunnel.layout.tres → MeshInstance3D children
├── Environment (WorldEnvironment)       fog (exponential density + colour), background colour or sky gradient
├── Objects (Node3D)                     Chest, Door, HinderDoor, LadderDoor, Lever, SavePoint, Riddle, Boss …
│                                         @export cell, facing, frames, statuses, links (database-name strings)
└── Weather (GPUParticles3D, optional)   snow/rain; follows the camera rig
Player rig (added at runtime): Node3D → Camera3D (fov 45, near 1, far 75) + OmniLight3D (light0 headlamp)
```

* **Style resource** (`DungeonStyle.tres`): the texture slots for floor, wall
  and roof, materials from `material`/`invMaterial`, light and fog values.
  Floors of one area share it (e.g. every Great Mine floor).
* **Lighting.** Two ways to light the dungeons, chosen per area (section 13):
  * Keep the fixed-function look exactly: reuse GLBackend's lighting/fog
    shader code as a `ShaderMaterial` with per-style uniforms.
  * Modern: an `OmniLight3D` on the camera with attenuation fitted to
    `1 / (c + l·d + q·d²)`, plus `StandardMaterial3D`. Verify it with parity
    screenshots.
* **Objects** are `Sprite3D`/`AnimatedSprite3D` nodes, sized and offset as
  `Inventory.setSettings` does (Y height, Z offset, scale). Database names
  are still derived from map name + kind + cell address, so saves and
  cross-floor links stay valid.

*As built (pilot, 7.7; `docs/ARCHITECTURE.md` section 10)*, where it differs
from the sketch:

* `map_pos` is in the layout and the enemy colour in the style; the root
  also exports `map_name` and the mission as MapLoader keeps it.
* `Environment` has neither fog nor sky: the dungeon shader does fog and
  light (decision 2), the background is the clear colour, and the sky is a
  quad of the walls' mesh, as in the display list.
* `Weather` is an interim node (`DungeonWeather`: the legacy simulation's
  quads, one mesh per pass and frame), not `GPUParticles3D` (decision 6 is
  open).
* The rig is part of the scene (`Rig/Camera`, at mark 0 in the editor), with
  no light: light0 is a shader uniform. At run time the camera stays at the
  origin and the floor and objects move (7.5).
* A style per distinct look, not per area: the floors of an area share
  `<Area>.tres` where every value agrees (light, material, fog, sky,
  textures, slot ranges, weather, enemy colour), a floor that differs has
  its own. 23 of the 80 floors have their own, 57 share their area's (20
  area styles; the pilot counted 25, 7.8). Forest Path and Deep Forest
  differ in rain, fog, light1, sky and enemy colour.
* The objects' Views (`AnimatedSprite3D` with SpriteFrames) show the floor in
  the editor; at run time they only mirror their frame and stay hidden, and
  the legacy quads are drawn instead (7.7).

### 7.3 Converter `tools/import/map_to_scene.gd`

* Runs `MapLoader` on each `.map`, then writes the layout resource, the
  scene and the object nodes.
* Groups floors by area (`<Area>--<Floor>.map`) and extracts the shared
  styles.
* *As built:* a subclass of MapLoader reads each file, so every value is
  the legacy loader's; the area's style is the look most of its floors
  have. It also writes the image series' SpriteFrames and sets
  `detect_3d/compress_to=0` in the used textures' `.import` files (the
  editor would otherwise VRAM-compress a texture it sees on a 3D material,
  which changes the legacy drawing too). Results in 7.7.

### 7.4 Step A: data from scenes

* `Labyrinth.init` builds `Graph`, the nodes and the inventory from the scene
  instead of from `MapLoader`.
* A verifier compares the graph, walls, textures and inventory with the old
  loader output for all 80 files.
* *As built:* `MapLoader._init` builds a converted floor from its scene, so
  both `Labyrinth.init` and Load's saved floor maps use it.
  `verify_dungeons.gd` also compares the renderer, the weather system, the
  mission, the Database after the build and the random numbers, and
  (`--meshes`) the walls' mesh with the display list.

### 7.5 Step B: nodes draw the dungeon

* `DungeonScene` is shown under `World`. The camera rig mirrors
  `LabyrinthPlayer` (position and angle) every frame.
* `init3D`, the display list and `graph.drawInventory` are removed.
* Weather → `GPUParticles3D`. This removes the documented 20–30 FPS
  bottleneck.
* The minimap (`MapRenderer`) becomes a 2D `Control`, or a `SubViewport` if
  its 3D tilt must stay.
* Expected side effect: the walls-seen-through-walls bug disappears,
  because the geometry is opaque with real depth testing.
* **Battles stay legacy in this phase** and are drawn by GLBackend on
  `LegacyLayer`, in their own 3D chunk over the scene. Consequences:
  * The legacy GL fog and light state the battle relies on must still be set
    (`LabyrinthRenderer.addFog/addLight`) until phase 4.
  * Battle objects no longer share a depth buffer with the walls. The
    original does share it; whether walls ever clipped enemies (enemies sit
    at eye-space z ≈ −6, a wall can be 2 units away) is unverified.
  * The weather front pass over the battle is lost until phase 4, unless
    the legacy front pass is kept just for battles.

  Compare `tools/autoplay/battle.txt` shots before and after, and decide
  deliberately.

*As built (pilot, 7.7)*, where it differs:

* The camera does not follow the player. It stays at the origin, and
  `Layout` and `Objects` get the legacy modelview as their transform, as
  GLBackend draws (its camera at the origin, the display list under the
  modelview). A camera moved by the inverse view rounds differently, and
  the eye-space meshes (objects, weather) need a camera at the origin. The
  rig matters only in the editor; step C turns this around.
* `init3D`, the display list and `graph.drawInventory` are not called on the
  scene path; they stay for `--legacy=dungeons`.
* **The weather is not GPU particles, and the scene does not fix the frame
  rate.** Decision 6 is open, so the interim node draws the legacy
  simulation's quads. In Forest Path the GDScript simulation
  (`WeatherSystem.update`) takes ≈10 ms of a frame and computing the back
  pass's quads ≈13 ms (the front pass ≈1 ms), in either path: ≈24 of the
  ≈33 ms. The scene only saves the emulation's drawing of them (27 → 30
  FPS). The FPS fix needs GPU particles (or a faster simulation), so it
  depends on decision 6.
* The minimap stays legacy (`MapRenderer`, 3D), drawn into the scene's
  World3D by the 3D bridge. As a 2D `Control` its half-transparent disk
  would blend in sRGB and come out darker. Recommended for phase 3: a 3D
  node on the rig (or a SubViewport that blends in linear space).
* **The walls-seen-through-walls bug stays; it is not a depth problem.**
  *(Fixed in the rollout, in both paths: 7.8.)*
  GLBackend's lit shader multiplies the lit colour by the current glColor.
  OpenGL 2 ignores glColor while lighting is on unless `GL_COLOR_MATERIAL`
  is enabled, and the Java never enables it. On a floor with a sky the
  display list is compiled after renderSky's last glColor, so the walls take
  the sky's bottom colour and its alpha:
  * Deep Forest: 0.8, blended, so walls show through walls (`TODO.md`:
    "Some walls are seen through others").
  * Forest Path: grey 0.45, darker.
  * Empyrian Temple--Dark: 0;0;0, the walls and floors render black (one
    legacy screenshot; its fog is thin and its light moderate).
  * Five floors have a sky alpha of 0.8, 18 have a sky.

  For the same reason the objects take the minimap arrow's yellow from the
  previous frame. Decision 2's exact look reproduces all of this. A fix
  changes GLBackend and the dungeon shader together (new goldens). The sky
  gradient is a further emulation bug: the emulated display list does not
  record renderSky's `glLoadIdentity`, so the sky is a world quad near the
  origin and the view shows the clear colour. *(Both fixed in the rollout:
  a lit vertex ignores glColor, the display list keeps renderSky's
  gradient in eye space; 7.8.)*
* **Battles: the listed consequences do not occur.** The 3D bridge
  (`GLBackend.scene_3d`, ARCHITECTURE section 10) draws the frame's first 3D
  chunk into the scene's World3D. So the battle shares the depth buffer and
  the linear blending with the walls as before. The legacy front weather
  pass stays over battles. The GL fog and light state is set as before
  (`Labyrinth.init_scene_3d`). `battle` and `dungeon_tunnel_battle` are
  identical legacy vs. scene. Whether walls ever clip enemies is still
  unverified; it no longer matters for the hybrid period.

### 7.6 Step C: logic (later)

* Moving and turning become Tweens on the rig.
* Objects emit signals (`interacted`, `opened`).
* `LabyrinthPosition` and `Camera` go away.

**Exit:** all 80 floors load from scenes; the dungeon AutoPlay scripts
(`newgame_to_forest`, `battle`, `boss`) pass; `src/labyrinth` contains no GL
calls.

### 7.7 Pilot results (Forest of Reil, The Great Mine--Tunnel)

* **Baseline** (on the phase 1 commit): `tools/check.sh` 0 failed; goldens of
  all cases. The dev additions for the coverage (`--no-encounters`, `pos`
  in labyrinths) change none of the 117 older cases (2,770 shots identical
  to a recording before them).
* **Coverage:** 14 new cases (`dungeon_*`, 158 shots), recorded on
  unconverted code. A second recording is identical:
  * tours of the three floors with "Slot 1" and "Start" (one script,
    `dungeon_tour.txt`);
  * Forest Path in the rain and fog with its hinder door and save point;
  * Deep Forest's crate and leaving through its door;
  * the Tunnel's mission display and miner, its lever and the hinder door
    it opens;
  * a battle in the Tunnel (no weather);
  * the menu's map page after a walk;
  * entering the Forest of Reil from the world map. No world map node leads
    to Forest Path; only the opening story does (`newgame_to_forest`).

  Older cases through the pilot floors: `battle` (Forest Path, rain),
  `newgame_to_forest`, `story_having_fun`. Labyrinth cases on unconverted
  floors: `bridge_test`, `story_meanwhile_in_zazo`,
  `story_menthu_kills_teo`, `story_senate_of_pensara`.
* **Checked on the legacy drawing:**
  * `Labyrinth.draw`'s order: the walls (display list), the objects in Graph
    order, lighting off, the weather's back pass, a battle or riddle, the
    front pass (also over a battle), then without depth the minimap (3D),
    and in 2D the mission, dialog and card info, the battle's top layer, the
    top layer and the fade.
  * The projection is GLBackend's `gluPerspective(45, 4/3, 1, 75)`.
  * light0 is set under the identity, so it is a headlamp; light3 has fixed
    values (`LabyrinthRenderer.setLight`).
  * The fog is `GL_EXP` with the map's density and colour.
  * The two emulation bugs of 7.5 (glColor on lit vertices, the sky quad).
  * The Labyrinth game mode was never freed (fixed below).
* **Converter:** all 80 `.map` files convert in a dry run, with 124
  warnings, none an error:
  * an ignored `mapSize` line in all 80 files and an `end` line in 36;
  * 8 repeated `dir` lines in Frozen Forest--Forest Passage, kept: the
    legacy loader counts them as neighbours again.

  Converting twice changes no file. Temple of Aegis's Base Level (carpets)
  and First Floor (pillars) were built and previewed without converting
  them for the game.
* **Step A:** `verify_dungeons.gd` passes for the pilot and in the dry run
  of all 80 floors: 160 of 160 builds ("Slot 1", "Start"), 80 of 80 meshes.
  Golden vs. after step A: 2,927 of 2,928 shots and all 131 logs identical.
  The one shot (`story_revelation_of_elmer`) is a dialog line removed from
  its `.seq` during the session, not the conversion; the legacy run after
  step A has it too.
* **Step B, legacy vs. scene** (`ab "--legacy=dungeons" ""`, the 14 cases
  plus `battle`, `newgame_to_forest`, `story_having_fun`): 189 of 189 shots
  identical at tolerance 0, logs identical. Each of these was needed, found
  by a failing shot:
  * the exact materials (decision 2);
  * the camera at the origin (7.5);
  * the walls as one instance with the display list's surfaces (an instance
    per surface changed the order of Godot's unstable sort for equal-depth
    surfaces);
  * the objects drawn as the legacy quads. Sprite3D's own vertices lost the
    z-fight of the hinder door, which lies in its wall's plane, in some
    turns: the door vanished.
  * the quads batched as GLBackend batches them. One instance per object
    changed some wall pixels by 1/255 with the "Start" save in the Tunnel;
    the mechanism in the renderer was not found.
* **Step B, other cases:** golden vs. after: 2,927 of 2,928 shots identical
  (the same `.seq` shot), all 131 logs identical; the bridge test is
  identical.
* **Battles in the hybrid frame:** identical to legacy (7.5, the 3D
  bridge): the enemies over the scene's walls, the rain's front pass over
  the battle in Forest Path. Nothing of the legacy look is lost.
* **Frame rate** (normal runs, windowed, "Slot 1"; median of the walk or
  battle frames, legacy (`--legacy=dungeons`) → scene):

  | Route | Capped | Uncapped |
  |---|---|---|
  | Forest Path, walking in the rain | 27 → 31 | 27 → 30 |
  | Forest Path, a battle | 27 → 30 | 27 → 30 |
  | The Great Mine--Tunnel, walking | 60 → 60 | 709 → 667 |

  Forest Path is bound by the weather in GDScript (7.5: ≈24 ms of a frame).
  The Tunnel is about 6 % slower uncapped (the ranges overlap: 642–729 vs.
  620–694). Not profiled; likely the scene path's extra GDScript per frame:
  recording the objects' quads and building their batch meshes.
* **Fixed on the way:**
  * The Labyrinth game mode leaked: its Graph, player and battle starter
    keep references back to it (a RefCounted cycle). It is released when the
    mode ends (`Labyrinth.releaseBackReferences`).
  * Main frees the scenes of modes that are still referenced at exit and
    the dungeon materials, so the renderer reports nothing new at exit.
  * Not fixed: the MainMenu mode stays alive. Exit-time leak warnings
    (textures, ObjectDB) exist in every run since before phase 2.
* **Still legacy:**
  * the minimap (in the scene's World3D), the mission display, dialogs and
    card info, the top layer and the fade: phase 3;
  * battles and riddles: phase 4;
  * the weather and save point simulations (GDScript): decision 6;
  * the 77 other floors: the rollout (7.8), `docs/CONVERTING_DUNGEONS.md`.

  The `.map` files stay (decision 5).

### 7.8 Rollout results (the other 77 floors)

* **Baseline** (on the commit after the tickets COTZ-012 to 018):
  `tools/check.sh` 0 failed; goldens of the 131 cases (2,959 shots); a
  second recording of the 14 `dungeon_*` cases is identical (158 shots, the
  logs too); the pilot's check (`ab "--legacy=dungeons" ""` on the 14 cases,
  `battle`, `newgame_to_forest`, `story_having_fun`) gives 7.7's result: 189
  of 189 shots identical, logs identical.
* **Coverage:** 205 new cases (`tools/parity/cases.txt`; 336 in all, 5,690
  shots), recorded on unconverted code: a tour of each of the 76 floors
  main.bank reaches, with both saves (`dungeon_tour_*`, the pilot's
  script), and 53 hand-written cases by shared script
  (`docs/CONVERTING_DUNGEONS.md` section 1): doors and floor changes
  (`dungeon_door_*`: a Grivera ladder, a Mt. Cesadur ladder down and
  door--down, Temple of Aegis's stairs, a door to its own floor, a prison
  hinderDoor--up, the NUL-named door, the if door both ways, the hidden,
  additive and riddle doors), objects (`dungeon_use_*`: an ice button, the
  Ice Cavern and Aegis combos, a villager, a bomb, the mission chest, a
  chest of each of the nine images), floor buttons and a save point
  (`dungeon_step_*`), a trigger door, nine riddles (each class; two under
  weather), six battles (snow, rain, the enemy colours .7, .8 and 1), two
  bosses, the map page of the largest floors, saving on a floor and loading
  it (COTZ-005), the console's goto, teleport and savepoint (COTZ-006). A
  second recording of the 219 `dungeon_*` cases is identical (2,889 shots,
  logs identical; one shot of the title's Continue list, which shows the
  slot file's time, was dropped). The dev additions (`--start-node`,
  `loopuntil … dialog`, the freeing reports, the ladder fix below) change
  none of the 131 older cases (2,959 shots identical to the baseline).
  Boss--Test is reached by nothing (no place, no size line, no textures):
  data check and preview only. Ice Cavern--Mysterious Forest and Dorma's
  Forest have no enemy group (`enemyBank.bank`): no random battles; their
  weather is covered by tours and riddles.
* **Cases that switch to scenes:** `bridge_test` (Grivera--First Floor),
  `story_meanwhile_in_zazo` (Central Pass--North East Part),
  `story_menthu_kills_teo` (Temple of Aegis--Top Floor),
  `story_senate_of_pensara` (Grivera--Third Floor); no other case's log
  names a labyrinth. All four are identical legacy vs. scene; the bridge
  test still passes.
* **Fixed on the way** (found by the coverage, before the goldens):
  COTZ-010 had made every ladder of Grivera and Mt. Cesadur unusable. It
  skips doors in the cell ahead, but a ladder's cell cannot be entered
  (`LadderDoor.isPassable` is false, as in the Java), so a ladder is used
  from the cell before it; only the one the player arrived at worked.
  `Labyrinth.checkNode` uses ladders from the cell before again.
* **Converter:** all 80 files convert, 134 warnings, none an error: the
  pilot's 124 and 10 lines with a NUL byte in a hinder door's link name
  (The Great Mine--The Hall 69; The Sewers--South East 84, 86, 87, 89; The
  Sewers--South 99, 100, 101, 104, 105), which the converter now names.
  `GameResourceLoader` drops NUL bytes when it reads a file, the scene holds
  the name without it, and the Java kept the NUL but `Organizer.convert`
  dropped it wherever the name was looked up: the doors lead where they
  should in all three (`dungeon_door_nul_name`). Converting twice changes
  none of the 553 output files; the pilot's files do not change; 188
  `.import` files only get `detect_3d/compress_to=0`. 23 floors have a style
  of their own, 57 share their area's (20 area styles); 7.2's 25 was not
  right. Five demon floors (Grivera--Corridor of Agony, Menthu's Lair--Hall
  of Memories and --Throne of Serpents, Mt. Cesadur--Mountain Top, Temple
  of Aegis--Top Floor) have no floor or roof texture: their walls stand in
  black, as in the legacy drawing. The previews of all 80 floors (rig and
  top views) show the layouts and looks; three opened in the editor build
  without errors.
* **Step A:** `verify_dungeons.gd --all` with "Slot 1" and "Start": 160 of
  160 builds pass; `--meshes`: 80 of 80. `--legacy=dungeon_drawing` (new,
  dev) builds floors from their scenes and draws them the legacy way:
  golden vs. after step A: 5,690 of 5,690 shots and all 336 logs identical
  (17 pilot-floor logs with `--ignore-world`, their floors were scenes in
  the golden).
* **Step B, legacy vs. scene** (the look still GLBackend's, bugs included;
  the 219 `dungeon_*` cases and the 7 cases through floors, 3,046 shots,
  tolerance 0, `--ignore-world`): all 226 logs identical; 2,981 shots
  identical; 65 differ:
  * 17 shots of the snow floors (Frozen Forest, Ice Cavern--Frozen Field and
    --Mysterious Forest), up to 111/255 on up to 21 % of the frame: their sky
    has alpha 0.8, so the glColor bug drew their walls at alpha 0.8, and
    where two of them overlap the result depends on which surface of the
    walls' instance Godot draws first. Equal-depth transparent surfaces are
    ordered by an unstable sort whose result depends on the whole render
    list, and the scene's list differs from GLBackend's chunk.
  * 1 shot of Dorma's Forest in a turn, up to 48/255: the misplaced sky quad
    (a surface of the walls without depth test) drawn after some walls in
    the legacy frame, before them in the scene: the same sort.
  * 47 shots by 1/255 (below).
* **The look: the glColor bug and the sky, fixed in both paths** (decision
  2's exact look kept, its emulation bugs removed; ARCHITECTURE section 10).
  A lit vertex ignores the current colour (OpenGL 2 without
  `GL_COLOR_MATERIAL`): GLBackend's shader and the dungeon shader. The
  emulated display list records renderSky's glLoadIdentity: its gradient is
  in eye space (the list's eye-space part, drawn with the identity; in the
  scene the floor's `Sky` mesh at the camera, drawn first). So Deep Forest's
  and the snow floors' walls are opaque (no walls seen through walls),
  Empyrian Temple--Dark's are not black, the objects are not yellow, and the
  18 skies fill the top of the view. Scene before vs. after: 1,031 of 5,690
  shots change, all in the 142 cases that show a labyrinth floor (floors
  without a sky only where an object is in view: their walls were baked
  white); all 336 logs identical; nothing else changes (lighting is on only
  for the labyrinth's walls and objects and the Demolish card's spheres;
  no case outside a labyrinth changes). New goldens: `afterC`. Not emulated still: the
  specular term (light and material specular on Fire Cavern--Blazing Maze
  and the four Grivera floors) and the black streaks while turning in the
  rain.
* **Step B after the fix** (the same 226 cases): all logs identical; 2,962
  of 3,046 shots identical; the 84 others differ by 1/255 in one channel
  (on 0.0003–2.2 % of a frame, both ways: 67,026 channel values brighter in
  the scene, 191,574 darker). Tolerance 1, chosen deliberately: all 3,046
  pass. The opaque walls and the separate sky removed the order effects.
  What the 1/255 is: Godot's rounding where legacy drawing blends over the
  floor. In the ice button case the scene and the legacy frame are
  identical without the minimap, and its batches are identical in both
  paths (vertices, colours, textures, order); the 1/255 stays when the
  scene's walls use GLBackend's own materials, and when GLBackend's
  SubViewport is opaque. The shots are the minimap over walls (after the
  menu, after a lever), the weather, and alpha-textured walls (Silent
  Ruin). The stage in the renderer that rounds differently was not found;
  the pilot met the same (7.7, the Tunnel's 1/255) and avoided it by
  batching, which here is already as GLBackend's.
* **Other cases:** the 110 cases that never show a converted floor: 2,644
  of 2,644 shots and all logs identical to the golden (before and after the
  fix).
* **Bridge code checked:** every Inventory class that overrides `draw` has
  a `place_view` twin (Inventory, Door, HinderDoor, FloorButton, Boss,
  Save); the classes that change what is drawn through other overrides
  (`checkIfOpen` of the hinder doors, `currentTex` of chests, levers,
  combos, villagers, bombs and mission chests, a ladder's images) go
  through the same checks in the twins; every state change of the draws
  the scene path skips (texture binds, the save point's update and
  lighting, the weather's front list and cached view values, the last
  colour and texture coordinate) happens in the twins. Every floor change
  and exit frees the old Labyrinth mode and its scene at the next mode
  switch (both log it: 29 modes and 254 scenes in the 336 cases; the floor
  current at quit only its scene, Main frees it). The exit-time leak
  reports are those of the golden in all 336 cases.
* **Battles, riddles and the weather in the hybrid frame:** as in the
  pilot: the battle is the scene's first legacy 3D chunk (the 3D bridge),
  over the walls with their depth, the snow's or rain's front pass over it,
  the enemy colour as before; a boss battle runs inside the labyrinth's
  frame (what the boss leads to afterwards can be a mode of its own: Memory
  Taur's win starts Memory Salmonman's BossBattleArea). A riddle draws
  nothing in 3D, all of it is its 2D top layer after the minimap; under rain
  or snow the front pass before it stays in the scene's chunk. Nothing of
  the legacy look is lost.
* **Frame rate** (normal runs, windowed, "Slot 1"; median of the walk or
  battle frames, legacy (`--legacy=dungeons`) → scene; after the fix,
  before the weather change below):

  | Route | Capped | Uncapped |
  |---|---|---|
  | Ice Cavern--Frozen Field, walking in the snow (115 cells) | 41 → 42 | 41 → 41 |
  | Ice Cavern--Frozen Field, a battle | 35 → 39 | 37 → 39 |
  | Empyrian Temple--Light (169 cells) | 60 → 60 | 766 → 696 |
  | Silent Ruin--The Great Ruins (25 objects) | 60 → 60 | 727 → 633 |
  | Temple of Aegis--Base Level (carpets) | 60 → 60 | 1,110 → 1,047 |

  The snow floor is bound by the weather in GDScript in both paths. The
  scene is 6–13 % slower uncapped on the others: the per-frame GDScript of
  the objects' quads and batches (7.7).
* **Load time** of the largest floor (Empyrian Temple--Light): the legacy
  path parses the `.map` file in 3.6 ms and compiles the display list in
  1.6 ms. The scene path loads the floor's scene twice, about 80 ms each
  (the text `.tscn` and its layout of 169 cell sub-resources; step A's
  MapLoader frees its instance, so the PackedScene leaves the cache before
  `create_scene` loads it again), and the first frame builds the walls in
  about 20 ms (the materials' shader variants; 1.6 ms once they exist).
  About 180 ms instead of 5 ms, during the black loading screen; Silent
  Ruin 20 ms per load, Frozen Field 8 ms. Keeping the PackedScene from step
  A to step B would halve it; a binary layout or packed cell arrays would
  cut the rest.
* **The weather's cost** (deliverable 7 of the rollout, without decision
  6): `WeatherSystem.place_particles` does `drawParticle`'s arithmetic for
  all particles of a pass at once (the per-pass values once, one vertex
  array, texture coordinates and colours filled natively; the copy of the
  growing arrays per particle is gone), `DungeonWeather` builds the quads'
  index array once. Every vertex, colour and random number is the same:
  the 222 dungeon and weather cases are identical before and after (2,920
  shots, logs). Back pass 11.0 → 8.8 ms per frame, front pass 0.8 → 0.6 ms; Forest
  Path 33 → 36 FPS (capped and uncapped), Ice Cavern--Frozen Field 41 →
  47–48. The rest is the view test of all 10,000 particles in GDScript and
  the simulation (`WeatherSystem.update`, ≈10 ms): GPU particles need
  decision 6.
* **Content quirks found** (kept, not fixed):
  * Silent Ruin's door at node 29 leads to `-mark12`, which main.bank
    lacks: using it drops the game to the title screen ("unknown place").
  * Three Great Mine levers name objects that do not exist: Great Deep's
    lever 189 names `The_Great_Mine--Mine_Core…` (the floor is "The Mine
    Core"), so it opens neither the Mine Core's door 9 nor flips its lever
    (the Mine Core's own lever opens that door); Mine Shaft's lever 29 names
    a Tunnel lever 189 and the Mine Core's lever 189 a Mine Shaft lever 28,
    neither of which exists.
  * Silent Ruin's riddle at node 86 (RubicsPuzzle19) uses the 4×4 tile set;
    the magic square check knows only 3×3 and 5×5, so any key solves it
    (the Java too).
  * main.bank's Fire Cavern--First Floor places have no `.map` file; nothing
    leads there.
  * Ten hinder doors lead to `_` (Pensara Prison's side cells, Menthu's
    Lair, Forest Path's): locked, they lead nowhere.
  * With `--mute`, a boss win that keeps its battle music
    (`BattleManager.dontFadeBattleMusic`) calls `overwriteStarterMusic` on a
    labyrinth without a music player: a script error (Memory Taur's case),
    no visible effect. A floor with "No Music" would do the same unmuted
    (the Java would throw there too).

### 7.9 Closing phase 2 (prepared, not done)

Removing the legacy dungeon path deletes or changes (line counts as of the
rollout, including doc comments):

| Part | Lines | Still used by |
|---|---|---|
| MapLoader's `.map` parsing: `parseFile` 6, `executeCommand` 124, `addSettings` 11, `addTexture` 3, `InsertNodes` 13, `sort` 9, the key maps 31 | 197 | the converter (`map_to_scene.gd`'s MapReader reads every value through it), `verify_dungeons.gd`, `--legacy=dungeons`. Load's saved floor maps are built from the scenes (`MapLoader._init`). `AbstractMapLoader` stays (the other loaders) |
| The shapes mapEnd's sort chooses: `LabyrinthNode.setFloor` 5, `addCarpetFloor` 25, `setWalls` 7; `Horizontal`'s setters 22; `PillarWalls` 98 | 157 | only the parse (the layout stores the results); `Horizontal` stays as data (the scene gives nodes their carpet), `PillarWalls.node` is set by `load_into` |
| `Labyrinth.init3D` | 24 | `--legacy=dungeons` |
| Display lists: `Graphics.glGenLists`/`glNewList`/`glEndList`/`glCallList`/`glDeleteLists` and the Java wrappers (`generateList`, `compileDrawList`, `endList`, `callList`) 36, `DisplayList` 60, the eye-space bookkeeping 12; `ImageHandler.generateDrawList` 2 | 110 | `--legacy=dungeons`, `verify_dungeons.gd --meshes`; nothing else compiles a list |
| `LabyrinthRenderer.draw` 26, `renderSky` 22 | 48 | `--legacy=dungeons`, `--meshes`; `addLight`, `setMaterial`, `addFog`, `setLight`, `init` stay: `init_scene_3d` sets the GL state the battle still reads |
| `LabyrinthNode.draw` 17, `drawRoof` 3, `drawFloors` 5, `drawWall` 4; `Horizontal.draw` 30 | 59 | `--legacy=dungeons`; `drawOneWall` (34) and `drawOneFloor` (2) stay: hinder doors and floor buttons draw through them (`DungeonQuads`) |
| `Graph.drawInventory` 7; `draw` of Inventory 13, HinderDoor 10, FloorButton 9, Boss 5, Save 9, Door 7 | 60 | `--legacy=dungeons`; `Inventory._drawQuad` (69) stays (`place_view`) |
| `Labyrinth.draw`'s legacy branches | ~8 | `--legacy=dungeons` |
| `WeatherSystem.loop`, `loopBackwards` and the back pass of `draw` | ~25 of 47 | `--legacy=dungeons`; `draw`'s front pass and `WeatherParticle.drawParticle` (72) stay: the front pass over a battle or riddle |
| `SaveSystem.draw` 21, `loop` 3, `loopBackwards` 3; `SaveParticle.drawParticle` 18 | 45 | `--legacy=dungeons` |
| `--legacy=dungeons` and `dungeon_drawing` (`MapLoader.dungeon_scene_for`, `Labyrinth.create_scene`) and the parity cases' legacy runs | ~5 | `Main.is_legacy` stays for later phases |
| `tools/import/verify_dungeons.gd` | 325 | needs the parse and the `.map` files |
| the 80 `.map` files (decision 5) | 7,328 (325 KB) | the converter (`map_to_scene.gd`, 715 lines), the data check, `--legacy=dungeons`. COTZ-013 edited three of them: a content change today is a `.map` edit and a conversion |

Battles read the GL fog and light state (`init_scene_3d` sets it as
`init3D` did) until phase 4.

What keeps the exit criteria of 7.6 from being met:

* "All 80 floors load from scenes": met.
* "The dungeon AutoPlay scripts (`newgame_to_forest`, `battle`, `boss`)
  pass": met; `newgame_to_forest` and `battle` are identical legacy vs.
  scene, `boss` (a village's boss battle area) never shows a floor.
* "`src/labyrinth` contains no GL calls": not met. About 300 GL-style calls
  remain in `src/labyrinth`, `src/weather` and the save point's particles:
  the minimap (`MapRenderer`, `LabyrinthMap`: phase 3), the 2D overlays
  (mission, dialogs, the top layer, the fade), `init_scene_3d`'s GL state
  for the battle, the `place_*` twins (texture binds, blend and alpha state,
  lighting: they keep the legacy GL state for whatever draws after them),
  `Inventory._drawQuad`, `drawOneWall` and `drawOneFloor` (emitted into
  `DungeonQuads`), and the whole `--legacy=dungeons` path.
* The weather and the save points are still the legacy simulation drawn as
  quads (`DungeonWeather`): GPU particles need decision 6. The Views
  (`AnimatedSprite3D`) only mirror at run time; real Sprite3D objects and a
  moving camera are step C (7.6), which gives up exact parity.
* Delete the `.map` files: decision 5 is open.
* Parity at tolerance 0 is not reached everywhere (the 1/255 of 7.8); closing
  needs that tolerance accepted, or the renderer stage found.

## 8. Phase 3: shared UI and transitions

Villages, dungeons, cutscenes and stores all draw the same overlays through
legacy code. Converting them once removes most of the remaining `draw(g)`
from phases 1–2.

1. **Theme.**
   * `resources/theme/game_theme.tres` uses the game's two fonts
     (`res/Main/font.ttf`, `boldfont.ttf`) at the even sizes 20–50 that
     `setFontSize` allows. StyleBoxTextures come from the menu pieces
     (`res/Menu/Pieces/*.png`) and the dialog papers.
   * Expect to tune baselines and widths: the legacy text code positions by
     baseline and measures JOGL-style ink bounds (`Graphics.getStringWidth`).
   * This is also where the UI items in `TODO.md` get fixed (the papyrus
     font, text running out of the paper, a vertical Yes/No).
2. **Dialog** (`villages/utils/Dialog.gd`, 381 lines, a singleton used by
   villages, dungeons, cutscenes and stores) → `ui/Dialog.tscn`.
   * It is a Control that draws the state of the legacy `Dialog`/
     `DialogSequence`: name, two lines, question cursor, gift line.
   * Then `SignBox.tscn` and the card info popup (`DeckPage.drawCardInfo`).
   * The emotion bubbles become children of `ActorView`, with an absolute
     `z_index` above `Overhead` and `Effects` (the original draws them on
     top of roofs).
3. **Fades** → `Transition` layer: a ColorRect, or a TextureRect for
   `setFadeImage(WHITE | image)`.
   * First, render only: draw `fadeValue` from the legacy `Fadeable`, so the
     exit timing does not change.
   * Later (after the time-base decision), a Tween whose `finished` signal
     ends the mode's exit.
4. **HUD pieces:** dungeon mission display, minimap frame, "Paused" and
   "game pad lost" (`GameCore.testDraw`).

**Exit:** villages, dungeons and cutscenes have no `draw(g)` left except
battles and riddles.

## 9. Phase 4: remaining modes

Each one follows the same A/B/C steps. They are independent of each other,
so the order can follow interest. The suggested order goes from cheapest to
most entangled.

### 9.1 World map and airship

* The world map uses `DoubleBackground` like the villages: 256 px tiles in
  `res/Landscape/<W>/<W>folder/`, a `top/top.info` layer and night variants.
  Reuse the village converter for the background and top layer.
* Roads (`road …` + `co x y` points in `maps/Landscape/*.map`) become
  `Path2D` children and nodes become `Marker2D` with exported kind and name;
  both converters are mechanical.
* Keep the 7-points-per-segment walking (`Road.gd:61-86`) and the
  visited/closed state from `Visited`/`Database`.
* The airship (`AirShip.gd`: velocity per update, wraps at the screen
  edges) needs the time-base decision.

### 9.2 Title, game over, mini-games, stores, menu

* **Title, game over:** trivial Control scenes with Tweens.
* **Mini-games** (12 files) are self-contained. Make one Control scene per
  puzzle kind; tiles come from `res/MiniGames/TileGames/*`. They are started
  from dungeon `riddle` objects, so they plug into the dungeon scene as a
  modal UI child, not as an Organizer mode.
* **Stores** (Building → AbstractStore → CardStore / WeaponStore / Inn;
  Church): one `Store.tscn` template.
  * The parts: background, keeper portrait, the shared Dialog, a menu
    column, confirm boxes.
  * The input state machines stay as script. `stores.bank` and
    `cardStores.bank` stay data (or become `.tres` later).
* **Menu** (21 files, 3,024 lines): one Control scene per page (start,
  status, equip, deck, map, bestiary, help, tutorial) on a shared frame.
  * `MenuNode` lists → a small `MenuList` control that keeps the legacy
    cursor and key-repeat behaviour.
  * The tutorial and help files (`.tut`/`.help`, word colour maps) → BBCode
    for `RichTextLabel`, with an offline converter.
  * The automap (`LabyrinthMap.draw`) → a Control drawing from
    `LabyrinthMap` data.
  * Fix `HelpPage`'s volume options on the way: the names it compares never
    match.

### 9.3 Infrastructure

* **Game modes:** a `Game` autoload with a place registry generated from
  `main.bank` (mechanical), including the `land::`, `land<node>` and
  `air<node>` prefixes and the runtime changes from `updateNextPlaceFor`.
  * It keeps live suspended scenes, the previous/current pair, the loading
    gate, the exit-after-fade rule and the per-mode music policy.
  * About 40 `Organizer.getOrganizer()` call sites move over gradually.
* **Input:** InputMap actions for the PlayStation-style buttons, plus a thin
  wrapper that keeps `GameAction`'s three behaviours (press once, hold,
  repeat after 480 ms then every 90 ms). AutoPlay then injects through
  `Input.parse_input_event`.
* **Audio:** a Music autoload (intro `<Name>1.ogg` + loop `<Name>2.ogg`, Tween
  fades, the FAST/SLOW/HALF rules) and Music/SFX buses; today everything
  plays on Master.
* **Saves:** JSON (or a Resource) under `user://saves/`, plus a reader for
  the old text format so the 24 shipped `.sav` files still load. Add the
  "last save data" and autosave items from `TODO.md` here.

### 9.4 Battle, cards and effects (largest)

Keep the logic classes (`Battle`'s state machine, `EnemyLogic`,
`HitElement`, `Card.use`) and replace the view first.

* **Placement.** `Battle.tscn` is a Node3D under the dungeon camera rig, so
  its eye-space coordinates carry over 1:1 and it shares depth and fog with
  the walls. Boss areas get their own camera.
* **Enemies:** `AnimatedSprite3D` + SpriteFrames from
  `res/Battle/enemies/<name>/`.
  * The slice effect becomes a shader.
  * Colour flash, shake and rise become Tweens.
  * `attackSpec` frame lists (`maps/Battle/EnemyMaps/*.enemy`) are
    converted mechanically to Animation resources: a frame track plus method
    tracks for hit, sound and card effect.
* **Cards and slots:** two-sided quads with Tweens for flip and move.
* **Text:** info panels → Label3D, or Controls placed with
  `Camera3D.unproject_position`. AttackText → Label3D + Tween.
* **Bars:** TextureProgressBar, or a quad with a percent uniform.
* **Screens:** result, spoils, level-up, legend, clock → Control scenes.
  Move the gold and item grants out of `SpoilsScreen`'s display code.
* **Effects:** `AnimSettings` becomes a typed Resource, and the
  `AnimationSettingsFactory` presets become `.tres`. Each card gets an effect
  scene (`fx/<Card>.tscn`):
  * GPUParticles3D, or CPUParticles3D where the logic needs per-particle
    counts, since damage waits on `isDestroyed()`;
  * a `SphereMesh` + `OmniLight3D` for the sphere systems;
  * emission points baked from the enemy frame for Shatter.
  * It exposes signals `impact` (= `isDestroyed`), `ready_for_next`
    (= `isReady`) and `finished` (= `isDead`), which replace the polled
    flags. About 40 effects need hand work.
* **Weather front pass** goes away once the battle shares the depth buffer.
* **Riskiest code change:** `Vector3f` is a reference type with `*Local`
  mutators, and card code relies on the aliasing (`Fire.gd:66`).
  Replacing it with the value type `Vector3` must be done per call site.

## 10. Phase 5: remove the emulation

When no mode draws through `g` any more:

* Delete `Graphics.gd`, `GLBackend.gd`, the texture paths of
  `GameTexture`/`ImageHandler`, `Utils3D` and `Object2D`.
* `Main` becomes a plain scene, and Organizer becomes the `Game` autoload.
* `update(ms)` becomes `_process(delta)`, and the
  `Values.originalFrameStep` workarounds go away.
* `PORTING.md` becomes historical.

## 11. Testing and tooling

* `tools/check.sh` stays the compile gate.
* Parity: AutoPlay screenshot runs per converted place or mode, legacy vs.
  new (`tools/parity/`).
* Data equivalence: `verify_villages.gd`, `verify_dungeons.gd`.
* Performance: AutoPlay already prints `fps=` with every `log`/`shot`. Track
  it per phase, from normal runs: parity runs are uncapped and fixed-step,
  so their `fps=` values do not measure anything.

## 12. Risks

* **Hybrid ordering.** Scene content sits under all legacy drawing. Anything
  that drew between world layers has to move into the scene in the same
  step, e.g. cutscene images drawn under or between the actors (6.4).
  Emotion bubbles are safe: the original draws them above roofs and
  effects too.
* **Feel changes in step C** (collision, speed). They are kept out of steps
  A and B on purpose.
* **Converter mistakes.** Covered by the data equivalence checks, run for
  every file, not samples.
* **Sort ties.** Equal-y sprites may swap order. The port already has this
  issue (`docs/port_notes/villages.md`).
* **Texture memory.** Stitched backgrounds up to 2820×1442 are fine.
  Use lossless import so the painted art stays crisp.
* **Identity-keyed sprite maps** (`get_instance_id()`) in Village. Views must
  look sprites up through these keys, not keep their own copies.
* **State changed inside `draw()`** (see 2.4). Removing a `draw` without
  moving its side effect into `update` silently breaks logic. Grep every
  `draw` that is removed.
* **Logic timed by effects.** Battle damage waits for particle packets.
  GPU particles cannot report how many particles are left, so those effects
  use CPUParticles or an explicit timer that matches the legacy timing.
* **Battle in the hybrid period** (7.5): depth, fog and the weather front
  pass behave differently until phase 4. *Pilot:* avoided in the labyrinth
  by the 3D bridge (7.5), which only covers the frame's first 3D chunk drawn
  before any 2D. Later 3D chunks are separate SubViewports, composited in
  sRGB.
* **Pixel parity rests on renderer details** (7.7). These had to match
  GLBackend exactly:
  * Godot's transparent sort (depth minus `sorting_offset`, unstable for
    equal depths);
  * the batching;
  * the vertex rounding that decides coplanar z-fights (hinder doors in
    walls).

  A Godot update can change any of them. Step C (real Sprite3D, a moving
  camera) gives up exact parity by design, so it needs a tolerance or
  accepted differences.
* **Exact looks keep emulation bugs.** Decision 2 reproduces GLBackend:
  the glColor on lit vertices and the misplaced sky (7.5) were fixed in the
  rollout in both paths at once, with new goldens (7.8). The specular term
  is still missing (GLBackend never had one). Fix such a bug in GLBackend
  and the dungeon shader together.
* **Order-dependent blending.** Godot orders equal-depth transparent
  surfaces with an unstable sort whose result depends on the whole render
  list, so two paths that draw the same surfaces can blend them in a
  different order: up to 111/255 on the translucent walls of the rollout's
  first step B (7.8). Keep surfaces that blend with each other at distinct
  depths or sorting offsets (the sky is its own instance now), or opaque.
  A 1/255 rounding where legacy drawing blends over a scene remains
  unexplained (7.8).
* **Load time.** A floor's scene is a text `.tscn` with a layout of one
  sub-resource per cell, loaded twice per floor entry: about 180 ms on the
  largest floor where the `.map` path took 5 ms (7.8).
* **RefCounted cycles** keep game modes and their scenes alive (the
  Labyrinth until phase 2, the world map until phase 1, the MainMenu still).
  Check that a converted mode is freed when it ends.
* **Texture import:** a texture used on a 3D material gets VRAM-compressed by
  the editor (`detect_3d`). That changes the legacy drawing too, which uses
  the same texture. The converters set `compress_to=0`.
* **`Vector3f` aliasing** in card effects (9.4).

## 13. Open decisions

1. **Village variants:** inherited scene per `.vil` (recommended: maps 1:1 to
   today's file choice) vs. one scene per place with per-node status filters
   (fewer files, harder to see a single variant). *Decided (phase 1
   rollout):* one inherited scene per `.vil` variant on a shared base
   scene, as in the pilot.
2. **Dungeon lighting:** exact fixed-function look (shader) vs. Godot lights
   (more modern, slightly different). *Applied for the pilot (phase 2):*
   the exact look: GLBackend's spatial shader as a ShaderMaterial with the
   style's values. It also kept the emulation's glColor bug (7.5); *the
   rollout applied it to every floor and fixed that bug and the misplaced
   sky in both paths (7.8).* The Godot-lights variant was not tried.
3. **Step C timing:** accept changes in movement and collision feel (and fix
   the speed TODOs) right after step B, or only after every mode is on
   scenes.
4. **Resolution:** keep the 1024×768, 4:3 virtual screen (recommended for
   now; menus, battle and dungeons assume it). Scenes make widescreen
   villages possible later.
5. **Text formats:** delete them after conversion (recommended) or keep them
   as an export format.
6. **Time base** (2.5): when motion moves to nodes, which speed is the
   target?
   * The original's feel: about 30 updates/s, expressed as per-second
     rates. Recommended; `TODO.md` already asks for several speed changes,
     and those are easier to tune from a correct baseline.
   * Today's port speed: about 2× for the per-update systems.

   Step B views that only mirror legacy positions do not need this
   decision. Particles (phase 1) and Tweens do. The phase 2 pilot showed
   the labyrinth weather's frame rate depends on it: the GDScript
   simulation, not the drawing, holds the rainy floors at ≈30 FPS (7.5).
7. **Village top layer** (from the pilot, 6.7): *decided (phase 1
   rollout):* roofs and treetops are always drawn (6.1, the pilot's
   default). The legacy rule draws a piece only where a sprite overlaps it,
   and the PNG pieces differ from the JPEG background under them, so the
   villages look slightly different where no sprite is near a roof or
   treetop. `--legacy=village_top_layer` keeps the legacy rule for parity
   runs.

## 14. Suggested order and size

Sizes are relative: S ≈ a focused session, XL ≈ many sessions.

| # | Phase | Size | Depends on | Unlocks |
|---|---|---|---|---|
| 0 | Groundwork: bridge, parity tool, `ARCHITECTURE.md` | S | — | everything |
| 1 | Villages + cutscenes + village particles + SpriteFrames | L | 0; decisions 1, 6 | editable villages |
| 2 | Dungeons + weather + minimap | L | 0; decision 2 (the weather: 6) | editable dungeons; FPS fix (with decision 6) |
| 3 | Theme, Dialog, signs, emotions, fades, HUD | M | 1 (or 2) | most of the remaining `draw(g)` |
| 4.1 | World map + airship | M | 1 (converter), 3 | — |
| 4.2 | Title, game over, mini-games, stores, menu | L | 3 | — |
| 4.3 | Input, audio, saves, `Game` autoload | M | any time after 0; the autoload is best after 4.2 | 5 |
| 4.4 | Battle, cards, effects | XL | 2, 3 | 5 |
| 5 | Remove the GL emulation; per-delta time | M | all of the above | — |

Phases 1 and 2 are the user-visible goal and can run in parallel after phase
0. Within phase 1, the Zazo pilot should go all the way through steps A and
B before any other place is converted. It proves the converter, the bridge
and the parity checks on the hardest case.

## Appendix: side findings

These came up during the survey. They are independent of the plan and can be
fixed or deleted at any time.

* **Dead code:**
  * `src/shaders/Shader.gd` (`GameShader`): nothing calls it, and the GLSL
    files it reads do not exist.
  * `src/battleBacks/*`: only reachable through a commented-out line in
    `main.bank`.
  * `SwordBackground`: its `drawable` is never assigned.
  * `MenuMapLoader`: no callers.
  * The `Values.getClassMap()` entries `story.Story`,
    `story.StorySequence`, `store.Library`, `store.House` and
    `villages.Landscape` have no classes.
* **Latent bugs:**
  * The particle kinds `rainparticle` and `sandparticle` have no class in
    `ParticleFactory`, so they create null bodies. The same bug is in the
    Java original. It never runs: `Home of Celisnode1.seq` only lists
    `rainCelissystem` (`load particleSystem=`, a name in a list), and its
    `fadeparticlesystem` line is commented out; no sequence runs
    `fadeparticlesystem` or builds a rain or sand system (checked in the
    phase 1 rollout).
  * `HelpPage`'s volume options never match (9.2).
  * `VillageStoryTimeLine` calls `updateFadeValue()` in both `update` and
    `draw` (`:262-265`, `:602-604`), so its fades may step twice per frame.
    Not checked against the Java.

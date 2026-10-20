# Modernization plan: from the GL emulation to Godot scenes

Status: **phase 0 done** (2026-10-16); **phase 1 pilot done** (Zazo and
"Zazo - Miner's Home" through steps A and B, see 6.7); the rest of phase 1
and phases 2–5 are proposals. The plan
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

### 2.2 Villages (89 `.vil` files, 60 places)

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

### 7.3 Converter `tools/import/map_to_scene.gd`

* Runs `MapLoader` on each `.map`, then writes the layout resource, the
  scene and the object nodes.
* Groups floors by area (`<Area>--<Floor>.map`) and extracts the shared
  styles.

### 7.4 Step A: data from scenes

* `Labyrinth.init` builds `Graph`, the nodes and the inventory from the scene
  instead of from `MapLoader`.
* A verifier compares the graph, walls, textures and inventory with the old
  loader output for all 80 files.

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

### 7.6 Step C: logic (later)

* Moving and turning become Tweens on the rig.
* Objects emit signals (`interacted`, `opened`).
* `LabyrinthPosition` and `Camera` go away.

**Exit:** all 80 floors load from scenes; the dungeon AutoPlay scripts
(`newgame_to_forest`, `battle`, `boss`) pass; `src/labyrinth` contains no GL
calls.

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
  pass behave differently until phase 4.
* **`Vector3f` aliasing** in card effects (9.4).

## 13. Open decisions

1. **Village variants:** inherited scene per `.vil` (recommended: maps 1:1 to
   today's file choice) vs. one scene per place with per-node status filters
   (fewer files, harder to see a single variant).
2. **Dungeon lighting:** exact fixed-function look (shader) vs. Godot lights
   (more modern, slightly different).
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
   decision. Particles (phase 1) and Tweens do.

## 14. Suggested order and size

Sizes are relative: S ≈ a focused session, XL ≈ many sessions.

| # | Phase | Size | Depends on | Unlocks |
|---|---|---|---|---|
| 0 | Groundwork: bridge, parity tool, `ARCHITECTURE.md` | S | — | everything |
| 1 | Villages + cutscenes + village particles + SpriteFrames | L | 0; decisions 1, 6 | editable villages |
| 2 | Dungeons + weather + minimap | L | 0; decision 2 | editable dungeons; FPS fix |
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
    Java original. `rainCelissystem` is used by `Home of Celisnode1.seq`;
    this has not been run-tested.
  * `HelpPage`'s volume options never match (9.2).
  * `VillageStoryTimeLine` calls `updateFadeValue()` in both `update` and
    `draw` (`:262-265`, `:602-604`), so its fades may step twice per frame.
    Not checked against the Java.

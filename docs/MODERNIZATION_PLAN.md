# Modernization plan: from the GL emulation to Godot scenes

Status: **phase 0 done** (2026-10-16); **phases 1, 2, 3, 4.1 and 4.2 done
and closed** through step B, their legacy paths, `--legacy=` flags and the
`.vil` and `.map` files removed (decision 5, 2026-11-06): the villages (63
places, 86 variants; pilot 6.7, rollout 6.8, closing 6.9), the dungeons (80
floors; 7.7, 7.8, closing 7.9), the shared UI and transitions (8.1, 8.3,
closing 8.4), the world map and the airship (9.1 and its closing), the
title, the game over, the menu, the stores and the mini-games (9.2: the
pilot, three rollout parts and the closing, 2026-11-07); **the particles
phases P and P2 done** (6.10, 6.12; the village and dungeon legacy paths
closed with phases 1 and 2, the battle effects' stay until 4.4); 4.3 and
4.4 are prepared (9.3, 9.4: 4.4's top layer recommended next); the rest of
phases 4–5 are proposals. The plan
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
* **Commands** (`VillageLoaderMapLoader.executeCommand`, removed in 6.9):
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
| Title, game over | 2 / 168 (209 with the port's additions) | images + fades | — | Control + Tween (*4.2:* UI nodes in step B; the Tweens are step C) |
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

*Removed when phase 1 closed (6.9), with its workflow document; see the git
history up to 1e0229df. The scenes are now edited by hand.*

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
  `docs/CONVERTING_VILLAGES.md` (removed in 6.9).

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

  *As built (particles phase, 6.10):* not ParticleProcessMaterial presets
  but one particle shader per class that runs the legacy laws as per-second
  rates (so no hand tuning of curves); the wind is the legacy's shared
  vector, read every frame; `warmUp` is `preprocess`; a warm-up shape is a
  `preprocess` to the steady state (snow) or a one-shot emission (stars);
  master/slave is a child system fed at the legacy rate, not a
  sub-emitter (not deterministic). `LegacyParticles2D` stays as the slot that
  instances the generated system.
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

### 6.9 Closing phase 1 (done on 2026-11-03; decision 5 on 2026-11-06)

Removing the legacy village path deletes or changes (line counts as of the
rollout, including doc comments; as built below the table):

| Part | Lines | Still used by |
|---|---|---|
| `.vil` loading: `VillageLoader.VillageLoaderMapLoader` (inner class) | 244 | `--legacy=villages`, `tools/import/verify_villages.gd` |
| `Door.getDoor` (a door line), `Loot.getLoot` (a loot line) | 40 + 25 | only `VillageLoaderMapLoader` |
| `VillageLoader.village_scene_for`'s `--legacy` check, `load`'s `.vil` branch | ~5 | — |
| `Village.drawBottom`, `drawTop` and the legacy branch of `draw` | 18 + 5 + 3 | `--legacy=villages`; `sortSprites` (15) and `drawOverlays` (15) stay (the scene path and the overlays use them) |
| `VillageStoryTimeLine.draw`'s legacy branch | ~25 of 47 | `--legacy=villages`; `draw_scene`, `sortActors`, `drawTop` (overlays) stay |
| `DoubleBackground`: `loadImages` (village tiles), `init`, `putextra` (dead while `USE_CUT`) | 24 + 19 + 2 | the scene path still builds a `DoubleBackground` per village (`load_into` → `loadImages`), for its scroll logic, particle system lists and top-layer list: it also loads the tile textures the scene does not draw (wasted texture memory until the scroll moves to the camera, step C) |
| `DoubleBackground`: `doit`, `cutImage`, `cutImage2`, `generateNames`, `doTopLayer`, `drawBottom`, `drawBottomLayer`, `drawTop`, `drawSystem` | 29+14+40+14+19+5+22+42+4 | stay: the world map and the airship (`setLandscapeImages`, `drawBottom`, `drawTop(g, false, null)`) until phase 4.1. *After 4.1 (9.1):* the map scenes' path still builds a `DoubleBackground` per map (`setLandscapeImages` → `doit`, `cutImage` → `generateNames`, `doTopLayer`) for the state its twins read (the tiles' names, the top layer, `nightTop`); `drawBottom`, `drawBottomLayer`, `drawTop` and `drawSystem` are then only `--legacy=villages`, `--legacy=world_map` and `--legacy=airship`; `cutImage2` stays (three villages' one-image backgrounds, scene path) |
| `DoubleBackground.overlapped_pieces` | 33 | stays while `PartyMember.getMemberPos` is updated there (a state change of the legacy `drawTop`) and for `--legacy=village_top_layer` |
| Sprite draws: `Villager.draw` 10, `PartyMember.draw` 6, `AnimatedObjects.draw` 6, `DefaultSprite.draw` 6, `Actor.draw` 5, `bodies.system.ParticleSystem.draw`/`drawIt` 31, `BodySystem.draw` 5, `Body.draw` 8 | 77 | `--legacy=villages` only; `Sprite.draw`/`drawSprite`/`drawAtPosition` stay (the world map's `LandPlayer`; *after 4.1, 9.1:* only its `--legacy=world_map` and `--legacy=airship` drawing); the `place_*` twins stay (the scene path; `LandPlayer.place_view` uses `place_sprite`) |
| `--legacy=villages` and `--legacy=village_top_layer` (`Main.is_legacy` calls in `VillageLoader`, `Village.scene_top`) and the parity cases' legacy runs | ~10 | `Main.is_legacy` stays for later phases |
| `tools/import/verify_villages.gd` | 242 | needs `VillageLoaderMapLoader` and the `.vil` files |
| the 89 `.vil` files (decision 5) | 6,865 (132 KB) | the converter (`vil_to_scene.gd`, 911 lines), the data check, `--legacy=villages` |

*As built (2026-11-03):* everything in the table is removed except the
`.vil` files (decision 5) and what the table says stays.

* `VillageLoader` has no `.vil` loader: `load` asserts (with a release
  guard) when a variant has no scene. `Door.getDoor`, `Loot.getLoot` and
  `Loot.convert` went with it. The `.vil` files are no longer read; their
  paths still name the variants (`VillageScene.path_for`).
* `Village.draw` and `VillageStoryTimeLine.draw` have only the scene path.
  `Village.drawBottom`/`drawTop` and the table's sprite draws (`Villager`,
  `PartyMember`, `AnimatedObjects`, `DefaultSprite`, `Actor`) are removed.
  The bodies' draws (`bodies.system.ParticleSystem.draw`/`drawIt`,
  `BodySystem.draw`, `Body.draw`) stay: `DoubleBackground.drawSystem` (the
  world map's and airship's legacy drawing) and `--legacy=particles` call
  them.
* `DoubleBackground.init`, `loadImages` and `putextra` are replaced by
  `init_village`: the night layer (`doit`) and the top layer, no tiles. The
  double load is gone: the scene path no longer loads every 256 px tile
  texture of the background next to the stitched image the scene draws.
  `overlapped_pieces` stays for `PartyMember.getMemberPos`; its result is
  unused, and `VillageScene.show_top` lost its `pieces` argument.
* The 65 tile folders (`res/Village/<Place>/<image>folder/`, 1,192 images,
  20 MB) are deleted, and `file_index.txt` lost their paths. The whole
  background JPEGs next to them stay: the scenes draw two of them (Tower
  Prison, Zazo - Farl's House, which had no tiles); the others are not read.
* `--legacy=villages`, `--legacy=village_top_layer`,
  `tools/import/vil_to_scene.gd` (+ `.sh`), `verify_villages.gd` and
  `docs/CONVERTING_VILLAGES.md` are deleted (git history up to 1e0229df).
  The village scenes and their `SpriteFrames` are edited by hand now.
* Parity: every case (407, 7,436 shots), recorded before (set `vbase`, on 1e0229df) and after (`vafter`), is identical at tolerance 0, with the same exit codes, shot counts and error counts per case. The one exception was one pixel of Dellna's snow by 1/255 (`tour_dellna_2`), which a re-record of that case does not show: run-to-run noise.

What kept the exit criteria of 6.6 from being met before this:

* "All 89 variants load from scenes": met.
* "`village*.txt` and the story scripts pass parity": met except the frames
  of cutscene zooms, where the legacy drawing magnifies each 256 px tile on
  its own (seams) and rounds differently (6.7, 6.8); and by default the
  top layer is always drawn (decision 7). Closing needs these accepted as
  the expected differences (a tolerance or a list), not fixed.
* "`Village`/`VillageLoader` contain no world drawing": met (as built
  above).
* "Delete each `.vil`": done on 2026-11-06 (decision 5, below).
* Particles: done on the GPU (6.10); `--legacy=particles` kept the legacy
  simulation (`BodiesParticleSystem`'s bodies, `step`, `drawIt`,
  `place_quad` and `LegacyParticles2D`'s quads) until 2026-11-06 (below).
* The emotion bubbles, dialogs, signs, fades and the cover-all/story/
  translucent-over-actor cutscene images are legacy overlays until phase 3
  (not part of the exit criteria).

*Decision 5 (2026-11-06):* the 86 `.vil` files are deleted (the git
history up to aab714c9 has them), with the closings of phases 2, 3 and 4.1
(7.9, 8.4, 9.1) and one parity check for all of them (9.1, "Parity of the
closings").

* The legacy code still names a variant by its `.vil` path
  (`VillageLoader.load`); `VillageScene.path_for` resolves the scene's name
  in `file_index.txt` without regard to case, where the `.vil` path was
  resolved before (`tools/gen_file_index.py` lists the village and dungeon
  scenes for it; every `.vil` had exactly one scene).
* The village-remake tool (`remake_inventory.gd`) read the obstacle groups,
  the comment headings over each place's `o` lines, from its `- 0.vil`:
  they are saved in `tools/village_remake/obstacle_groups.json` (60 places,
  189 groups); its output for Alares and Zazo is byte-identical before and
  after.
* `--legacy=particles` is removed (closing the particles phase, 6.10).

### 6.10 The particles phase (P): village and cutscene particles on the GPU

Done as `docs/particles_prompt.md` asked (decision 6 for particles, 13):
every system of `particleSystems.info` is a generated `VillageParticles2D`
scene, the legacy objects stay in charge (step B), and the legacy
simulation runs only with `--legacy=particles`. Conventions:
docs/ARCHITECTURE.md section 9 ("Particles"); regenerating and tuning:
docs/CONVERTING_PARTICLES.md.

* **Own random numbers first.** The village and cutscene particles drew
  from J's shared generator (as Java's `Math.random`); they now draw from
  `BodiesParticleSystem.rand` (port notes, particles-bodies), seeded in
  `Main._init_deterministic`. Normal play is unchanged; seeded runs changed,
  so the goldens (all 342 runs incl. `bridge_test`, with the new
  `--hide-particles`) were recorded after it. `verify_villages.gd` seeds the
  new generator per build too.
* **Coverage.** Five new cases (`particles_*`, recorded twice: identical):
  the player in front of and behind Pass to Zazo's fire, overlapping it
  (`particles_pass_to_zazo_behind`); a god system starting while Home of the
  Gods is shown (talking to Gemini sets `godGeminiSystem`;
  `particles_hotg_god_start`); Home of Celis's smoke over time; the Menthu
  and Ophiuchus systems of "Talking to Menthu" (a new script,
  `particles_story_slow.txt`: the systems run while the first dialog waits;
  `story_tour` paged through it in 3 s) and of the Berca Desert--South West
  node1 cutscene (which moves its fire systems with their actors). The 34
  cases that show village or cutscene particles were also recorded with the
  particles shown, twice: 791 shots identical (the legacy simulation is
  deterministic with its own generator).
* **Facts found** (deliverable 1; where they differ from the prompt):
  * Motion: confirmed. The command queue runs the emitter first, then
    gravity (cancelling the default force), the wind (smoke only) and the
    update, so a particle moves at F·dt/m from its first step on, plus the
    wind's acceleration for smoke. dt is the step: 1/30 s normally, but
    `originalFrameStep` takes all pending time once two steps are pending,
    so below 30 FPS the particles move faster: at Home of the Gods' 6 FPS
    (≈170 ms steps) the god particles rose about five times as high as
    intended. The GPU systems use 1/30 s.
  * Lives: confirmed; FireParticle's fade accumulates (the growth adds to
    the fade every step); SmokeParticle's fade grows multiplicatively
    (×(1 + d/10000) per step); `modifySize`'s clamp of the life to 1 never
    binds (max ≤ 0.7), so drawing changes nothing. StarParticle's colour
    re-roll never runs: **the legacy code never updates the bottom layer**
    (`DoubleBackground.update` steps only the upper and weather layers, as
    in Java), and the stars are its only systems. They stay as placed.
  * Emission: confirmed, with two more facts. **A master/slave emitter is
    updated by both its systems** (the slave system's emitter command is the
    same emitter, as in Java), so Pass to Zazo's fire emits at twice its
    time step's rate (33 a second instead of 16.7). The emitter's clock runs
    on while the pool is empty, so a pool-limited system re-emits every dead
    body in the next step. Warm-up: only systems active when built warm up
    (the gods and the exit door start inactive and fill up when they start);
    cutscene actors' systems never warm up. The rates (the generator's
    estimates from stepping legacy particles): the snow is limited by its
    time step, not its pool (55.6 a second, about 5,300 of 6,000 flakes
    alive: a simulation of the legacy pool gave 5,370); the smokes with max
    0.3 or more are pool-limited, the max 0.15 ones step-limited; the fires
    are step-limited (the crystal fires: about 60 of 300 bodies alive; the
    image systems about 350 of 3,000).
  * Shapes: confirmed. ImageShape tries at least 500 random pixels per
    emission (the cost of the god systems: about two million random numbers
    a second with all twelve on) and gives the edge columns half the weight
    (`round(random · (width − 1))`); 17 image systems.
  * Master/slave: confirmed (the slave particle starts at the dead fire
    particle's position, with half its velocity plus its own emit force).
  * Door systems: `blackness.png` at the system offset, in the current GL
    colour, before the particles: confirmed.
  * Where they draw: Ground: the four star systems; Actors: the twelve
    gods, the two doors, Pass to Zazo's fire and its smoke (each sorted on
    its own key); Effects: the snow and the smokes; cutscene actors' systems
    in Actors, sorted by the actor's y. A cutscene actor moves its system's
    emitter (`setPos`); **its live particles do not move with it**, and the
    actor's draw never sets the system position, so **its particles are
    drawn in screen space** (they do not scroll with the village), as are
    the stars (as in Java).
  * State read besides the drawing: the sort key `getY` (the emitter's
    position), `Village.getParticleSystem` (the timeline's emitter fade,
    which no sequence runs), the activation status in `update`, and
    `Village.SceneGLState`: an active system's draw leaves alpha test 0.1
    and colour 1 for the sprites after it.
* **Built** (deliverable 2): the generator (51 scenes; the rain and sand
  systems have no particle class, as in the original, and get none), five
  particle shaders, `VillageParticles2D`, the GPU path in
  `BodiesParticleSystem` (`gpu_path`, `gpu_run`, `gpu_warm`, `gpu_view`),
  `AbstractEmitter.advance`, `WindCommand.drift`, and `LegacyParticles2D`
  instancing the scenes. Chosen over the converter writing the generated
  scenes into the village scenes: the village scenes stay as they are (the
  `LegacyParticles2D` slot keeps the legacy loader's data, and
  `--legacy=particles` still needs it), the cutscene actors' systems exist
  only at run time, and a system's look is one scene for every place that
  uses it. Not a Godot sub-emitter for Pass to Zazo's smoke: which slot
  takes which request varies between runs, and two GPU recordings differed
  (up to 34/255 on 3 % of a frame); the slave emits on its own at the rate
  the legacy feeds it, each particle where a simulated master particle dies.
  Time: the game time the legacy system was updated for, as `speed_scale`
  per frame (so a suspended village, the never-updated bottom layer and a
  cutscene with Circle held behave as in the legacy); with `--fixed-fps 60`
  in parity runs the frames are fixed too. Seeds: one per system, drawn
  from `BodiesParticleSystem.rand` when the legacy system is built.
  Dellna's snow and wind are back ("Dellna - 0" reconverted: identical to
  the file before 7130b377).
* **Parity** (deliverable 3):
  * Golden (recorded after the own generator, before the conversion) vs.
    after, both with `--hide-particles`: all 347 cases identical (5,984
    shots), logs identical. The compare also lists 15 shots of
    `tour_berca_2` "only in A": a directory left in `out/golden` by an
    older run (no case since COTZ-027), not a difference. The runs' error
    counts are the same except two WASAPI errors in one golden run (an
    audio device event while recording).
  * The GPU path recorded twice (the 34 particle cases, 791 shots):
    identical, logs identical. Before the slave became a system of its own,
    Pass to Zazo's smoke differed between the two (the sub-emitter).
  * `--legacy=particles` after the conversion vs. the unconverted recording
    with the particles shown: 791 shots identical: the legacy path is
    unchanged. `--legacy=villages` still runs and draws them (it differs
    from the scene path only as in 6.8: the top layer, the zooms).
  * `verify_villages.gd --all`: 230 of 234 builds pass; the four that fail
    are "Zazo at Night - 0"'s loot, whose `.vil` line was changed in
    7d6f42bf without reconverting the scene (not a particles matter).
* **Look** (legacy vs. GPU on the 34 cases; contact sheets per system in
  `tools/parity/out/p_sheets/`, legacy left): the shapes, colours, sizes,
  layers, positions and motion match; the differences besides the
  intensity:
  * All: particles at sub-pixel positions, filtered (the legacy quads have
    whole-pixel corners), so edges are softer; emission is spread evenly
    over time instead of in the legacy's per-step bursts (a pool-limited
    smoke re-emits whenever a body dies); other random draws.
  * Below 30 FPS the legacy particles moved faster (6.10, motion); the GPU
    systems always have the 30-step speeds. Seeded parity runs do not show
    this (their frames are 1/60 s).
  * Snow: the GPU snow starts in its steady state (about 5,200 flakes); the
    legacy one starts with all 6,000 spread evenly and thins to about 5,370
    over minutes.
  * Smokes: Pensara North's wind (turbulence 1) wanders differently in each
    path, so its plumes lean differently at any moment.
  * Pass to Zazo's smoke comes from simulated fire particles, not the
    visible ones (the same stream; no 0.8 s delay when the fire starts);
    the column is a little lighter and longer.
  * Stars: other positions and colours (random); both never change.
  * The god, Menthu, Ophiuchus and door systems, the cutscene systems
    moving with their actors and the zoom: no difference besides the above.
* **Frame rate and load time** (normal runs: no `--seed`, windowed, one at
  a time; the median of AutoPlay's `fps=` after the fade-in; load: from
  `VillageLoader.load` to the second frame after the scene is shown, by
  temporary prints, removed):

  | Run | Capped FPS | Uncapped FPS | Load |
  |---|---|---|---|
  | Home of the Gods, all 12 god systems (`particles_hotg` route) | 8 -> 60 | 7.5 -> 930 | 1.84 s -> 0.60 s |
  | Dellna - 0 with the snow (`particles_dellna`) | 18 -> 60 | 18 -> 1,270 | 1.67 s -> 0.46 s |
  | Zazo (`zazo_0`) | 60 -> 60 | 452 -> 980 | 1.05 s -> 0.28 s |
  | Berca Desert--South West node1 (Menthu, Ophiuchus) | 18 -> 60 | 18 -> 1,530 | 0.53 s -> 0.23 s |

  The legacy load is mostly building and warming up the bodies. On the GPU
  path the first frame of a place still runs its systems' warm-up
  (`preprocess`, 30 steps a second): 10 s for most systems; the snow's
  ~200 s warm-up takes 2 steps a second (its law is linear), without which
  Dellna's load was 0.89 s.

*Closed (2026-11-06, with phase 1's decision 5, 6.9):* `--legacy=particles`
and the legacy simulation are removed: the bodies (`addBody` at build,
`step` and its command queue, `drawIt`, `init`), the quads
(`place_particles`' legacy branch, `Body.place_quad`, `LegacyParticles2D`'s
canvas items) and the bodies' draws (`Body.draw`, `BodySystem.draw`, whose
last caller was the world map's legacy `DoubleBackground.drawSystem`). The
particle classes keep the laws, which `particles_to_scenes.gd` samples.

### 6.11 The next particles (prepared; done in 6.12)

Decision 6 for these: the dungeon weather and the save points keep today's
look at 60 FPS, updated with the frame's delta (they step once per frame
and never had the `originalFrameStep` correction: every per-step law
becomes a per-second rate at 60 steps a second); the card effects keep
their look at 30 steps a second, and a battle may wait up to about 100 ms
more or less than today (12).

**Dungeon weather (P2).** `WeatherSystem` (`src/weather`), drawn by
`DungeonWeather`; 10,000 particles, rain or snow by the floor's style
(snow wins when both are set; rain: Dorma's Forest, Forest of Reil--Forest
Path, Pensara Forest; snow: Frozen Forest, Ice Cavern--Frozen Field and
--Mysterious Forest).

* Laws (per step, one step per frame): each particle keeps a fixed column
  (x in [0, 52), z in (-52, 0]: 13 x 13 cells, so the outer three rows and
  columns of a 16 x 16 floor get none) and falls by its force plus a drift
  drawn at its respawn: rain 12.0-12.2 units/s, snow 0.18-0.38 units/s,
  both drifting up to 0.06 units/s sideways. It respawns at y U[2, 4) in
  its column below y -2 (rain) or -2.2 (snow), so a rain drop lives
  0.33-0.5 s and a flake 11-34 s. No fade, size or colour law. A
  GPUParticles3D: a slot's column from a hash of its index, `lifetime` the
  longest fall, the drift and the fall speed per emission, `preprocess` to
  the steady state (the legacy starts at y U[-2, 4)).
* Drawing: axis-aligned quads, not billboards (rain 0.01 x 0.045, snow
  0.075 x 0.075 units): in the x-y plane when the facing d is in
  (-135, -45) or (45, 135), else in the z-y plane, with the corner and
  texture order of the "upper" test; additive (SRC_ALPHA, ONE), snow with
  alpha test > 0, depth tested against the walls, the floor's fog, no
  lighting. The view test is part of the look: the back pass draws
  7.5 < s < 20, the front pass 3 < s < 7.5 (s: the distance ahead of the
  player), both inside a 30.7 degree half-angle cone; particles with
  7 <= s <= 7.5 are drawn by neither pass (the front list takes s < 7).
  The cached view values go stale while the player stands still: a legacy
  quirk to decide on, not to copy blindly. On the GPU: a draw pass mesh
  whose shader orients the quad by a facing uniform and discards outside
  the band and cone; the dungeon shader's fog (`dungeon_gl.gdshaderinc`).
* What draws it today (`Labyrinth.draw`): the walls and objects, the back
  pass, a running battle's or riddle's 3D (`drawExtra`), then the front
  pass: the scene's (`DungeonScene.show_weather`) unless a battle or riddle
  runs; over a battle the legacy front pass draws into the scene's `Legacy`
  node (the 3D bridge, after the battle's batches). A GPU version needs the
  same two passes: two instances of one simulation (or two draw passes),
  the back pass sorted before and the front pass after the bridge's battle
  batches (their sorting offsets start at 1e6).
* Every frame it needs: the legacy modelview (the scene already gets it,
  `show_view`; the weather is in eye space today), the player's location and
  facing (an integer angle) for the view test, `Labyrinth.runSubGameMode`
  for the front pass, the style's rain/snow and fog. No wind (`WindCommand`
  is village-only). `place_particles` today also rebuilds the front list,
  the cached view values and the GL state (blend, alpha test, colour); a GPU
  path must leave the same GL state for the next drawing.
* Random numbers: `WeatherParticle.rand` (columns, heights, drifts; nothing
  else draws from it), but the rain's initial height draws from `J.random()`
  (`RainParticle`, 10,000 draws per rain floor build). Give it
  `WeatherParticle.rand` first and record the goldens after that (as this
  phase's deliverable 0), or the GPU version shifts every later seeded draw.
* Cost today: ~10 ms of simulation and ~9 ms of placing the back pass per
  frame on the rain floors (7.7, 7.8).

**Save points (P2).** `SaveSystem` / `SaveParticle` (`src/particleSystem`),
one per `InventorySave`, built in the floor's first frame.

* 2,000 particles on a ring of radius 0.9 around the node, starting at
  y -2: they rise 0.48-0.72 units/s and fade 0.15-0.75 per second (alpha =
  life), and respawn above y 1 or at life 0 with a new random colour, speed
  and fade; the colour cycles (R +0.6, G +1.2, B +1.8 per second, back to 0
  above 1). Quads of 0.15 x 0.15 (half the `size` 0.3: the code uses
  `size / 2`), oriented by the facing's quadrant (nothing at exactly +-45 or
  +-135 degrees), additive, alpha test > 0, no culling. Each particle runs
  400 steps in its constructor: 800,000 updates per save point at floor
  load (a GPUParticles3D: `preprocess` 400 / 60 s).
* Stepped once per draw (`Save.place_view` calls `SaveSystem.update`), also
  during battles; drawn today in the objects' batches
  (`DungeonScene.show_object`). A GPU system would be a child of
  `DungeonSavePoint`, with the facing as a uniform.
* `SaveParticle.rand` is its own; nothing else draws from it.

**Battle background snow.** `BattleBackSnowSystem` (1,000 particles,
`BattleParticle.rand`) is built only for a boss place with a `particles`
info, and the only such line in `main.bank` is commented out: dead code.

**Card and enemy effects (phase 4.4, `src/particleSystem`).**

* How the battle waits: `Animation.update` steps the packets, applies the
  damage when a packet `isDestroyed()`, starts the next card when it
  `isReady()` (after 400 ms for an attack card) and drops it when it
  `isDead()`. `isDestroyed` is set by the system's travel (path length over
  speed: a timer in effect, quantised to 33 ms steps), by CHECK_DISTANCE
  (the sword cards: distance squared < 0.2, also a function of time) or by
  Flare's PARTICLES_DESTROYED (exactly 400 particles whose counter passed
  8). `isDead` is "destroyed and at most IS_DEAD_LIMIT particles alive";
  with the per-step fades known, a lifetime estimate after the destroy time
  stays within the 100 ms. `isReady` is one of the two or an IS_DELAYED
  timer. The damage text (`AttackText`, ~2.1 s) usually ends a card's
  animation later than its last `isDead` anyway.
* What can move to GPUParticles3D before the rest of 4.4: the battle's 3D is
  drawn into the dungeon scene's World3D with the camera at the origin
  (7.5), so an effect can be a GPUParticles3D in eye space under the scene's
  `Legacy` node, sorted among the bridge's batches. Its legacy packet keeps
  the logic (the travel and the timers that make it destroyed, ready and
  dead; the shakes and colours it triggers) and hands the effect its state,
  as the village systems do (6.10). That fits the plain emitters and the
  equations, which are stateless curves of the emitter's time: Fire,
  BlackFire, Ice, Blizzard, Earth, Colliding, Wind, BlackWind,
  ChameleonStrike (CircularWave), Ultima, BlackUltima (UpDownSideWave),
  Tornado (WhirlWind), SacredBeam, SmallSacredBeam, the Cure family (Line),
  Drain and EnemyDrain (target-point gravity, a per-particle law) and the
  sword cards. Not as particles, or not without more work: Shatter
  (CrushingSaber: emits from the enemy's current frame, taking each pixel's
  colour and alpha and consuming the opaque ones; bakeable per frame, but up
  to 5,000 particles at 12,000/s with a dead limit the battle waits on), the
  sphere systems (Demolish, SerphiaDeath: lit `gluSphere`s, i.e. meshes and
  a light, not particles), DemolishEmitter (its destroy shrinks the enemy:
  logic feedback; its path is analytic), Flare (its destroy condition counts
  particles: it needs the timer) and the non-particle systems
  (ImageParticleSystem, SlowParticleSystem: sprites with coroutines;
  EnemySystem: the enemy's colour). The per-step laws to convert: the fades
  and their growth, the destroy kicks (one step's force: half the kick at
  60 steps unless scaled) and the per-step gravity jitter.
* The cheaper interim (stepping the legacy effects every frame with
  per-second rates) doubles their GDScript cost: the Flame pre-run gives
  about 9.5 us per particle update, so the biggest effect (Wind level 3,
  about 10,700 particles) costs about 100 ms per step today, every other
  frame, and would cost it every frame. Not recommended; the GPU is the fix.
* The Flame pre-run (`Flame.getAnimation` -> `FlameParticleSystem.create`,
  for Menthu's `pl=true` frames): 200 iterations of 3,000 particles, each
  stepping the particles and the emitter twice (the Java duplicates the
  loop): 1.2 million particle updates and at least as many `J.random()`
  draws, 11.4 s. What is kept is only the live system (no frames); its
  motion does not depend on the enemy (the image and settings are fixed; the
  enemy's scale, offset and height only place it). Neither the GPU version
  nor the every-frame interim removes the loop by itself, but a GPU version
  replaces it with `preprocess` (milliseconds). It can be fixed on its own
  first: compute the canonical state once and place it per build (removes
  the stall from the second attack on), or run the pre-run without the
  duplicated particle loop (halves it). Give it its own random generator
  first: removing its draws shifts the battle's later seeded rolls
  (critical hits, `EnemyLogic`), so Menthu's goldens would change.

### 6.12 The dungeon particles and battle effects phase (P2): done

Done on 6.11's preparation, for "the rest of the particles (battle/dungeon)":
the dungeon weather and the save points (P2), and the card and enemy
effects of 9.4 that are particles. Decision 6 as 6.11 states it.
Conventions: docs/ARCHITECTURE.md section 10 ("Dungeon particles") and
section 11; tuning and checking: docs/CONVERTING_PARTICLES.md sections 4
and 5.

* **Own random numbers first.** The rain's initial heights drew from J
  (`RainParticle`, 10,000 draws per rain floor build) and the effects from
  J's shared generator (every draw in `src/particleSystem` and the cards'
  effect positions); they now draw from `WeatherParticle.rand` and the new
  `ParticleSystem.rand` (port notes inventory-weather, particles-system).
  `--hide-particles` also hides the weather, the save points and the
  effects drawn as particles, with the GL state their drawing leaves. Then
  the goldens: all 347 cases and `bridge_test` hidden (`p2golden`) and the
  235 dungeon and battle cases shown (`p2shown`). Village runs did not move
  (the old and new goldens of the village cases are identical).
* **Coverage.** The console's `cast` (cards played on a party member's turn;
  `cast next` plays the rounds of `--casts=`) and 13 cases `effects_*`:
  every card effect (level 3, some at 1 and on all, a combo of three) on
  Memory Taur (20,324 hp; Salmonman's 1,081 do not outlast some cards),
  whose battle runs in the labyrinth's frame, and in Serphia's battle area;
  Menthu's burning man (`effects_menthu_flame`). Two save point cases
  (`particles_save_*`: in the rain on Forest Path, without weather in
  Grivera). All recorded twice, hidden and shown: identical. Not castable by
  the party: the enemies' Flame (speed 0, never destroyed), SerphiaDeath and
  BlackDeath (they read the attacking enemy); neutral cards fail in
  `ResultScreen.calcResult` (index 3 of 3 types, as in Java).
* **Facts found** (where they add to 6.11):
  * Weather: `isMoving` includes turning, so the cached view values go stale
    only while the player stands still, by the flakes' drift (at most 0.06
    units a second): the GPU view test is always fresh. Both passes draw
    with the depth test and depth writes on (additive), GL back faces culled
    (the quads always face the camera), fog on; snow's alpha test is
    GREATER 0, rain's the one left from before (mostly GREATER 0.1).
  * Save points: drawn without fog; the quad is not centred (its corner at
    the particle minus 0.15, the legacy `size / 2`); a save point's particles
    move only in the frames it is drawn.
  * Effects: the waits, measured per system from its destroy to isDead
    (legacy): 0.17 s for the sword cards, 1.0-1.5 s for most magic, 1.6 s
    for Ultima (its limit is 0: the last particle), 2.3 s for Chameleon
    Strike's second system; a packet asks its systems in order, so its
    first system's time counts. An interpolating emitter's time counter
    advances by a share of the elapsed time per particle emitted, so its
    emission point lags behind the body while the pool is empty (Tornado's
    narrow cone). A labyrinth battle's effects are drawn into a SubViewport
    chunk (2D comes before them), not into the floor scene's. The battle's
    GL state culls back faces (the legacy quads never are). Drain's second
    system has masses from 0 to 0.3 (a near-zero mass throws a particle
    out). FlareEmitter's 400 particles fade in (a negative fade) and its
    other 1,100 wait at the source until the destroy throws them out.
* **Built.** P2: `QuadParticles3D`, `WeatherParticles3D` (`Rain.tscn`,
  `Snow.tscn`), `SaveParticles3D` (`.tscn`), `weather_particle`,
  `save_particle` and `quad_particle_3d.gdshader`, `random.gdshaderinc`
  (shared with the village shaders); the GPU paths of `WeatherSystem` and
  `SaveSystem` (`gpu_path`, `place_gpu`), `Labyrinth.show_weather_over`, the
  3D bridge's batch slots (`Graphics.reserve_scene_slot`). Effects:
  `EffectParticles3D`, `effect_particle.gdshader`,
  `effect_draw.gdshaderinc`; the GPU path of `ParticleSystem` (the smaller
  pool for the waits, `gpu_state`), the packets' game time, the Flame
  without its pre-run, GLBackend's nodes in a chunk (`Graphics.show_node`).
  Not a Godot sub-emitter or collision: every law is in the process shader.
* **Parity** (all from one snapshot of the final code):
  * Golden vs. after, both with `--hide-particles`: 6,806 of the 6,858 shots
    of all 362 cases (361 and `bridge_test`) identical, all logs but two
    identical. The 52 other shots are in battles: the effects cases and one
    shot of `dungeon_tunnel_battle`, where the waits of the smaller pool end
    an animation a little sooner or later (an enemy's tint fading out, a
    damage number floating, a party member's turn); the two logs show an
    animation ending 200 ms later (one poll of the script). With
    `--legacy=effect_waits` (the legacy pool decides the waits) all 25
    battle cases are identical to the golden (1,134 shots, logs too): the
    GPU effects change nothing in a battle but the waits.
  * Before the weather passes were hidden by their visibility, a pass that
    drew nothing (every particle collapsed) still changed Godot's
    transparent sort: 23 shots of weather floors by 1/255 (section 12,
    order-dependent blending).
  * The legacy paths (`--legacy=dungeon_particles,battle_effects`) vs. the
    unconverted drawing with the particles shown: all 250 dungeon and battle
    cases identical (4,269 shots, logs too).
  * The GPU path recorded twice (those 250 cases and the 34 village particle
    cases): identical (4,957 shots, logs too). The GPU seeds of the effects
    come from `ParticleSystem.gpu_rand`, seeded from a hash of `--seed`: a
    first version drew it from J's seed sequence, which shifted every later
    `JRandom` (the steps to a random battle) against the goldens.
  * The village particle cases on the GPU vs. the particles phase's own GPU
    recording: identical but Dellna's snow (that recording predates the
    snow's coarse warm-up) and the shots that show this phase's rain or a
    battle.
  * `verify_dungeons.gd`: 160 of 160 builds; `verify_villages.gd --all`:
    111 of 117, the "Zazo at Night - 0" loot as before and "Dellna - 1" and
    "Dellna - 2", whose scenes the last commit re-saved with snow systems
    their `.vil` files do not build (not this phase).
* **Look** (legacy vs. GPU; contact sheets per floor, save point and card in
  `tools/parity/out/p2_sheets/`, legacy left): the shapes, colours, sizes,
  positions, layers and motion match, for every card, Menthu's burning man,
  the rain, the snow and the save points. Besides other random draws:
  * All: the particles move every frame (smooth emission and motion, no 30
    or 60 Hz steps); additive systems at the legacy intensity (1; tunable in
    the weather and save point scenes).
  * The weather's view test is fresh while the player stands still (the
    legacy one lagged by the flakes' drift).
  * Effects: the waits of the smaller pool (within about 0.1 s) shift when
    the next card, the enemy's turn and the result screen come; Tornado's
    emission point follows the smaller pool's estimate of the legacy time
    counter, so its cone is caught at a slightly different height; with a
    party turn order that shifts, Drain's and Cure's targets and the sword
    cards' random slashes differ between runs.
  * The first effect of a battle compiles its shaders (one frame of about
    0.1 s; Fire 3's minimum below).
* **Frame rate and load time** (normal runs: no `--seed`, windowed, one at
  a time; the median of AutoPlay's `fps=`; times by temporary prints,
  removed):

  | Run | Legacy | GPU |
  |---|---|---|
  | Forest of Reil--Forest Path (rain), capped / uncapped FPS | 35 / 36 | 60 / 926 |
  | Ice Cavern--Frozen Field (snow), capped / uncapped FPS | 50 / 50 | 60 / 880 |
  | Building the weather at floor load | 165 ms (rain), 150 ms (snow) | 0.6 ms |
  | A save point at the floor's first frame (2,000 particles x 400 steps) | 379-389 ms | 0 ms |
  | The floor's first frame with a save point (Forest Path, Grivera) | 449 ms, 440 ms | 47 ms, 64 ms |
  | Wind 3 (about 10,700 particles), lowest FPS of its round, capped / uncapped | 7 / 6 | 59 / 166 |
  | Tornado 3, lowest FPS, capped / uncapped | 25 / 25 | 60 / 265 |
  | Fire 3, Ice 3, Earth 3, Blizzard 3, Colliding 3, Ultima 3, lowest capped FPS | 58-60 | 52-60 |
  | Menthu's Flame (`Flame.getStaticAnimation`), the game stands still | 10,450 ms | 1.6 ms |

*Closed for the dungeons (2026-11-06, with phase 2, 7.9):*
`--legacy=dungeon_particles` and the weather's and save points' legacy
simulation and quads are removed. `--legacy=battle_effects` and
`effect_waits` stay until the battles are converted (4.4): the legacy
effect pool still decides the waits on the GPU path.

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
  batching, which here is already as GLBackend's. *Phase 3 (8.2):* with the
  minimap not drawn in either path, the ice button case and the Silent Ruin
  tour are identical (24 of 24 shots; 15 differ with it): the 1/255 of those
  shots, Silent Ruin's too, comes from the minimap's batches in the scene's
  world, not from its walls.
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

### 7.9 Closing phase 2 (done on 2026-11-06)

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

*As built (2026-11-06):* decision 5 is decided (delete the text files)
and the 1/255 of 7.8 accepted: with the legacy path gone there is nothing
to compare it with. Everything in the table is removed, and:

* `MapLoader` keeps `addTexture` (`load_into` calls it) and the constants;
  a floor without a scene stays empty with one error, as a missing file
  left it. `DungeonScene.path_for` resolves the floor's scene by its `.map`
  name in `file_index.txt`, without regard to case (6.9).
* `PillarWalls` is deleted (`PillarWalls.node`, which `load_into` set, is
  read by nothing but the parse; the data check compared it), and
  `MenuMapLoader` (no caller; it parsed `.map` files).
* With `--legacy=dungeon_particles` (6.12) gone, `WeatherSystem` and
  `SaveSystem` build no particles and `place_particles` returns the GPU
  state; `WeatherParticle.drawParticle`, `SaveParticle.drawParticle` and
  `place_quad`, `DungeonWeather.show_pass` and its meshes go too (the front
  pass over a battle is the GPU pass, `show_weather_over`); `set_quads`
  stays (the objects' batches).
* The display lists go with `Graphics`' eye-space bookkeeping
  (`DisplayList`, `_list_eye`).
* The debug console reads the floors from the scenes (the floor list, save
  points, bosses, the cells' links); `boss` puts the party on the boss's
  neighbour with the lowest address, which for all six bosses is the one
  the first `dir` line of the `.map` file gave.
* A prototype look's camera set `DungeonWeather.eye`, which only the
  legacy quads used; the line is removed with them.

Not in the table and still there: `init_scene_3d`'s GL state (the battles
read it), the minimap (the 3D bridge, 8.4), `drawOneWall` and
`drawOneFloor` (`DungeonQuads`), `Inventory._drawQuad` (`place_view`).

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
   * *Pilot (8.1):* the theme has the fonts, a size per role and the papers;
     nothing is restyled. No baseline tuning was needed: a text node drawn
     by its baseline with the legacy call (`BaselineLabel`) is exact. The
     `TODO.md` items are look changes, open (13, decision 8).
2. **Dialog** (`villages/utils/Dialog.gd`, 381 lines, a singleton used by
   villages, dungeons, cutscenes and stores) → `ui/Dialog.tscn`.
   * It is a Control that draws the state of the legacy `Dialog`/
     `DialogSequence`: name, two lines, question cursor, gift line.
   * Then `SignBox.tscn` and the card info popup (`DeckPage.drawCardInfo`).
   * The emotion bubbles become children of `ActorView`, with an absolute
     `z_index` above `Overhead` and `Effects` (the original draws them on
     top of roofs). *Rollout (8.3):* UI nodes that draw the legacy quad; in
     `World` a cutscene zoom rounds them differently.
3. **Fades** → `Transition` layer: a ColorRect, or a TextureRect for
   `setFadeImage(WHITE | image)`.
   * First, render only: draw `fadeValue` from the legacy `Fadeable`, so the
     exit timing does not change.
   * Later (after the time-base decision), a Tween whose `finished` signal
     ends the mode's exit.
4. **HUD pieces:** dungeon mission display, minimap frame, "Paused" and
   "game pad lost" (`GameCore.testDraw`). *Rollout (8.3):* all but the
   minimap, which stays the 3D bridge's batches.

**Exit:** villages, dungeons and cutscenes have no `draw(g)` left except
battles and riddles.

### 8.1 Pilot results (the dialog family and the fade)

Done as `docs/phase3_prompt.md` asked: the Theme, and step B for the dialog
box (the legacy `Dialog`: speeches on both papers, questions and the hand,
the input question, a shown image, gift lines), the message box
(`Dialog.drawMessages`: signs, loot, gift lines without a speaker), the card
info popup (`DeckPage.drawCardInfo`) and the fade (`GameMode.draw`'s and a
cutscene's own). Conventions: docs/ARCHITECTURE.md section 12; the procedure
for the next overlays: docs/CONVERTING_UI.md.

* **Baseline** (on 55499bc7): `tools/check.sh` 0 failed; goldens of all 362
  cases and `bridge_test` (`p3golden`, 12 minutes with 8 jobs: the GPU
  particles made recording five times faster); the cases that show dialogs
  (`story_*`, `dungeon_use_*`, `dungeon_trigger_*`, `stores`, `boss`)
  recorded again: identical (1,793 shots, logs too).
* **Facts found** (deliverable 1; where they add to or differ from the
  prompt):
  * The order around the dialog, mode by mode, is as the prompt lists it,
    with these additions. Village: the card info drawn under a message is a
    loot's or a sign's card (`Sign` content). Cutscenes: `draw_scene` calls
    the village's `drawOverlays(g, null)` (no emotions, the village's dialog
    only while it talks, which no cutscene does), the timeline then draws its
    actors' emotions, `drawTop`'s images, the dialog (after
    `loadIdentity`: the zoom applies to the images before it, not to the
    dialog), its own fade (not in the two translucent image modes), the text,
    the scroll text and the translucent-over-actor image; `VillageStory.draw`
    then draws the mode's fade last. Labyrinth and BossBattleArea: their
    `card` is never set (nothing calls `drawCard(c)`, in the Java either), so
    the card info after their dialog never shows; the card a chest gives is
    the dialog's gift (`Dialog.drawGift`). Stores: after `drawStandard`'s
    dialog come the keeper, the menu strips and `draw3D` (menus, the confirm
    dims and boxes, the card store's card info at y −23, the Inn's prize
    message with its card, tutorials). World map: the dialog after the node's
    name plate, then the fade. A riddle draws no dialog.
  * The mode fade is the last drawing of every mode that has one (Village,
    VillageStory, Labyrinth, Landscape, AirLandscape, the stores, the boss
    areas, the menu, the title and game over; not BattleManager, Cheater,
    BattleTest and the riddles, which have none): only `GameCore.testDraw`'s
    "Paused" and "game pad lost" come after it (a fade of 0.5 and text). The
    story texts and images are drawn after the cutscene's own fade, before
    the mode's.
  * Fades: `FADE_TO_WHITE` comes from cutscenes (`setfadeimage`, "Getting the
    Crystal of Levitation", "Elder of Dellna Saves the Day"); `FADE_TO_IMAGE`
    only from `Menthu1.kill` and `Menthu2.kill` (`res/test.png`, Menthu on his
    knees), which no case reaches; a fade-in that completes sets black again.
    The quad takes `setFadeColor`'s colour (a cutscene's tint) and is drawn
    with the frame's 2D state: an alpha test drops it while it is nearly
    transparent. `fadeOldSchoolColor(White)` (the tutorial's dim, an enemy's
    red flash) and `dim` (the menu hand) are no mode fades.
  * State changed while drawing: the shown image's alpha (and the
    `isFinished()` it calls at 0, which moves the dialog on), `questionNumer`,
    `alternatives`, `input` and `xChoice = -1` of the input question; the
    GL and text state (drawString's `setColor(color)`, `startText`'s alpha,
    the font sizes, drawImage's bound texture). `DialogSequence`, `MenuHand`
    (not used by the dialog, which draws its hand image itself) and
    `drawCardInfo` change nothing else.
  * Text: every converted text is left aligned at a fixed baseline (no
    `calcAlignCenter`, `getStringWidth` or `drawMultiString` of a measured
    width); `drawString` draws at alpha 1, `drawMultiString` at `startText`'s
    alpha, the current mode's fade value: a store's lines fade with it, the
    speaker's name does not. The dialog sets black for speeches and messages;
    questions, the input question and the card info take the current text
    colour; the bold font is whatever was set last.
  * The layers share the canvas: at 1280 x 720 and 1440 x 1080 (letterboxed)
    the papers and images are identical legacy vs. node; text was rasterized
    at the window's scale by the nodes (Godot's oversampling for Controls:
    sharper, up to 107/255 on 1 % of a frame), at 1 by the legacy; with
    `BaselineLabel.oversampling` 1 it differs by 1/255 on 3–23 pixels a shot
    (the transform's rounding). `copyFrame` and AutoPlay's shots read the
    main viewport: every layer, as the frame before rendered it.
  * A dialog never shows with a visible story, cover-all or translucent image
    in the 80 stories that ran headless with a slow CROSS (the timeline waits
    for input at a dialog); it shows under a cutscene's own fade only while
    "Vincent Tries to Cool Down the War" (80 frames) and "Menthu is
    Disappointed" (5) fade in.
* **Coverage.** Nine new cases (`dialog_*`, 141 shots), recorded twice on
  unconverted code: identical. A probe copy with prints in the draws and in
  AutoPlay's `shot`, run headless over every case, gave what each shot
  shows; the new cases add what none showed: Math in Dellna (his name, a
  question with the hand moved, the shown image fading in and out, the input
  question, a gift line with its card), The Prison Cell (a loot's card, Kin
  answering on the second paper, both papers), a sign, the world map's "We
  can't enter now!", a trigger door's dialog while the floor fades in and its
  question with the hand moved, a store's dialog through its fade-in and
  fade-out, the card info on the menu's deck page and over the card store's
  menus, a cutscene's dialog under its own fade. The existing cases already
  show the dialog in every mode that draws one (boss areas, stores, the
  labyrinth's villagers, chests, missions and riddles), whispers (cutscenes,
  labyrinth, boss areas), both papers in cutscenes and labyrinths, the mode
  fade in every mode, white fades and a dialog during a mode's fade.
  Not covered: an image fade (`FADE_TO_IMAGE`; the Fade node's TextureRect
  with a tint, as the dialog's shown image, which is covered), "game pad
  lost" (no pad in seeded runs).
* **Built** (deliverables 2–4): the Theme; `BaselineLabel`; `Dialog`,
  `SignBox`, `CardInfo` (UI layer) and `Fade` (Transition) scenes; the twins
  in `Dialog`, `DeckPage.show_card_info`, `AbstractCard.place_card`,
  `Graphics.show_fade`; `Graphics.show_ui` / `GLBackend.show_ui` (a node's
  slot in the frame's 2D order, the legacy 2D after it on its layer);
  `--legacy=dialog`, `--legacy=fades`. Moved besides the mode fade: the
  cutscene's own fade (its texts are drawn over it, on Transition). Kept
  legacy: the riddle's fade, "Paused" and "game pad lost".
* **Parity** (all from one snapshot of the final code, tolerance 0; the 370
  cases and `bridge_test`, 6,999 shots, of which 432 in 70 cases show a node
  of the dialog family and 901 in 302 cases a fade, by the probe of the
  first 368 cases; the node run is the "" side of every pair):
  * golden vs. the nodes (`""`): 6,999 of 6,999 shots identical, all logs
    identical, the same script errors in every case (2,089, the content
    quirks of 6.8 and 7.8);
  * `ab "--legacy=dialog" ""`, on every case: 6,999 of 6,999;
  * `ab "--legacy=fades" ""`, on every case: 6,999 of 6,999;
  * `ab "--legacy=dialog,fades" ""`, on every case: 6,999 of 6,999; and the
    run with both flags equals the golden (6,999 of 6,999: the legacy paths
    and GLBackend's frame without nodes are unchanged).
  * No tolerance was needed: the nodes draw with the legacy calls
    (`draw_string`, textured rects of the same textures, GLBackend's own
    canvas materials), in the legacy order. The first parity run of the
    pilot case (Math) was already identical.
  * The bridge test passes (identical, "BridgeTest: freed" in the log).
* **Frame rate** (normal runs: no `--seed`, windowed, one at a time; AutoPlay's
  `fps=` every 0.5 s for 10 s while the dialog is shown, legacy → node):

  | Where | Capped | Uncapped |
  |---|---|---|
  | "Vincent Tries to Cool Down the War", its first dialog | 60 → 60 | 1,990–2,110 → 2,070–2,210 |
  | Central Pass--West Part, the trigger door's dialog | 60 → 60 | 960–1,040 → 920–1,010 |
  | Dellna, Math's first line | 60 → 60 | 1,400–1,640 → 1,420–1,790 |

  The same within the noise. One uncapped node run of the cutscene fell to
  145 FPS for its last 5 s and did not again in three repetitions.

### 8.2 The rollout (prepared; done in 8.3)

The legacy overlays left in villages, labyrinths and cutscenes, with their
place in each mode's frame and what each needs (in the order of the frames):

| Overlay | Where in the frame | What blocks it |
|---|---|---|
| Emotion bubbles (`Sprite.drawEmotions`, `Actor.drawEmotion`) | Village: first in `drawOverlays`, before the dialog; cutscene: the actors' after the scene, before `drawTop`'s images | Nothing in the order: they are the first legacy 2D after the scene, so they can be children of their `ActorView` in `World` (z above `Overhead` and `Effects`, item 2 above) or UI nodes. Keep the state their drawing changes (2.4, the bubble positions of `Village.update_draw_state`), the cutscene zoom's transform |
| Mission display (`Mission.draw`) | Labyrinth: the first 2D, after the minimap, before the dialog | Nothing: a UI node before the dialog's slot; its `pushState`/`hide`/`popState` stay legacy |
| Minimap (`MapRenderer`, 3D without depth test, in the scene's chunk) | Labyrinth: after the weather and a battle's 3D, before the 2D | It is 3D (a tilted disk and arrow). The plan 7.5's 3D node on the rig puts it where its batches are today; plan 7.8's 1/255 comes from those batches (below), so the node has to be checked against it. As a UI node it would need its perspective drawn in 2D |
| A battle's and a riddle's top layer | Labyrinth, boss areas: after the dialog | Phase 4 (battles, mini-games) |
| Tutorials' top layer (`Tutorial.drawTopLayer`, the trigger door's, the stores') | Labyrinth: after the battle's top layer, before the fade; stores: in `draw3D` | Its coloured text (`ColorTextLoader`, the `.tut` word colours: BBCode, 9.2) and its dim (`fadeOldSchoolColor`) |
| Cover-all, story and village images (`ImageSettings.draw`, `drawTextBack`) | Cutscene: `drawTop`, before the dialog, under the zoom's modelview | The zoom (the timeline scales the modelview at the start of `draw`; the images are drawn with it); the scroll modes; then UI nodes before the dialog's slot |
| Story texts (`Text.draw`), scroll texts (`ScrollableTexts`, the credits) | Cutscene: after the cutscene's fade (over it) | Their own fades (`Text` is a `Fadeable` stepped per draw), the font the credits leave set (each line's `setFontSize(size, bold)`; *4.2:* no line of the ending is bold); nodes on Transition after the fade's slot |
| Translucent-over-actor image | Cutscene: last of `drawTop`, over the dialog and the texts | As the images; on Transition after the texts |
| "Paused", "game pad lost" (`GameCore.testDraw`) | After the mode, over its fade | The pad overlay needs a dev flag to be covered (seeded runs read no pad); its menu is a `MenuNode` (9.2) |
| Menu pages (`MainMenu`, `AbstractPage.draw3D` per page; `LabyrinthMap.draw`) | The menu mode | Phase 4.2 (`MenuNode` lists, the help and tutorial texts, the automap) |
| The riddle's fade | Labyrinth, inside the riddle's top layer | Phase 4 (the riddle's backdrop) |

**The minimap and plan 7.8's 1/255.** Drawn without the minimap (both paths),
`dungeon_use_ice_button` and the Silent Ruin tour are identical legacy vs.
scene (24 of 24 shots); with it, 15 differ by 1/255, also the Silent Ruin
shots that 7.8 attributed to the alpha-textured walls (their differing
pixels lie on walls far from the minimap). So the 1/255 comes from the
minimap's legacy batches in the scene's 3D world (the 3D bridge), not from
the walls or the weather: a minimap that is a node replaces exactly the
drawing that causes it, but where and how the node is drawn decides whether
the 1/255 goes (a node in the same world, sorted after the walls as the
batches are, may keep it).

**What keeps the exit from being met after the rollout** ("villages,
dungeons and cutscenes have no `draw(g)` left except battles and riddles"):

* The modes still have `draw(g)`: the Organizer drives every mode through
  it, and step B's twins run there (where the legacy state changes happened).
  Only a `Game` autoload (9.3) and `_process` (phase 5) remove it.
* The `--legacy=` paths (`villages`, `dungeons`, `dialog`, `fades`, …) draw
  through `Graphics` until each phase closes (6.9, 7.9).
* Labyrinths: `init_scene_3d`'s GL state, which battles read, and the 3D
  bridge for a battle's drawing (battles are exempt, but the bridge is not
  battle code); the frame's structure (`GLBackend.begin_frame`, chunks)
  until phase 5.
* The world map and the airship (`Landscape`, `AirLandscape`) are other
  modes (4.1), the menu (4.2) another; they are not in the exit's list but
  they draw the shared dialog and fade through the same twins.

### 8.3 Rollout results (the other overlays)

Done as `docs/phase3_rollout_prompt.md` asked: step B for the overlays that
villages, labyrinths and cutscenes still drew. Conventions: docs/ARCHITECTURE.md
section 12; the procedure: docs/CONVERTING_UI.md.

* **Baseline** (on 99cd1b64): `tools/check.sh` 0 failed; goldens of all 370
  cases and `bridge_test` (`r3golden`, 6,999 shots, 13 minutes with 8 jobs;
  2,089 script errors, the pilot's count); the pilot's check
  (`--legacy=dialog,fades` vs. the golden): 6,999 of 6,999 shots identical,
  all 371 logs identical.
* **Facts found** (deliverable 1; where they add to or differ from 8.2):
  * Emotion bubbles. Only a cutscene's timeline sets them
    (`Sprite.setEmotion`); no case, and no sequence the cases run, leaves one
    on a village sprite, so no case's village frame draws one (the console's
    `emotion` covers that path). A village draws its sprites'
    bubbles first in `drawOverlays`, in the sprite map's order (party members,
    villagers, animated objects: not the y-sort); a cutscene draws every
    actor's bubble after `draw_scene` (also a hidden actor's, at its last
    position), before `drawTop`. Both come first among the frame's legacy 2D
    (the village's dialog in a cutscene is never drawn), so a node in `World`
    would keep the order (over the actors, roofs, treetops, the night layer
    and the particles, under every overlay) with a layer of its own after
    `Effects` (not `ActorView` children: the order is the sprite map's, and a
    hidden actor's bubble is drawn). Under a cutscene zoom the bubbles are
    drawn with the scaled modelview (253 of the 604 shots that show one, zoom
    1.33 to 2.0). There a node in `World`, zoomed by the village camera,
    differed by up to 2/255 on 1–67 pixels in 36 of those shots (the camera's
    transform rounds the corners differently from the legacy CPU transform),
    and a UI node with the modelview as its Node2D transform in 34: the
    bubbles are UI nodes that draw the legacy quad (its corners transformed
    as `_emit2D` does). Their drawing changes the shake counter (`counter`,
    `emotionSpeed`, `currentX`) and binds the image; the bubble positions
    are set where the sprite is placed (`place_sprite`, phase 1).
  * Mission display. Drawn after `set2DNow`, first in the labyrinth's 2D,
    every frame (also in battles and riddles), before the dialog. Each
    subclass's `draw` steps the slide (`Hideable.update`: per drawn frame,
    while the minimap's `update` is per update) and reads the Database; the
    time mission counts its clock there (`Values.INTERVAL` per drawn frame)
    and, at 0, writes four statuses and leaves the floor ("Time's up!",
    shown while the floor fades out). `pushState`/`hide`/`popState` are
    called by `Labyrinth.push`/`pop` (dialogs), not while drawing. Text:
    `startText()` (alpha = the mode's fade value), size 40, white; the x
    moves with the slide (`int(800 + xtrans × 300)`, the bombs' `700 + ×
    350`). The "Slot 1" save's prison clock starts at 0:49, not 2:30.
  * "Paused", "game pad lost". After the mode's draw and its fade, in
    `GameCore.testDraw`; their dim is `fadeOldSchool(0.5)` (the fade mode's
    image: black, white or Menthu's image). The game goes on under "Paused"
    (only `Time` checks it). "Game pad lost" reads its menu's buttons inside
    the draw, between its texts and its menu, but every mode reads the
    directions and CROSS in its `update` first (the village walks with them,
    a cutscene drops them), so its menu moves only when the mode did not take
    the press: in a labyrinth while the player steps. A cutscene takes START
    itself (`VillageStory.checkGameInput`: it ends the story), so a cutscene
    is paused only by a START while it loads. Both as in the Java.
  * Cutscene images. `drawTop` draws the cover-all, story and village images
    under the zoom's modelview (it scales at the start of `draw`; nothing
    resets it before), a story image's text back after `loadIdentity`, then
    the dialog (after `loadIdentity`); the translucent image over the actors
    after the texts, under the modelview only when no dialog reset it. The
    probe: every mode shown, the scroll down and right (a story image at
    size 2), the text back, the translucent image under a zoom (with a
    dialog). Drawing changes: the image binds, the text back's
    `loadIdentity`; the scroll and the zoom's `offsetx` step in `update`.
  * Texts. `Text.draw`: `startText(alpha, colour, size)` (40 or 50; whisper
    −6: no sequence whispers; black only in "Ending - Part 2.x"),
    `drawMultiCenteredText` (the advance width, `J.round` of half) for each
    line; it changes the font size, the text colour and alpha and
    `setColor(color)`. The timeline steps its own and the text's fade in
    `update` and in `draw` (the Java does the same: not a port bug).
    `ScrollableTexts.draw` draws every line from 50 px above the screen on
    (also those far below it), each with `setFontSize(size, bold)`: the bold
    font stays set; the parser never sets a line's mode, so all credits are
    left aligned.
  * Tutorials. `Tutorial.drawTopLayer` draws the dim (`fadeOldSchoolColor`:
    the black fade image at 0.5), the paper, the title (size 34, centred,
    alpha 1), then `Row.drawRows` (size 26: each word black, a coloured word
    over a black shadow 1 px off, alpha 1 after the first word's
    `setTextColorAndApply`; the next word after the JOGL ink width + 7) and
    the icons (scaled images, in the colour `finishText` leaves). It is
    called by trigger doors (the labyrinth's top layer, after the dialog: a
    tutorial page stays drawn after walking away), battles, the weapon and
    card stores and the Church, and the menu's tutorial page. The Church's
    `HelpText` draws rows too (`Row.drawRows`, a store: phase 4.2).
  * Minimap. `MapRenderer.draw`: in 3D after the weather (and a battle's 3D),
    depth test and mask off; two disks (`gluDisk`, untextured, black at 0.5),
    the compass, the visited and seen cells (`LabyrinthMap.draw2` →
    `drawInSmallMap` → each inventory's `drawInMap`, which reads doors'
    states), the yellow arrow; its slide steps in `update`. It lands in the
    floor's world (the 3D bridge) except at a battle's start: the battle has
    drawn 2D, so the minimap is a SubViewport chunk of its own while it
    slides out (19 battles, 10 frames each; hidden by then for the rest of
    the battle).
* **Coverage** (deliverable 1). The probe (`tools/parity/probe.sh`, new,
  with `probe_report.py`) over every case: the minimap in 3,408 shots of 246
  cases, the mission display in 743 of 62 (every kind, done; sliding out
  for a dialog, hidden under it and shown again after it; no shot of the
  slide back in), cutscene images in 252 of 7, texts in 552 of 13,
  the credits in 123 of 1, emotions in 445 of 25 (all in cutscenes), a
  tutorial in 4 of 1 (a trigger door's first page); none showed "Paused",
  "game pad lost", an image fade or a village frame's bubble. Twelve new
  cases (226 shots; recorded from the committed code plus the scripts and
  the two dev hooks below, twice: identical): `emotions_village` (Pass to
  Zazo at night: a villager's and party members' bubbles, Kin's shaking, over
  treetops), `pause_village`, `pause_labyrinth` (also during the fade-in),
  `pause_story` (paused while the cutscene loads, over its image, text and
  fades), `pad_lost` (the menu moved during steps), `mission_time_up`,
  `tutorial_trigger` (seven pages), `tutorial_battle` (Forest Path with the
  "Start" save), `tutorial_store` (eight and four pages), `tutorial_menu`,
  `story_ending_part2` (the black size-50 texts), `image_fade_menthu1`
  (Menthu1's defeat by the console's `kill`: the floor fades out to
  res/test.png, the next mode fades in from it). Dev hooks: the debug
  console's `padlost` (`InputManagers.lost_simulated`) and `emotion`
  (`Sprite.setEmotion`). The old cases with the hooks: 6,999 of 6,999 shots
  and all logs identical to `r3golden`; the goldens are `r3gold1` (382 cases
  and `bridge_test`, 7,225 shots), `r3gold2` the new cases again.
* **Built** (deliverables 2–4; docs/ARCHITECTURE.md section 12): UI nodes
  `EmotionBubble` (on UI: the legacy quad through the modelview,
  `Graphics.screen_points`), `MissionDisplay` (UI), `Paused` and `PadLost`
  (Transition; their dims are Fade nodes, `Graphics.show_fade(0.5)`),
  `CutsceneImage` (UI; the translucent image over the actors on Transition:
  `show_ui` pools a scene per layer), `StoryText` and `ScrollText`
  (Transition), `Tutorial` (UI, wherever the top layer is drawn); theme
  roles `MissionLine`, `PausedTitle`, `PadLostTitle`, `PadLostLine`,
  `PadLostNote`, `TutorialTitle`, `TutorialWord` (and `Text<size>` for sizes
  that are data); `BaselineLabel.alignment` (centred and right-aligned text
  as `calcAlignCenter`/`calcAlignRight` place it) and its culling (it clears
  its Control's custom rect: a line whose baseline is off the screen, the
  credits' first and last lines, was culled with glyphs on the screen);
  `LabelList` (pooled lines). Twins in `Sprite`/`Actor`/`Village` and the
  timeline, the missions, `GameCore.testDraw` (with `MenuNode` and
  `MenuHand`), the timeline's `drawTop` and `ImageSettings`, `Text`,
  `ScrollableTexts`, `Tutorial`/`Row`/`Icon`. Flags `--legacy=emotions`,
  `mission`, `pause`, `story_images`, `story_texts`, `tutorials`. The
  minimap stays the 3D bridge's batches; its node is the dev flag
  `--minimap-node` (below).
* **Parity** (tolerance 0 everywhere; the final code, 382 cases and
  `bridge_test`, 7,225 shots; the node run is `r3fin`):
  * golden (`r3gold1`) vs. nodes: 7,225 of 7,225 shots identical, all 383
    logs identical, the same error lines in every log (2,091);
  * `--legacy=<overlay>` vs. nodes on the cases that show it (by the probe):
    emotions 1,293 of 1,293 shots (26 cases), mission 925 of 925 (63), pause
    18 of 18 (4), story images 1,831 of 1,831 (36 cutscene cases), story
    texts 1,831 of 1,831 (36), tutorials 42 of 42 (5);
  * every phase 3 flag (`--legacy=dialog,fades,emotions,mission,pause,
    story_images,story_texts,tutorials`) vs. nodes, and vs. the golden:
    7,225 of 7,225 shots and all 383 logs identical, both (the legacy paths
    and the frame without nodes are unchanged);
  * the bridge test passes (identical, "BridgeTest: freed" in its log).
  * On the way to it (each explained and fixed in the bridge code, not in
    legacy logic): the credits' and the ending's lines at the screen's top
    and bottom edges were missing (up to 255/255 on up to 1,309 pixels in
    70 shots: `BaselineLabel`'s culling, above); the emotion bubbles under a
    cutscene zoom differed by up to 2/255 on 1–67 pixels in 36 shots as nodes
    in `World` and in 34 as UI nodes with the modelview as a Node2D
    transform: they draw the legacy quad now (above).
* **The minimap and the 1/255.** A node draws the minimap's batches with the
  dev flag `--minimap-node` (`MapRenderer.show_map`: the legacy drawing runs
  with its 3D primitives kept, `Graphics.begin_capture_3d`, and each batch is
  a `MinimapPart` in the frame's 3D chunk and slot, `Graphics.show_node`). On
  the floor's frames it draws to the bit (all 3,408 shots that show the
  minimap identical to the golden), so it does not remove the 1/255 of 7.8:
  that comes from the drawing in the floor's world, which the node draws the
  same. But 41 battle shots after a floor's frames differ by 1/255 (`battle`
  4, `dungeon_battle_frozen_field` 7, `_frozen_forest` 7, `_pensara_forest`
  2, `dungeon_tunnel_battle` 8, `image_fade_menthu1` 13), on walls and
  ground far from the minimap. Experiments on `battle` and
  `dungeon_tunnel_battle`: nodes only in a battle's SubViewport and the
  legacy batches in the floor's world: identical; the reverse: different;
  the 3D bridge's pool instances created early (hidden), or holding the
  minimap's meshes hidden: different; the legacy batches drawn as well as
  the nodes on the floor's frames: the battle frames identical. So the
  bridge's pool instances that drew the minimap render a battle's batches
  1/255 apart from instances that did not (the renderer's per-instance
  state; the mechanism was not found, as 7.8's was not). Against the legacy
  dungeon path (`--legacy=dungeons`, which since P2 also draws the legacy
  dungeon particles: 281 of the 3,083 shots of 7.8's 231 cases differ more
  there) the 1/255 shots are 112 with the bridge's minimap, and the node adds
  `dungeon_tunnel_battle`'s 8. That fails the bar (7.8's shots, nothing
  more), so the bridge draws the minimap by default. A minimap node is worth
  trying again when battles leave the 3D bridge (phase 4.4). *Phase 4.4's
  rollout, part 1: the differing pixels were the floor's walls, whose tied
  surfaces Godot's sort reordered; with the walls drawn in a fixed order
  `--minimap-node` is identical to the node run on all 34 battle cases
  (1,992 shots; 9.4).*
* **Frame rate** (normal runs: no `--seed`, windowed, one at a time, the
  shipped saves (`APPDATA` a scratch folder); AutoPlay's `fps=` every 0.5 s
  for 10 s, legacy (`--legacy=emotions,mission,pause,story_images,
  story_texts,tutorials`) → nodes):

  | Where | Capped | Uncapped |
  |---|---|---|
  | "The Farl Story": a story image scrolling down with its text back, texts | 60 → 60 | 2,104–2,224 → 2,125–2,292 |
  | "Ending - Part 3": the credits | 60 → 60 | 587–631 → 1,260–1,323 |
  | The Sewers--North West, turning: the mission display (the minimap: the bridge in both) | 60 → 60 | 729–795 → 746–803 |
  | Pass to Zazo at night: four bubbles, one shaking | 60 → 60 | 1,780–1,918 → 1,779–1,902 |

  The credits run twice as fast: the legacy drew all 119 lines from 50 px
  above the screen on, glyph by glyph, every frame; the labels keep their
  glyphs and move. The rest is within the noise.
* **What stays legacy around the nodes.** Under the bubbles: nothing legacy
  (the village scene). Over them and the other UI nodes: the frame's later
  legacy 2D, moved to their layer (a cutscene's dialog is a node already;
  in a labyrinth a battle's or riddle's top layer over the mission display,
  in the stores their menus around the tutorial, in battles the result
  screens and legend under it). Under the mission display: the minimap (3D,
  the bridge) and a battle's 2D. Over everything: the mode's fade (a node)
  and "Paused"/"game pad lost" (nodes); the riddle's fade, the stores'
  dims and the battle's are legacy, inside their modes' drawing.
* **Not covered:** a whispered text (no sequence whispers); "Paused" over a
  cutscene by START (a cutscene ends on START; the case pauses while it
  loads); the mission display sliding back in after a dialog (shots show it
  shown, sliding out and hidden); "game pad lost" with a real pad; the
  Church's tutorials (`HelpText`'s rows stay legacy: phase 4.2; its
  `Tutorial` pages are the node, as in the stores).

### 8.4 Closing phase 3 (done on 2026-11-06)

Removing the legacy overlay paths deletes or changes (line counts as of the
rollout, including doc comments):

| Part | Lines | Still used by |
|---|---|---|
| `Dialog`'s drawing: the legacy branches of `_drawCurrent` (the shown image) 4, `drawInputQuestion` 21, `_drawDialog` 8, `drawMessages` 7, `_drawQuestion` 11; `_drawLines` 20; the `xs`/`ys`/`handX`/`handY` tables and their index constants 8 | 79 | `--legacy=dialog` only (the nodes hold the layout). `drawQuestion` with a title (20) has no caller at all (dead in the port) |
| `DeckPage.drawCardInfo`'s drawing | 23 of 26 | `--legacy=dialog` |
| The fades' legacy branches (`GameMode.draw`, `VillageStoryTimeLine.drawTop`) | 4 | `--legacy=fades`; `Graphics.fadeOldSchool` (11) stays: the stores' confirm dims, the battle's result screens, the riddle's fade |
| Emotions: `Sprite.drawEmotions` 8, `Actor.drawEmotion` 2, the legacy loops of `Village.drawOverlays` and the timeline's `draw` 6 | 16 | `--legacy=emotions` (the legacy village path that also drew them is removed: 6.9) |
| `Mission.show_line`'s legacy branch | 3 | `--legacy=mission` |
| `GameCore.testDraw`'s legacy branches ("Paused", "game pad lost", its menu) | 14 | `--legacy=pause`; `MenuNode.drawAllChildren` stays (every menu) |
| Cutscene images: `drawTop`'s legacy branches 12; `ImageSettings.draw` 3, `drawTextBack` 3 | 18 | `--legacy=story_images` (`ImageSettings.draw` was also called by the legacy village path, removed in 6.9) |
| Texts: `Text.draw`'s drawing 6, `ScrollableTexts.draw`'s 9, `ScrollableText.draw` 13 | 28 | `--legacy=story_texts` |
| `Tutorial.drawTopLayer`'s drawing | 13 | `--legacy=tutorials`; `Row.draw`, `drawIcon`, `drawRows` (26) and `Icon.draw` (2) stay: the Church's `HelpText` (phase 4.2) |
| The flags (`Main.is_legacy` checks: dialog 7, fades 2, emotions 2, mission 1, pause 3, story_images 1, story_texts 2, tutorials 1) and the parity cases' legacy runs | ~19 | `Main.is_legacy` stays for later phases |

Not removable with phase 3: the minimap (`MapRenderer.draw` 32,
`drawBackground` 8, `LabyrinthMap.draw2` 24, `Node.drawInSmallMap` 18, the
inventories' `drawInMap`) is still drawn by the 3D bridge (8.3); the dev
path `--minimap-node` (`MapRenderer.show_map` 17, `MinimapPart` 39,
`Graphics.begin_capture_3d`/`end_capture_3d`/`_capture_triangles` 27) only
redraws its batches.

The Graphics text API after that is used by (calls outside `src/graphics`):
the battle (`drawMultiString` 20, `drawWithShadow` 21, `drawValueWithShadow`
2, `startText`/`finishText` 4 each, `drawMultiCenteredText` 2,
`setTextColorAndApply` 4), the menu pages (`drawString` 62,
`drawMultiString` 7, `startText`/`finishText` 6, `setTextColor` 12,
`setTextColorAndApply` 8, `calcAlignRight`, `getStringWidth` 2,
`drawStringRightWithReg` 2, `drawStringSetSize` 2, `drawSingleCenteredText`),
the stores (`drawString` 27, `drawStringSetSize` 2, `calcAlignRight`,
`setTextColor`), the riddles (`drawString` 4, `drawMultiString` 3,
`startText` 5, `drawMultiCenteredText` 3, `setTextColor` 2), the equipment
pages (`drawStringRightAligned` 4, `setTextColor` 5), the menu's map page
(`LabyrinthMap`: `drawSingleCenteredText` 4, `setTextColor` 3), the world map
(`drawSingleCenteredText` 2; since 4.1 only its `--legacy` drawing, the name
plate's twin calls `startText`/`finishText`), the title (`drawWithShadow`); `MenuNode` (every
menu: `drawString`), the Church's `HelpText` (`Row`). With the legacy paths
gone, villages, labyrinths and cutscenes call none of it (the twins read the
text state: `startText`, `finishText`, `setFontSize`, `setTextColor`,
`text_color`, `text_alpha`, `font_bold`, which the nodes' look depends on
while the rest of the frame is legacy).

What keeps the exit ("villages, dungeons and cutscenes have no `draw(g)` left
except battles and riddles") from being met after the rollout:

* The modes still have `draw(g)`: the Organizer drives every mode through
  it, and the twins run there (where the legacy state changes happen: the
  shake, the mission's slide and clock, the fades, the pad-lost input). Only
  a `Game` autoload (9.3) and `_process` (phase 5) remove it.
* The `--legacy=` paths of phases 1–3 draw through `Graphics` until each
  phase closes (6.9, 7.9, the table above).
* The minimap is drawn by the legacy `MapRenderer` through the 3D bridge
  (8.3): a node in the floor's world changes the battles drawn after it by
  1/255; with the battles out of the bridge (phase 4.4) a minimap node (one
  that builds its disks, compass, cells and arrow from the state, with the
  legacy CPU vertex math for parity) can be checked again.
* Labyrinths: `init_scene_3d`'s GL state, which battles read, the 3D bridge
  for a battle's drawing, the frame's structure (`GLBackend.begin_frame`,
  chunks) until phase 5 (8.2).
* The world map, the airship, the stores' menus and the menu pages are other
  modes (4.1, 4.2); they draw the shared dialog, fade, card info and
  tutorials through the same twins.

*As built (2026-11-06):* everything in the table is removed. `Dialog.draw`'s
branch to the private overload that drew the lines (`_drawLines`) had no
caller (every call passes nothing or a bool), nor had the public
`drawQuestion`: both are gone with the layout tables. `GameCore` keeps
`--legacy=menu_list` for the game pad lost menu (phase 4.2). The minimap
stays the 3D bridge's (above); the stores', riddles' and battles' overlays
are phase 4's.

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
  edges) needs the time-base decision. *Found in 4.1:* only for step C;
  views that mirror its position (step B) do not.

**Results (phase 4.1, `docs/phase4_1_prompt.md`; conventions in
docs/ARCHITECTURE.md section 13).** Steps A and B for the world map (West,
East, North) and the airship (land1, land2); the legacy objects keep the
state, the input and the timing.

* **Baseline** (on 8e1bc65c): `tools/check.sh` 0 failed; goldens of the 382
  cases and `bridge_test` (`g41base`, 7,225 shots, 2,091 error lines),
  identical to `r3gold1` shot for shot and log for log.
* **Facts** (deliverable 1), where they add to or differ from the prompt
  and this section:
  * Draw order (`Landscape.draw`, `AirLandscape.draw`) as listed, but the
    name plate's image (`Pieces/1.png`) is drawn every frame, also while
    walking, on a crossroad and on the airship away from a node; only the
    name depends on them. Where the order shows: the top layer over the
    player (West's `top/0.png` over Kin at Alares and Pass to Zazo,
    `top/1.png` at Forest of Reil--Deep Forest-mark0; East's `top/0.png` at
    Dorma's Forest) and over the dots and markers under it (roads 2 and 3
    and the Forest of Reil's marker on West); the player over its node's
    marker; the night layer over the whole map, top layer included, under
    the name plate; the plate over the airship near the top edge (the
    airship's y < 155 within x 361–662); the dialog over the plate; the fade
    over everything. No two roads have overlapping dots (checked on all
    three maps), so the order of `visitedRoads` (insertion order in the
    port, `HashMap` order in the Java) never shows.
  * State changes: `setColor(1)`, `setFontSize(30)`, every `drawImage`'s
    bind, `drawTop`'s `setAlphaFunc(0)` in every frame (the next frame and
    the next mode inherit it; the first frame after another mode keeps that
    mode's blending and alpha test), the name's `startText(1, 0)` and
    `finishText` (text colour black, alpha 1, the current colour back to
    white), `checkMenu`'s thumbnail (the frame before, with the scene).
  * Night: only `land::continue::forest_of_reil--deep_forest-mark0`
    (Forest Path's door 10) makes a world map night: West. Nothing reaches
    East or North at night; started there (`--start=land::continue::
    parasne`, dev) they draw no night layer and print an error every frame
    (`standardOvernight.png` does not exist). No landscape has a night
    background: night is the overlay only.
  * Data: the parser's `road<address>` statuses are never written (every
    road starts open); `road<map>-<address>` come from story triggers
    (`load trigger="road0-8"`), doors (`Door`, `IfDoor`) and saves: "Start"
    closes 13 roads, "Slot 1" none (its `road0-17 0` names a road that is
    commented out of `world0.map`). A closed road that the save lists as
    visited keeps its dots (`Landscape.init` adds `Visited`'s roads without
    the closed check; the Java too) and is not walked. A visited road
    visits both its nodes, so markers show for nodes the save's
    `visitedNodes` does not list ("Slot 1" lists 4 of West's 20, all 20
    show). East's road 12 joins two nodes no other road reaches
    (Fire Cavern--Inferno-mark2, Silent Ruin--The Great Ruins-mark0),
    reached only by leaving those labyrinths. The index: 37 names, none on
    two maps.
  * Airship: `land1.map` 28 nodes (zones west 14, east 12, north 2),
    `land2.map` 29 (Empyrian Temple--Hall of Wind, without the `land`
    prefix: landing there enters the labyrinth, not a world map node).
    "Slot 1" has the status `airship` 1, "Start" 0; nothing in the cases
    reaches 2 (`--status=airship:2`). The wrap: past the left or top edge the
    airship jumps to x 1079 or y 823; on the right it is out of sight until
    x 1042, at the bottom it shows at once (drawn at y − 50, 55 high); past
    the right edge it is out of sight from x 1042 until it wraps to x 0;
    past the bottom only from y 818 to 823. No crossroad nodes on the
    airship maps. SQUARE on a world map node that the airship map lacks (the
    seven crossroads, Inferno mark2, Silent Ruin) raises script errors and
    leaves the airship at (0, 0) (the Java: a NullPointerException;
    `tickets/triage.md` W1). Airship1..16 needed no SpriteFrames (the view
    adds the images it is shown).
  * The bridge as the prompt says; the airship's reference cycle kept every
    airship mode alive (fixed, below).
* **Coverage:** the probe over every case showed the world map in 36 shots
  of 12 cases (West and East by day, all of West visited but in two story
  exits), the airship in none (drawn only in `story_crystal_of_levitation`,
  between shots), no night, no North, no closed road but two hidden ones.
  Ten new cases (67 shots): `world_west`, `world_east`, `world_north` (each
  road direction, the plate on villages and labyrinths, none on crossroads
  or while walking, the player under the top layer), `world_first_visit`
  ("Start": nodes and roads appearing, Start's closed road0-3 not drawn and
  not walked), `world_closed_visited` (`--status=road0-5:0`: dots kept, not
  walked), `world_night`, `world_east_night` (dev only), `airship_land1`
  (each direction, every edge's wrap, the plate over a node, under the
  plate), `airship_land1_menu` (the menu's thumbnail, the map page,
  landing with its fade), `airship_land2`. AutoPlay's `pos` prints the
  world map's and the airship's position (no existing case printed `pos`
  there). Goldens: `g41gold` (all 392 cases and `bridge_test`, 7,292
  shots; its old cases identical to `g41base`), `g41gold2` (the new cases
  again: identical).
* **Built** (ARCHITECTURE section 13): `scenes/world_map/` (the template,
  `WorldMapRoad` (Path2D), `WorldMapNode`, `AirshipNode` (Marker2D), five
  map scenes, five stitched backgrounds), `resources/world_map/place_index.tres`,
  `scenes/ui/NamePlate`, the converter `tools/import/world_to_scene.gd`
  (the village converter's stitching moved to `tools/import/tile_art.gd`
  and shared: the village converter writes the same files as before), the
  data check `tools/import/verify_world_map.gd`, the flags
  `--legacy=world_map` and `--legacy=airship`; `--bridge-test` implies
  `--legacy=world_map`. Port fix: `AirLandscapeLoader` kept its map loader,
  which refers back to it (Java's inner class), and the cycle kept every
  airship mode alive; now each map scene logs `WorldMapScene: freed` with
  its mode.
* **Data check:** `verify_world_map.gd` with "Slot 1" and "Start": 196
  builds (the index; each world map from each of its nodes by day and from
  its first at night; each airship map from each node), all pass; a road
  point moved by 1 px fails with the field path.
* **Parity** (tolerance 0): golden vs. after step A, all cases: 7,292 of
  7,292 shots, all 393 logs and every case's error lines identical; legacy
  (`--legacy=world_map,airship`) vs. scene on the 21 cases that show the
  world map or the airship: 301 of 301 shots, logs identical (without
  `world=`); golden vs. after step B, all cases: 7,292 of 7,292, logs
  identical with `--ignore-world` (those 21 cases log `world=<map>`), the
  same error lines; golden vs. the legacy run: 301 of 301. The bridge test
  passes ("BridgeTest: freed"). West went first (its cases identical before
  the others ran); no difference had to be explained.
* **Frame rate** (normal runs: no `--seed`, windowed, one at a time, the
  shipped saves; AutoPlay's `fps=` every 0.5 s, the first second dropped;
  legacy → scene, median and range):

  | Where | Capped | Uncapped |
  |---|---|---|
  | West, walking Home of Celis to Main Cross and back | 60 (58–60) → 60 | 424 (390–432) → 1,926 (1,879–1,943) |
  | The airship on land1, flying in each direction | 60 → 60 | 1,713 (1,568–1,741) → 2,280 (2,257–2,295) |

  The legacy world map drew ~120 road dots and 20 markers as quads every
  frame; the nodes keep them.
* **Still legacy:** the state, the input and the timing (step C: walking
  along a `Path2D`, the airship as per-second rates, decision 6); the menu
  and its map page (4.2); `DoubleBackground` is still built per map for the
  state the twins read (the tiles' names, the top layer, `nightTop`) and
  loads the tile textures the scene does not draw.
* **Found on the way:** running extra windowed games beside an 8-job
  recording exhausted the 16 GB of memory: one run crashed in AutoPlay's
  `get_image`, three failed to decode floor textures (re-recorded:
  identical; risks, 12). The village converter does not reproduce three
  scenes the editor saved in 4b74ade3 (`Dellna - 1`, `Dellna - 2`, `Zazo at
  Night - 0`: `vil_to_scene.sh --all` rewrites them; kept as committed).
  The debug console's `roads` reads the road addresses from the scenes now
  (the `.map` text with `--legacy=world_map`).

**Closing phase 4.1 (done on 2026-11-06).** Removing the legacy world map and
airship paths deletes or changes (line counts with doc comments):

| Part | Lines | Still used by |
|---|---|---|
| `LandscapeLoader.LandscapeLoaderMapLoader` (inner class) | 47 | `--legacy=world_map`; `verify_world_map.gd` (its legacy builds) |
| `LandscapeLoader.PlaceMapLoader` | 28 | `--legacy=world_map` (`createMap`); `verify_world_map.gd` |
| `AirLandscapeLoader.AirLandscapeLoaderMapLoader` | 34 | `--legacy=airship`; `verify_world_map.gd` |
| `init`'s parse branches, `world_scene_for`'s and `airship_scene_for`'s flag checks, `place_index`'s | ~15 | — (a map without a scene would have nothing to load) |
| `Landscape.draw`'s legacy branch | 14 | `--legacy=world_map`, `--bridge-test` |
| `AirLandscape.draw`'s legacy branch | 7 | `--legacy=airship` |
| `Road.drawRoad` 4, `MoveDot.draw` 2, `LandscapeNode.draw` 3, `LandPlayer.draw` 7 | 16 | the legacy branches only; `MoveDot` (its image) and `LandscapeNode.im` stay while the twins bind the images (`skip_image`); `Sprite.draw`, `drawSprite`, `drawAtPosition` stay for `--legacy=villages` (6.9) |
| The flags (`Main.is_legacy`: `world_map` 3, `airship` 1, `--bridge-test`'s implication 2) and the cases' legacy runs | ~6 | `Main.is_legacy` stays for later phases |
| The five `.map` files (decision 5) | 488 (11.9 KB) | the converter (`world_to_scene.gd`, 380 lines), `verify_world_map.gd` (291), the legacy paths, the console's `roads` with `--legacy=world_map` |
| `DoubleBackground`'s landscape path: `setLandscapeImages` 8 (+ `doit` 29, `cutImage` 14, `generateNames` 14, `doTopLayer` 19, shared with villages) | 8 | the scene path builds a `DoubleBackground` per map for the state the twins read (the tiles for their binds, the top layer, `nightTop`); stays until the twins read the scene or step C. `drawBottom` 5, `drawBottomLayer` 22, `drawTop` 42, `drawSystem` 4: then only `--legacy=villages` (6.9) |

What keeps the phase from closing: decision 5 (the `.map` files); the
bridge test, which needs a legacy world map under its scene (moving it to a
mode of its own, or BridgeTest inside the map's scene, is a choice); the
twins' binds and the `DoubleBackground` state, which matter while legacy 2D
follows the map in the frame (the name plate's twin binds last, so only the
GL state the plate leaves is observable); step C for walking and flying.

*As built (2026-11-06):* everything in the table is removed except
`DoubleBackground`'s landscape path, which the scene path builds for the
twins: decision 5 (the five `.map` files), the parse, the legacy drawing
(with `DoubleBackground.drawBottom`, `drawBottomLayer`, `drawTop`,
`drawSystem` and `Sprite.draw`, `drawSprite`, `drawAtPosition`, whose last
callers these were), `world_to_scene.gd` (+ `.sh`), `tile_art.gd`,
`verify_world_map.gd` and the flags. A map without a scene, or a missing
index, is an error (the airship still loads its images, as a missing file
left it). The bridge test is deleted (decided on 2026-11-06): every
village, labyrinth, cutscene and world map case runs through the bridge it
checked, and a scene that is not freed shows as an exit leak report
(ARCHITECTURE section 8).

**Parity of the closings** (phase 1's decision 5, P, phase 2 with P2's
dungeon part, phase 3, phase 4.1; 2026-11-06). Goldens `cbase` on aab714c9
(409 cases, 7,674 shots; recorded from a copy of the project) are identical
to `leakfinal` (the leak cleanup's set: shots, logs, error and leak lines),
so the prototypes' commit changed nothing in a default run. After the
closings, `cafter2` vs. `cbase`: all 7,674 shots identical at tolerance 0,
every AutoPlay log identical, and per case the same exit code, shot count
and counts of script errors, engine errors, exit leak lines (only the
`effects_*` cases, as before) and device events. A first recording
(`cafter`) caught a bug of the change: `VillageScene.path_for` still
expected the `res://` path that `resolve` used to return, and no village
loaded; fixed before `cafter2` (a smoke set `cfix`, 11 cases, first). There
is no `bridge_test` case any more. Beyond parity: `tools/check.sh` 494
scripts, 0 failed; the remake tool's inventory of Alares and Zazo is
byte-identical; an exported debug build runs a village, a floor, the world
map and a cutscene (the village's 916 "image not found" lines are Hilda's,
triage C1, and the same in an export of aab714c9). The frame rate was not
measured: only legacy paths and dev tools were removed, and normal play runs
the same code.

### 9.2 Title, game over, mini-games, stores, menu

* **Title, game over:** trivial Control scenes with Tweens. *Done through
  step B in the pilot (below): UI nodes that mirror the legacy state; the
  Tweens (and a Timer for the game over's 22 s) are step C.*
* **Mini-games** (12 files) are self-contained. Make one Control scene per
  puzzle kind; tiles come from `res/MiniGames/TileGames/*`. They are started
  from dungeon `riddle` objects, so they plug into the dungeon scene as a
  modal UI child, not as an Organizer mode.
* **Stores** (Building → AbstractStore → CardStore / WeaponStore / Inn;
  Church): one `Store.tscn` template. *Found in the pilot:* while a store
  still draws legacy parts, its converted parts are UI nodes in the
  frame's order (ARCHITECTURE section 14), so a store is several nodes;
  one scene per store fits when nothing of it is legacy any more.
  * The parts: background, keeper portrait, the shared Dialog, a menu
    column, confirm boxes.
  * The input state machines stay as script. `stores.bank` and
    `cardStores.bank` stay data (or become `.tres` later).
* **Menu** (21 files, 3,024 lines): one Control scene per page (start,
  status, equip, deck, map, bestiary, help, tutorial) on a shared frame.
  * `MenuNode` lists → a small `MenuList` control that keeps the legacy
    cursor and key-repeat behaviour. *Pilot:* `scenes/ui/MenuList` shows a
    plain list (step B); `MenuNode` keeps the cursor and `GameAction` the key
    repeat until step C; the variants are listed below.
  * The tutorial and help files (`.tut`/`.help`, word colour maps) → BBCode
    for `RichTextLabel`, with an offline converter.
  * The automap (`LabyrinthMap.draw`) → a Control drawing from
    `LabyrinthMap` data.
  * Fix `HelpPage`'s volume options on the way: the names it compares never
    match.

**Results of the pilot (phase 4.2, `docs/phase4_2_prompt.md`; conventions in
docs/ARCHITECTURE.md section 14).** Step B for the title (`TitleScreen`),
the game over screen (`GameOver`) and the menu list they draw (`MenuNode`
as `MenuList`); no store, menu page or mini-game yet (the list for their
rollout follows). The legacy objects keep the state, the input and the
timing.

* **Baseline** (on 56abbb39): `tools/check.sh` 0 failed; goldens of the 392
  cases and `bridge_test` (`g42base`, 7,292 shots), identical to `g41gold`
  shot for shot and log for log (with `--ignore-world`); the error lines
  differ only where a game pad or audio device event hit a run (`WASAPI`,
  `HIDAPI` lines in 17 logs, and the exit leak counts of the runs whose
  audio failed to start).
* **Facts** (deliverable 1), where they add to or differ from the prompt:
  * Order. `TitleScreen.draw`: `setColor(1)`, `setFontSize(24)`, the
    background (`loggasten.png`, 867 x 650 at (78, 59)); unless the mode
    fades in, the logo (`loggatext.png`, the same rectangle, tinted
    `(1, 1, 1, index)` while index < .9); once index > .9 the active list
    (`drawAllChildren`), then the difficulty's description
    (`drawWithShadow` at (450, 728), size 20) or the Continue list's dates
    (x 620, size 20); then the mode fade. The title's fade-in speed is 1:
    its first two frames draw the background alone at fade value 1, the
    logo starts in the third; it takes 180 updates (3 s: its alpha goes
    from .005 to .895, then the colour stays 1); CROSS sets index 1. The
    lists: the root at (450, 600), the difficulty list at (450, 570), the
    Continue list at (450, 750 − 50n): all over the picture (which ends at
    y 709), the hand 35 px left of them; the description (baseline 728,
    size 20) lies below it, over black; the dates
    over the picture; nothing overlaps the description or the dates. So the
    order shows: the logo over the background, the lists and dates over
    both, the fade over all. Around the frame: the title is not pausable
    (START does nothing); a lost game pad draws its overlay and menu over
    it (Transition). `GameOver.draw`: `setColor(1)`, `setFontSize(24)`, the
    image (1024 x 768 at 0, 0), the fade (fade-in speed .01: 100 frames);
    "Paused" over it (the game over is pausable; its timer runs on).
  * State changes. Besides the binds and the font sizes: `drawTitle` leaves
    `(1, 1, 1, index)` as the current colour while the logo fades (the
    mode fade at 1 draws nothing and does not set it; the next frame's
    `setColor(1)` resets it), `drawString` sets `color` (1) after every line,
    `drawWithShadow` leaves the text colour white, the dates keep the text
    colour the list left (white: all title choices are enabled). The
    cursor fix-up never fires on the title (its lists never shrink).
    `place_all_children` and `place_hand` (phase 3) keep all of the plain
    list's state changes; they assert that no child is active and that
    there is no bounding box.
  * Menus. Root: Start, Continue. Start: Easy, Medium, Original, the cursor
    on Medium, the list keeping its cursor when left with CIRCLE and
    entered again; Continue: the autosave (when there is one) and the three
    slots, the list 50 px higher with the autosave; CIRCLE back to the root.
    The title uses only plain lists (enable colour white, no disabled
    child, no "character" name, no bounding box, prices, numbers or
    equipment; the hand never dimmed). The stores' and the menu's variants
    are listed below.
  * The game over's image per party: `Start` Kin, `Start demon1` Kin and
    Celis, `Start demon2` and `Start mt cesadur class3 level3` with Borealis,
    `Slot 1` and `Start demon3` Kin, Celis and Zalzi, `Start Menthu1`,
    `Start d3` (and the old `Slot 2`, `Slot 3`) all four: the five images of
    `res/Title`. A seeded run reaches it by a lost battle (`boss`) or by
    `--start="Game Over Screen"` with the save of the party (no dev command
    needed).
  * The credits do not leave the bold font set: no line of "Ending - Part
    3" is bold (`bold=1`), so the title after the ending is plain (8.3
    said the credits leave the bold font on: only a bold line would).
  * Where the nodes live: UI nodes in the frame's order, not the mode's
    scene under `World` (ARCHITECTURE section 14 has the reasons). The
    prompt's premise that the stores and the menu pages draw 3D cards as
    SubViewport chunks is wrong: their cards are 2D images
    (`AbstractCard.drawCard`); the stores, the menu pages and the riddles
    draw nothing in 3D (a riddle's frame is the labyrinth's).
* **Coverage.** The probe (prints in the title's and the game over's draws,
  `MenuNode.draw`, the menu pages, the stores and the riddles) over every
  case: the title in 5 shots of 4 old cases (`title_start`: the logo at
  index .74 and the root menu; `dungeon_save_load`'s root menu; the Celis
  memories `story_ana_reaction` (the root menu) and
  `story_someones_comming` (the difficulty list with Medium's
  description)), the game over in 3 shots of `boss` (fading in at .67, the
  image of Kin, Celis and Zalzi); the menu's Save list showed the dates
  ("Empty", `draw_dates_under`, not converted). No shot of the background
  alone, the logo at other values, the cursor moved, the other difficulty
  levels, the Continue list, a new game's or a load's fade-out, another
  party, "Paused" over the game over or its timeout. Nine
  new cases (75 shots): `title_intro` (the first two frames, the logo at
  seven values, the root's cursor and wraps, START, each difficulty with its
  description, CIRCLE and back), `title_new_game` (CROSS skipping the logo,
  Easy, the fade-out, the story), `title_continue` ("Empty" slots, cursor
  and wraps, CIRCLE, loading Slot 1 through the fade-out),
  `title_continue_autosave` (the autosave and a saved slot with their
  dates: the dev-only game-clock dates of seeded runs,
  `SaveSlots.note_saved`), `game_over` (Kin: the fade-in, "Paused", CROSS,
  the fade-out to the title), `game_over_timeout` (Kin and Celis: 22 s),
  `game_over_borealis`, `game_over_zalzi`, `game_over_all`. Goldens:
  `g42gold` (401 cases and `bridge_test`, 7,361 shots; its old cases
  identical to `g42base`), `g42gold2` (the new cases again: 75 of 75
  identical, logs and error lines too). Not covered: a title in the bold
  font (no route found that leaves it set before the title), "game pad
  lost" over the title (the `pad_lost` case covers the overlay's menu in a
  village).
* **Built** (ARCHITECTURE section 14): `scenes/ui/Title`, `MenuList`,
  `ShadowText`, `SlotDates`, `GameOverScreen`; theme roles `MenuChoice24`,
  `MenuChoice20`, `DifficultyInfo`, `SaveSlotDate`; twins
  `TitleScreen._show_background`, `_show_logo`, `_show_difficulty_info`,
  `GameOver._show_image`, `MenuNode.show_all_children`,
  `SaveSlots.show_dates_beside`, `Graphics.place_with_shadow`; flags
  `--legacy=title`, `game_over`, `menu_list`. The game pad lost overlay's
  menu moved onto `MenuList` (`PadLost` lost its own list and hand); its
  parity held.
* **Parity** (tolerance 0 everywhere; the final code, 401 cases and
  `bridge_test`, 7,361 shots; the node run is `g42node`):
  * golden (`g42gold`) vs. nodes, every case: 7,361 of 7,361 shots
    identical, all 402 logs identical, the same error lines in every log
    but three `WASAPI` lines (an audio device event during the golden's
    runs; 3,226 vs. 3,223 lines);
  * `--legacy=title,game_over,menu_list` vs. nodes on the cases that show
    the title, the game over or the game pad lost menu (by the probe: the
    `title_*` and `game_over*` cases, `dungeon_save_load`,
    `story_ana_reaction`, `story_someones_comming`, `newgame_to_forest`,
    `story_long`, `boss`, `pad_lost`): 250 of 250 shots identical, logs
    identical; each flag alone vs. nodes: `title` 121 of 121 (12 cases),
    `game_over` 140 of 140 (6), `menu_list` 126 of 126 (13), logs and error
    lines identical;
  * every flag on (`--legacy=title,game_over,menu_list`, every case) vs. the
    golden: 7,361 of 7,361, all logs identical (the legacy paths and the
    frame without nodes are unchanged);
  * the bridge test passes (identical, "BridgeTest: freed after 748
    frames" in its log).
  * No tolerance was needed and no difference had to be explained: the
    nodes draw the same textures with `draw_string` and textured rects in
    the legacy order, with GLBackend's canvas materials; the first node
    run of the title, game over and game pad lost cases was already
    identical (217 of 217 shots), and a run with temporary prints showed
    the nodes drew those frames. The game pad lost menu kept its parity on
    `MenuList`.
* **Frame rate** (normal runs: no `--seed`, windowed, one at a time, the
  shipped saves (`APPDATA` a scratch folder); AutoPlay's `fps=` every 0.5 s
  for 10 s, the first second dropped; legacy (`--legacy=title,menu_list`
  or `--legacy=game_over`) → nodes, median and range):

  | Where | Capped | Uncapped |
  |---|---|---|
  | The title's root menu | 60 → 60 | 2,346 (2,323–2,359) → 2,354 (2,335–2,361) |
  | The difficulty list with its description | 60 → 60 | 2,336 (2,320–2,350) → 2,334 (2,327–2,337) |
  | The game over screen ("Start": Kin) | 60 → 60 | 2,427 (2,415–2,449) → 2,455 (2,438–2,460) |

  The same within the noise: the legacy drew one or two images and a few
  lines per frame.
* **Still legacy** in the two modes: the state, the input and the timing
  (step C: a Tween for the logo and the fades, a Timer for the 22 s, the
  input through InputMap; decisions 3 and 6, phase 4.3's wrapper); the
  `draw(g)` methods themselves (the twins run there); the mode fade and
  "Paused" are phase 3's nodes. Nothing of their pictures is drawn through
  `Graphics` any more (with the flags off).

**The rollout of 4.2 (the menu done; the stores and the mini-games
prepared).** The mini-games, the stores and the menu, as they drew at the
pilot ("node" = already a phase 3 or 4.2 node; the menu's results follow
this list). None of them draws in 3D: the cards of the
stores and the menu are 2D images (`AbstractCard.drawCard`,
`Deck.drawDeck`), so nothing waits for phase 4.4's cards; a riddle's frame
is the labyrinth's (3D walls and weather, the riddle's 2D after them).

* **Mini-games** (*done through step B: results below*; `src/miniGames`, 12 files, 1,253 lines; `RiddleGame` and
  `HateRiddle`, `CesadurRiddle`, `GriveraRiddle`, `AegisRiddle`, `Puzzle`,
  `RubicsPuzzle`, `RubicsPuzzle19`; `RotatePuzzle` is unused). A dungeon
  `riddle` object (Cross in front of it) makes the riddle the labyrinth's
  `labDrawable` (`Labyrinth.enterRiddle`: `push` hides the minimap and the
  mission); it ends when its fade-out reaches 0 (`exitRiddle`).
  * Draws: its `draw` (the 3D slot) is empty; `drawTopLayer` comes after
    the labyrinth's dialog and before its `topLayer` items and its fade
    (`Labyrinth.draw`): the dim (`fadeOldSchool(1 − fade × image alpha)`,
    the fade image of the current fade mode), `setColor(1, 1, 1, fade)`,
    the riddle's image (`RiddleLoader`: name, x, y, scale); the puzzles'
    tiles (`Tile.draw`) and their markers (`NxNsingle.png`, `horizontal`/
    `vertical.png`); Aegis's and Grivera's centred texts (size 28, black;
    Aegis at alpha 1, Grivera at the riddle's fade); Hate's digits and code
    (size 36) and its hand (`MenuHand`); Cesadur's letters and rows
    (`drawMultiString` at the labyrinth's fade value, the size left by
    earlier drawing), its two hands (one dimmed) and its help (button icons,
    four labels).
  * State changes in the draws: none of the game's (the fade, the hands'
    positions and dims step in `update`); the GL and text state left (the
    colour `(1, 1, 1, fade)`, sizes 28/36, black text) carries into the
    labyrinth's next drawing. The fade is a port bug (1.1, Appendix).
  * Shared: `MenuHand` (dimmed too), `AbstractPage.BUTTON_ICONS`, the
    `fadeOldSchool` dim (the stores' confirm dim, a Fade node's quad).
  * Coverage (probe): 36 shots in the 9 `dungeon_riddle_*` cases, every kind
    in use. Cases still needed: each kind fading in and out (not only
    shown), a puzzle solved (the door's status), Cesadur's dimmed hand and
    its letter pool, Hate's code entered.
  * *Prepared by the menu and the stores (phase 4.2's rollout, parts 1 and
    2; ARCHITECTURE section 14).* Built, for a riddle to show with its own
    state at its call sites (`RiddleGame.drawTopLayer` and the kinds'
    overrides, which run after the labyrinth's dialog: UI nodes in the
    frame's order, before the labyrinth's fade on Transition):
    * The dim: `g.fadeOldSchool(1 − fos)` → `g.show_fade(1 − fos,
      Graphics.UI_LAYER)` (a Fade node on UI: the fade mode's colour or
      image at 1 − the value, as the stores' confirm dims; the riddle's
      nodes come after it). Its own flag, as the stores' `dim`.
    * The riddle's image (`RiddleLoader`'s, at its scale, in `(1, 1, 1,
      fade)`) and Aegis's and Grivera's centred lines (size 28):
      `AbstractStore.show_box(g, image, at, lines)` takes one placed image
      and lines with an alignment (MenuBox: its `Piece` is drawn at
      `place_image`'s rect, scaled too; a centred line is BaselineLabel's
      `HORIZONTAL_ALIGNMENT_CENTER`, as `calcAlignCenter`); a scale needs a
      `place_image(image, x, y, scale)` call instead of show_box's unscaled
      one (a parameter to add). Hate's digits (size 36, at the riddle's
      fade through `startText(fade, -1)`) and code (centred), Cesadur's
      letters and rows (`drawMultiString` at the labyrinth's fade, the size
      earlier drawing left): `AbstractPage.show_lines` (MenuText; roles by
      size through `MenuText.role`: `Text28`, `Text36`).
    * The hands: `MenuHand.place_hand_image(g)` (the dim of a dimmed hand,
      the bind; Cesadur's two hands, one dimmed) gives images for an
      `ImageList`, shown by `AbstractPage.show_pieces(g, images)`
      (MenuBackground without its back) or a small node of the riddle's.
    * Cesadur's help (button icons and four labels): `AbstractPage.draw_help(g,
      drawHelp)` (HelpLineCapture records the icons and labels: HelpLine).
    * Left for them: the tiles and the markers (`Tile.draw`,
      `NxNsingle.png`, `horizontal`/`vertical.png`: images at computed
      places, `ImageList` through `place_image`), the riddles' texts and
      their alphas (above), Cesadur's letter pool and rows, the riddle's
      image and fade; the fade's port bug first (Appendix), as its own change
      with new goldens; the cases above. One session.
* **Stores** (*done through step B: results below*; `src/store`, 7 files, 2,082 lines; `Building`, `AbstractStore`,
  `CardStore`, `WeaponStore`, `Inn`, `Church`; `Door` draws nothing).
  * Draws: `Building.draw` sets `setColor(1)`, size 22, `setAlphaFunc(.02)`,
    black text; `drawStandard`: the background (0, 0), the keeper's dialog
    (node), the keeper (`drawCenteredImage`, y 205; the Church 105), the menu
    pieces (`AbstractPage.drawMenuBackgroundStatic` with the store's mask);
    then the store's `draw3D`; the fade (node). Per store, in its
    sub-states: the root list (800, 147) and the title (800, 54) in all;
    the Weapon Store's equipment lists (price + `down`, bounding boxes on
    the sell lists; two lists and two hands), the character's status and
    item (`EquipPage.drawStatus`, `StatusPage.drawEquip`), "Equipped/Total/
    Gold", the confirm boxes (buy; sell with Keep/Sell); the Card Store's
    deck (`Deck.drawDeck`: 2 x 7 cards, the current one larger, the
    unaffordable gray), the card info (node), its scroll bar, the merge page
    (two pieces, the counts in bold 26/28 with shadows, the merge preview at
    size 40); the Inn's price list (price), its confirm box, the prize
    message and card (nodes), the trade list (bounding box); the Church's
    save list with dates (`SaveSlots.draw_dates_under`) and its bless page
    (pieces, costs, `LevelUpBar.drawStatic` per character, its hands, the
    legacy `HelpText` rows: `Row.drawRows`, the bless list at size 26,
    "Total cost", gold/steps/time, the help line); the tutorials (node).
    The confirm boxes: `fadeOldSchool(.5)` (a dim like "Paused"'s),
    `setColor(1)`, a piece (14 or 3), the texts, the Yes/No list.
  * State changes in the draws: the Church's `totalCost` (summed in its
    draw, read by Cross on "Done") and its hands' positions; the cursor
    fix-up; the scroll bars' lazy init and `loadIdentity`; `drawDeck` turns
    the bold font off and leaves black text; `Building.draw` resets the
    colour, size, alpha test and text colour every frame, not the blending
    or the bold font.
  * Shared: the menu pieces with the menu pages; the menu list variants
    (plain, price, price + down, bounding box); `MenuScrollBar`; the
    confirm box and dim (also `WeaponStore.drawConfirmSellDialog`; the
    menu's saving box has no dim); the keeper's dialog, the card info, the
    tutorials and the Inn's prize message (nodes); `Deck.drawDeck` with the
    deck page; `EquipPage`/`StatusPage`'s static helpers with the menu;
    `SaveSlots`' dates with the title and the menu; `HelpText`/`Row` with
    the tutorials (whose rows are nodes already: `Row.place_rows`);
    `BUTTON_ICONS`.
  * Coverage (probe): 50 shots in 6 cases (`stores`, `dialog_card_store`,
    `dialog_store_fade`, `tutorial_store`, the Zazo night Inns), but every
    list a shot shows is a store's root menu (the Inn's with its prices):
    no shot of a buy or sell list, the equipment comparison, a confirm box,
    the card store's deck, scroll bar or merge page, the Inn's trade list or
    prize, the Church's save list or bless page. Cases needed: one per
    store and sub-state (the Weapon Store's buy list scrolled, a sell list
    with its bounding box, both confirms; the Card Store's buy page scrolled
    past two lines, a merge with and without the preview, its confirms; the
    Inn's rest confirm, its prize and trade list; the Church's save list
    after a save (the game-clock dates), its bless page moved, its
    tutorials).
  * *Prepared by the menu (phase 4.2's rollout, part 1; ARCHITECTURE
    section 14, "The menu", has the nodes).* Built and shown by the menu,
    for the stores to show with their own state at their call sites (the
    shared helpers stay legacy until then; each call site switches on the
    flag of its kind of part):
    * `MenuBackground.show_background(back, pieces, mat)`: `back` the
      store's background (`Graphics.place_image(background, 0, 0)`) in one
      node, then, after the keeper's dialog (a node: its own slot), a second
      `MenuBackground` with no back and the keeper (`place_centered_image`,
      y 205 or 105) followed by the pieces of
      `AbstractPage.place_menu_background_static(g, store, menusUsed)` (the
      mask); `menu_frame`.
    * `MenuTitle` (the title at 800, 54: `AbstractPage.draw_title`),
      `MenuInfo.show_info(lines, …)` with the store's three lines
      (`WeaponStore.drawInfo`, `CardStore.drawInfo`, the Inn's
      `StartPage.drawInfo`: call `StartPage.draw_info`, the Church's copy),
      `HelpLine` (`AbstractPage.draw_help(g, drawHelp)`: the Church);
      `menu_frame`.
    * `MenuList` through `MenuNode.show_children_freely` (`AbstractPage.draw_list`):
      the price variant (`withPrice`, `down`: the Weapon Store's lists, the
      Inn's), the bounding boxes of the sell lists and the Inn's trade list
      (their `PageScrollBar`), the confirm boxes' Yes/No lists, the two lists
      and two hands of the Weapon Store (two nodes); the price variant is
      built from the legacy code but no case shows it yet; `menu_list`.
    * `EquipStatus` and `EquipItem` (`EquipPage.show_status`, `show_equip`)
      in the Weapon Store; `status`.
    * `DeckView` (`Deck.show_deck(g, gold, true, current, null)` for the
      buy page, `show_deck(g, current, map)` for the merge page: the
      numbers over their shadows in bold 26 and 28, the grey cards; both
      branches are built in `place_deck` and shown by no case yet),
      `PageScrollBar` (`MenuScrollBar.show_bar`), `CardView` for the merge
      preview (`AbstractCard.place_at` at size 1.0, the next level's balls);
      `deck`.
    * `MenuBox.show_box(piece, lines, mat)` for the confirm boxes (piece 14
      at 400, 300 or 3 at 400, 315; the texts at 430, 360 and the price
      right-aligned to 630: a line's sixth element); `SlotDates`
      (`SaveSlots.show_dates_under`) for the Church's save list; `menu_text`.
  * Left for the stores: the confirm dim (`fadeOldSchool(.5)` → a
    `Graphics.show_fade(.5)`-like Fade node on UI, before the box: a Fade
    node is on Transition today, and a UI node after it would be drawn
    under it, so the dim needs a UI Fade or the box and list on Transition);
    the card store's merge page (pieces 13 and 12, its counts in bold 26/28
    with shadows: `ShadowText`, "x 5 merges to" at size 40: `MenuText`);
    the Church's bless page (`HelpText`'s rows: `Row.place_rows` as the
    tutorials' (phase 3), `LevelUpBar.drawStatic` per character: a new node,
    the costs at sizes 26 and 30, its blue and green hands drawn twice
    (`drawHandWithColor` at white, then the colour at .3: two images), the
    bless list at size 26: `MenuChoice26` or `Text26`, `totalCost` summed in
    the draw: keep it in the twin); the Inn's prize message and card
    (nodes already); the Weapon Store's sell confirm.
  * Cases needed first (none of a store's sub-pages is covered; the dev
    console's `give` adds equipment for sell lists that scroll): the Weapon
    Store's buy list scrolled with its comparison, a sell list with its
    bounding box scrolled, both confirms and "You can't afford that!"; the
    card store's buy page past two lines (its scroll bar), a merge with and
    without the preview, its confirms; the Inn's rest confirm, its prize and
    trade list; the Church's save list after a save (the game-clock dates),
    its bless page with the hands moved, its tutorials.
  * Size: one session for the cases and the Weapon Store, the card store
    and the Inn (their parts are the menu's nodes); the Church's bless page
    (HelpText rows, LevelUpBar, the coloured hands) may need a second.
* **The menu** (*done through step B: results below*; `src/menu`, 15 files, 2,877 lines with `MenuNode`, plus
  `menu/tutorial` 447; `MainMenu`, `AbstractPage` and the pages; the
  automap is `info/LabyrinthMap.draw`). `StatusPage` and `BestiaryPage` are
  unreachable (Appendix), `Help.gd` unused.
  * Draws: `MainMenu.draw` sets `setColor(1)`, `setAlphaFunc(.02)`, size
    22, then the page's `draw3D`, then the fade (node; the menu fades only
    when it loads a game). Every page starts with `drawStandard`: black
    text, `back.jpg`, its pieces. StartPage: the root list (numbers), Key
    Items (numbers, bounding box, disabled in black), the Save list with
    the dates under each slot; the character select (an active child's
    list: only its hand shows); the title; each character's status line
    (`StatusPage.drawTop`: image, name, HP, class, level, slots); the
    thumbnail (`drawScreenShot`: the screenshot and `frame.png`); gold,
    steps, time; while saving, the saving box (no dim). EquipPage: the
    status with the comparison, the item, the slots list (`down` +
    equipment), the equipment list (numbers, bounding box), both hands, the
    help line. DeckPage: the decks' titles (`drawMultiString` at the fade),
    both decks (`Deck.drawDeck`, 4 x 5 cards, the passive one at .5 while
    editing), the Edit/Back list (hand dimmed while editing), the card info
    (node) or a status line, two scroll bars, the flying cards (`Animator`),
    the help line. MapPage: the list (labyrinths with a bounding box, or
    floors), the automap: all floors under a modelview `translate(25, 80)`,
    `scale(1/3)` and a translate per floor, or one floor; each node's
    pieces and icons, the player's arrow tinted, the floors' names (screen
    text at computed places; the player's floor green over a black
    shadow); "Explored", the thumbnail, the info. HelpPage: the options or
    the difficulty list (harder ones gray), the wrapped difficulty text
    (measured every frame). TutorialPage: its list (bounding box), the
    status lines, the thumbnail, the info, a tutorial (node).
  * State changes in the draws: the cursor fix-up (with its sound; a list
    left empty keeps the cursor at −1); the scroll bars' lazy init;
    `StatusPage.drawTop`/`drawEquip` add their offset to a static `y` array
    and replace it (`EquipPage.y` is `MenuValues.STATUS_Y` itself);
    `BUTTON_ICONS` load on first use; DeckPage's `setImageColor(.5)` lasts
    until the next `drawString`; `drawDeck` turns bold off; the automap
    leaves size 22 and black text.
  * Shared: the menu pieces (with the stores), `StartPage.drawInfo` (with
    the Inn; the Church has a copy), the thumbnail, `StatusPage`/`EquipPage`
    helpers (with the Weapon Store), `Deck.drawDeck` (with the Card Store),
    the list variants (numbers, equipment + down, bounding box, active
    children, dimmed hand), `MenuScrollBar`, the card info and tutorials
    (nodes), `SaveSlots`' dates. The thumbnail is taken where the menu is
    opened from (`MenuStarter.checkMenu` at the end of the labyrinth's,
    village's, world map's and airship's draw: `copyFrame`, the frame
    before); the stores open no menu.
  * Coverage (probe): 337 shots in 279 cases. StartPage 300 (every tour
    opens the menu once; the root list, Key Items 3, the Save list 2 with
    "Empty", the character select 3), DeckPage 12 (`dialog_deck_page`,
    `menu_pages`; the dimmed hand in 9), MapPage 15 (the `dungeon_map_page*`
    cases, `airship_land1_menu`, `menu_pages`), TutorialPage 6, EquipPage 2
    (its slot list only), HelpPage 2 (its options); scroll bars in 25
    shots. Cases needed: the equipment list with numbers, its bounding box
    scrolled and the comparison; the help page's difficulty list; the Save
    list after a save (dates) and the saving box; Key Items scrolled; a
    deck edit with cards flying; a map page scrolled (bounding box).
* **The menu list variants** used (*built in the menu: ARCHITECTURE
  section 14's table*; MenuNode call → flags `withPrice,
  allChildren, withNumber, down, withEquipment`): plain (`drawAllChildren`
  / `drawChildren`: the title, every store's root, the confirm boxes, the
  Church, CardStore, DeckPage, MapPage, HelpPage, TutorialPage, the
  Cheater's dev menu at size 26); the active child's list (StartPage's
  character select); `allChildren` + number (StartPage's lists); number
  (EquipPage's equipment list); `down` + equipment (EquipPage's slots);
  price + `down` (the Weapon Store's lists); price (the Inn). Bounding boxes
  (bar at x 978): `setStandardWithBB` (StartPage's Key Items, MapPage,
  TutorialPage), `setStandardWeaponWithBB` (EquipPage), the Inn's trade
  list, the Weapon Store's sell lists; scroll bars made directly: DeckPage
  (two, always drawn), CardStore (two, over two lines). Dimmed hands:
  DeckPage's Edit/Back, the Church's bless hands, Cesadur's.
* **Order and size.** Three parts, four or five sessions:
  1. The menu: *done in one session (results below)*. It built what the
     stores reuse: the menu pieces, `MenuList`'s variants and its scroll bar
     (`PageScrollBar`), the status helpers, the deck (`DeckView`, `CardView`:
     card images), the thumbnail, the info, the help line, the confirm box;
     the automap is TextureRects under a `Zoom` with the page's modelview,
     as planned (exact: results).
  2. The stores: *done in one session (results below)*. They reused the
     menu's pieces, lists, deck, status helpers, info lines, help line and
     box; new: the confirm dim (the Fade node on UI), `LevelBar` (the bars'
     image parts) and the Church's bless page (`BlessPage`, `BlessRow`).
  3. The mini-games: *done in one session (results below)*. They reused
     the stores' dim (the Fade node on UI), `LevelBar` (the scaled image as
     its legacy quad), the menu's `MenuBackground` images, `MenuText` lines
     and `HelpLine`; the fade's port bug was fixed first, as its own change
     with new goldens.
  No part needs a decision of section 13 for step B; step C of all of them
  needs decision 3 (and 6 for the riddle's fade and the stores' and menu's
  animations) and phase 4.3's input wrapper.

**Results of the menu (phase 4.2's rollout, part 1,
`docs/phase4_2_menu_prompt.md`; conventions in docs/ARCHITECTURE.md
section 14, "The menu").** Step B for `MainMenu` and its pages (start,
equip, deck, map with the automap, help, tutorial) and the parts the stores
reuse; the legacy objects keep the state, the input and the timing.

* **Baseline** (on 2930993c): `tools/check.sh` 0 failed (465 scripts);
  goldens of the 401 cases and `bridge_test` (`m0gold`, 7,361 shots),
  identical to the pilot's node run `g42node` shot for shot, log for log
  and error line for error line (3,223); the pilot's check
  (`--legacy=title,game_over,menu_list`, every case) vs. `m0gold`: 7,361
  of 7,361, all 402 logs and the error lines identical.
* **Facts** (deliverable 1), where they add to or differ from the prompt and
  the list above:
  * The frame. `MainMenu.draw` as listed; the alpha test (`GREATER .02`) is
    every node's material. The menu never fades: `init` sets the fade
    value 1 and no fade-in, `exit()` leaves without fading, and the only
    fading exit (`exitTo`, a slot loaded from the start page) needs a Load
    entry the root does not have (Deck, Equip, Key Items, Tutorial,
    Options, Map, Save; the Java's Load is in a dead `else`, Appendix):
    every probed menu frame has fade 1, so the Fade node never shows in
    the menu. The menu is pausable (only the title sets
    `pausable` false): "Paused" over it is now a case. "Game pad lost" is
    drawn after it as after every mode. No menu frame ends in the bold
    font.
  * Overlaps where the order shows: the lists' hands over the pieces (the
    root's hand1 at x 765 over piece 2); the character select's hand (x 15
    to 60) under each portrait (117 x 143 at x 54: 6 px); pieces 0 and 10
    overlap by one row, pieces 7 and 3 by 20 rows on the equip page (7
    first); the status lines over pieces 0, 10, 11, 12; frame.png over the
    screenshot; a help icon (64 x 32, centred) and its label (icon 30 to
    94, "Exit" from 90); drawChange's lines over the attribute values; a
    floor's name and its top row of cells in the overview. The card info
    (y 6 to 203 at the deck page's −29) does not reach the decks (cards
    from y 250).
  * State changes in the draws, all kept by the twins in order: as listed
    above, and: `Creature.isAlive()` (drawTop) sets `alive`; a chest's map
    image writes its Database status 0 the first time it is drawn
    (`Chest.getMapImage`); drawString's `setColor(color)` also for an empty
    string (the "(1)" a number 1 does not draw, the character select's ""
    names); the numbers, prices and equipment set size 22 after them
    whatever the size before; `startText(alpha, -1)` keeps the text colour
    (the automap's green). No probed frame fires the cursor fix-up.
  * Transforms: the overview's images go through the modelview on the CPU
    (`_emit2D`), its text not. The cells are small textures (27 px at 1.4,
    at a third), the kind that rounded differently under a cutscene zoom
    (the emotion bubbles), but here TextureRects in the floor's space under
    a `Node2D` with the modelview as its transform draw the legacy pixels:
    every automap shot (47; all six places of a floor in the overview, and
    single floors) identical, and so was a version that drew the legacy
    quads (`screen_points`, as `EmotionBubble`). The automap uses the
    `Node2D` (`AutomapFloor`'s `Zoom`), as this section planned.
  * The thumbnail: taken at the end of the labyrinth's, village's, world
    map's and airship's draw, after the fade (`MenuStarter.checkMenu` →
    `enterMenu` unless fading → `Values.getMenuScreenShot`: `copyFrame`,
    the main viewport's texture, i.e. the frame before with every layer,
    scaled to 183 x 137, cubic); drawn as an `Image` through
    `ImageHandler.getGameTexture` (one texture per Image); a TextureRect of
    that texture draws the same pixels. Headless runs have none.
  * Text: right-aligned numbers (980) and prices and equipment (985) at 20
    through `calcAlignRight` in the current font; the floors' names centred
    (`calcAlignCenter`, 24; a single floor 34); the help page measures its
    difficulty text every frame (`wrapText`, size 22); the deck titles at
    `startText`'s alpha; bold only in `drawDeck` (26/28, the card store's
    numbers), turned off after it.
  * Variants by call site: as in ARCHITECTURE section 14's table (the
    StartPage root drawn plain while a character select is open:
    `drawAllChildren` without numbers; Key Items' disable colour black; the
    difficulty list grey for the current level and the harder ones).
  * The stores share the pieces (with their mask), the info lines, the
    title line, the help line (Church), the price variant and bounding
    boxes, the scroll bars, the status helpers (Weapon Store), the deck
    (card store), the confirm boxes (a piece and texts, after a dim) and
    the save list's dates (Church): entry above.
* **Coverage.** The probe (prints in `MainMenu.draw`, each page's draw with
  its sub-state, `MenuNode.draw` with its flags, cursor, bounding box
  offset and whether the fix-up fires, `MenuScrollBar.draw`,
  `Deck.drawDeck`, the flying cards, `LabyrinthMap.draw`, the status
  helpers, the saving box, the dates, `MenuStarter.checkMenu` and
  AutoPlay's shot) over every case: the menu in 337 shots of 279 cases
  (StartPage 300, MapPage 15, DeckPage 12, TutorialPage 6, EquipPage 2,
  HelpPage 2), opened from a village (87 cases), a labyrinth (208), the
  world map (3: `landscape`, `world_night`, `bridge_test`) and the airship
  (2). Already covered, where 9.2 said not: the map page's labyrinth list
  scrolled in its bounding box (offset −328 and −369 in 6 shots, with its
  scroll bar) and the character select for Deck and Equip
  (`dialog_deck_page`, `menu_pages`); the overview of a labyrinth with two
  and five floors, one floor, the player's floor green, the card info and
  the status line instead of a missing card, Kin's deck scrolled. Not shown
  by any case: the equipment list, Key Items scrolled, the party deck
  edited (Kin's at .5), cards flying (drawn between shots), the Save list
  after a save and the saving box, the difficulty list, the tutorial list
  scrolled, "Paused" over the menu. Six new cases (86 shots):
  `menu_start_save`, `menu_key_items` (the console's `give`: nine items,
  four with numbers), `menu_equip_list` (`give`: a seven-entry weapon list
  scrolled, "(2)", red and green changes and slots, shields and armours
  compared, equipping, R1/L1), `menu_deck_edit`, `menu_options_difficulty`
  (the console's `difficulty`: Easy and Medium), `menu_tutorial_scroll`.
  Not covered: the cursor fix-up (no list shrinks under its cursor; an
  empty Key Items list would: "Start" has no items), the menu's fade
  (unreachable), the card store's deck branches and the price variant
  (the stores' part).
* **Built** (ARCHITECTURE section 14, "The menu"): the nodes
  `MenuBackground`, `MenuTitle`, `MenuInfo`, `MenuThumbnail`, `HelpLine`,
  `MenuText`, `MenuBox`, `PageScrollBar`, `StatusLine`, `EquipStatus`,
  `EquipItem`, `DeckView`, `CardView`, `Automap`, `AutomapFloor`, the helpers
  `ImageList` and `HelpLineCapture`; `MenuList` with every
  variant (`MenuNode.place_children` replaces the pilot's
  `place_all_children`); theme roles `MenuChoice22`, `MenuText22`,
  `AutomapFloorName`, `AutomapFloorTitle`, `CardIndex`, `CardIndexCurrent`;
  bridge members `Graphics.place_image`, `place_centered_image` and the
  twins listed there; flags `--legacy=menu_frame`,
  `menu_text`, `status`, `deck`, `automap` (and `menu_list` for the menu's
  lists); the dev console's `give`.
* **Parity** (tolerance 0 everywhere; the final code, 407 cases and
  `bridge_test`, 7,447 shots; the node run is `m2node`; "the menu cases":
  the 285 cases that draw the menu, by the probe, 3,921 shots):
  * golden (`m1gold`) vs. nodes, every case: 7,447 of 7,447 shots
    identical, all 408 logs identical, the same error lines in every log
    (3,229);
  * this task's flags (`--legacy=menu_frame,menu_text,status,deck,automap,
    menu_list`) vs. nodes on the menu cases: 3,921 of 3,921, logs and error
    lines identical (and vs. the golden);
  * each flag alone vs. nodes and vs. the golden, on its parts' cases:
    `menu_frame` 3,921 of 3,921 (285 cases), `status` 3,921 of 3,921 (285),
    `menu_list` 4,130 of 4,130 (294: the menu cases, the title's and the
    game pad lost's), `deck` 47 of 47 (3), `automap` 47 of 47 (6),
    `menu_text` 108 of 108 (10); logs and error lines identical;
  * every flag on (`--legacy=title,game_over,menu_list,menu_frame,menu_text,
    status,deck,automap`, every case) vs. the golden: 7,447 of 7,447, all
    logs and error lines identical (the legacy paths and the frame without
    nodes are unchanged);
  * the new cases recorded twice: 104 of 104 (with `menu_pages`), logs and
    error lines identical; the old cases with the `give` hook vs. the
    baseline: 7,361 of 7,361, the same 3,223 error lines;
  * the bridge test passes (identical, "BridgeTest: freed after 748
    frames").
  * No tolerance was needed. The one difference on the way was a bug in the
    nodes (the help line's size, Found below); the first node run was
    identical on every other shot.
* **Frame rate** (normal runs: no `--seed`, windowed, one at a time, the
  shipped saves (`APPDATA` a scratch folder); AutoPlay's `fps=` every 0.5 s
  for 11 s, the first second dropped; legacy (this task's flags) → nodes,
  median and range):

  | Where | Capped | Uncapped |
  |---|---|---|
  | The start page from Alares (three status lines, the thumbnail) | 60 → 60 | 759 (750–766) → 1,608 (1,548–1,619) |
  | The deck page editing the party deck (Kin's at .5, the card info) | 60 → 60 | 345 (340–347) → 839 (823–844) |
  | The map page's overview of the Empyrian Temple (five floors) | 60 → 60 | 1,123 (1,061–1,139) → 1,755 (1,746–1,772) |

  The legacy drew every line glyph by glyph and every image as a quad each
  frame (the deck page: 40 cards with their balls); the nodes keep their
  glyphs and rects and only change what changed.
* **Still legacy** in the menu: the state, the input and the timing (step
  C: decision 3, phase 4.3's input wrapper); the `draw(g)` methods (the
  twins run there); the unreachable `StatusPage.draw3D` and
  `BestiaryPage.draw3D`; the mode fade, "Paused", "game pad lost", the card
  info and the tutorials are phase 3's nodes. With the flags off nothing of
  a menu frame is drawn through `Graphics` (a run with a print in
  `GLBackend.ci_2d`: no legacy 2D canvas item in any menu frame of
  `menu_pages`, the six `menu_*` cases, `dialog_deck_page`,
  `dungeon_map_page_floors` and `airship_land1_menu`). The shared helpers
  keep their
  legacy drawing for the stores (`MenuNode.draw`, `StatusPage.drawTop`,
  `EquipPage.drawStatus`, `Deck.drawDeck`, `StartPage.drawInfo`,
  `drawMenuBackgroundStatic`).
* **Found on the way:** the theme's role lookup could not fail (12): the
  deck page's help line while editing (size 20, which the card info
  leaves) came out at 24 in the first node run (23 shots, box 91,722 to
  991,746, up to 110/255): `MenuText.role` now reads the type's own entries
  (`Theme.get_font_size_list`; `has_font_size_nocheck` is not exposed to
  scripts), `MenuList` uses it too. The automap under a `Zoom`, as planned:
  exact (Facts). The menu never fades (Appendix). A headless shot compare
  beside an 8-job recording ran the 16 GB out (12): four `--legacy=status`
  runs crashed in AutoPlay's `get_image`, four logged WebP decode errors
  with identical shots; the eight were recorded again, alone: identical.

**Results of the stores (phase 4.2's rollout, part 2,
`docs/phase4_2_stores_prompt.md`; conventions in docs/ARCHITECTURE.md
section 14, "The stores").** Step B for the Weapon Store, the card store,
the Inn and the Church with the menu's nodes and three new ones (`LevelBar`,
`BlessPage`, `BlessRow`); the legacy stores keep the state, the input and
the timing.

* **Baseline** (on 2a3a7b35): `tools/check.sh` 0 failed (494 scripts);
  goldens of the 409 cases (`st0base`, 7,674 shots), identical to `cafter2` (the closings' set) shot for shot and log for
  log, and in each case's error and leak lines but one: a run of
  `particles_save_grivera` logged WebP decode errors (memory pressure:
  12 runs of that 8-job recording crashed or failed to start and were
  recorded again; its shots were identical, and the golden's run of it
  equals `cafter2`);
  the menu's check (`--legacy=title,game_over,menu_list,menu_frame,
  menu_text,status,deck,automap`, every case, on the golden's code: the
  baseline and the console's two new commands, which no old case uses) vs.
  the golden: 7,817 of 7,817 shots, all logs and error lines identical.
* **Facts** (deliverable 1), where they add to or differ from the prompt and
  the stores entry above:
  * The frame. `Building.draw` as listed: `setColor(1)`, size 22,
    `setAlphaFunc(.02)`, black text every frame, not the blending (only the
    Inn's prize message sets it, to the usual `ONE_MINUS_SRC_ALPHA`) or the
    bold font (`setFontSize(22)` keeps the font: `drawDeck` turns bold off
    itself). `drawStandard`: the background at (0, 0), the keeper's dialog
    (a phase 3 node) while `dialogIsShowing` (the Weapon Store's equipment
    lists and the card store after its buy or merge page hide it; the merge
    page shows "The following cards can be merged."), the keeper centred at
    y 205 (the Church's at 105), the pieces of the store's mask. Every store
    fades in when entered and out when left (`initGameMode`'s fade-in, the
    exit's fade-out), with the current fade mode's image: black in every
    probed frame; the Inn's rest fades out and then waits seven seconds
    faded out (`checkExit`). The stores are pausable (only the title is
    not): START draws "Paused" over a store and over its confirm box (now
    cases); "game pad lost" is drawn after the store as after every mode.
  * Order and overlaps. The keeper is drawn after the keeper's dialog and
    before the pieces; the lists' hands over the pieces (x 765 over piece
    2's or 14's left edge); the Weapon Store's equipment list and its hand,
    then the category list and its hand (two lists, two hands); the dim over
    everything before it, the box and its list over the dim; the card info
    at −23 (its panel x 4 to 762, y 12 to 209) over the keeper's dialog and
    the keeper's top rows, not over the pieces (from x 762) or the deck
    (from y 410); the bless page's markers (hand2.png, 45 × 40, at y − 50)
    over their own row's bar and the row above's, under nothing drawn later;
    the bars (165 × 25 images drawn 340 × 34) under the markers only; the
    merge preview's text between its two cards, which do not overlap it.
  * State changes in the draws, all kept by the twins in order: the
    Church's `totalCost` (set to 0 and summed in the bless page's draw,
    read by CROSS on "Done") and its markers' positions (`handLow`,
    `handHigh`; `handAnim`'s y, its x stepped in `update`); the scroll bars'
    lazy init and `loadIdentity` (the card store's two, the lists'); the
    cursor fix-up and its sound; `drawDeck`'s bold font and black text;
    `fadeOldSchool(.5)`'s colour (the fade colour at alpha .5) and the fade
    image's bind, then `setColor(1)`; `LevelUpBar.drawStatic`'s `setColor`
    calls (white, green `(0, 1, 0, 1)`, white, white); the merge preview's
    size 40 and back; `drawStringSetSize`'s sizes (30, 26 per row); the help
    text's sizes 34 and 26, black, startText (the store's fade value) and
    each word's `setTextColorAndApply`; drawString's `setColor(color)` after
    every line. The Inn's prize (`currentLoot`, the gift message) is set in
    its update, not its draw.
  * The cursor fix-up is reachable in one place: selling the last weapon of
    a sell list that has more (Slot 1: Arcane Rod, the fifth of five).
    `WeaponStore.crossPressed` refills the list with the cursor kept, and
    `updateCurrent` reads the child at the cursor, which is past the end:
    two script errors (the Java's `ArrayList.get` threw: an original bug,
    Appendix), then the list's draw moves the cursor back (with its sound).
    `store_weapon_sell` sells it.
  * Text. Measured: the prices right-aligned to 985 at size 20 (25 px lower
    on the Weapon Store's lists), the confirm's price to 630 at 22, the card
    store's numbers right-aligned in bold 26 (x + 118 / 116, the shadow
    first) and the current card's at 28 (x + 128 / 126). Sizes: 22; 20 for
    prices; 26 (the bless list, each row's cost, the help text, "Total
    cost") and 30 ("Cost"); 40 ("x 5 merges to"). Bold only in `drawDeck`.
  * Variants by call site: plain (`drawAllChildren`: every root, the Weapon
    Store's categories, the confirm lists, the Church's lists; `drawChildren`:
    the Weapon Store's categories beside an equipment list, the Church's
    root beside the bless page), price + `down` (the Weapon Store's equipment
    lists; the sell lists in their bounding boxes, 370 to 550, bar at 978),
    price (the Inn's root and its trade list, bounding box 147 to 270: no
    price on the maps). MenuList's price variant draws what `drawWithPrice`
    draws (the name, then "<price> gp" at size 20 right-aligned to 985, the
    size back to 22): identical (parity below).
  * Images in parts. `LevelUpBar.drawStatic` draws `emptyBar.png` whole and
    `blueBar.png` twice and `overlay.png` once in parts
    (`GameTexture.drawPart` with percent 1, `drawPartRange` 0 to p1, p1 to
    p2, 0 to p2): the quad from `int(x + 200 × 1.7 × low)` to `int(x + 200
    × 1.7 × high)`, `int(y)` to `int(y + 34)`, the texture's u from low to
    high (the images are 165 × 25, drawn 340 × 34). A TextureRect of that
    rect with an AtlasTexture of that region, the first node tried, drew the
    bars' antialiased left ends (x 185 to 197 of every bar) 1–5/255 apart
    (17 on one pixel), in all 17 bless page shots: Godot's region rect does
    not sample the texture quite as the legacy triangles do. `LevelBar`
    draws the legacy quad instead (`Graphics.place_image_part`'s corners
    and texture coordinates, `canvas_item_add_triangle_array`, as
    `EmotionBubble`): exact. A zero-width part (p1 = 0, or p1 = p2 after the
    blessing) draws nothing either way.
  * Not reachable, so not covered: "Can't merge that card." (`CANT_MERGE`):
    the merge deck holds only the kinds whose `enabled` is true (five or more,
    `canBeMerged`, level below 3), so CROSS on a card of it always confirms
    (the Java does the same); for the same reason the merge page never shows
    a level 3 card without its preview: the page is without a preview only
    when it is empty (`store_card_merge_last`). `CardStore.drawMergedCard`
    and the Church's "Resurrect" (plan Appendix).
  * Coverage the plan missed: `dialog_card_store` already showed the card
    store's buy page (Alares at level 0: five cards, one line) and its merge
    page with the preview (three kinds; levels 1 and 2), the numbers and the
    card info.
  * The mini-games share: `MenuHand` (now also as images:
    `place_hand_image`), the button icons (`HelpLine`), the dim (the Fade
    node on UI) and the box (`MenuBox`): entry above.
* **Coverage.** The probe (prints in `Building.draw` with the store and its
  modes and fade, each store's `draw3D`, the confirm boxes, `MenuNode.draw`
  with its flags, cursor, bounding box offset and fix-up while a store
  draws, `MenuScrollBar.draw`, `Deck.drawDeck`, `LevelUpBar.drawStatic`,
  the Church's hands, `HelpText`, the dates, the Inn's gift, "Paused" and
  AutoPlay's shot) over every case: the stores in 50 shots of 6 cases
  (`stores`, `dialog_card_store`, `dialog_store_fade`, `tutorial_store`,
  `zazo_night_0`, `zazo_night_1`): every root list (the Inn's with its
  price, the Church's with Bless greyed), the Weapon Store's fade in and
  out, both stores' tutorials, and (not in the plan) the card store's buy
  page and merge page in `dialog_card_store`. Not shown: any Weapon Store
  list below the root, a confirm, a scroll bar, the bless page, the save
  list, the Inn's trade list or prize, "Paused" over a store, the other
  stores' fades. Eight new cases (143 shots): `store_weapon_buy` (Zazo:
  the categories, the weapons with prices and comparison, the hand moved,
  the buy confirm moved, a purchase, Borealis's greyed Iron Armlet and "No
  one can equip that.", the armours greyed after the console's `gold 100`,
  "You can't afford that!", "Paused" over the confirm and over the list),
  `store_weapon_sell` (Alares: the five weapons in their bounding box,
  scrolled, wrapped both ways, the sell confirm kept and confirmed, the
  last weapon sold: the fix-up, the shields and armours), `store_card_buy`
  (Dellna at level 1: 31 cards on five lines, the fade-in, the deck moved
  and scrolled, grey cards after `gold 14000`, "You can't afford that!", the
  confirm moved and cancelled, a purchase, the fade-out), `store_card_merge`
  (the console's `give card` for twelve more kinds: 16 kinds on three lines,
  the scroll bar, previews of level 1 and 2 cards, the confirm moved and
  cancelled, a merge), `store_card_merge_last` (the Start save: one merge
  leaves the page empty), `store_inn` (the fade-in, the rest confirm moved
  and cancelled, the trade list of five maps scrolled, a prize, the traded
  map greyed, "Paused", a night's rest: the fade-out and the wait),
  `store_church_save` (the fade-in, the save list "Empty", a save to Slot 2
  and its game-clock date, "Tutorial - Levels", the fade-out),
  `store_church_bless` (Dellna, `--status=churchbless.tut:1`: the five pages
  of the bless tutorial, the bless page, the blue marker moved, the green
  one chosen and moved both ways, the next rows, "Done" and the blessing on
  each row, the page when done). Goldens: `st1gold` (417 cases, 7,817
  shots; its old cases identical to the baseline and to `cafter2`, shots,
  logs and per-case error and leak lines), `st1gold2` (the new cases again:
  143 of 143 identical, logs and error lines too).
* **Built** (ARCHITECTURE section 14, "The stores"): the nodes `LevelBar`,
  `BlessPage`, `BlessRow`; the bridge members `Graphics.place_image_part`,
  `show_fade`'s layer (the confirm dim: a Fade node on UI),
  `AbstractPage.show_pieces`, `StartPage.show_info`,
  `MenuHand.place_hand_image`, `place_hand_with_color`,
  `LevelUpBar.place_static`, `HelpText.place_top_layer`,
  `AbstractCard.place_at`'s level, `Building.show_standard`,
  `AbstractStore.draw_dim`, `show_box`, `_show_confirm_box`,
  `CardStore._show_merge_preview`, `Church._show_bless`; the stores' call
  sites switched to the menu's twins (`draw_list`, `draw_title`,
  `draw_help`, `draw_info`, `EquipPage.show_status`, `show_equip`,
  `Deck.show_deck`, `MenuScrollBar.show_bar`, `SaveSlots.show_dates_under`);
  flags `--legacy=dim`, `bless`; the console's `gold` and `give card`;
  `tools/check_all.gd` skips folders with a `.gdignore` (project copies in
  `tools/parity/out`).
* **Parity** (tolerance 0 everywhere; the final code, 417 cases, 7,817 shots;
  the node run is `st2node`; "the store cases": the 14 cases that draw a
  store, by the probe, 222 shots):
  * golden (`st1gold`) vs. nodes, every case: 7,817 of 7,817 shots
    identical, all 417 logs identical, the same error lines in every log
    (2,421 errors, 3 script errors: `store_weapon_sell`'s two and an older
    case's one; the exit leak reports only in the five `effects_*` cases,
    as before);
  * the stores' flags (`--legacy=menu_frame,menu_list,menu_text,status,deck,
    dim,bless`) vs. nodes on the store cases: 222 of 222, logs and error
    lines identical (and vs. the golden); each flag alone vs. nodes and vs.
    the golden on the store cases: `menu_frame`, `menu_list`, `menu_text`,
    `status`, `deck`, `dim`, `bless` each 222 of 222, logs and error lines
    identical;
  * every flag on (`--legacy=title,game_over,menu_list,menu_frame,menu_text,
    status,deck,automap,dim,bless`, every case) vs. the golden: 7,817 of
    7,817, all logs and error lines identical (the legacy paths and the
    frame without nodes are unchanged);
  * the baseline's check: the menu's flags on every case of the golden's
    code vs. the golden: 7,817 of 7,817, logs and error lines identical;
  * the new cases recorded twice: 143 of 143, logs and error lines
    identical; no exit leak report in them.
  * No tolerance was needed. The one difference on the way was the first
    `LevelBar` (a TextureRect with an AtlasTexture region): 202 to 240
    pixels of the 17 bless page shots, up to 5/255 (17 once), on the bars'
    antialiased left ends (Facts); drawn as the legacy quad it is exact.
    The first node run of every other store case was identical.
* **Frame rate** (normal runs: no `--seed`, windowed, one at a time, the
  shipped saves (`APPDATA` a scratch folder); AutoPlay's `fps=` every 0.5 s
  for 11 s, the first second dropped; legacy (the stores' flags) → nodes,
  median and range):

  | Where | Capped | Uncapped |
  |---|---|---|
  | The Weapon Store's weapons with the comparison (Zazo; the status, the item, two lists) | 60 → 60 | 858 (830–868) → 1,526 (1,513–1,530) |
  | The card store's buy page (Dellna at level 1: 14 cards shown, the card info, the scroll bar) | 60 → 60 | 585 (578–588) → 1,211 (1,190–1,226) |
  | The Church's bless page (Dellna: three bars and rows, the help text) | 60 → 60 | 459 (454–462) → 863 (857–866) |

  The legacy drew every glyph and image each frame (the help text's about 70
  words, the deck's cards and balls, the status's attributes); the nodes
  keep their glyphs and rects.
* **Still legacy** in the stores: the state, the input and the timing (step
  C: decisions 3 and 6, phase 4.3's input wrapper); the `draw(g)` methods
  (the twins run there); `CardStore.drawMergedCard` (never called) and the
  Church's "Resurrect" branch (no menu entry). The keeper's dialog, the card
  info, the tutorials, the Inn's prize message, the mode fade and "Paused"
  are phase 3's nodes. With the flags off nothing of a store frame is drawn
  through `Graphics`: a run of the 14 store cases with prints in
  `Graphics._drawText` and `_emit2D` during the stores' draws found no
  legacy text or quad in 12,451 store frames.
* **Found on the way:** a TextureRect with an AtlasTexture region does not
  draw a part of an image as the legacy quad does (the bars' antialiased
  ends up to 5/255, Facts): `LevelBar` draws the legacy quads (12). Selling
  a sell list's last entry reads past its end (two script errors; an
  original bug, Appendix). "Can't merge that card." is unreachable
  (Appendix). The plan's "no shot of the card store's deck or merge page"
  was wrong (`dialog_card_store`). Project copies in the session scratchpad
  lost their old files to Windows' temp cleanup while the disk was full: a
  golden recording failed half-way and was redone from a copy in
  `tools/parity/out/_gold` (12, HANDOFF); `tools/check.sh` compiled that
  copy until `check_all.gd` skipped `.gdignore`d folders. The free memory
  at idle was 7 GB: an 8-job recording crashed 11 runs (12).

**Results of the mini-games (phase 4.2's rollout, part 3,
`docs/phase4_2_minigames_prompt.md`; conventions in docs/ARCHITECTURE.md
section 14, "The riddles").** The fade's port bug fixed first (its own
change, new goldens), then step B for the eight riddle kinds with the menu's
and the stores' nodes; the legacy riddles keep the state, the input and the
timing.

* **Baseline** (on 735eaee8): `tools/check.sh` 0 failed (497 scripts);
  goldens of the 417 cases (`r0base`, 7,817 shots), identical to the stores'
  node run `st2node` shot for shot, log for log and in every case's error and
  leak lines (3 script errors, 2,421 errors, the exit leak reports of the
  five `effects_*` cases); every phase 4.2 flag (`--legacy=title,game_over,
  menu_list,menu_frame,menu_text,status,deck,automap,dim,bless`, every case)
  vs. `r0base`: 7,817 of 7,817, all logs and error lines identical. Recorded
  with 4 jobs (5.5–6 GB free at idle).
* **The fade's port bug** (Appendix; `RiddleGame.update` rounds each step to
  a 32-bit float, `_toFloat`): the fade-in ends at 1.0000001 after 10
  updates (was 1.1 after 11), the fade-out after 9 (was 10). Goldens of every
  case on it vs. `r0base`: the 36 old shots that show a riddle differ (every
  one open: no old shot showed a fade), the other 7,781 shots, all 417 logs
  and every case's error lines are identical. The 36, explained pixel by
  pixel (`sheet_fadefix.png` in `tools/parity/out/_work` had them side by
  side): outside the riddle's image only the dim changed, its alpha fade ×
  .3 from .33 to .30000004: every differing pixel there is lighter after the
  fix, by at most 8/255 (.03 × 255; the bright ones round a little off the
  linear estimate); inside the image the opaque texels hide the dim and are
  unchanged (all of `hate1.png`, an RGB image: no pixel differs), the
  translucent ones (the parchment's edges, `iceriddle.png`, `back.png` and
  the tiles' edges) took the image's alpha 1.1 before and 1.0000001 now
  (up to 23/255), and Hate's digits' antialiased edges, drawn at the fade,
  changed with it (up to 16/255). Cesadur's text (at the labyrinth's fade)
  and the hands (after `finishText`'s colour) did not change. The one update
  less of the fade-out shows in no old shot (none during it; the riddle
  leaves the labyrinth one frame earlier, and every later shot and log line
  is the same).
* **Facts** (deliverable 2; the probe over every case), where they add to or
  differ from the prompt and the mini-games entry above:
  * The frame. A riddle starts in the labyrinth's update (CROSS on the
    riddle object: `Riddle.activate` → `enterRiddle`: `push` hides the
    minimap, which slides out, and the mission) and is drawn the same frame
    at fade 0 (nothing shows: the dim at 1 draws nothing, the image at alpha
    0); the labyrinth draws its scene, the back weather pass, the riddle's
    `draw` (empty, once its `initDraw`, empty too), the front weather pass
    over it (`show_weather_over`), the minimap, then in 2D the mission (no
    riddle floor has one), the dialog (never shown with a riddle: the
    riddle's `dialog.setDS` gets an empty list, and the labyrinth's `dialog`
    stays null), the riddle's top layer, the top-layer items (none in any
    probed riddle frame) and the mode fade (the labyrinth's fade value is 1
    in every riddle frame: nothing). "Paused" and "game pad lost" are drawn
    over it (Transition), but neither stops it: as in the Java, `GameCore`
    only draws them, so a riddle goes on fading in under "Paused" and reads
    its input under both (the pad lost menu's DOWN moved a puzzle's cursor
    too; Appendix). The riddle ends in the update its fade-out goes below 0
    (`exitRiddle`, `pop`); that frame draws the labyrinth.
  * Order per kind: the dim (the fade image, black in every probed frame,
    scaled ×8 over the screen at alpha fade × .3), `setColor(1, 1, 1, fade)`,
    the image (`RiddleLoader`'s, scaled: `resultBack.png` 608 × 337 at 1.12,
    `hatetest.png` at 1.7, `iceriddle.png` at 1.2, `14.png` at 1.12, the image
    riddles' and `back.png` at 1); then the puzzles' tiles (125 or 100 px,
    filling `back.png`'s inner square; a Puzzle's free slot has no image),
    and their marker (the 129 × 129 `4x4single.png` 2 px round the cursor's
    tile, over its neighbours' edges; `horizontal`/`vertical.png` over the
    cursor's row or column); Aegis's six lines a page and Grivera's page
    (centred at 512 from y 250, 50 apart; Silent Ruin's hint 35), black, size
    28, not drawn on the way out; Hate's nine digits and its code (size 36,
    black, at the fade; "_ _ _ _ " centred at y 500, the trailing space
    measured too), its hand (45 × 40 at x − 40, y − 25: over the digit's
    first pixels); Cesadur's four words and its pool (each letter and "__"
    2 px under it, 28 px apart, size 24: the size earlier drawing left, in
    every probed frame), its letter hand (hidden until the first CROSS),
    then its word hand (one of them dimmed in the letter or word mode), its
    help (four icons centred 28 px left of their labels at y 510, "Exit"
    overlapping its icon by 4 px, as the menu's help lines).
  * State changes in the draws: none of the game's (the fade, the cursors,
    the hands' places and dims change in `update`); the GL and text state as
    listed in ARCHITECTURE section 14. What the riddle starts from: the
    colour of the minimap's arrow `(1, .85, 0, 1)`, the font size and text
    colour earlier frames left (24, or the 28 and 36 the riddle's own text
    left), and the alpha test of the frame: `GREATER .1` on the floors whose
    weather (Forest of Hate, Mysterious Forest) or save point (Omnious Hall,
    Temple of Aegis) drew before it (`setAlphaFunc(.1)`), so the dim's
    first three frames (alpha .03 to .09) are dropped there. What it leaves: the colour `(1, 1, 1,
    fade)` after an image riddle or a puzzle, `(1, 1, 1, 1)` after the text
    kinds and Cesadur; the size and the black text carry into the next
    frame, whose 2D sets its own before it draws (the minimap's colour comes
    first; the walls and objects are lit and ignore the current colour).
  * Text: centred by `calcAlignCenter` at 512 (Aegis's and Grivera's lines,
    Hate's code), at `startText`'s alpha: 1 (Aegis), the riddle's fade
    (Grivera, Hate), the labyrinth's fade value (Cesadur: 1 in every probed
    frame). Cesadur's `setColor(0, 0, 0, .3)` before its pool is the GL
    colour, which the port's text ignores (`Graphics.drawMultiString` uses
    the text colour and alpha): the pool is drawn as the words.
  * Solved: the 4 × 4 magic square on its first move (tickets/triage.md
    R1; its tiles are never scrambled: 16 of 16 in place), Hate's 8145 and
    Cesadur's four words each set their hinder door's status 0 → 1
    (`InventoryButton.updateDoorStatus`) and fade out.
  * Found: `Puzzle` scrambles before its free slot is set (an original bug,
    Appendix); the probe saw 1 of 15 tiles in place and the free slot at
    (3, 3).
* **Coverage.** The probe (prints in `RiddleGame.drawTopLayer` with the kind,
  fade, dim, colour, font size, text colour and alpha, each kind's
  `drawTopLayer` with its state, the tiles drawn and in place, the hands, the
  labyrinth's frame around it and the state the riddle leaves, the solved
  doors, "Paused", "game pad lost" and AutoPlay's shot) over every case: the
  riddles in 36 shots of the 9 `dungeon_riddle_*` cases, every kind open at
  fade 1 (Grivera's ten pages and Aegis's second page already turned, the
  plan did not list them); no shot of a fade, a solved riddle, Cesadur's
  letter mode or Hate's code. Ten new cases (266 shots): `riddle_image` (Mysterious
  Forest's image: every frame of the fade-in and fade-out),
  `riddle_aegis_pages`, `riddle_grivera_pages` (the fades, every page),
  `riddle_silent` (Silent Ruin's hint), `riddle_puzzle_moves` (the marker
  wrapped, tiles slid), `riddle_rubics_moves` (rows and columns shifted,
  both markers), `riddle_rubics19_solved`, `riddle_hate_code` (TRIANGLE on
  the empty code, 1234 reset, 8145), `riddle_cesadur_word` (the word hand
  moved, SQUARE on the empty words, the letter pool, a letter picked and
  undone, SUN, EARTH, MOON, WATER, both hands dimmed in turn, SQUARE), the
  last three printing their door's status before and after (the console's
  `trigger`), `riddle_paused` (a 5 × 5 Puzzle: "Paused" during the fade-in,
  "game pad lost" and its menu). Each kind's fade-in and fade-out is shot
  frame by frame (`wait 16`): 10 frames in (.1 to 1.0000001), 8 out (.88 to
  .04). Goldens: `r1gold` (427 cases, 8,083 shots), `r1gold2` (the new cases
  again: 266 of 266 identical, logs too, no error line). No dev hook was
  needed.
* **Built** (ARCHITECTURE section 14, "The riddles"): no node; the bridge
  members `RiddleGame.draw_dim`, `multi_line`, `multi_centered_line`,
  `RiddleLoaderImage.place` (the image's quad for `LevelBar`), `Tile.place`,
  `CesadurRiddleText.place`, `Letter.place`; the flag `--legacy=riddle`; the
  riddles use `dim` and `menu_frame` too.
* **Parity** (tolerance 0 everywhere; the final code, 427 cases, 8,083 shots;
  the node run is `r3node`; "the riddle cases": the 19 `dungeon_riddle_*`
  and `riddle_*` cases, 348 shots):
  * golden (`r1gold`) vs. nodes, every case: 8,083 of 8,083 shots
    identical, all 427 logs identical, the same error lines in every log (3
    script errors, 2,421 errors; the exit leak reports only in the five
    `effects_*` cases);
  * `--legacy=dim,riddle,menu_frame` vs. nodes and vs. the golden on the
    riddle cases: 348 of 348, logs and error lines identical; each flag
    alone (`dim`, `riddle`, `menu_frame`) vs. nodes and vs. the golden: 348
    of 348 each, logs and error lines identical;
  * every flag on (`--legacy=title,game_over,menu_list,menu_frame,menu_text,
    status,deck,automap,dim,bless,riddle`, every case) vs. the golden: 8,083
    of 8,083, all logs and error lines identical;
  * no exit leak report in the riddle cases (none before either).
  * No tolerance was needed. The one difference on the way: the riddle's
    image as a TextureRect of `place_image`'s scaled rect (the first node
    run of the riddle cases: 132 of 348 shots, 1/255 on 1 to 127 pixels,
    18/255 on one pixel of `iceriddle.png`; every scaled image: 1.12, 1.2,
    1.7) — drawn as its legacy quad (`LevelBar`) it is exact (12); every
    1:1 image (tiles, markers, hands, `hate1.png`) and every text was
    identical from the start.
* **Frame rate** (normal runs: no `--seed`, windowed, one at a time, the
  shipped saves (`APPDATA` a scratch folder), `--no-encounters`; AutoPlay's
  `fps=` every 0.5 s for 11 s with the riddle open, the first second
  dropped; legacy (`--legacy=dim,riddle,menu_frame`) → nodes, median and
  range):

  | Where | Capped | Uncapped |
  |---|---|---|
  | The 4 × 4 sliding puzzle (The Great Ruins: the image, 15 tiles, the marker) | 60 → 60 | 570 (548–581) → 680 (668–685) |
  | Cesadur's anagram (Mt. Cesadur: 96 lines of letters and "__", two hands, the help line) | 60 → 60 | 582 (564–593) → 615 (603–621) |

  A smaller gain than the menu's and the stores': the labyrinth under the
  riddle (its 3D scene, the minimap) costs most of the frame.
* **Still legacy** in the riddles: the state, the input and the timing (step
  C: decision 3; decision 6 for the fade; phase 4.3's input wrapper); the
  `drawTopLayer` methods (the twins run there); `RotatePuzzle` is unused (it
  inherits `Puzzle`'s drawing and nodes; no case can show it). The
  dungeon around a riddle keeps the minimap on the 3D bridge (8.4); the
  battles' top layers are phase 4.4's. With the flags off nothing of a riddle
  is drawn through `Graphics`: a run of the 19 riddle cases with prints in
  `Graphics._drawText` and `_emit2D` while a riddle's top layer draws found
  no legacy text or quad in 4,439 riddle frames (with the three flags on,
  the same prints counted 90,360 texts and 9,947 quads in Cesadur's case
  alone).
* **Found on the way:** scaled-up images as TextureRects round a few pixels
  1/255 apart from the legacy quads (12, "Parts of images"): the riddle's
  image is a `LevelBar` quad. The Java's 32-bit `float` counts steps
  differently from GDScript's 64-bit floats (the fade's port bug; check
  other ported loops that step a float to a bound). `Puzzle`'s scramble and
  the pause that stops nothing are the Java's (Appendix).

**Closing phase 4.2 (done on 2026-11-07, `docs/phase4_2_close_prompt.md`).**
What deleting the phase's legacy paths and its eleven flags removes, per
flag (the list it was done from: a survey of the code after the mini-games;
the battles are `src/battle`, phase 4.4; *As built* below says where it was
wrong). "Dead" = no caller left once the flag is gone.

| Flag | Its legacy branches (call sites) | Dead with it | Stays, for |
|---|---|---|---|
| `title` | `TitleScreen`: the background and logo `drawImage`s, `SaveSlots.draw_dates_beside`, `drawWithShadow` (the description) | `SaveSlots.draw_dates_beside`; `_draw_dates` with `menu_text` | `Graphics.drawWithShadow`: the battles (`SpoilsScreen`, `ResultScreen`, `Attack`, `Clock`) |
| `game_over` | `GameOver`: the image's `drawImage` | — | — |
| `menu_list` | `TitleScreen`'s and `GameCore`'s (game pad lost) `drawAllChildren`, `AbstractPage.draw_list`'s `drawChildrenFreely` | `MenuNode.drawChildrenFreely`, `drawWithPrice`, `drawWithEquipment`, `drawWithNumber`, `Graphics.drawStringRightWithReg` (no game caller) | `MenuNode.draw`, `drawChildren`, `MenuHand.drawHand`, `MenuScrollBar.draw`: the Cheater (`Cheater.draw`, dev) — `MenuNode.show_children` fits it and has no caller yet |
| `menu_frame` | `AbstractPage.show_standard`'s, `draw_title`'s and `draw_help`'s legacy halves, `StartPage.draw_screen_shot`, `draw_info`; `Building.show_standard`, `WeaponStore.drawInfo`, `CardStore` (pieces 13 and 12, its info), `Church` (pieces, its info copy); `CesadurRiddle`'s help (through `draw_help`) | `AbstractPage.drawMenuBackground`, `drawMenuBackgroundStatic`, `Building.drawMenuBackground` | the pages' and Cesadur's `drawHelp` (the twin runs them against `HelpLineCapture`) |
| `menu_text` | `StartPage` (the Save list's dates, the saving box), `MapPage` ("Explored"), `HelpPage` (the difficulty text), `WeaponStore` (the sell confirm's line), `AbstractStore`'s confirm boxes, `Church`'s save dates | `SaveSlots.draw_dates_under`, `StartPage.drawConfirmBuyDialog`, `HelpPage.drawDifficulty` (`wrapText` stays: the twin uses it) | — |
| `status` | `StatusPage.draw_top`, `EquipPage` (`drawStatus`, `drawEquip`), `WeaponStore`'s | `EquipPage.drawStatus`, `drawChange`, `drawEquip`, `StatusPage.drawEquip` | — |
| `deck` | `DeckPage` (the titles, the decks, the scroll bars, the flying cards), `CardStore` (the decks, the scroll bars, the merge preview) | `Deck.drawDeck`, `Deck.drawCard`, `DeckPage.Animator.draw`, `AbstractCard.drawGrayCard`, `Graphics.drawStringRightAligned` (no game caller) | `AbstractCard.drawCard`: the battles (`ResultScreen`) |
| `automap` | `MapPage` (`drawAll`, `drawSingle`) | `MapPage.drawAll`, `drawSingle`, `LabyrinthMap.draw`, `LabyrinthNode.drawInMap`, `Graphics.drawSingleCenteredText` (only tools/render_test.gd) | the minimap's `LabyrinthMap.draw2`, `drawInSmallMap` (`MapRenderer`) |
| `dim` | `AbstractStore.draw_dim`, `RiddleGame.draw_dim` (`fadeOldSchool`) | — | `Graphics.fadeOldSchool`: the battles (`Screen`) |
| `bless` | `Church`'s bless page | `Church.drawHand`, `MenuHand.drawHandWithColor`, `LevelUpBar.drawStatic`, `HelpText.drawTopLayer`, `Row.drawRows`, `draw`, `drawIcon`, `Icon.draw`, `Graphics.drawStringSetSize`, drawImage's (low, high) part and `GameTexture.drawPartRange` | `LevelUpBar.draw` with drawImage's (percent) part: the battles (`SpoilsScreen`) |
| `riddle` | `RiddleGame` (the image), `AbstractPuzzle` (the tiles), `Puzzle`, `RubicsPuzzle` (the markers), `AegisRiddle`, `GriveraRiddle`, `HateRiddle`, `CesadurRiddle` (the texts, the hands) | `RiddleLoaderImage.draw`, `Tile.draw`, `CesadurRiddleText.draw`, `Letter.draw` | `MenuHand.drawHand`: the Cheater (above) |

* Effectively dead already: `StatusPage.draw3D` and `BestiaryPage.draw3D`
  (unreachable pages, Appendix) are the last callers of `StatusPage.draw`,
  `drawTop`, `drawAttributes`, `drawSlots`, `StartPage.drawInfo`,
  `drawScreenShot` and `MenuNode.drawAllChildren`; deleting the two pages'
  drawing (or the pages) frees them. `CardStore.drawMergedCard` and the
  Church's "Resurrect" branch draw nothing reachable.
* The Cheater (the console's `cheater`, dev only, unconverted) keeps the
  legacy list drawing (`MenuNode.draw` → `MenuHand.drawHand`,
  `MenuScrollBar.draw`) once every flag is gone; 12 of the 14 store cases
  pass through it, none shoots it. Switching it to `MenuNode.show_children`
  (a case shot first) frees that drawing too.
* What the battles need of it all: `Graphics.drawWithShadow`,
  `AbstractCard.drawCard`, `Graphics.fadeOldSchool` and `LevelUpBar.draw`
  (with drawImage's percent part); nothing of `MenuNode`, `MenuHand`,
  `MenuScrollBar` or `Deck` (their decks and scroll bars are their own:
  `AbstractDeck`, `BattleScrollBar`). The game pad lost menu over a battle is
  `MenuList` already.
* `Graphics` methods that lose their last game caller (`drawStringRightWithReg`,
  `drawStringRightAligned`, `drawSingleCenteredText`, `drawStringSetSize`,
  the (low, high) `drawImage`, `drawCenteredImage` after `menu_frame` and
  `menu_text`) are the emulation's API, which phase 5 deletes whole.
* Two comments are stale already: `StatusPage` and `StartPage` still say the
  stores keep `drawTop` and `drawScreenShot` until their part.
* The bridge members become the only paths (`AbstractPage.draw_list`,
  `draw_title`, `draw_help`, `StatusPage.draw_top`, `AbstractStore.draw_dim`,
  `RiddleGame.draw_dim`, `DeckPage`'s and `CardStore`'s `_draw_deck` and
  `_draw_bar` turn into plain forwards).
* The cases that cover each part (the parity results above): `title`,
  `game_over`, `menu_list`: the pilot's 17 cases (the `title_*` and
  `game_over*` cases, `dungeon_save_load`, `story_ana_reaction`,
  `story_someones_comming`, `newgame_to_forest`, `story_long`, `boss`,
  `pad_lost`), the menu's 285 and the store cases; `menu_frame`, `status`:
  the menu's 285 cases and the 14 store cases (Cesadur's help: the
  Cesadur riddle cases); `menu_text`: 10 menu cases and the store cases;
  `deck`: `dialog_deck_page`, `menu_pages`, `menu_deck_edit` and the card
  store's four; `automap`: the six map page cases; `dim`: the store cases with
  a confirm and the 19 riddle cases; `bless`: `store_church_bless`; `riddle`:
  the 19 riddle cases (`dungeon_riddle_*`, `riddle_*`). The closing changes
  no picture: every case before and after, identical.

*As built (2026-11-07):* every call site of the eleven flags is gone; the
twins are the only paths. In this order: the Cheater's shot first (a new
case, `cheater_menu`: its root, the cursor moved and wrapped, Buildings and
the 17 card stores, Villages, Stories and a chapter, "Paused" over it, back
to the village; 13 shots, recorded twice on the unchanged code: identical),
then flag by flag, then the dead code. Deleted (about 1,530 lines removed
and 400 rewritten or added, comments included; per flag, roughly):

| Part | Removed (about) | What |
|---|---|---|
| `title` | 20 | `TitleScreen`'s four branches; `SaveSlots.draw_dates_beside` |
| `game_over` | 3 | `GameOver`'s branch |
| `menu_list` | 60 | `TitleScreen`'s and `GameCore`'s branches; `AbstractPage.draw_list` (its 19 call sites call `MenuNode.show_children_freely`, `show_children` or `show_all_children`); `MenuNode.drawChildrenFreely`, `drawWithPrice`, `drawWithNumber`, `drawWithEquipment` |
| `menu_frame` | 90 | the branches in `AbstractPage` (`drawStandard`, `draw_title`, `draw_help`), `StartPage` (`draw_screen_shot`, `draw_info`), `Building`, `WeaponStore.drawInfo`, `CardStore` (pieces, info), `Church` (pieces, info), `CesadurRiddle` (through `draw_help`); `AbstractPage.drawMenuBackground`, `drawMenuBackgroundStatic`, `Building.drawMenuBackground`, `StartPage.drawScreenShot`, `drawInfo` |
| `menu_text` | 90 | the branches in `StartPage`, `MapPage`, `HelpPage`, `WeaponStore`, `AbstractStore` (the confirm boxes), `Church`; `SaveSlots.draw_dates_under`, `_draw_dates`, `StartPage.drawConfirmBuyDialog`, `HelpPage.drawDifficulty` |
| `status` | 190 | `StatusPage.draw_top` (its callers call `show_top`), `draw`, `drawTop`, `drawAttributes`, `drawSlots`, `_drawCharacterSlots`, `drawEquip`; `EquipPage.drawStatus`, `drawChange`, `drawEquip` and its static `x`, `y` (only `drawChange` read them); the branches in `EquipPage`, `WeaponStore` |
| `deck` | 140 | `DeckPage`'s titles, flying cards, `_draw_deck`, `_draw_bar` (the call sites call `Deck.show_deck`, `MenuScrollBar.show_bar`), `Animator.draw`; `CardStore`'s branches; `Deck.drawDeck`, `drawCard`; `AbstractCard.drawGrayCard` |
| `automap` | 90 | `MapPage.drawAll`, `drawSingle` and the branch; `LabyrinthMap.draw`; `LabyrinthNode.drawInMap` (the minimap's `drawInSmallMap` and the inventories' four-argument `drawInMap` stay) |
| `dim` | 20 | `AbstractStore.draw_dim`, `RiddleGame.draw_dim` (their call sites call `Graphics.show_fade` on the UI layer) |
| `bless` | 90 | `Church`'s bless branch and `drawHand`; `MenuHand.drawHandWithColor`; `LevelUpBar.drawStatic`; `HelpText.drawTopLayer`; `Row.draw`, `drawIcon`, `drawRows`; `Icon.draw` |
| `riddle` | 75 | the branches in `RiddleGame`, `AbstractPuzzle`, `Puzzle`, `RubicsPuzzle`, `AegisRiddle`, `GriveraRiddle`, `HateRiddle`, `CesadurRiddle`; `RiddleLoaderImage.draw`, `Tile.draw`, `CesadurRiddleText.draw`, `Letter.draw` |
| The Cheater's switch | 55 | `Cheater.draw` calls `MenuNode.show_children(g, Graphics.UI_LAYER)`; `MenuNode.draw`, `drawChildren`, `drawAllChildren`, `MenuHand.drawHand`, `MenuScrollBar.draw` lost their last caller |
| Dead code | 300 | `BestiaryPage` (the file), `StatusPage`'s page (its constructor, buttons, `draw3D`, `drawHelp`; the class keeps the twins and `extends RefCounted`), `MainMenu.initStatusPage`, `initBestiaryPage`, `checkEnemyInRange`, `AbstractPage.STATUS_PAGE`, `MenuValues.BESTIARY_STATS_X`/`Y`, the registry's `menu.BestiaryPage`; `CardStore.drawMergedCard`; the Church's "Resurrect" branch (`initResurrectMenu`, `fillResurrect`) |

The git history has all of it up to 9a9c2341. Kept: `Graphics`' API whole
(the methods no game code calls any more: `drawStringRightWithReg`,
`drawStringRightAligned`, `drawSingleCenteredText`, `drawStringSetSize`,
`drawCenteredImage` (the pages' `drawHelp` run against a `HelpLineCapture`),
the (low, high) `drawImage` and `GameTexture.drawPartRange`), and what the
battles call:
`Graphics.drawWithShadow`, `drawValueWithShadow`, `AbstractCard.drawCard`,
`Graphics.fadeOldSchool`, `fadeOldSchoolColorWhite`, `LevelUpBar.draw` with
drawImage's percent part (9.4). `BESTIARY_PAGE` stays (the help and map
pages use its layout), and so do `Help.gd` and `RotatePuzzle` (Appendix).
`tools/parity/parity.sh`'s examples name `--legacy=battle_effects` now.

Where the list above was wrong or short:
* `MenuHand.drawHand` does not stay for the Cheater: the Cheater's switch
  removed its last caller (with `MenuNode.draw`), as the Cheater's bullet
  foresaw; the riddle row's "Stays" is stale.
* There were no `CardStore._draw_deck` or `_draw_bar`: only `DeckPage` had
  the wrappers; `CardStore`'s branches were inline.
* `AbstractStore.draw_dim` and `RiddleGame.draw_dim` did not become
  forwards: they were removed and their callers call `Graphics.show_fade`.
  `StatusPage.draw_top` and `AbstractPage.draw_list` likewise; the wrappers
  whose body was the twin keep their names (`draw_title`, `draw_help`,
  `StartPage.draw_screen_shot`, `draw_info`).
* `GameTexture.drawPartRange` and the (low, high) `drawImage` are not dead
  code to delete: they are the emulation's API (phase 5).
* More dead code than listed: `EquipPage.x`/`y`,
  `MainMenu.checkEnemyInRange`, `MenuValues.BESTIARY_STATS_X`/`Y`,
  `AbstractPage.STATUS_PAGE`.
* The table's line references (close42_list.md) were right on the commit
  the closing started from; nothing had moved. The two stale comments
  (`StatusPage`, `StartPage`) went with the functions they were on.

**Parity of the closing** (2026-11-07; tolerance 0; 428 cases, 8,096
shots). Baseline `c42base` on 9a9c2341 plus the new case (recorded from a
project copy, 4 jobs, no failed run): identical to the mini-games' node run
`r3node` on its 427 cases (8,083 of 8,083 shots, all logs, every case's
script error, error and exit leak lines: 3, 2,421, the five `effects_*`
reports). `cheater_menu` recorded twice on the unchanged code: 13 of 13
identical. After the closing (`tools/check.sh`: 496 scripts, 0 failed; a
smoke set of 18 cases first, the title, the game over, the menu pages, the
automap, the stores, the bless page, the riddles, the Cheater and the game
pad lost menu: 322 of 322 identical), `c42after` vs. `c42base`: 8,096 of
8,096 shots identical (the Cheater's 13 on `MenuList` among them), all 428
logs identical, the same script error, error and exit leak lines in every
case (only the five `effects_*` cases print a leak report, as before). A
run of 18 cases that cover every removed flag with
`--legacy=title,game_over,menu_list,menu_frame,menu_text,status,deck,
automap,dim,bless,riddle` vs. `c42after`: 318 of 318 shots, logs and error
lines identical (a removed name is ignored). No tolerance, no difference.
The frame rate was not measured: only legacy paths and dead code were
removed, and the node paths that normal play runs are unchanged (the
Cheater, dev only, draws one `MenuList` instead of its legacy list). Only
`c42after` is kept in `tools/parity/out`.

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

**Prepared after closing phase 4.2 (2026-11-07).** What 4.3 touches, and
what checks it (counts as of the closing):

* **Input:** `src/input` (6 files, 573 lines): `GameAction`'s three
  behaviours, the keyboard and game pad managers (`InputKeyBoardManager`,
  `InputGamePadManager`, `GamePadController`, the lost pad's overlay),
  `FakeInputManager`; read through `gameActions[…]` at 130 places in 22
  files. AutoPlay presses the actions, so every parity case runs the input
  path: a wrapper over InputMap, with AutoPlay injecting
  `Input.parse_input_event`, must keep every shot and log line (key repeat
  included: the menu and store cases hold buttons). Seeded runs read no pad
  (`GameCore.init2`). No step B needs it; step C of every converted mode
  does (decision 3).
* **The `Game` autoload:** `Organizer` (289 lines), `GameCore` (175),
  `GameMode` (417), `GameModeQueue`, `ResourceLoader`; 49
  `Organizer.getOrganizer()` calls in 17 files. Every case's log has the
  mode and place at each shot (`mode=`, `place=`), so parity checks the
  registry and the switches; the developer console's jumps (`goto`, the
  Cheater, `--start`) go through `Organizer.jump_to`.
* **Audio:** `src/sound` (3 files, 335 lines: `SoundPlayer`, `OggStreamer`'s
  intro and loop, its fades). Parity runs are `--mute`: no case checks it.
  A log of the music and sound calls (name, time, fade) before and after,
  and the user listening, are the checks.
* **Saves:** `Save` (284 lines) and `Load` (489); 49 shipped `.sav` files
  under `maps/Banks` (13 at its top, 28 older ones in `testStarts`), and the
  tickets' saves, which the user edits by hand: the text format is a
  working tool. Deterministic runs read the shipped files
  and write `user://saves_deterministic/`: every `--load` case checks
  loading, `store_church_save`, `menu_start_save` and
  `title_continue_autosave` check saving and the slot dates. The format
  (JSON, a Resource, or the text kept with a schema) is a decision for the
  user.
* **Order inside 4.3:** the input wrapper and the autoload first (parity
  checks them; step C needs the wrapper), audio and saves after a decision
  each (neither changes a picture).

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
    counts, since damage waits on `isDestroyed()` (or a timer: waits may be
    off by about 100 ms, 12);
  * a `SphereMesh` + `OmniLight3D` for the sphere systems;
  * emission points baked from the enemy frame for Shatter.
  * It exposes signals `impact` (= `isDestroyed`), `ready_for_next`
    (= `isReady`) and `finished` (= `isDead`), which replace the polled
    flags. About 40 effects need hand work.
  *Done for the particles (6.12):* the effects drawn as particles are
  GPUParticles3D (`EffectParticles3D`) while the legacy packets keep the
  logic and, with a 64-particle pool, the waits (within about 0.1 s); the
  settings stay in code. The spheres, the image and slow systems and the
  enemy colour are still to do, and so are the Resource presets, the effect
  scenes and the signals (step C).
* **Weather front pass** goes away once the battle shares the depth buffer.
* **Riskiest code change:** `Vector3f` is a reference type with `*Local`
  mutators, and card code relies on the aliasing (`Fire.gd:66`).
  Replacing it with the value type `Vector3` must be done per call site.

**Prepared after closing phase 4.2 (2026-11-07).** How a battle draws
today, what the closing left for it, and the order:

* **The frame.** A battle is the labyrinth's `labDrawable`
  (`Labyrinth.drawExtra`). After the floor's scene and the weather's back
  pass, `BattleManager.draw` draws, through the 3D bridge's chunks: the
  enemies (`BattleEnemy.draw`: textured quads with the slice, the colour,
  the shake and rise, their particle systems), the info panels
  (`Creature3D`: text drawn into a texture through a 2D `Graphics`), then
  `Battle.drawBattle` with the depth test off (COTZ-011): the deck (`GLDeck`,
  `GLCard`: 3D quads), the hand (`GLHand`), the legend (`Legend.draw`: a
  gradient and six lines), the card effects (`Animation`: the GPU particles
  of 6.12; the spheres, image and slow systems legacy), the attack text
  (`AttackText`); the clock (`Clock.draw`: "Fleeing" with `drawWithShadow`,
  the time bar) and an enemy's attack name (`Attack.draw`,
  `drawWithShadow`) are 2D text among those chunks. Then the weather's
  front pass (`show_weather_over`), the minimap (the 3D bridge's, 8.4), the
  mission and the dialog, and the battle's 2D top layer
  (`BattleManager.drawTopLayer`): an enemy's red flash
  (`BattleEnemy.drawTopLayer`: `fadeOldSchoolColorWhite(.8, 0, 0, .5)`), the
  result screen (`ResultScreen.drawResult`: `fadeOldSchool(.5)`,
  `resultBack.png` at 1.1, `drawWithShadow` and `drawValueWithShadow` at
  size 26, the played cards: `AbstractCard.drawCard`), the spoils screen
  (`SpoilsScreen.drawSpoils`: the same background, lines over their
  shadows, a `LevelUpBar.draw` per character), the legend's button icons
  (`Legend.drawTopLayer`), the tutorial (phase 3's node); last the mode
  fade, "Paused" and "game pad lost" (nodes).
* **What the closing of 4.2 kept for it** (9.2, "Closing phase 4.2"), by
  caller: `Graphics.drawWithShadow` (`ResultScreen`, `SpoilsScreen`,
  `Attack`, `Clock`), `drawValueWithShadow` (`ResultScreen`),
  `AbstractCard.drawCard` (`ResultScreen`), `Graphics.fadeOldSchool`
  (`ResultScreenBase.drawBackground`), `fadeOldSchoolColorWhite`
  (`BattleEnemy`), `LevelUpBar.draw` with drawImage's percent part
  (`SpoilsScreen.drawBars`). Nothing of `MenuNode`, `MenuHand`,
  `MenuScrollBar` or `Deck`: the battle's decks, hand and scroll bar are
  its own (`AbstractDeck`, `GLHand`, `BattleScrollBar`), and the game pad
  lost menu over a battle is a `MenuList` already.
* **What 4.2 built that the top layer can reuse:** UI nodes in the frame's
  order after the labyrinth's dialog's slot, as the riddles' (ARCHITECTURE
  section 14): `ShadowText` (a line over its shadow, in a colour), the Fade
  node on UI (the result dim; the flash is `fadeOldSchoolColorWhite`'s
  colour at its alpha), `LevelBar` (`resultBack.png` at 1.1 as its legacy
  quad; the level-up bars' parts through `place_image_part`), `CardView`
  (`AbstractCard.place_at`), `MenuBackground` images (the legend's icons).
* **The rest** (the rollout): the 3D view (`Battle.tscn` under the camera
  rig, above), the info panels, the legend's and the clock's 2D text among
  the 3D chunks (a UI node before a 3D chunk turns that chunk into a
  SubViewport at its layer, ARCHITECTURE section 12; check the 1/255 of 8.3
  first), the effects that are not particles, then step C (signals,
  Tweens).
* **Which first: 4.4, starting with the top layer (recommendation).**
  * It continues the work of phases 3 and 4.2 with their tools (UI nodes in
    the frame's order, twins, flags, parity at tolerance 0) and their
    nodes: a pilot of the result and spoils screens, the level-up bars, the
    red flash and the legend's icons needs few new nodes and ends four of
    the five helpers 4.2's closing kept (`drawWithShadow` stays for the
    clock and the attack name until the 3D part).
  * 4.4 is the largest and riskiest phase left (XL: the bridge, the waits,
    `Vector3f`); phase 5, the minimap's node (8.4) and the last `--legacy=`
    flags (`battle_effects`, `effect_waits`) all wait for it. Starting it
    early brings its risks up early.
  * 4.3 changes no picture and has no step B: it can come at any time
    (14). Its input wrapper is needed for step C, whose timing decision 3
    leaves open; its audio and saves need the user (no parity check, a
    format decision). If step C of the converted modes comes first, the
    input wrapper (and with it the autoload) should come first instead.
  * Coverage to check first: the level-up screen has no case (HANDOFF);
    `battle`, `boss`, the `dungeon_battle_*` and `effects_*` cases show
    battles, and a probe would tell which shots show the result and spoils
    screens.

**Results of the pilot (phase 4.4, `docs/phase4_4_prompt.md`; conventions in
docs/ARCHITECTURE.md section 15).** Step B for the battle's 2D top layer: an
enemy's red flash, the result screen, the spoils screen with its level-up
bars, the legend's button icons, with the nodes of phases 3 and 4.2 (no new
scene); the legacy battle keeps the state, the input and the timing.

* **Baseline** (on a16c172b): `tools/check.sh` 0 failed (496 scripts);
  goldens of the 428 cases (`c44base`, 8,096 shots), identical to the closing's
  `c42after` shot for shot, log for log and in every case's error and leak
  lines (3 script errors, 2,421 errors, the exit leak reports of the five
  `effects_*` cases). Recorded from a project copy with 4 jobs.
* **Facts** (deliverable 1; the probe over every case), where they add to or
  differ from the prompt and the entry above:
  * Two callers. `BattleManager.drawTopLayer` runs from `Labyrinth.drawExtra`
    (after the mission and the dialog; a boss's words are the dialog) and from
    `BossBattleArea.drawExtra` (Serphia, Menthu, Memory Salmonman: 7 cases;
    after the area's dialog). A boss area's battle 3D is all SubViewport
    chunks (it sets no `use_scene_3d`); its weather (`battleBacks.*`) never
    runs: no place has a `particles` entry.
  * The clock is never drawn: `Clock.draw` has no caller (the Java's
    `Battle` neither), so "Fleeing" and the time bar of the entry above do
    not exist; `drawWithShadow` stays for `Attack.draw` alone.
  * The order: each object's top layer (the enemy's flash; the rows draw
    nothing there), then the result screen (RESULT) or the spoils screen
    (SPOILS), the legend's icons, the tutorial; after it the floor's
    top-layer items (none in any probed battle frame) and the mode fade.
    Overlaps, over every probed frame (not only the shots): the flash (12 or
    13 frames: the 200 ms hide of a critical hit, during ANIMATE) is drawn
    over the whole battle, the attack texts included, and never with a
    screen; the legend's icons are drawn every frame, at x 10 while it shows,
    −190 while hidden (−209 before its first show: `instantHide` stops a step
    past the limit), sliding 20 px an update over 10 updates; they are over a
    screen only in the frames after the console's `kill` on a party turn (the
    spoils screen comes at once and the icons slide out over its dim, bright
    over the dimmed legend gradient: 7 frames in `battle_spoils`; in play the
    legend has slid out before a screen comes); the tutorial is drawn over
    the icons (`tutorial_battle`, 176 frames); "Paused" (Transition) over a
    result screen. The party's red screen is not here: `Character3D.draw`
    draws it in the battle's 3D (below, the rollout).
  * State changes in the draws, all kept by the twins in order: the flash's
    `glColor4f(.8, 0, 0, .5)`, the white fade image's bind,
    `glColor4f(1, 1, 1, 1)`; `fadeOldSchool(.5)`'s colour (the fade colour,
    white, at .5) and the fade image's bind, `setColor(1)`, the background's
    bind; `setFontSize(26)` (it keeps the font: plain in every probed
    frame); each `drawWithShadow`: black text, `setColor(color)`, the line's
    colour, `setColor(color)`; `drawValueWithShadow` the same with the value's
    colour when it is above 0, else white; the cards' binds (picture, balls);
    the bars' lazy creation and `LevelUpBar.update`'s percent (read only by
    the bars' drawing: no game state), `LevelUpBar.draw`'s
    `setImageColor(1, 0, 0, 1)` at a class's last level, its three binds,
    `setColor(1)`; the legend's `setColor(1)` and six binds. No draw of the
    top layer changes game state.
  * What the top layer starts from: the minimap arrow's colour
    `(1, .85, 0, 1)` in a labyrinth (white, or the colour an effect left, in
    a boss area); the alpha test `GREATER 0` (the enemy's draw leaves it),
    `GEQUAL .01` (a blended effect's `endBlend`) or `GREATER .1` (the
    weather's front pass), as the riddles met; the blending
    `ONE_MINUS_SRC_ALPHA`; the font size 24 or 40 and black or white text
    (the legend's and the deck's lines); the fade mode black with a white
    fade colour (the image fade of Menthu1's defeat shows no screen). Every
    part sets its own colour; the nodes take `canvas_material()` where their
    part was drawn, so they inherit the alpha test (text edges below it are
    dropped as before). What it leaves: the colour white and
    `Graphics.color` 1 (the legend's `setColor(1)`), the size 26 after a
    screen, the last line's text colour, the last icon bound; the next frame
    sets its own before it draws.
  * Text: size 26, plain, at alpha 1 (`drawString`); every line over its
    shadow (1 px down and to the right, black). The result screen's values in
    red (attack, magic) or green (support; a total of 0 or less, as its
    absolute value), 0 in white; the spoils screen's names white, green
    after a level up, red when dead; "Max level" and "0 exp" red.
  * The dropped item ("You found <item> laying on the ground!") cannot be
    shown: no enemy in `enemyBank.bank` has a `dropdata` line (nor the
    Java's data), so `dropRate` is 0. `getSpoils` still draws a
    `J.random()` for every non-boss battle (the "<enemy>drop" status is −1,
    not 0). The console's `drop` (dev) gives the battle's enemies drop data.
  * "Level up!" when the experience exactly fills the bar: `calcSpoils`
    levels a character up only when the experience exceeds what is left
    (`gottenExp <= cnext`, as in the Java), but `LevelInfo.update` shows
    "Level up!" once the bar is full; the level up comes with the next
    battle's experience (the probe's first `battle_spoils`: Kin 1 point
    short got 1). Kept (original); the case gives him 0 left instead.
  * A character's bar at the last level of a class: red and full, "Max
    level" and "0 exp" in red; reaching that level in the battle: "Level
    up!" in green over the red bar (COTZ-003's path).
  * Scaled and partial images: the background `resultBack.png` at 1.1 (a
    scaled-up image: drawn as its legacy quad, a `LevelBar`, plan 12); the
    played cards at 0.7 (scaled down: `CardView`'s TextureRects, as the
    menu's); the bars' parts at 1:1 (200 × 20 from 165 × 25 images, the
    percent of the width: `LevelBar` quads); the icons at 1:1.
* **Coverage.** The probe (prints in `BattleManager.drawTopLayer` with the
  caller, the mode and the 2D state, the flash, the result screen's team,
  values and cards, the spoils screen's step and each character's state, the
  legend's x and slide, the tutorial, the state the top layer leaves, the
  labyrinth's or area's frame, the enemy's hide timer, the party's hidden
  creatures, the attack name, the clock, "Paused", "game pad lost" and
  AutoPlay's shot) over every case: 27 old cases draw a battle; the result
  screen in 65 shots of 13 cases (the `effects_*` cases and `boss`: one
  enemy, or the party after support cards), the spoils screen in 10 shots of
  the 6 `dungeon_battle_*` cases (its gold line, and the end after CROSS
  skipped ahead: no level up, "Max level", death or drop), the flash in one
  shot (`effects_offense_3/c_020`), the legend's icons in 159 shots and
  sliding in 18, the tutorial over them in 3, no "Paused" over a battle.
  Four new cases (161 shots): `battle_result` (Berca's Ogre, Ogre, god mode,
  the console's `cast`: an attack on one enemy with the other's zeros, magic
  on both, three cards in the played row, support on the party in green,
  "Paused" over a result screen, the legend sliding out and in frame by
  frame, the support legend; then the spoils screen at its steps),
  `battle_spoils` (the console's `exp`: Kin at the last level but one of his
  class with 0 to the next, Celis at the last level; the icons sliding out
  over the spoils screen frame by frame, then a shot every 100 ms: each step,
  Kin's "Level up!" over his red bar, Celis's "Max level", Zalzi's plain
  experience), `battle_spoils_skip` (Kin 1 short of a level, Zalzi killed by
  the console's `heal -100000`, the console's `drop`: CROSS at the gold line
  skips to the end, both bars filling, Kin's level up and his bar starting
  again, Zalzi's red name, "You found Healing Potion …"), `battle_flash`
  (Critical Blow 3: seed 1 lands a critical hit on the first and the second
  cast, 0.88 s and 0.58 s after them: both flashes frame by frame). Goldens:
  `c44gold` (432 cases, 8,257 shots; the old cases identical to `c44base`,
  logs and error lines too), `c44gold2` (the new cases again: 161 of 161
  identical, logs and error lines too). `battle_result` prints the exit
  leak report of the console's `cast` cards (7 objects, as the `effects_*`
  cases; `battle_flash` casts too and prints none).
* **Built** (ARCHITECTURE section 15): no scene; the bridge members
  `Graphics.show_fade_colour_white` (fadeOldSchoolColorWhite: a Fade node's
  colour), `place_value_with_shadow`, `ResultScreenBase.show_background`,
  `shadow_lines`, `value_lines`, `LevelUpBar.place`, the twins
  `ResultScreen._show_result`, `SpoilsScreen._show_spoil`, `_show_bar`,
  `Legend._show_icons` and the flash's in `BattleEnemy.drawTopLayer`; flags
  `--legacy=battle_screens`, `battle_flash`, `battle_legend`; the console's
  `exp` and `drop` (dev).
* **Parity** (tolerance 0 everywhere; the final code, 432 cases, 8,257
  shots; the node run is `c44node`; "the battle cases": the 31 cases that
  draw a battle, by the probe, 1,331 shots):
  * golden (`c44gold`) vs. nodes, every case: 8,257 of 8,257 shots
    identical, all 432 logs identical, the same error lines in every log (3
    script errors, 2,421 errors; the exit leak reports in the five
    `effects_*` cases and `battle_result`);
  * each flag alone (`--legacy=battle_screens`, `battle_flash`,
    `battle_legend`) vs. nodes and vs. the golden on the battle cases: 1,331
    of 1,331 each, logs and error lines identical;
  * every flag on (`--legacy=battle_screens,battle_flash,battle_legend`,
    every case) vs. the golden: 8,257 of 8,257, all logs and error lines
    identical (the legacy paths and the frame without the nodes are
    unchanged); vs. nodes on the battle cases: 1,331 of 1,331;
  * the new cases recorded twice: 161 of 161, logs and error lines
    identical.
  * No tolerance was needed, and there was no difference on the way: the
    first node run (a smoke set of 8 battle cases, 367 shots) was identical.
* **No legacy 2D left:** a run of the 31 battle cases with prints in
  `Graphics._drawText` and `_emit2D` while `BattleManager.drawTopLayer`
  draws found no legacy text or quad in 49,189 top-layer frames with the
  flags off (with the three flags on, the same prints counted 4,450 texts and
  14,255 quads in `battle_result` alone).
* **Frame rate** (normal runs: no `--seed`, windowed, one at a time, the
  shipped saves (`APPDATA` a scratch folder); Berca Desert--South, god mode,
  the console's `cast` and `kill`; AutoPlay's `fps=` every 0.5 s for 11 s on
  each screen, the first second dropped; legacy (the three flags) → nodes,
  median and range):

  | Where (normal runs meet random enemies: the runs below met Ogre and Ogre) | Capped | Uncapped |
  |---|---|---|
  | The result screen (Battle Card 1 on an Ogre: the dim, the background, 15 lines over their shadows, one card) | 60 → 60 | 289 (282–292) → 286 (280–331) and 286 (277–290) |
  | The spoils screen (its end: 9 lines, three bars) | 60 → 60 | 306 (299–309) → 358 (350–367) and 312 (296–319) |

  The other runs met other enemies (legacy, a Stitchman: 327 and 304 on the
  result screen, 318 and 305 on the spoils screen; nodes, one Ogre: 309 and
  326). The battle's 3D under the screens costs most of the frame (about
  3.3 ms); the top layer's legacy drawing (18 to 30 text draws and 9 to 17
  quads a frame, the icons' six included) is within the run-to-run spread: no measurable change on the
  result screen, at most a small gain on the spoils screen.
* **Still legacy** in a battle: the state, the input and the timing (step C:
  decision 3; decision 6 for the legend's slide, the bars' counting, the
  steps); the `drawTopLayer`/`drawResult`/`drawSpoils` methods (the twins
  run there); the whole 3D part with its 2D text (the rollout, below). The
  helpers closing phase 4.2 kept (deliverable 3): `Graphics.drawWithShadow`
  is still called by `Attack.draw` (the attack name, drawn among the 3D
  chunks; and by `Clock.draw`, which nothing calls) and by the legacy path
  of `--legacy=battle_screens`; `drawValueWithShadow`,
  `Graphics.fadeOldSchool`, `fadeOldSchoolColorWhite`, `AbstractCard.drawCard`
  and `LevelUpBar.draw` (with drawImage's percent part) only by the legacy
  paths of the three flags. When phase 4.4 closes, `AbstractCard.drawCard`
  and `LevelUpBar.draw` lose their last caller (legacy classes: delete them);
  `drawValueWithShadow`, `fadeOldSchool`, `fadeOldSchoolColorWhite` and the
  percent `drawImage` (`GameTexture.drawPart` with a percent below 1) become
  `Graphics`' API only, which phase 5 deletes; `drawWithShadow` keeps
  `Attack.draw` until the rollout's texts.
* **Found on the way:** `Clock.draw` has no caller (the plan's "Fleeing" and
  time bar); no enemy can drop an item; "Level up!" shows without a level up
  when the experience exactly fills the bar (both original: Appendix); the
  party's red screen is drawn behind the near plane (the rollout's table
  below). The legend's icons are drawn after the screens, so in the frames
  after the console's `kill` they slide out bright over the spoils screen's
  dim (as legacy). The probe per frame, not per shot, found the overlaps
  (CONVERTING_UI). Afterwards only `c44node` was kept in `tools/parity/out` (the
  baseline, the golden and the check sets were deleted after their
  compares).

**Prepared after the pilot (2026-11-11): the rollout, the battle's 3D.** What
`BattleManager.draw` draws, part by part, in the frame's order (a survey of
the code after the pilot; line counts are of the drawing involved). Every
part is drawn under the 3D projection with its own `loadIdentity` (eye
space, the camera at the origin), at z −2 (`STANDARD_Z_DEPTH`; the enemy at
its `.enemy` depth); `Battle.drawBattle` draws the deck, the hand and the
legend without the depth test (COTZ-011), the effects with it, the attack
texts without. In a labyrinth the 3D bridge puts the battle's 3D drawn
before the frame's first 2D into the floor scene's World3D (it shares the
depth buffer, the fog and the linear blending with the walls, 7.5); the
first 2D is the attack name when it shows, else the deck's text, else the
legend's text (always drawn), so the cards, the hand, the effects and the
attack texts are SubViewport chunks composited in sRGB after it. A boss
area (Serphia, Menthu, Memory Salmonman) sets no `use_scene_3d`: all of its
battle is SubViewport chunks.

| # | Part | What it draws | State it changes in the draw | 2D among it | Size |
|---|---|---|---|---|---|
| 1 | The enemy (`BattleEnemy.draw`, `drawSlice`) | its frame (`drawTex`) at its depth, shaken and risen (`translate`), in `usedColor`; while an effect slices it (`destroyEnemySlice`) two quads, the top one sliding (`xs`), at alpha `life` | `life -= sliceFade`, `xsSpeed`, `xs`, `test1`/`test2` per draw; alpha test on (`GREATER .1`, left at `GREATER 0`: never turned off) | — | ~100 lines |
| 1b | Its particle systems, the attack name (`Attack.draw`: `AttackBackground`'s quad, then the name), the enemy's card (`EnemyCard`: an identity quad) | the systems (GPU nodes, 11); `attackBack.png`; the name with `drawWithShadow` at size 46 twice (a black copy 3 px off, then white over its shadow) | `Attack.pos += SPEED` per draw (the name's slide); `ParticleSystem.gpu_state` per draw; `endBlend` leaves the depth mask off | the attack name: the frame's first 2D when shown | ~40 |
| 2 | The info panels (`CharacterRow`, `EnemyRow`, `CreatureRow`, `Creature3D`, `Character3D`, `Enemy3D`, `ProgressBar`) | the row's gradient; per creature its portrait (`drawTex`), the progress bar (`emptyBar`, `white.png` tinted blue/green/red to the percent, `overlay`: `Utils3D.draw3DPart`), the info texture (name, "Elem:", life drawn into an Image by `GraphicHelp`: `updateTexture` when `Battle.update_`), the element icon, the boosts' cards | `progressBar.update` (its percent) per draw; the info texture rebuilt in the draw; `setColor(.75)` for an inactive creature (also `Graphics.color`); the info, element and boosts tinted by the colour the bar leaves `(1, 1, 1, a)` | — | ~150 |
| 2b | The party's red screen (`Character3D.draw` while a critical hit hides a party member) | `setImageColor(.7, 0, 0, .5)`, `drawImage` of a 1024 × 768 white image at (0, 0) | `loadIdentity` (the row's later characters drawn at z 0) | a 2D image drawn under the 3D projection at z 0, behind the near plane (1): never visible (the Java too; no probed frame) | 5 |
| 3 | The deck (`GLDeck`, `AbstractDeck`, `GLWeapon`, `GLSlot`, `WeaponModeIcon`, `GLCard`) | the weapon's slots and mode icon, the deck's balls and "save" image, the cards (two-sided, rotating), the hand pointer (`hand2.png`), a gradient and the deck's texts (the card's name at 34, the count at 50, its info and "Deck" at 24, at the mode's fade value) | `GLSlot.draw` calls `update()` (the slot's flip advances per draw: `rotation`, `currentList`, `rotateDone`); `setAlphaFunc(.5)` around the cards, then 0 | the deck's texts | ~140 (33 of text) |
| 4 | The hand (`GLHand.draw`) | `hand1.png` at the target, turned for the party | — | — | 7 |
| 5 | The legend (`Legend.draw`, every frame, off the screen while hidden) | a gradient, six lines twice (black at the fade value, then white 2 px up and left) | — | its lines | ~33 |
| 6 | The card effects (`Animation.draw`) | the systems (GPU nodes); still legacy: the spheres (Demolish: `gluSphere`, lit), the image and slow systems (Death, Slow: sprites), the enemy colour system (Elements) | the image and slow systems start their coroutine on their first draw (it fades, switches images and calls `plainDestroy`: the battle waits on it); Slow moves its particles; the enemy colour sets `usedColor` (the enemy, drawn earlier, takes it a frame late) | `Animation.draw` draws the attack texts too: twice per frame during ANIMATE (the Java too) | ~150 (effects) |
| 7 | The attack texts (`AttackText.draw`) | damage, "Miss!", "Critical Hit!": 2D text at the screen point of an eye-space position (`draw3DText`), in its colour at its `life` | — (`life` changes in `update`) | all of it | ~30 |
| — | The clock (`Clock.draw`: "Fleeing", the time bar) | nothing: no caller (the Java neither) | | | — |
| — | `BossBattleArea`'s weather (`battleBacks.*`) | nothing: no place's info has a `particles` entry (main.bank's only one is a comment) | | | — |

Also in the draw: in TALKING mode `drawBattle` calls `manager.setDialog`
every frame (in a labyrinth `drawDialog`: the dialog's `setDS` and the
minimap's and mission's `pushState`, once a frame; as in the Java); the
first frame's `initDraw` draws stray quads (`GLSlot`, `EnemyCard`,
`AttackBackground`). `ScrollBar.gd` (`BattleScrollBar`) has no user.

* **What the 3D bridge does today:** the battle's 3D is GLBackend's
  geometry: rebuilt as ArrayMeshes every frame, in the floor's world up to
  the first 2D, in SubViewports after it; the effects' GPU nodes are
  `show_node` nodes in the current chunk. The texts are GLBackend's 2D
  canvas items between those chunks.
* **The 2D text among the 3D chunks** (the attack name, the deck's and the
  legend's lines, the attack texts): a UI node before a 3D chunk turns that
  chunk into a SubViewport at the node's layer (ARCHITECTURE section 12),
  composited in sRGB, where today the 3D after the first text is a
  SubViewport on LegacyLayer. A text made a UI node while legacy 3D still
  follows it lifts that 3D, and everything the frame draws after it (the
  weather's front pass, the minimap's batches), to the UI layer, in chunks
  laid out differently: parity would have to show that unchanged. Text in the 3D scene instead (`Label3D`, or
  Controls placed with `Camera3D.unproject_position`) needs the 3D around
  it converted first. The other way round has the same problem: 3D moved
  out of its chunk into the floor's world (the plan's `Battle.tscn` under
  the camera rig) is drawn under every 2D text of the frame, also the texts
  that were drawn before it (an effect or the hand over the deck's or the
  legend's lines today would go under them). Recommended for step B: each
  3D part as nodes in the chunk and slot where its batches were
  (`Graphics.show_node`, as the effects' GPU particles and the minimap's
  `MinimapPart`), which keeps every chunk boundary and the boss areas'
  SubViewports; the texts as nodes after the 3D around them is converted;
  `Battle.tscn` under the rig (and a camera of its own in a boss area,
  which would change the boss areas' sRGB compositing: a look change) once
  nothing of the battle is legacy, with step C.
* **The minimap's 1/255 (8.3):** the bridge's pool instances that drew the
  minimap render a battle's batches 1/255 apart from instances that did
  not. Moving some of a battle's batches to nodes while others stay on the
  bridge changes which pool instance draws which batch: expect 1/255 on the
  battle's remaining legacy batches (and on later battle frames) even where
  the converted part is exact; compare the frames after the change, explain
  a 1/255 by the pool before blaming the node, and prefer converting a whole
  chunk's content at once. Once no battle batch is left on the bridge, the
  minimap's node (`--minimap-node`) can be the default (8.4). *Part 1 found
  the mechanism: the differing pixels are the floor's walls, whose tied
  surfaces Godot's sort reordered with the rest of the list; they are drawn
  in a fixed order now (below).*
* **Coverage** (the pilot's probe, 31 battle cases): the enemy, the info
  panels, the deck, the hand and the legend in every battle shot; the
  attack name in 144 shots of 14 cases; the effects in the `effects_*`
  cases; the slide of the legend frame by frame (`battle_result`), a
  critical hit's hide (`battle_flash`); the inactive creatures' 0.75 tint on
  every other creature's turn. To probe before the rollout (the pilot's
  probe did not print them): the enemy's slice (an effect's
  `destroyEnemySlice`, `ParticleSystem.update`), a haste or slow bar, the
  boosts' cards and the element icons on a panel, a slot's flip (R2) frame
  by frame, the deck's shuffle (`animate.init("Shuffle")`: a deck that runs
  out), a boss's TALKING frames (the `dungeon_boss_*` cases page them). Not
  reachable: the enemy colour system (the neutral Elements card fails in
  `ResultScreen.calcResult`, as in the Java), the party's red screen, the
  clock. Write the missing cases first, on the unconverted code. *Done in
  part 1 (below): `battle_enemy`, `battle_panels`, `battle_enemy_rise`.*
* **Order and sizes** (S ≈ a session):
  1. The enemy (`show_node` in its chunk and slot): its frame as a quad
     with its texture (an `AnimatedSprite3D` later), the slice as a shader
     or the two legacy quads, the colour, shake and rise mirrored from the
     legacy values (step B: the coroutines and the slice's per-draw steps
     stay in the twin). With it the coverage cases of the whole 3D. M.
     *Done (part 1, below): the quads as they were (an `EnemyView` mesh),
     not an AnimatedSprite3D or a shader yet.*
  2. The info panels: portraits, bars (a quad with a percent uniform), the
     info texture (a SubViewport with Labels, or the legacy Image kept as a
     texture first), elements, boosts. M.
  3. The deck and the hand: two-sided card quads, slots and the mode icon
     mirroring `GLSlot`'s rotation (its `update` in the draw stays in the
     twin), the deck's balls and pointer. M–L.
  4. The legend's gradient, the rows' gradients. S.
  5. The texts among the chunks: the attack name, the deck's and the
     legend's lines, the attack texts (UI nodes or `Label3D` once the 3D
     around each is nodes; then `Battle.tscn` under the rig). M.
  6. The effects that are not particles: the spheres (`SphereMesh` and a
     light), the image and slow systems (sprites; their coroutines stay),
     the enemy colour. M.
  7. Then the minimap's node (8.4), the closing of 4.4 (the flags, the
     legacy drawing, `battle_effects` and `effect_waits`), step C (signals,
     Tweens; decisions 3 and 6) and phase 5.

**Results of the rollout, part 1 (phase 4.4, `docs/phase4_4_rollout_prompt.md`;
conventions in docs/ARCHITECTURE.md section 15, "The battle's 3D").** The
coverage of the whole battle 3D, then the enemy's frame and slice through
step B: an `EnemyView` node in the chunk and batch slot of its batch; on the
way, the floor's walls drawn in a fixed order (its own change, decided by
the user).

* **Baseline** (on d53546be): `tools/check.sh` 0 failed (496 scripts); the
  432 cases (`e0base`, 8,257 shots) identical to the pilot's `c44node` shot
  for shot, log for log and in every case's error and leak lines. Recorded
  from a project copy with 4 jobs.
* **Facts** (deliverable 1; a headless probe over the 31 battle cases and
  the new ones: `[cov]` prints of each part's batches, their chunk, index
  and merges, the enemy's render state, its frame, visibility, slice, shake,
  rise and colour, the panels' bars, boosts and elements, the slots' turning,
  the shuffle, the mode; per-frame checks over about 55,000 battle frames),
  where they add to or differ from the prompt and the table above:
  * One `BattleEnemy` per battle draws the image; a group's other enemies
    are logic only (`Battle.fillIdling`).
  * The enemy's batch is the first of its chunk in every frame but a
    battle's first: on a floor the scene chunk's batch 0 (the floor's scene
    and the weather's back pass are nodes of the scene, not batches), in a
    boss area the first SubViewport's; on a battle's first frame
    `initDraw`'s stray quads (`AttackBackground`, `EnemyCard`'s three, two
    per `GLSlot`) come first. Nothing merges into it (the attack background,
    another texture, follows); the slice's two quads are one batch.
  * Its render state: never additive or opaque; depth test and write on;
    back faces culled; unlit (lit only in a boss area's first frame); the GL
    fog only on the floors with fog (Forest Path, the frozen floors,
    Pensara; the prompt had it on in every labyrinth); the alpha test as the
    previous frame left it (`GREATER 0`, `GREATER .1` or `GEQUAL .01`; the
    table's "left at `GREATER 0`" is what the enemy's own draw leaves). It
    starts from `loadIdentity`, `translate(shakeoffx, shakeoffy + risey,
    depth)`, `setColor3(usedColor)`; it leaves its texture bound, the last
    texture coordinate (`(left, top)`; the slice's `(0, test1)`) and the
    colour (the slice's at alpha `life`), then `loadIdentity`.
  * `usedColor` is the floor's enemy colour (.7 Grivera and Forest Path, .8
    Forest of Bri, 1 Berca and the boss areas) and fades while an enemy
    attacks; the Elements card's colour system stays unreachable.
  * The shake is along x only (`shakeoffy` is never set: `mode %= 3`): attack
    frames with `s=true` and Earth's and Colliding's hits, 1 s. The rise is
    Menthu's alone (`menthuattack.enemy`'s `r=`). The slice lasts 90 frames
    (1.5 s) from Destroyer's hit; a hit hides the enemy 12 frames (200 ms).
  * `AttackBackground` and `EnemyCard` are drawn every frame (off the
    screen while hidden), not only while the attack name shows.
  * The chunks: on a floor the scene chunk holds the enemy, the attack
    background, the enemy's card, both rows and the deck's 3D up to the
    deck's text (the frame's first 2D); while the attack name shows only the
    enemy and the attack background (the rest in SubViewports). The
    weather's front pass and the minimap come after the battle's 3D, in a
    SubViewport (in the scene chunk only in frames without battle 2D). The
    character row is 15 to 25 batches, the enemy row 1 to 9.
  * TALKING frames (a boss's words) were shot already (`boss`,
    `dungeon_boss_salmonman`, `image_fade_menthu1`, `effects_area_*`,
    `effects_menthu_flame`): the enemy and the rows (hidden) are drawn,
    nothing of `drawBattle`. The deck's shuffle (`initNewRound` with an
    empty deck) is ANIMATE for 125 frames with the "Shuffle" text.
* **Coverage** (deliverable 1): `battle_enemy` (265 shots: the enemy hidden
  and shaken by Earth's hit and sliced by Destroyer, frame by frame; an
  Ogre's attack frames, the attack name and a hidden party member),
  `battle_panels` (303: the weapon's slots flipped and back frame by frame,
  haste and slow bars, Focus's and Shield's boost cards, discards until the
  deck's owner shuffles), `battle_enemy_rise` (93: Menthu's rise frame by
  frame, a boss area); no new console command. The enemy in the scene chunk
  with snow (the frozen floors), rain (Forest Path, Pensara) and none
  (Berca, Grivera, Bri), the element icons (three elements) and a boss's
  words were in the old cases. Goldens of the 435 cases on the unconverted
  code (`e1gold`), the new ones twice: identical (661 shots).
* **The enemy (step B, ARCHITECTURE section 15):** `scenes/battle/EnemyView`
  (a MeshInstance3D) draws the frame's quad or the slice's two in eye space
  (`Graphics.eye_points`, `eye_normal`, the colour at the draw) with the
  material of the render state there (`Graphics.material_3d`), shown through
  `Graphics.show_node` in the chunk and slot of the enemy's batch (keyed by
  the enemy's instance id: kept from frame to frame, freed when the enemy is
  not drawn). The twins `BattleEnemy._show_frame` and `_show_slice` make the
  drawing's state changes in order (the binds, the last texture coordinate,
  the slice's `xsSpeed`, `xs`, `test1`, `test2`, its colour at `life`, the
  matrix push and pop). Flag `--legacy=battle_enemy`.
* **The 1/255 and the walls.** Golden vs. node on the battle cases: 26 of
  1,992 shots differed by 1/255 (frozen field 5, frozen forest 5, the
  Tunnel 2, `image_fade_menthu1` 13, `tutorial_battle` 1), all on the
  floor's walls, the enemy identical in every shot. Experiments (each on the
  battle cases): the enemy's slot taking its pool instance (hidden), so that
  every later batch keeps its instance: 3 left; that instance kept visible
  with an empty mesh: the same as the plain node (on 3 cases); the walls'
  surfaces as one instance each in a fixed order: legacy and node identical
  (1,992 of 1,992), and the golden differs from that in 816. The mechanism:
  the walls are one instance with a surface per material; the shader writes
  `ALPHA`, so Godot sorts them in its transparent pass per instance (depth
  minus `sorting_offset`) with an unstable sort whose result depends on the
  whole render list; the surfaces tie (the instance's depth), so a frame
  with other instances, or the same ones in another cull order, reorders
  them, and where two overlap (a wall's edge on the floor, a corner) the
  pixels change. 8.3's minimap node and likely 7.7's objects did the same.
  Decided by the user: the walls are drawn in a fixed order
  (`DungeonFloor.show_walls_in_order`: an instance per surface,
  `WALL_SORTING_STEP` 0.001 apart, after a prototype look's `floor_built`;
  `walls_instance` keeps the whole mesh, hidden). That is the surfaces'
  order (the order the display list first used their materials), not
  exactly GL's, which interleaved them quad by quad.
* **The walls' change, new goldens** (`e2gold`, 435 cases, 8,918 shots)
  vs. `e1gold`: 1,686 shots in 179 cases differ, every differing pixel on a
  floor's walls, floors or roofs (also the floor in the menu's screenshot
  and behind the pause, a pad's loss, a tutorial or a dialog); 1,679 by
  1/255, 3 by 2/255 (the menu's scaled screenshot, a turn in Pensara's
  prison), 4 by 27–29/255 (`dungeon_tour_temple_of_aegis_second_floor` and
  `_third_floor`, both saves, the frame mid-step backwards: translucent
  surfaces in the dark opening, where the order changes the blend, not only
  the rounding). Logs, exit codes and error lines identical.
* **Parity on the new goldens** (tolerance 0; node run `e2node`, 435 cases,
  8,918 shots; 3 script errors, 2,421 errors and 12 exit leak lines, as the
  baseline): golden vs. node identical (every shot, log and per-case error
  and leak line); the new cases recorded twice identical (661);
  `--legacy=battle_enemy` vs. the node run and vs. the golden on the 34
  battle cases identical (1,992); all four phase 4.4 flags vs. the golden on
  every case identical (8,918); with `--legacy=battle_effects` added, vs. a
  golden with it, on the battle cases identical (1,992). With prints in
  `Graphics._emitTriangles` while the enemy draws (headless, the 34 battle
  cases): flag off 47,903 enemy frames, 47,903 node calls (all under the 3D
  projection) and no legacy emission; flag on no node call and 48,059
  emissions (one quad a frame, two in the 156 slice frames).
  `--minimap-node` vs. the node run on the battle cases: identical (1,992;
  8.3's 1/255 is gone).
* **Frame rate** (normal runs: no `--seed`, windowed, one at a time, the
  shipped saves; `fps=` every 0.5 s for 11 s at a party turn, the first
  second dropped; legacy `--legacy=battle_enemy` → node; random enemy
  groups): capped 60 → 60 on a floor (Berca Desert--South) and in Serphia's
  boss area; uncapped on the floor 301, 293, 293 → 289, 306, 297, in the
  boss area 365, 422, 340 → 364, 420, 352: within the run-to-run spread.
* **Surprises:** the 1/255 was not the bridge's pool but the walls' tied
  surfaces (above); the probe copy's first patch had a parse error that made
  four headless runs exhaust the machine's memory (two hard lock-ups): the
  copies' `tools/check.sh` comes first now, and a watchdog kills a copy's
  runaway Godot (HANDOFF).

**Prepared after part 1 (2026-11-13): part 2, the info panels.** Plan 9.4's
order holds (the enemy's results change neither the order nor the place):
with the walls in a fixed order a part's slots move nothing on the screen,
so `Graphics.show_node` in the chunk and slot of each batch stays the place
until the 3D around the texts is nodes; `Battle.tscn` under the rig with
step C. What the panels draw (`CharacterRow`, `EnemyRow`: `CreatureRow.draw`
per creature): the row's slide (`Hideable`) and gradient
(`Graphics.drawGradient`: untextured, black from the top alpha to the
bottom; the enemy row's height by its creature count), then per
`Creature3D`: the tint (`setColor(.75)`, alpha .2, when the creature is not
active and not a support target; .7 else), the portrait (`drawTex`; a party
member with the turn translated and scaled), the progress bar
(`progressBar.update` in the draw; `emptyBar`, `white.png` tinted blue,
green with haste, red with slow at the alpha, to the percent, `overlay`:
`Utils3D.draw3DPart`), the info texture (rebuilt in the draw when
`mustUpdateText`: name, "Elem:", life in an Image, `GameTexture.updateImage`;
red under 20 % or dead), the element icon (bound, but drawn with the info
texture's coordinates: original), the boosts' cards (`Cards/<n>.png`; the
enemy's scaled .9 and moved). The party's red screen is never visible
(Appendix). Lessons for it: a node with several overlapping batches must not
be one instance with several surfaces (they would tie like the walls did):
one instance per legacy batch, each in its own slot (`show_node` per batch,
as `MinimapPart`), or one surface where the batch was one material; probe
which panel quads merge into one batch; keep the info texture's Image as the
node's texture first. Coverage still to write: a creature's life under 20 %
(red), the rows sliding in at a battle's start frame by frame, a group of
three enemies (the enemy row's height), a dead party member's panel during a
battle, the info texture's update frames. Size M.

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
* Data equivalence: `verify_dungeons.gd`, `verify_world_map.gd`
  (`verify_villages.gd` was removed with the village converter, 6.9).
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
  *Relaxed (2026-10-27):* the timer may be off by up to about 100 ms; a
  smooth, frame-rate independent effect matters more than exact waits.
  *Applied (6.12):* not a timer: the legacy system keeps a pool of at most
  64 particles whose counts decide the waits (within about 0.1 s of the
  legacy waits, measured), and the GPU draws the whole effect.
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
  *Phase 4.4's rollout:* the floor's walls were one instance whose surfaces
  tied (its depth): their order changed with the rest of the list, 1/255
  where two overlap, whenever a change moved other instances (the battle's
  pool, the minimap's nodes: 8.3's 1/255 for certain, likely 7.7's). They are
  drawn as one instance per surface in a fixed order now (9.4); a mesh of
  several surfaces that overlap one another needs the same.
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
* **UI nodes in the legacy frame** (phase 3). A node on UI or Transition is
  ordered among GLBackend's canvas items by their draw index, and the legacy
  2D after it is moved to its layer; a node of a lower layer shown after one
  of a higher layer in the same frame would be drawn under it (GLBackend
  warns). Godot sets a node's draw index from its tree index when it enters
  the tree or moves; GLBackend sets it again whenever it shows the node, so
  other nodes added to UI or Transition must be shown through
  `Graphics.show_ui` too while legacy drawing remains.
* **Godot's transforms round differently** (phase 3 rollout). A node under a
  Camera2D or a Node2D transform puts a quad's corners a few ulps away from
  the legacy drawing's CPU transform: small textures under a cutscene zoom
  differ by up to 2/255 (the emotion bubbles: they draw the legacy quad).
  Step C, with real cameras, gives this up.
* **History in the 3D bridge** (phase 3 rollout). Drawing the minimap's
  batches with nodes instead of the bridge's pool instances leaves every
  frame that draws it the same, but the pool's instances then render a later
  battle's batches 1/255 apart (8.3). Compare the frames after a change, not
  only those that show it. *Phase 4.4's rollout:* the differing pixels were
  the walls', reordered by Godot's sort (above), not the battle's batches;
  fixed with the walls' order (9.4).
* **A Control's culling rect** (phase 3 rollout). Godot culls a Control by
  its size from its position; text drawn outside that rect (a
  `BaselineLabel` at a baseline off the screen) vanished: check new nodes at
  the screen's edges.
* **Memory during recordings** (phase 4.1). An 8-job recording leaves
  about 3 GB of the 16 GB free; four more windowed runs beside it made
  runs fail at random (a crash in AutoPlay's `get_image`, WebP textures
  that did not decode, both with identical shots once re-recorded). Run
  nothing windowed beside a recording, and check the error lines of every
  log, not only the shots. *4.2's menu:* not even a headless shot compare
  (`diff_shots.gd` over 4,000 shots): it did the same to eight runs. *The
  stores:* the free memory at idle varies with what else runs (7 GB with
  the other programs of that day): an 8-job recording crashed 11 runs in
  `get_image` (exit 139), one more logged WebP decode errors, one failed to
  start. Check the free memory first and record with fewer jobs (5); count
  each log's error lines against the last set. *The mini-games:* 5.5–6 GB
  free at idle; five full recordings with 4 jobs (about 23 minutes for 427
  cases) had no failed run.
* **Disk during recordings** (4.2's stores). A full set is 5.3 GB (7,674
  shots) and `tools/parity/out` had grown to 290 GB of old sets, the disk to
  96%: a task needs four or five full sets at once (baseline, golden, nodes,
  every flag on) besides two project copies. Delete a task's intermediate
  sets once compared, and old sets when they are not needed. *Done
  (2026-11-07): every set older than the stores' node run `st2node` was
  deleted.*
* **Parts of images through AtlasTextures** (4.2's stores). A TextureRect
  with an AtlasTexture of a part of an image (the level bars' ranges) drew
  the image's antialiased edges 1–5/255 apart from the legacy quad (up to
  17 on one pixel), though the quad, the texture coordinates and the colour
  were the same; whole images in TextureRects match to the bit. Draw such
  parts as the legacy quad (`LevelBar`, as `EmotionBubble`). Note too: an
  AtlasTexture whose region has width 0 draws the whole texture. *4.2's
  mini-games:* whole images scaled up (the riddles' at 1.12, 1.2 and 1.7) as
  TextureRects of `place_image`'s rect were 1/255 off on a few pixels (18/255
  on one) in 132 of 348 riddle shots, where images scaled down (the menu's
  cards) and at 1:1 match; drawn as the legacy quad (a `LevelBar` part of
  percent 1) they are exact.
* **Generated scenes edited by hand** (phase 4.1). The editor saved three
  village scenes in 4b74ade3; the converter no longer reproduces them and
  `vil_to_scene.sh --all` overwrites them. Re-convert one place at a time
  and keep hand edits out of generated scenes (or in the data they come
  from). *Since 6.9 the village converter is gone, and since 7.9 and 9.1
  the dungeon and world map converters too: every scene is edited by hand,
  and this risk is gone with them.*
* **Curves that only look like paths** (phase 4.1). A road's `Path2D` curve
  is the road's data: editing it in the editor changes where the player
  walks (`Road.addCoordinates` builds the line from its points), but
  nothing moves along the curve, and bezier handles are ignored until step C.
* **Text at other window sizes** (phase 3). Godot rasterizes a Control's
  text at the window's scale; the legacy text is rasterized at 1024 x 768
  and scaled. `BaselineLabel` keeps the legacy look (`oversampling` 1);
  sharper text in full screen is a look change (13, decision 8).
* **Pooled UI nodes outlive their modes** (phase 4.2). A whole 2D mode's
  parts are UI nodes pooled by GLBackend (ARCHITECTURE section 14): they
  stay, hidden, after the mode is left, with the textures last given (the
  title and the game over: about 7.5 MB). The menu pages and the stores
  would keep a node per page and store; release large textures when hidden
  if that grows.
* **Premises about what is 3D** (phase 4.2). The prompt of 4.2 expected the
  stores' and the menu's cards as 3D chunks; they are 2D images. Check a
  mode's drawing (`set3D`, `glVertex3f`, `drawImage`) before planning its
  chunks.
* **Theme lookups that cannot fail** (phase 4.2's menu). `Theme.has_font_size`
  and a Control's `has_theme_font_size` are true for any type while the
  theme has a default font size, and a label whose type variation the
  theme lacks is drawn at that default (24): the deck page's help line, at
  the size 20 the card info leaves, came out at 24. Look up a type's own
  entries (`Theme.get_font_size_list`, `MenuText.role`); the pilot's
  `MenuList` had the same check (never hit: its sizes had roles).
* **The Java's 32-bit floats** (phase 4.2's mini-games). The port computes
  every `float` in 64 bits. A value the Java steps in a loop until a bound
  (`fade += .1f` until `>= 1`) can take one step more in GDScript (the
  riddle's fade: 11 updates to 1.1 where the Java took 10 to 1.0000001), a
  port bug that changes the picture and the timing. Where the count of
  steps matters, round each step to a 32-bit float (`RiddleGame._toFloat`),
  as its own change with new goldens before a conversion.
* **Shared legacy helpers** (phase 4.2's menu). The menu and the stores call
  the same static helpers (`MenuNode.draw`, `StatusPage.drawTop`,
  `Deck.drawDeck`, `StartPage.drawInfo`, `drawMenuBackgroundStatic`):
  switching inside them would convert the stores' drawing with the menu's,
  untested. Twins go beside them, and the converted mode's call sites
  switch. *Closing phase 4.2 (9.2)* removed them once no caller was left;
  the ones the battles still call stay until phase 4.4 (9.4).
* **Callers that cannot run** (closing phase 4.2). A legacy helper can look
  shared while its only other callers are unreachable (the status and
  bestiary pages, opened only from themselves) or dev-only (the Cheater's
  list): a survey of callers must say which can run, and a dev mode that
  draws through the helper needs a shot before it moves to the twin.
* **A removed flag is silently ignored** (closing phase 4.2).
  `Main.is_legacy` answers only for names the code asks about: a run with a
  removed `--legacy=` name is a normal run and would "pass" a parity check it
  no longer makes. Keep the flag lists in ARCHITECTURE section 7 current.
* **Drawing that never shows** (phase 4.4's pilot). The plan listed the
  clock's "Fleeing" and time bar among a battle's parts: `Clock.draw` has no
  caller (the Java neither). The spoils screen's dropped item needs drop
  data no enemy has, and the party's red screen is a 2D image drawn under
  the 3D projection behind the near plane. Check that a drawing can show
  (a caller, the data, a probe line in some frame) before planning its node
  or its case; dev state (the console's `drop`) can still cover a twin.
* **Overlaps between shots** (phase 4.4's pilot). Which parts overlap is a
  question about frames, not shots: the legend's icons slid out over the
  spoils screen only in the frames after the console's `kill`, and no shot
  showed it until a case shot those frames. Print the probe per frame and
  look for coincidences over all frames.

## 13. Open decisions

1. **Village variants:** inherited scene per `.vil` (recommended: maps 1:1 to
   today's file choice) vs. one scene per place with per-node status filters
   (fewer files, harder to see a single variant). *Decided (phase 1
   rollout):* one inherited scene per `.vil` variant on a shared base
   scene, as in the pilot. *Not applied to the world map (4.1):* one scene
   per `.map` file; its night is a layer shown when the map loads at night
   (9.1).
2. **Dungeon lighting:** exact fixed-function look (shader) vs. Godot lights
   (more modern, slightly different). *Applied for the pilot (phase 2):*
   the exact look: GLBackend's spatial shader as a ShaderMaterial with the
   style's values. It also kept the emulation's glColor bug (7.5); *the
   rollout applied it to every floor and fixed that bug and the misplaced
   sky in both paths (7.8).* The Godot-lights variant was not tried.
   *Phase 4.4's rollout:* the walls' surfaces are drawn in a fixed order
   (one instance each; 9.4, decided by the user): where two overlap the
   pixels no longer change with the rest of the frame (1/255).
3. **Step C timing:** accept changes in movement and collision feel (and fix
   the speed TODOs) right after step B, or only after every mode is on
   scenes.
4. **Resolution:** keep the 1024×768, 4:3 virtual screen (recommended for
   now; menus, battle and dungeons assume it). Scenes make widescreen
   villages possible later.
5. **Text formats:** delete them after conversion (recommended) or keep them
   as an export format. *Decided (2026-11-06):* delete them. The `.vil` and
   `.map` files are deleted with the closings of phases 1, 2 and 4.1 (6.9,
   7.9, 9.1; the git history has them). The text formats that were not
   converted (`.char`, `.seq`, `.bank`, `.help`, `.tut`,
   `particleSystems.info`, `.trig`, saves) stay the data.
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

   *Decided for particles (2026-10-27):* today's speeds, updated every
   frame with the frame's delta (smooth at any frame rate, in line with the
   rest of the game). The speeds: the village and cutscene systems and the
   card effects as they look at the original's 30 steps/s
   (`Values.originalFrameStep`, commit 6dad0c75, which made them feel
   right); the dungeon weather and the save points as they look at 60 FPS
   (one step per frame; they never had that correction). Every per-step law
   becomes a per-second rate at its system's step rate; the 30 Hz steps stay
   only in the `--legacy` paths. A battle may wait up to about 100 ms more
   or less than today for an effect (12). Other motion (2.5's list without
   the particles) is still open.
   *Applied (particles phase, 6.10):* the village and cutscene systems run
   their laws at 30 steps a second as per-second rates, every frame, for
   the game time the legacy system is updated for.
   *Applied (6.12):* the dungeon weather and the save points run their laws
   at 60 steps a second as per-second rates, every frame the legacy system
   is updated in; the card and enemy effects at 30 steps a second, every
   frame, for the game time their packet runs; the waits within about 0.1 s.
   *Not needed for 4.1 (9.1):* the world map's walk and the airship's flight
   stay legacy (per `J.currentTimeMillis()` step and per update); their
   views mirror the positions. *Not needed for 4.2's pilot (9.2):* the
   title's logo (.005 per update) and the mode fades (per drawn frame) stay
   legacy; the nodes mirror them. A Tween for them is step C. *Not needed
   for the menu (9.2):* the flying cards (`DeckPage.Animator`, 2 px per ms)
   and the saving box's dots (`Scheduler` timers) stay legacy; the nodes
   mirror them. *Not needed for the stores (9.2):* the Church's blessing
   swing (`Church.update`: per update, its speed × .95), its saving dots
   (`Scheduler.sleep`), the markers' moves (per update while held) and the
   Inn's seven seconds after a rest stay legacy; the nodes mirror them.
   *Not needed for the mini-games (9.2):* the riddle's fade (.1 up and .12
   down per update, now in 32-bit steps as the Java's) stays legacy; the
   nodes mirror it. A Tween for it is step C. *Not needed for 4.4's pilot
   (9.4):* the spoils screen's steps (a `Scheduler` tick every 700 ms), its
   bars' counting (per update), the legend's slide (0.1 per update) and the
   enemy's 200 ms hide stay legacy; the nodes mirror them. *Nor for the
   rollout's enemy:* its frame, shake, rise, colour and slice stay legacy
   (coroutines, the slice's per-draw steps in the twin); its node mirrors
   them each frame.
7. **Village top layer** (from the pilot, 6.7): *decided (phase 1
   rollout):* roofs and treetops are always drawn (6.1, the pilot's
   default). The legacy rule draws a piece only where a sprite overlaps it,
   and the PNG pieces differ from the JPEG background under them, so the
   villages look slightly different where no sprite is near a roof or
   treetop. `--legacy=village_top_layer` kept the legacy rule for parity
   runs until phase 1 closed (6.9).
8. **UI look** (from the phase 3 pilot, 8.1): the `TODO.md` UI items
   (replace the papyrus font, a vertical Yes/No, the papers that look "not
   in world", text running out of the paper) and sharper text in full screen
   (`BaselineLabel.oversampling` 0) change the look; the pilot kept the
   legacy look so that parity holds. Each is a theme or scene edit now.
   Open (the rollout kept the legacy look too, and so did phase 4.1, 4.2's
   pilot, the menu, the stores, the mini-games and 4.4's pilot and its
   rollout's first part).

## 14. Suggested order and size

Sizes are relative: S ≈ a focused session, XL ≈ many sessions.

| # | Phase | Size | Depends on | Unlocks |
|---|---|---|---|---|
| 0 | Groundwork: bridge, parity tool, `ARCHITECTURE.md` | S | — | everything |
| 1 | Villages + cutscenes + village particles + SpriteFrames. *Done and closed (6.9).* | L | 0; decisions 1, 6 | editable villages |
| 2 | Dungeons + weather + minimap. *Done and closed (7.9); the minimap stays the 3D bridge's (8.4).* | L | 0; decision 2 (the weather: 6) | editable dungeons; FPS fix (with decision 6) |
| P | Village and cutscene particles on the GPU (6.4; `docs/particles_prompt.md`). *Done (6.10); closed with phase 1 (6.9).* | M | 1; decision 6 (decided for particles) | Dellna's snow back on; Home of the Gods and Dellna at 60 FPS |
| P2 | Dungeon weather, save points and the card and enemy effects that are particles, on the GPU (6.11). *Done (6.12); the dungeon part closed with phase 2 (7.9), the battle effects' legacy path stays until 4.4.* | M | 2, P | rainy and snowy floors at 60 FPS; battles without the effects' stalls (Wind 3 at 7 FPS, the Flame's 10 s) |
| 3 | Theme, Dialog, signs, emotions, fades, HUD. *Done through step B: the pilot (8.1: the Theme, the dialog family, the fade) and the rollout (8.3: emotions, mission display, pause overlays, cutscene images and texts, tutorials; the minimap stays the 3D bridge's); closed (8.4).* | M | 1 (or 2) | most of the remaining `draw(g)` |
| 4.1 | World map + airship. *Done through step B (9.1): the scenes, the name plate, legacy vs. scene identical; closed (9.1).* | M | 1 (converter), 3 | — |
| 4.2 | Title, game over, mini-games, stores, menu. *Done through step B (9.2: the pilot, the menu, the stores and the mini-games, one session each) and closed (9.2, "Closing phase 4.2").* | L | 3 | — |
| 4.3 | Input, audio, saves, `Game` autoload. *Prepared (9.3).* | M | any time after 0; the autoload is best after 4.2 | 5; step C (the input wrapper) |
| 4.4 | Battle, cards, effects. *The pilot, the battle's 2D top layer, done through step B (9.4: the result and spoils screens, the level-up bars, an enemy's red flash, the legend's icons); the rollout, the battle's 3D: part 1, the enemy, done through step B (9.4: `EnemyView` in its chunk's slot; the floor's walls drawn in a fixed order); next the info panels.* | XL | 2, 3 | 5; the minimap's node (8.4) |
| 5 | Remove the GL emulation; per-delta time | M | all of the above | — |

After phase 2, P comes before phase 3 (2026-10-27): the particle
simulation makes Home of the Gods (6 FPS with the god systems) and Dellna's
snow (12–18 FPS) unplayable, and P and phase 3 do not depend on each other.
P2 can follow at any time. The card effects are part of 4.4 (the battle
waits on them, 12); with the waits relaxed to about ±100 ms they may move
earlier, as GPU effects or a per-frame interim: P's last deliverable
assesses that. *P is done (6.10); the assessment and P2's preparation are
in 6.11. P2 is done, with the effects that are particles (6.12).*

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
  * *Found in phase 4.2:* `StatusPage` and `BestiaryPage` are opened only
    from themselves (`MainMenu.initStatusPage`/`initBestiaryPage`; the
    Java's StartPage has no entry for them either); `menu/Help.gd` is never
    instantiated; `CardStore.drawMergedCard` is never called; no map uses
    `RotatePuzzle`; the Church's "Resurrect" branch has no menu entry.
    *Removed when phase 4.2 closed (9.2):* the two pages (`BestiaryPage`,
    `MainMenu.initStatusPage`, `initBestiaryPage`, `checkEnemyInRange`;
    `StatusPage` keeps only the twins of its static helpers), `drawMergedCard`
    and the "Resurrect" branch (`initResurrectMenu`, `fillResurrect`). Kept:
    `Help.gd` (draws nothing), `RotatePuzzle` (data could use it).
  * *Found in phase 4.2's menu:* the start page's Load path (`executeNode`'s
    "Load" and a slot under another list than Save: `Load.loadGame`,
    `exitTo`) has no entry: the Java's `fillRoot` inserts Save under
    `if (true)` and Load only in its dead `else` (the port inserts Save), so
    the menu never fades; `TutorialPage.drawHelp` is never called (its call
    is commented out in the Java); `MapPage.drawAll`'s `g.scale(3)` before
    its `pop` does nothing (as in the Java).
* **Latent bugs:**
  * The particle kinds `rainparticle` and `sandparticle` have no class in
    `ParticleFactory`, so they create null bodies. The same bug is in the
    Java original. It never runs: `Home of Celisnode1.seq` only lists
    `rainCelissystem` (`load particleSystem=`, a name in a list), and its
    `fadeparticlesystem` line is commented out; no sequence runs
    `fadeparticlesystem` or builds a rain or sand system (checked in the
    phase 1 rollout).
  * `HelpPage`'s volume options never match (9.2).
  * *Found in phase 4.4's pilot (as in the Java):* `Clock.draw` has no
    caller, so a battle never shows "Fleeing" or its time bar (the clock's
    time is not counted either: `timesUp` is always false). No enemy can drop
    an item: `enemyBank.bank` has no `dropdata` line, so the spoils screen's
    "You found …" is never shown, while `getSpoils` draws a `J.random()` for
    every battle won (the "<enemy>drop" status is −1, not 0). The spoils
    screen shows "Level up!" when the experience exactly fills the bar, but
    `calcSpoils` levels up only when it exceeds what is left (`gottenExp <=
    cnext`): the level up comes with the next battle. The party's red screen
    of a critical hit (`Character3D.draw`: a 1024 × 768 image at (0, 0)) is
    drawn under the 3D projection at z 0, behind the near plane, so it never
    shows, and its `loadIdentity` puts the row's later characters at z 0 for
    the 150 ms (by reading; no case has a critical hit on the party). In
    TALKING mode `Battle.drawBattle` calls `setDialog` every frame (in a
    labyrinth the minimap's and the mission's `pushState` once a frame).
  * *Found in phase 4.2's stores:* selling the last entry of a Weapon Store
    sell list that has more entries (Slot 1's fifth weapon) refills the
    list with the cursor kept, past its new end; `WeaponStore.updateCurrent`
    then reads the child at the cursor (`getCurrentChild`): two script
    errors in the port (an index out of bounds, then a call on null), where
    the Java's `ArrayList.get` threw. The list's next draw moves the cursor
    back (`MenuNode.draw`'s fix-up), so the store goes on. Not a port bug
    (the Java's `fillEquipment` keeps the cursor too); `store_weapon_sell`
    sells that weapon (its two errors are in the goldens). A fix: reset or
    clamp the cursor in `fillEquipment`, or check the size in
    `updateCurrent`.
  * *Found in phase 4.2's stores:* the card store's "Can't merge that
    card." (`CANT_MERGE`) cannot be reached: the merge deck holds only the
    kinds that can be merged, so every card of it confirms (as in the
    Java).
  * *Found in phase 4.2's stores (cosmetic, from COTZ-005):* the Church's
    save list puts its entries 72 px apart for the date under each slot
    (`SaveSlots.MENU_DISTANCE`; the Java's 41), so Slot 3's date and "Back"
    run past the bottom of piece 14 (y 322) onto the background
    (`store_church_save`'s shots). A layout fix (a shorter distance, a
    taller piece) changes the look: decision 8, or a ticket.
  * *Port bug (found in phase 4.2):* `RiddleGame.fade` steps by .1 in a
    64-bit float, so the fade-in stops at 1.1 after 11 updates; the Java's
    32-bit float stops at 1.0000001 after 10. The riddle's dim is then
    1.1 × its image's alpha (.33 for .3), its colour's alpha 1.1 (clamped)
    and Grivera's text alpha 1.1, and the fade-out takes one update more.
    *Fixed (phase 4.2's mini-games, before their conversion, with new
    goldens):* each step is rounded to a 32-bit float as the Java computes
    it (`RiddleGame._toFloat`); the fade-in ends at 1.0000001 after 10
    updates, the fade-out after 9 (9.2, "Results of the mini-games").
  * *Found in phase 4.2's mini-games (an original bug, kept):* `Puzzle`
    scrambles its tiles in `AbstractPuzzle.init` before its own `init` sets
    the free slot, so the 500 swaps start from a free slot at (0, 0) (its
    first swap exchanges two tiles that are not neighbours); `init` then
    takes the image off whichever tile ended at (N − 1, N − 1) and declares
    that the free slot. The Java does the same (`Puzzle.init` after
    `super.init`). The puzzle is then solvable or not by chance (a
    transposition changes the permutation's parity). A fix: set the free
    slot before scrambling (a ticket: it changes the puzzles' layouts).
  * *Found in phase 4.2's mini-games (as in the Java):* "Paused" stops
    nothing but the play time (`Time`): `GameCore.testDraw` draws the
    overlay over the mode, which keeps updating and reading input (a riddle
    goes on fading in under "Paused"; with "game pad lost" up, the menu's
    DOWN also moves a puzzle's cursor and its CROSS reaches the puzzle).
  * `VillageStoryTimeLine` calls `updateFadeValue()` in both `update` and
    `draw` (`:262-265`, `:602-604`), so its fades may step twice per frame.
    *Checked (phase 3 rollout):* the Java does the same
    (`VillageStoryTimeLine.java` `update` and `draw`): not a port bug.

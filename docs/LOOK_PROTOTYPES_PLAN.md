# Look prototypes: an HD labyrinth and a 16-bit labyrinth

Two optional looks for one or two labyrinth floors, built to compare
directions before committing to one:

* **HD:** a modern high-resolution look: PBR materials, real lights and
  shadows, moving volumetric fog, particles, a sky, post-processing, in two
  art directions (painted and photographic). In battle, the enemies become
  lit sprites or rigged 3D models, the Boar first.
* **Pixel:** a 16-bit look at 512×384, UI included, made two ways: (a) a
  pixelating render path over the current art, and (b) art converted to
  pixel art.

Neither changes the default game: both are dev switches (section 3).
Status (2026-11-03): **step 0 done; first passes of PX1–PX3, HD1 and part
of HD2** (section 10, "As built"). The open questions were decided the same
day (section 9) and are worked into the sections below. The first review
of the HD look (2026-11-04: embers, light leaks, flat walls) is in 10.6,
its tuning panel (F2) in 10.7, and the panel's per-floor defaults in 10.8.
A heat haze over the frame (for hot places) is in 10.10.

## 1. What the code does today

* **Renderer:** Forward+ (`project.godot`), 1024×768 with `canvas_items`
  stretch. The 3D renders at the window's resolution, and the 2D is scaled.
  Volumetric fog, `FogVolume`s, SDFGI, VoxelGI, LightmapGI, SSAO, SSIL, SSR,
  glow and the Compositor are all available without changing the renderer.
* **A floor** is a `DungeonScene` (`scenes/dungeons/`):
  * `Layout` (`DungeonFloor`): one flat quad per wall, floor and roof
    (4 units a side), with one surface per legacy material.
  * `Objects`: flat quads drawn in the legacy batches.
  * `Weather`: GPU particles.
  * `Rig/Camera`.
* **Materials:** `DungeonMaterials` makes `unshaded` ShaderMaterials from
  `dungeon_gl.gdshaderinc`. These are GLBackend's fixed-function light
  (light0 at the camera), material and exponential fog, kept exactly
  (decision 2 of `docs/MODERNIZATION_PLAN.md`). Textures are sampled
  `filter_linear` without mipmaps.
* **Camera:** it stays at the origin, and `DungeonScene.show_view` gives
  `Layout`, `Objects` and `Weather` the legacy modelview (for pixel parity).
  Two things live in eye space at the origin:
  * the sky quad (`top_level`);
  * the 3D bridge's `Legacy` node (the battle, the minimap).
* **Textures:**
  * Walls, floors and roofs are 512×512: about 190 files in
    `res/Labyrinth/{Walls,Floors,Roofs}`. Object images (`Images/`) are up
    to 408×569.
  * Three walls already have normal maps, left over from the original's
    bump-mapping experiment: `aegiswall0normal.png`, `forestwallnormal.png`
    and `southpasswallnormal.png`. `LabyrinthTexture` loads
    `<name>normal.png`, but nothing draws it. `res/Shaders/` holds the
    experiment's test maps.
* **Battle:**
  * The legacy code draws the battle through the 3D bridge into the floor's
    World3D, in eye space: the enemies at z = `depth` (−6), and the cards,
    bars and texts in front of them.
  * An enemy is a painted quad (`BattleEnemy.draw`): 3–9 frames about 650 px
    tall, each with a baked drop shadow (`res/Battle/enemies/<name>/`).
  * `attackSpec` lines (`maps/Battle/EnemyMaps/*.enemy`) are keyframe lists,
    for example `(f=1,a=330)--(f=2,h=true,a=800)`. Each entry gives a frame
    (`f`) and a time in ms (`a`), and can add the hit (`h`), a sound (`se`),
    a card effect (`c`), a shake or a rise.
  * `BattleEnemy.attack` walks the list as a coroutine and sets
    `currentList` (the frame shown). At rest the default frame shows. There
    is no idle animation.
* **Dev switches:** `Main._parse_args` reads the command-line options
  (`--legacy`, `--no-encounters`, …), and `scenes/debug/GameCommands.gd`
  holds the console commands. AutoPlay reaches both (`console <line>`).

## 2. The prototype floors

* **The Great Mine--Tunnel** (indoor):
  * rock between wooden beams (`minecavewall.png`), with a roof;
  * a chest, a button, a villager, a door and a hinder door;
  * enemies: Goblin (humanoid), Bat, Hexaroc.

  A cave shows torch light, dust and fog at their best.
* **Forest of Reil--Forest Path** (outdoor, the game's first labyrinth):
  * stone walls topped with grass, rain, a sky instead of a roof, fog;
  * a door, a hinder door and a save point;
  * one enemy: Boar1 (a quadruped);
  * `forestwallnormal.png` already exists.

Both were the phase 2 pilot floors, so their parity cases (tour, door,
battle) exist and can shoot each look. To start one:
`-- --load="Slot 1" --start="The Great Mine--Tunnel-mark0"` (or
`--start="Forest of Reil--Forest Path-mark0"`), or use the console's `goto`.

## 3. How the looks are reached

The recommended switch is a dev option, like the existing ones:

* **`--look=hd-painted`**, **`--look=hd-photo`** or **`--look=pixel`**
  (after `--`). Main stores it as `Main.look`, which is `&"legacy"` by
  default.
* **Console `look <legacy|hd-painted|hd-photo|pixel>`:** applies from the next floor entry
  (re-enter with `goto` or `teleport`); switching live is a later nicety.
  AutoPlay can use it (`console look pixel`), so one tour script shoots all
  three looks.
* **Fallback:** a floor without prototype content keeps the default look,
  so the rest of the game still plays with the flag on.
* **Content lives in `res://proto/`** (`proto/hd/…`, `proto/pixel/…`):
  * The shipping export excludes `proto/*` (the Windows preset's
    `exclude_filter`).
  * So game code must reach it only through `load()` behind the flag:
    never `preload`, and no `class_name` from `proto/` named in game code.
    A script that names a class the export left out compiles from source
    but fails only in the exported build.
  * The hooks go through a small base class in game code (`DungeonLook`,
    `scenes/dungeons/`). The implementations live in `proto/hd/HDLook.gd`
    and `proto/pixel/PixelLook.gd`.
* *Decided:* the command line and the console are enough: no prototype
  export preset and no menu entry. (Should a build ever be handed out with
  the looks, an export preset with a feature tag `proto` that includes
  `proto/*` is Godot's equivalent of a compile-time flag.)

**Guard:** without `--look`, nothing changes. To show it:

* `tools/check.sh` reports 0 failed;
* the `dungeon_*` and `battle*` cases compare identical with goldens
  recorded before step 0.

The prototype looks get no parity cases. They differ from the default by
design.

Where the code branches:

| Where | default | `hd-*` | `pixel` |
|---|---|---|---|
| `DungeonScene.show_view` | the modelview on `Layout`, `Objects`, `Weather` | the camera moves (`Rig` = the modelview's inverse, the floor at identity); the eye-space parts become children of the camera | as default |
| After `DungeonFloor.build` | the GL materials | each surface's material swapped by legacy texture name (an `HDMaterialSet` resource), tangents generated | textures nearest-sampled or swapped for pixel versions; banded light and fog |
| The floor's scene | `scenes/dungeons/<Area>/<Floor>.tscn` | `proto/hd/dungeons/<Area>/<Floor>.tscn` if it exists: an inherited scene that adds lights, fog volumes, particles, props, an environment | as default |
| `Main._sync_world` and the window | the scene under `World`, the frame at the window's resolution | as default | the whole frame rendered at 512×384 (5.1) |
| `BattleEnemy.draw` | the painted quad | skipped while an `EnemyView3D` shows the enemy | as default, or pixel frames |

The prototype scenes inherit the floor scenes, which are edited by hand
since the dungeon converter and the `.map` files were deleted
(MODERNIZATION_PLAN 7.9): keep the node names the prototype scenes refer to.

## 4. Mode 1: HD

*Decided:* two art directions, both built on the same code. The material
swap of 4.1 takes one material set per direction, and only the textures
and a few scene parts differ. The UI stays as it is in both.

* **Painted (`hd-painted`):** the legacy textures repainted in detail by an
  image model (6.2, 6.3), with normal, height, roughness and AO maps
  generated from them. This direction stays close to the painted enemies
  and portraits.
* **Photographic (`hd-photo`):**
  * Surfaces of one material (the mine's floor and roof, the forest's
    stones and ground) use photographic CC0 PBR sets from Poly Haven and
    ambientCG. They come complete with normal, roughness, AO and
    displacement maps, and I can fetch them through the sites' public
    download APIs.
  * Where a legacy texture combines materials, the parts become geometry.
    The mine wall is a rock set, and the beams of `minecavewall.png` (posts
    at the wall's edges, a top beam, two braces) are boxes in a wood set,
    built by the floor from its layout. This is a first piece of the kit in
    4.4.
  * Doors are an image model's photographic repaint, with generated maps.
  * The sky is an HDRI.

The two directions share everything else: the camera, the lights, fog,
particles, post-processing and the battle.

### 4.1 Groundwork (no new art)

1. **A moving camera.** SDFGI, VoxelGI, reflection probes, shadow caching
   and the temporal reprojection of volumetric fog all assume a still
   world. Moving the floor every frame would make the fog ghost and GI
   re-voxelize.
   * In this look, the rig gets the inverse of the legacy modelview (the
     battle's camera shake included), and `Layout`, `Objects` and `Weather`
     stay at identity.
   * The eye-space parts move under the camera: the bridge's `Legacy` node
     and the save points' eye-space meshes. The sky quad gives way to a
     real sky (4.3).
   * This is the modernization plan's step C for dungeons (7.6), applied
     only to this look.
2. **Materials.** Each legacy texture gets a `StandardMaterial3D`:
   * maps: albedo (at first the legacy texture), normal, roughness, AO, and
     height for parallax;
   * mipmaps and 16× anisotropic filtering;
   * `SurfaceTool.generate_tangents()` in the HD build.

   Before any new art arrives, the normal and height maps come from the
   existing albedo (a tool script: luminance gives height, a Sobel filter
   gives the normal; or DeepBump or Materialize). Roughness starts as one
   value per surface type (rock, wood, moss). The three existing normal
   maps are used where they exist.
3. **Light.** The legacy light0 at the camera becomes the player's light:
   * an `OmniLight3D` (or a wide `SpotLight3D`) on the rig, a little to the
     right and below the eyes, warm, flickering by noise, with shadows;
   * walls and objects cast shadows;
   * a `WorldEnvironment` with dim ambient light, the AgX (or ACES)
     tonemapper, glow, SSAO and SSIL;
   * SDFGI for bounce light, which needs no bake. If it is too slow or
     leaks, bake VoxelGI or LightmapGI per floor.
4. **Objects.** Their quads get a lit alpha-scissor material with the same
   frames, so chests and levers sit in the light.

To check it, shoot the tour in both looks and put the shots side by side
with `tools/parity/contact_sheet.gd`. Take FPS from a normal run, not a
`--seed` run.

### 4.2 Atmosphere

* **Volumetric fog** in the Environment: density, albedo, a little
  emission, and anisotropy for light shafts. Lights get
  `volumetric_fog_energy`, so the torch makes a halo and the mine's
  lanterns make shafts.
* **Moving fog:**
  * `FogVolume`s with a fog shader that scrolls a 3D noise texture over
    time;
  * ground mist in the forest, slow drifts low in the mine's corridors,
    thicker at dead ends;
  * a height falloff.
* **Particles** (`GPUParticles3D`):
  * mine: dust motes that show only where the torch lights them; drips
    from the roof that collide and splash (a sub-emitter); embers near
    lanterns;
  * forest: the existing rain as lit streaks that splash on the floor
    (`GPUParticlesCollisionHeightField3D`); falling leaves; fireflies, a
    few of them carrying a real `OmniLight3D`;
  * wind from a turbulence field or a `GPUParticlesAttractor3D`.
* **A wet forest** while it rains: lower roughness and a puddle mask on the
  floor, SSR in the puddles, an animated ripple normal map.

### 4.3 Backgrounds

* **Forest:**
  * The gradient sky quad becomes a `Sky` in the Environment: a CC0 HDRI
    (Poly Haven: overcast or rainy dusk), a painted 2:1 panorama, or a
    `ProceduralSkyMaterial`.
  * A tree line above the walls: trunk and canopy cards (alpha-scissor
    quads swaying in the wind in the vertex shader) along the outer walls,
    and a ring of layered distant silhouettes outside the floor.
  * Light shafts from a directional moonlight through the fog.
* **Mine:**
  * no sky: darkness beyond the torch's reach;
  * a few lanterns on the beams (placed in the prototype scene) and one or
    two shafts of faint light from above.

### 4.4 Geometry (optional, larger)

Normal and parallax maps go a long way, but the walls stay flat at corners
and in silhouette. Two ways past that:

* **Displaced walls.** Each wall is subdivided into a grid (for example
  16×16) and displaced by its height map in the vertex shader. The
  displacement goes to zero at the edges, so neighbouring walls meet
  without seams. Real bumps at the corners, no modelling. Cheap to try.
* **A modular kit.** `DungeonFloor` places meshes per area from the
  layout: a wall, a corner pillar or beam, a floor tile, a roof piece, at
  every wall edge and every corner where walls meet.
  * The mine's beams become real beams, and the rock bulges.
  * The forest walls get roots and moss.
  * Props are scattered by rules (dead ends, corners, long corridors).

Try displacement first. Build the kit only if the look convinces.

*Tried (10.6):* displaced walls work and cost little, sunk behind the
plane rather than raised. How they look depends on the height map, which
the brightness alone does not give (`proto/hd/tools/wall_height.gd` makes
them for both floors). Real thickness (silhouettes, wall ends) needs the
kit.

### 4.5 Post-processing and camera

* **Post:**
  * glow on lights and save points;
  * colour grading per area (`adjustment_color_correction` with a LUT);
  * a light vignette and film grain;
  * a faint far depth-of-field blur;
  * TAA or FSR2 against shimmering foliage and thin edges.
* **Camera feel:**
  * a small head bob at each step and an eased curve over the legacy
    step and turn;
  * a slight lean into turns;
  * a FOV punch with a radial blur or a shatter when a battle starts.
* **Sound** (cheap, and much of a "professional" feel):
  * a reverb bus per area (`AudioEffectReverb`);
  * footsteps per floor type;
  * ambient beds (drips, wind, rain on leaves);
  * a positional crackle on the torch.

### 4.6 Objects (optional)

* Chests, buttons and save points as 3D props:
  * the chest opens by animation (the legacy frame index decides open or
    closed);
  * the save point becomes a crystal with a light and particles.
* Doors are wall textures in the walls' mesh, so they get the PBR
  treatment with the walls.

### 4.7 Battle: enemies in 3D

The logic stays legacy, as in the modernization plan's step B. An
`EnemyView3D` mirrors `BattleEnemy` every frame, and the painted quad is not
drawn. It reads:

* the frame (`currentList`);
* the shake (`shakeoffx`, `shakeoffy`) and the rise (`risey`);
* the colour (`usedColor`);
* the slice (`slice_`, `life`) and `killed`.

The view sits under the camera at the enemy's eye-space position and size,
where the quad was, so the floor's lights (the torch) light it and its fog
covers it.

There are three tiers, cheapest first, and each enemy can use any of them:

* **A. Lit sprites (S).**
  * The painted frames get a normal map and a depth map each, generated
    with Depth Anything V2 or an image model, or from luminance.
  * A lit alpha-scissor material: the torch wraps around the goblin, with
    a rim light.
  * A real shadow on the floor (from the alpha-scissor quad, or a blob
    decal) replaces the baked one, which is removed from the frames.
  * Idle: a vertex-shader breath (a scale about a pivot near the feet,
    plus a slow sway).
  * A cross-fade between frames (about 80 ms) instead of a cut.

  A script can do this for all 44 enemies, with no modelling.
* **B. Cut-out puppet (M).** The rest frame is cut into parts (head, arms,
  weapon, torso, legs) on a few bones for idle and anticipation; the attack
  frames stay painted. It sits between A and C and is likely not worth
  doing if both of those are.
* **C. Mesh, rig and animations (L per enemy).** This is the investigation
  asked for. *Decided:* the Boar comes first, then the Goblin. The Boar is
  Forest Path's Boar1. Deep Forest's Boar has the same frames and the
  Shadow Boar the same shapes, so one model with a dark material serves
  them too.

  The Boar's frames (`image boar 4 3 1`: four frames, the fourth reusing
  the second):
  * 0, `boar1`: the rest, head low, glaring;
  * 1, `boar2`: rearing up;
  * 2, `boar3`: fully reared on its hind legs, head up;
  * 3, `boar2` again: coming down.

  Its attack is `(f=1)--(f=2)--(a=400,f=3,se=Monster/Boar/attack)`, then
  back to the rest: it rears up and slams down.
  * Poses: `rest`, `rear` and `rear_full`; frame 3 is `rear` again.
  * The slam is in the blend back to `rest`, with a short impact: a burst
    of dust at the front hooves and a shake.
  * Idle: breathing, a snort with a puff of dust from the nostrils, a front
    hoof pawing the ground, tail flicks, ear twitches, now and then a head
    toss.

  The steps:
  1. **Reference.** Clean the rest frame (no drop shadow, no white fringe).
     Ask an image model for a turnaround of the same animal in a neutral
     pose: side, front and back views on grey, with the boar standing square
     on all four legs and the goblin in an A-pose (prompts in 6.3).
     Image-to-3D tools make a cleaner, riggable model from that than from
     the crouching frames. The goblin's weapons go apart, as separate
     meshes on the hand bones.
  2. **Mesh.** Use an image-to-3D tool, with multi-view input where it
     takes it: Meshy, Tripo or Rodin (free tiers with credits), or the open
     models Hunyuan3D 2.x and TRELLIS. Their free Hugging Face demos can
     also be called through an API (6.4). Locally they likely need more
     than this machine's 6 GB RTX 3050.
     * Expect 20k–200k triangles of soup: decimate to about 10–20k.
     * These tools bake lighting into the albedo: de-light or repaint it,
       so that it lights correctly.
  3. **Rig.**
     * The Boar is a quadruped, which the free humanoid auto-riggers
       (Mixamo, AccuRIG) cannot rig. Rigify's quadruped meta-rigs in
       Blender (the wolf or the horse) fit it. First check whether the
       image-to-3D tool's own auto-rig takes quadrupeds. Blender is not
       installed on this machine yet.
     * The Goblin: Mixamo or AccuRIG (free), or Meshy's or Tripo's
       built-in auto-rig.
     * The Bat and the Hexaroc, later: by hand in Blender.
  4. **Poses.** In Blender, put each painted frame behind the model as a
     camera background image, from the battle camera's angle, and pose the
     rig to match it. That gives one key pose per frame (rest, wind-up,
     strike, cast…). Then add:
     * an idle loop (breathing, a weight shift, a twitch of the weapon;
       Mixamo's library has humanoid idles);
     * a hit reaction;
     * a death (the slice, as a cut-plane shader on the mesh, or a dissolve).
  5. **Import.** A `.glb` in `proto/hd/enemies/<name>/`, with an
     `AnimationLibrary` of `rest`, `f1` … `fn`, `idle`, `hit` and `die`.
  6. **Timing from `attackSpec`.** The view plays no fixed clip.
     * It blends toward the pose of the current frame index over about
       0.1 s (`AnimationPlayer.play(pose, blend)`, or an `AnimationTree`).
     * The legacy coroutine keeps timing the attack: the `a=` times, the
       `h=true` hit, sounds and card effects. Every `attackSpec` line works
       with no new data.
     * At rest (`currentList` on the default frame, not hitting) the view
       plays `idle`.
     * If the blends look robotic, a converter can later write real clips
       from `attackSpec`: a key per frame entry at its time, plus method
       keys for the hit, the sound and the card. The poses stay the same.
  7. **Procedural extras.** Godot's skeleton modifiers: the head looks
     toward the party; spring bones move ears, tail and the boar's bristles;
     a breath runs along the spine.

  Estimate:
  * the Boar: 3–5 days, including learning the pipeline and a hand-made
    rig;
  * the Goblin: about 1–2 days, with an auto-rig and the pipeline in place.

  After the Boar, decide: does a 3D boar look better than tier A, next to
  the painted cards and portraits? The Goblin then tests a humanoid with
  weapons.
* **Effects.** The card and enemy effects (GPU particles in eye space) stay
  as they are. Effects that use the enemy's image keep using its rest frame.

## 5. Mode 2: Pixel (16-bit)

The 16-bit first-person crawlers (Shin Megami Tensei, Eye of the Beholder on
the SNES) drew their walls at a few fixed distances and moved one step at a
time. A grid crawler like this one fits that look well. The look comes from
a low resolution, a small palette, hard pixels and stepped motion.

### 5.1 The pixelating render path (2.1, S)

* **Low resolution: the whole frame at 512×384** (decided), UI included.
  * The window renders everything at half the virtual screen: the 3D, the
    legacy 2D (HUD, dialogs, menus, battle cards) and the fades.
  * In Godot that is the window's `viewport` content-scale mode with a
    512×384 render, and the game's 1024×768 coordinates scaled by 0.5. The
    exact settings are to be verified in step PX1. The fallback is a
    512×384 `SubViewport` holding `World` and the layers.
  * It applies to the whole game while the look is on, because switching
    the resolution per mode would jump at every transition. Only the two
    floors get the rest of the look (the palette, the pixel textures).
  * Text is drawn at half resolution, so it gets blocky. A pixel font is
    the follow-up (5.3).
* **Scaling to the window.** 384 lines go into 1080 by 2.81, which makes
  the pixels uneven. Two fixes:
  * integer scaling (Godot's integer content-scale stretch): 768 lines at
    1080p with wide black borders, 1152 at 1440p;
  * a "sharp bilinear" shader (an integer prescale, then bilinear): even
    pixels at any size, with slightly soft edges. This is the better choice
    at 1080p.
* **Palette and dither** (a canvas shader on the container):
  * quantize to a palette: a small palette texture per area (16–32 colours
    taken from its textures, or a Lospec palette), or plain 15-bit RGB as
    on the SNES;
  * a 4×4 Bayer ordered dither before the quantizing, with an adjustable
    strength (0 for the flat look).
* **Light and fog in steps.** A variant of `dungeon_gl.gdshaderinc` cuts
  the light and the fog into 4–6 bands, so walls darken in steps with
  distance, as in the old crawlers.
* **Textures.** A toggle between two samplings, both worth seeing:
  * `filter_nearest`: crunchy, with texels larger than screen pixels near
    the camera;
  * mipmapped linear: a downscaled painting, then quantized.
* **Outlines (optional).** A dark 1-pixel outline at depth and normal edges
  (a full-screen quad in the SubViewport reading the depth texture) makes
  it look hand-pixelled.
* **Stepped motion (optional).** Steps and turns show in 2–4 discrete
  frames instead of 500 ms of smooth motion. The view samples the legacy
  interpolation at fixed times; the logic is unchanged. This is the
  strongest retro cue of all.
* **Enemies.** At 512×384 an enemy is about 200–300 px tall. To start
  with, the painted frames downscaled (mipmaps) and quantized look fine;
  pixel versions from 5.2 come later.

Texel density at 512×384 (vertical FOV 45°):

* the wall at the end of the next cell (6 units away) is about 310 px tall;
* the wall one cell further (10 units) is about 185 px.

Wall textures of 128 px (chunky) to 192 px (detailed) match that. Both fit
under PixelLab's 200 px limit on the current plan.

### 5.2 Converted art (2.2)

The same floors, with the textures swapped for pixel versions. They go in
`proto/pixel/textures/<legacy path>` under the same names, and the material
picks them by name. There are three sources to compare:

* **a. Algorithmic (S, every texture in seconds).** A tool script
  (`tools/art/pixelize.py`, or a Godot script):
  * box-downscale 512 to 128 or 192 px;
  * quantize to the area's palette (k-means, or a fixed palette);
  * an optional ordered dither, then sharpen.

  Enemy frames get the same treatment, with one palette per enemy so its
  frames stay consistent. It is deterministic and re-runnable, and it is
  the baseline the AI versions must beat.
* **b. Redrawn by Nano Banana (or another image model).** Give it the
  legacy texture as input and a prompt for a 16-bit version (6.3). These
  models draw images that look like pixel art without being on a pixel
  grid: uneven pixel sizes, soft edges, colours off the palette, seams.
  * Every output goes through the same cleanup: detect the pixel size,
    snap to the grid (a nearest downscale), lock the palette, check the
    tiling (wrap the image and look at the seams).
  * Start with walls, doors and floors of the two floors. Do the enemies'
    rest frames only if the walls work.
* **c. PixelLab** (set up as an MCP server in this project). It is made for
  this job: its output has a real grid and alpha, so less cleanup is
  needed.
  * `image_to_pixelart` converts an image for 1 generation. Its output can
    be up to 512 px a side; the current plan caps it at 200.
  * `edit_image_pixen` (1 generation, up to 256 px) can fix a result.
  * Neither promises seamless output, so the seam check stays.
  * *Budget (decided): 10–20 generations.* The eight textures of the two
    floors (the mine's wall, floor, roof and two doors; the forest's wall,
    floor and door) and the Boar's three frames take 11. The rest goes to
    retries, then to the Goblin's four frames if any are left.
  * The server shows as connected (`claude mcp get pixellab`), but its
    tools were not loaded in the VS Code session that wrote this plan. A
    new session (or `/mcp`) should load them.

### 5.3 The UI in the pixel look

*Decided:* the UI is pixelated with the frame (5.1). The follow-up, once
the floors work:

* a pixel font through the theme (free ones exist: m5x7 and m6x11,
  Monogram, Silver, Press Start 2P; check each licence), drawn on the
  512×384 grid so that it is crisp instead of blocky;
* nearest-filtered panels.

## 6. Requesting assets

### 6.1 What the two floors need

| Asset | Legacy file | HD | Pixel |
|---|---|---|---|
| Mine wall | `Walls/minecavewall.png` | albedo 2048² (maps generated) | 128 or 192 px |
| Mine floor | `Floors/minecavefloor.jpg` | albedo 2048² | 128 or 192 px |
| Mine roof | `Roofs/minecaveroof.jpg` | albedo 2048² | 128 or 192 px |
| Mine doors | `Walls/minecavedoor0.png`, `Walls/minecavedoorbig0.png` | albedo 2048² | 128 or 192 px |
| Forest wall | `Walls/forestwall.png` | albedo 2048² | 128 or 192 px |
| Forest floor | `Floors/forestfloor.jpg` | albedo 2048² | 128 or 192 px |
| Forest door | `Walls/forestdoor0.png` | albedo 2048² | 128 or 192 px |
| Forest sky | the gradient | a CC0 HDRI or a painted 2:1 panorama | a pixel backdrop |
| Tree cards | — | 3–5 trunks, canopy, bushes (cut out) | optional |
| Particle sprites | — | dust, leaf, drip, ember (small, cut out) | — |
| Boar | `res/Battle/enemies/boar/` | a turnaround standing square, then a 3D model (4.7) | 3 frames (5.2) |
| Goblin | `res/Battle/enemies/goblin/` | an A-pose turnaround, then a 3D model, after the Boar | 4 frames (5.2) |
| Bat, Hexaroc | their folders | tier A only (generated maps) | frames (5.2) |

The HD column is for `hd-painted`. For `hd-photo`, the floor, roof and
stone surfaces come from CC0 sets (section 4) and need no request; the
doors still do.

### 6.2 How to ask (Nano Banana and similar)

* **In the browser** (decided). I write the requests into
  `proto/PROMPTS.md`, one block per asset: the prompt, the file to attach,
  and the name to save the result under. You run them in Nano Banana 2 and
  drop the results in `proto/incoming/<floor>/`.
* **One asset per request,** with the legacy texture attached and "keep
  the same layout" in the prompt. Ask for 3–4 variants and pick one.
* **Always say:**
  * square, seamless and tileable;
  * a straight-on orthographic view;
  * evenly lit, no shadows or highlights (albedo only);
  * no text, frame or border, filling the image edge to edge.
* **No alpha.** These models return opaque images. For anything cut out
  (tree cards, sprites, doors with gaps), ask for a flat magenta (#FF00FF)
  background; I key it out.
* **Resolution.** Outputs are typically 1–2K. For 2048², upscale with
  Real-ESRGAN or Upscayl (free). A tiling detail normal map keeps close-ups
  crisp.
* **Only ask for albedo.** Image models rarely give consistent normal or
  roughness maps. Generate those from the albedo instead: my script,
  Materialize (free), DeepBump (a free Blender add-on), or Substance 3D
  Sampler (paid; the best "image to material"). A height-map request to the
  model can work as a starting point.
* **Seams.** Shift the image by half (I can script it; Krita's wrap-around
  mode and GIMP's Tile Seamless do the same), then ask the model to
  "remove the seams through the middle, change nothing else".
* **Watermarks.** Check the corners for a visible watermark before using an
  image.
* **Keep a log.** Write each prompt next to its output in
  `proto/ASSET_LOG.md`, to redo or vary it later.
* **Free CC0 alternatives:** Poly Haven (HDRIs, textures) and ambientCG.
  They are photographic, so they suit the sky better than the painted
  walls.

Drop the files in `proto/incoming/<floor>/`, with the legacy name in each
file name. I do the rest: keying, grid snapping, palettes, seams, normal
and height maps, import settings and the material sets.

### 6.3 Prompt templates

Fill in the brackets; attach the legacy file each time.

**HD wall or floor:**

> Repaint the attached game texture as a high-detail, seamless, tileable
> square texture for a modern 3D game. Same design and layout: [rough dark
> rock with pale mineral veins, framed by weathered wooden support beams
> with iron bolts, in the same positions]. Painterly but detailed, with
> believable materials. Albedo only: flat, even, shadowless lighting, no
> highlights, no ambient occlusion, no light direction. Straight-on
> orthographic view, no perspective. Fill the image edge to edge: no
> border, no text, no logo.

**Tree card:**

> One [tall, mossy oak trunk with its lowest branches], full height, front
> view, in the painted style of the attached texture, on a flat pure
> magenta (#FF00FF) background. No shadow, no glow, crisp edges.

**Sky (if not an HDRI):**

> A 2:1 equirectangular 360° panorama of [an overcast, rainy dusk sky above
> a dark forest canopy], horizon at the vertical centre, the left and right
> edges seamless, nothing below the horizon but dark treetops. Painted
> style, no text.

**Boar turnaround (for 3D; attach `boar1.png`):**

> A model turnaround sheet of exactly this boar (same bristly mane, tusks,
> brown hide, tufted tail): left side view, front view and back view side
> by side, full body, standing square on all four legs, head level, mouth
> closed, tail hanging. Plain mid-grey background, even studio lighting,
> no cast shadows, the same painted style.

**Goblin turnaround (for 3D; attach `goblin1.png`):**

> A character turnaround sheet of exactly this goblin (same face, green
> skin, purple loincloth, shoulder plate): front view, left side view and
> back view side by side, full body, in a relaxed A-pose with the arms 30–45°
> from the body and the legs slightly apart, no weapons. Plain mid-grey
> background, even studio lighting, no cast shadows, the same painted
> style.

(Then the spear and the knife separately, each on grey.)

**Pixel wall or floor:**

> Redraw the attached texture as 16-bit console era pixel art (SNES style):
> a 128×128 pixel image scaled up 8× with hard square pixels (every art
> pixel a solid 8×8 block), at most 32 colours, no anti-aliasing, no
> gradients, no blur, clear clusters and dark lines between the stones.
> Same layout as the input, seamless and tileable, straight-on, edge to
> edge.

**Pixel enemy frame:**

> Redraw this monster as a 16-bit SNES-era battle sprite: about 200 pixels
> tall, scaled up 4× with hard square pixels, at most 32 colours, a 1-pixel
> dark outline, no anti-aliasing, on a flat pure magenta (#FF00FF)
> background, no shadow on the ground. Keep the pose, proportions and
> colours.

For the other frames, attach the converted frame 1 and the painted frame n:
"the same sprite and palette as the first image, in the pose of the second
image". Expect drift between frames; the algorithmic version (5.2 a) does
not drift.

### 6.4 Other APIs

What I could call from here, besides the browser:

| Service | For | Cost | Needs |
|---|---|---|---|
| PixelLab (MCP, set up) | pixel conversions and edits | 1 generation per conversion | its tools loaded in the session |
| Gemini API (Nano Banana 2) | the same requests as the browser | paid per image: third-party sources say roughly $0.07–0.10 for a 2K image (unverified); the API's free tier is limited | an API key from Google AI Studio, in an environment variable |
| Retro Diffusion (its own API, or on Replicate) | pixel art; its tile model makes seamless tiles of 16–384 px | about $0.18 an image (RD Pro) | an account and a key |
| Replicate or fal.ai | many models: upscalers, Hunyuan3D, TRELLIS, Retro Diffusion | paid per run | a key |
| Hugging Face Spaces (Hunyuan3D 2, TRELLIS) | the Boar's mesh | free, within a free account's daily GPU quota | an HF token |
| Local (RTX 3050, 6 GB) | upscaling (Real-ESRGAN), my scripts | free | — |

Every service but the local one sends the game's art to an outside
service, so I would ask before the first call to each. The browser route
costs nothing and needs no setup. PixelLab is the one worth using for the
pixel art, and a Hugging Face Space the one to try for the Boar's mesh.

## 7. Steps and sizes

S ≈ a focused session, M ≈ a few sessions, L ≈ many sessions or external
work.

| # | Step | Size | Needs | Gives |
|---|---|---|---|---|
| 0 | The switch: `--look`, console `look`, `proto/`, the export filter, the hooks (no effect by default) | S | — | the looks can be built; parity unchanged |
| PX1 | Pixel render path: the whole frame at 512×384, scaling to the window, palette and dither, the nearest/linear toggle | S | 0 | first 16-bit shots of both floors (2.1) |
| PX2 | Banded light and fog, outlines, stepped motion | S | PX1 | the full 2.1 look |
| PX3 | Algorithmic pixel textures and enemy frames (script) | S | PX1 | 2.2 a |
| PX4 | AI or PixelLab pixel textures, the cleanup script, a comparison sheet | M | PX3, the assets | 2.2 b and c |
| HD1 | Moving camera, the PBR material swap (painted: generated maps; photo: CC0 sets), torch, shadows, environment | M | 0 | first HD shots in both directions, no requested art |
| HD2 | Volumetric and moving fog, particles, post-processing, camera feel, sound | M | HD1 | the atmosphere |
| HD3 | Prototype floor scenes in both directions: the requested textures, the mine's beam geometry (photo), sky, tree cards, lanterns, props | M | HD2, the assets | the HD showcase |
| HD4 | Battle tier A: lit enemy sprites, idle breath, cross-fades (the Tunnel's and the Forest's enemies) | S–M | HD1 | lit enemies |
| HD5 | Battle tier C: the Boar's mesh, rig, poses and idle, and `EnemyView3D`; then the Goblin | L | HD4, the model | a 3D boar fight in Forest Path; the call on 3D enemies |
| HD6 | Optional: displaced walls or the modular kit; 3D chests and save point | M–L | HD3 | real geometry |

Suggested order: 0, then PX1 and PX2 (quick, with a clear result), HD1 and
HD2. Requests for assets can start in parallel from step 0, the Boar's
turnaround first: the 3D pipeline takes the longest. Then PX3, PX4 and HD3
as assets arrive, then HD4, HD5 and HD6.

Every step is checked in the same way:

* `tools/check.sh` reports 0 failed;
* the tour shot in each look, side by side on a contact sheet;
* FPS from a normal run.

Step 0 also needs the parity compare from section 3.

**Who does what.** I can build the code, the shaders, the scripts and the
generated maps, and process every image you bring. You request the images
from Nano Banana or similar, and the 3D model from an image-to-3D tool
(or I call a Hugging Face Space, 6.4). The posing in Blender is judgment
work. Blender is not installed here yet; once it is, I can script its
import, decimate and export steps.

## 8. Risks

* **The battle overlay in the HD world.** The cards, bars and texts are 3D
  in the same World3D. Tonemapping, glow, volumetric fog and depth of field
  would hit them too. Ways out:
  * give the bridge's materials `fog_disabled` and keep the tonemapper
    mild;
  * or, in this look, draw the overlay in its own SubViewport.
* **Style clash.** Photographic PBR walls next to painted enemies, cards
  and portraits look like two games. Aim for painted PBR: painted albedo,
  with real normals and lights.
* **AI assets** drift between frames and variants, have seams, and bake in
  lighting. Fine for a prototype; for shipping, check the tool's terms.
  (The input art is the game's own.)
* **3D enemies.**
  * The painted frames have their own perspective, and their poses may not
    map onto a rig.
  * Image-to-3D meshes vary in quality.
  * The time per enemy adds up over 44 enemies. That is why tier A exists,
    and why the decision comes after one enemy.
* **Performance.** SDFGI, volumetric fog, shadows and SSR at 1080p and
  above need measuring. A few quality presets may be needed.
* **The moving camera.** Anything left in eye space at the origin floats in
  the world. The sky, the bridge's batches and the save points' eye-space
  meshes must follow the camera.
* **The pixel look** shimmers in motion (low resolution with linear
  textures); stepped motion and nearest sampling help. Full screen needs
  integer scaling or the sharp bilinear shader.
* **The pixelated UI.** At 512×384 the legacy text is blocky, and small
  text may be hard to read until a pixel font replaces it.
* **The export.** With `proto/` left out, a hook that names a prototype
  class breaks only the exported build. Run an export before handing a
  build to anyone.

## 9. Decisions (2026-11-03)

1. **Floors:** The Great Mine--Tunnel and Forest of Reil--Forest Path.
2. **HD art direction:** both, painted and photographic (section 4). The
   UI need not match: these are explorations.
3. **The switch:** the command line and the console only (section 3).
4. **Pixel:** the whole frame at 512×384, with the UI pixelated too (5.1,
   5.3).
5. **Image generation:** PixelLab may use 10–20 generations (5.2 c). The
   Nano Banana 2 requests are written as prompts, and you run them in the
   browser (6.2). The other APIs are in 6.4.
6. **3D enemies:** the Boar first, then the Goblin (4.7).

## 10. As built (2026-11-03)

### 10.1 The switch (step 0)

* `--look=<legacy|hd-painted|hd-photo|pixel>` and
  `--look-settings=<key=value,...>` (after `--`), and the console's
  `look [<name>] [key=value ...]`.
  * `look` alone prints the current look and its settings.
  * `look <name>` switches the look. On a labyrinth floor outside a
    battle, it also enters the floor again at the same node and facing
    (`Load.labyrinthPosition`, as the console's `boss` does).
* **Game code** (the only changes outside `proto/`):
  * `scenes/dungeons/DungeonLook.gd`: the base class, the list of looks,
    `FLOORS`, settings parsing. It loads the look scripts by path only.
  * `DungeonScene` hooks: `_set_up` calls the look's `set_up`,
    `show_floor` its `floor_built`, and `show_view` its camera.
    `DungeonFloor` gains `walls_instance()` and `sky_instance()`.
    `DungeonWeather` gains `eye`.
  * `dungeon_gl.gdshaderinc` gains `#ifdef LOOK_NEAREST` / `LOOK_BANDS`
    blocks, which the default shaders do not define.
  * `Main` gains the flags, `GameCommands` the command.
* `export_presets.cfg` excludes `proto/*` from the Windows build.
  `tools/check_all.gd` now also compiles `res://proto`.
* **Guard:** the 225 `dungeon_*` and `battle` cases recorded before the
  change ("lkbase", from a copy of the clean tree) and after it ("lkafter",
  from a copy of the changed tree), compared at tolerance 0; the result is
  in 10.5.

### 10.2 The pixel look (`proto/pixel/`)

* **`PixelFilter`** (a CanvasLayer on layer 40, under the console's 50)
  draws the whole frame again at 512×384 cells, the UI included
  (`pixel_filter.gdshader`):
  * each cell takes its centre's colour (`average=on`: the mean of its
    screen pixels);
  * each channel is cut to 16 levels with a 4×4 Bayer dither;
  * `sharp=on` blends cells over one screen pixel at their edges, so they
    stay even at any window size.

  It is a screen-reading shader, not a low-resolution render: nothing in
  `Main`'s tree moves, and it switches on and off at once. The 3D still
  renders at the window's resolution; sampling one point per cell gives
  the low-resolution look.
* **On the two floors** (`PixelLook.floor_built`):
  * the walls', floors' and roofs' materials, and the sky's, are
    duplicated with `LOOK_BANDS` (light and fog in 6 steps) and
    `LOOK_NEAREST`;
  * their textures are converted by rule: Lanczos to 128 px, 16 levels,
    hard alpha (5.2 a);
  * a PNG in `proto/pixel/textures/<Walls|Floors|Roofs>/<name>.png`
    replaces the rule-converted texture (5.2 b and c; `art=off` ignores
    it).
* **Settings:** `res`, `levels`, `dither`, `average`, `sharp` (the
  filter, live) and `bands`, `nearest`, `textures`, `art` (the floors, at
  the next entry). `textures=0 average=on` is the pure filter version
  (2.1).
* **Looked at:** the defaults (`textures=128`, centre sampling, 16 levels)
  read as 16-bit: chunky textures, hard edges, the floor darkening in
  bands. Averaging softens everything into a blurred image. 8 levels make
  the dither a crosshatch.
* **Not done:**
  * stepped motion: the objects' eye-space quads follow the legacy
    interpolation, so it has to be done in `LabyrinthPlayer`, not in the
    view;
  * outlines;
  * a pixel font;
  * PixelLab conversions: its tools were not loaded in this session.

### 10.3 The HD look (`proto/hd/`)

* **Camera:** it moves (the legacy view's inverse on the Rig, the floor
  at the identity). The eye-space meshes follow it: the bridge's
  `Legacy` node, the objects' batches, the legacy weather quads.
* **Materials:** `HDMaterials` makes a StandardMaterial3D per legacy
  texture.
  * The albedo is the legacy texture, lifted (`brightness` 1.1,
    `contrast` 0.85), or a set's `albedo.png`.
  * Normal and height maps are made from its brightness
    (`Image.bump_map_to_normal_map`, `bump` 3), or the original's
    `<name>normal.png` where one exists.
  * Parallax (`parallax` 1), roughness 0.85, mipmaps with 16×
    anisotropic filtering, clamped (not repeated: see 10.6).
  * A set's files (`proto/hd/<painted|photo>/<Walls|Floors|Roofs>/<name>/`
    with `albedo`, `normal`, `height`, `roughness`, `ao`, and
    `material.cfg`) replace what they cover. The painted set has height
    and normal maps for the forest and mine walls (10.6); otherwise no set
    has files yet, so `hd-photo` looks like `hd-painted` until the CC0 sets
    are in.
* **Light:**
  * a flickering torch (`Torch`: energy 8, falloff exponent 1.6, shadows,
    a sixth of the energy on a floor with a sky);
  * on a floor with a sky, a daylight with shadows and a
    ProceduralSkyMaterial in the legacy sky's colours (the gradient quad
    is hidden).
* **Environment:** AgX tonemapping, glow, SSAO, SSIL, SDFGI and
  volumetric fog (the floor's density, or a faint haze in the mine).
* **Atmosphere:** a FogVolume over the floor with drifting 3D-noise fog
  near the ground (`drift_fog.gdshader`), and embers around the camera
  that fade out close to it (10.6).
* **Found:**
  * **Turn the mesh.** The legacy quads wind counter-clockwise (GL's front
    faces, Godot's back faces). Lit and shadowed as back faces, the walls
    went dark under a shadowing light. The HD mesh turns every triangle
    (`HDLook._flipped`) and culls back faces.
  * **Dark painted textures.** They light far darker under PBR than
    under the legacy light (sRGB modulation, strong ambient), hence the
    lift and the torch's energy.
  * **Generated relief.** Normal maps from brightness suit the forest's
    fieldstones, but make the mine's veined rock blobby. The requested
    art should fix that.
  * **Debug settings:** `materials=off` (the legacy shader under the HD
    camera), `normals`, `shadows`, `cull`.
* **Looked at:**
  * the forest: sun shadows across the corridor, the sky, rain, stone
    relief;
  * the mine: a warm torch-lit tunnel falling off into darkness. Up close,
    the lifted rock reads as sandstone.
* **Not done:**
  * the CC0 photo sets and the mine's beam geometry (`hd-photo`);
  * lanterns and props (HD3);
  * lit objects (chests and doors still use the legacy shader);
  * the battle overlay's tonemapping and fog (risk in section 8, not yet
    looked at in a battle);
  * battle tiers A and C.

### 10.4 Assets

`proto/PROMPTS.md` holds the browser requests, the Boar's turnaround and
the Hugging Face steps first. Results go in `proto/incoming/`.

### 10.5 The guard

"lkbase" (the clean tree) and "lkafter" (step 0 and the looks, without
`--look`), recorded from copies of the tree: **2,934 of 2,934 shots
identical** at tolerance 0, all 225 logs pass, and the same error-line
count (450 in each, the usual exit-time leak reports).

A battle in the Tunnel (`battle.txt`) in `hd-painted` and `pixel` plays
and draws (0 errors): the enemy (still the legacy quad), the HUD and the
numbers.

### 10.6 First review of the HD look (2026-11-04)

Three points from the review, each shot in Forest Path (and the Tunnel)
before and after:

1. **Embers.** The dust motes were square specks. They are now embers
   (`embers` 160, the count; 0: none): a round glow that falls off to the
   edge (`ember.gdshader`: unshaded, added, turned to the camera), each
   between yellow and red, flaring up, then cooling to a dim red, rising
   slowly on a turbulent draught. Their glow is moderate (energy 2): at 4
   the AgX tonemapper turned the yellow ones white. They write no depth, so
   they are drawn after the objects' quads and the weather, before the
   minimap and a battle (`HDLook.EMBERS_SORTING_OFFSET`): sorted as the
   particle node (at the camera, offset 0), they came before the objects'
   batches (`DungeonScene.SORT_STEP` offsets), and the Tunnel's door, three
   cells away, was blended over an ember right in front of the camera.
2. **Light under the walls and at seams** (the forest). Two causes:
   * **Repeated textures.** The forest wall's top 24 rows are transparent
     (above the grass). Repeated, the sampler blended them into the wall's
     bottom edge, which the alpha scissor then cut: a dotted see-through line
     along the floor, and an opaque line along the wall's top. The HD
     materials now clamp (`texture_repeat` off, unless a set's `uv_scale` is
     not 1).
   * **Nothing behind the outer walls.** In Forest Path every wall is an
     outer wall (single-width corridors, void behind). The daylight's shadow
     map is empty behind a wall, and its soft-shadow filter, reaching past
     the wall's foot or a corner, sampled that emptiness as lit: a bright
     strip along the foot of a wall in shadow, and a bright line down
     corners. Lowering the shadow bias (down to 0.01) did not help; it is not
     the bias. Now a box behind every wall with no cell behind it
     (`HDWalls.sun_blockers`, setting `blockers`) casts shadows for the
     daylight only (render layer 20, which the torch's `shadow_caster_mask`
     leaves out, so it changes nothing for the torch). It reaches 1 below
     the floor and up to the texture's first transparent row, so the grass
     still casts its own ragged shadow edge.
3. **Flat walls.** Findings and a first try:
   * **No geometry or tessellation shaders in Godot 4** (Vulkan Forward+
     exposes neither). Displacement means a mesh with the vertices: built
     on the CPU, or a fine grid displaced in a vertex shader.
   * **Relief walls** (`HDWalls.relief`, settings `relief` 0.05 units and
     `relief_grid` 64): each wall is a 64×64 grid sunk behind its plane by
     its height map (the stones' faces stay in the plane, the mortar sinks),
     with the set's normal map and no parallax. One mesh per texture, an
     instance per wall, scaled to the depth (so the depth changes at once,
     10.7). A set's `material.cfg` may make a texture's relief deeper
     (`relief_scale=<n>`, times `relief`); `relief=0` at a floor entry
     leaves all walls flat quads.
     * Sunk, not raised: raised stones covered what the objects draw on the
       wall plane (the hinder door at mark0 disappeared), and narrowed the
       corridors.
     * The relief fades to the plane at the floor, at the roof, and at a
       side that does not go on into the same texture (corners, a wall's
       end, a door), so walls still meet without gaps. Side by side, the
       texture wraps and the relief runs on.
     * Two walls back to back each sink into the other's side; such walls
       cast shadows from their face only. The sun blockers stop short of
       the relief round a corner (a box in the relief's way shadowed it in
       dark blotches).
     * Cost: none to measure at 1024×768 (Forest Path 27 walls, about 220k
       triangles; median 137 fps flat, 154 with relief, as relief walls drop
       the parallax shader).
   * **The height map is what matters.** With the brightness height map
     (10.3), relief is barely visible in the forest, and in the mine the
     white veins become ridges and the beams do not stand out. So relief is
     only for textures with a set's `height.png`.
     `proto/hd/tools/wall_height.gd` makes them, by recipe:
     * `stones` (the forest wall): the darkest 20 % of the texels are
       mortar, and each stone rises from it in a rounded profile (a distance
       transform, wrapped sideways). The stones stand out and the wall tops
       get a ragged silhouette. 0.15 was far too jagged; 0.05, the default,
       is a gentle depth.
     * `timber` (the mine wall, `material.cfg` `relief_scale=5`: 0.25): the
       wood-coloured texels (saturated, red to orange; the mask closed over
       the bolts) are beams with their faces in the plane and rounded edges;
       the rock lies at 0.4, roughened a little by its paint's shading, the
       white veins flattened. The beams stand 0.15 in front of the rock: the
       posts show their sides down the corridor and the braces look round.
       0.05 was too little to see in the mine.
   * **Image to mesh AI is the wrong tool for walls.** Image-to-3D models
     (Hunyuan3D, TRELLIS) make closed objects, not tiling wall panels.
     What fits is image to *depth or normals*: Depth Anything V2 or
     Marigold (which also has a normals model and one that splits albedo
     from shading) on the painted texture, or Materialize, DeepBump,
     Substance Sampler (6.2).
     * Tried on the mine wall: the Depth Anything V2 Space (and every other
       ZeroGPU Space) no longer answers anonymous API calls; it needs a free
       Hugging Face account's token. The free CPU Space
       `nielsr/dpt-depth-estimation` (DPT) answered: a soft depth with the
       beams in front, but no rock detail, a gradient from top to bottom
       (its perspective prior) and no tiling. The `timber` recipe is better
       for this texture.
   * **What relief cannot do:** real thickness. The beams get no silhouette
     and the walls no thickness at their ends; that is the kit of 4.4
     (beam boxes, corner pillars).
   * **Iterating:**
     * the depth: the tuning panel (10.7), or the debug console (F1 or the
       key left of 1) `look hd-painted relief=0.08`, which enters the floor
       again at the same node and facing (or `--look-settings=relief=0.08`);
       per texture, its set's `material.cfg`, then `look hd-painted`;
     * the height map: run `wall_height.gd` again with other options
       (`mortar`, `radius`; `bevel`, `rock`, `rough`, `veins`; `bump`),
       then `look hd-painted`: the HD look reads a set's files again at
       every floor entry.
   * The console's `look` entered the floor again facing the floor's
     start direction: it passed the camera's angle in degrees where a save
     has the direction (0-3). Fixed (`GameCommands._look`).

Settings changed: `dust` became `embers` (a count); new `blockers`,
`relief`, `relief_grid`.

### 10.7 The tuning panel (2026-11-04)

`proto/hd/HDTuner.gd`: **F2** on an HD floor shows or hides a panel on the
right with the settings of `HDLook.KNOBS`:

* **Fog:** `fog` (the floor's density, times), `fog_anisotropy`,
  `fog_length`, `fog_sky`, `torch_fog` (the torch's halo), `sun_fog`;
* **Drifting fog:** `drift` (density, times), `drift_height` and
  `drift_wind` (times their own), `drift_scale` (the noise's frequency:
  smaller, larger puffs), `drift_cover` (the share of clear air);
* **Light:** `torch`, `sun`, `exposure`, and switches for `shadows`, `gi`,
  `ssao`, `ssil`, `glow`;
* **Surfaces:** `relief` (times each texture's `relief_scale`),
  `roughness`, `parallax`, `embers`.

Each has a slider and a box with its value. Typed values (Enter takes
them, Escape leaves the box) may go past the slider's ends. A change takes
effect at once (`HDLook.apply`: the Environment, the lights, the drifting
fog's shader, the embers, the materials; the relief by scaling its
instances, the sun blockers made again behind it) and stays for the
session like the console's `look` settings. **Copy** puts the settings
changed from their defaults on the clipboard as a console line (`look
hd-painted fog=1.4 ...`, also printed to the log); **Reset** puts the
panel's back (to the floor's defaults since 10.8, which also adds **Save**
and a revert button per row).

* All of them are settings too, so the console and `--look-settings` take
  them; the new ones are the fog's and the drifting fog's above.
* While a box has the focus, `Main._input` gives the keys to it, not to
  the game (any focused `LineEdit`; the game has none, so the default game
  is unchanged), and focusing one releases the game's buttons. The
  sliders and switches never take the keyboard.
* Escape while the panel is shown leaves the box, or with no box focused
  hides the panel; it never reaches the game, where it quits (as the
  console's Escape only closes the console). Checked through AutoPlay:
  F1 + Escape and F2 + Escape left the game running, a third Escape quit.
* Checked with a temporary hook that set sliders in code (the signal a
  drag sends) and typed into the exposure box through AutoPlay, in both
  floors: the fog, light, relief and embers changed in the same frame
  run, Up and Enter in the box neither moved the player nor opened the
  menu, and the box let go of the keyboard after Enter.
* Relief meshes are now built 1 unit deep with the flat grid's tangents,
  and each wall's instance is scaled to its depth.

### 10.8 Per-floor defaults and reverting a row (2026-11-04)

* **Save** (the panel's head) saves the panel's settings as the floor's
  defaults: `proto/hd/<set>/maps.cfg` (`painted` for hd-painted, `photo`
  for hd-photo, as the materials), a section per map with the settings that
  differ from the look's own defaults (the others follow those):

  ```
  [Forest of Reil--Forest Path.map]

  fog=2.5
  ssao=false
  ```

  Other floors' sections are kept, and so are keys outside the panel, which
  can be written by hand (`relief_grid=96`). `ConfigFile` does not keep
  comments. A key that is no setting, or a value of the wrong type, is an
  assert (skipped in a release build).
* **A floor entry** (`HDLook.set_up`) gives every setting the floor's
  default (`HDLook.map_defaults`: the look's own, with the map's section
  over them), except the settings changed this session (the panel, the
  console's `look`, `--look-settings`): those keep their values from floor
  to floor, as before.
* **↺ at the end of each row** puts the setting back to the floor's
  default. It is yellow while the setting differs from it and faint while it
  is at it; its tooltip gives the floor's default (and the look's, when the
  floor's differs). A setting put back, or saved, is no longer a session
  change. **Reset** puts every row back to the floor's defaults.
* **Copy** still lists the settings that differ from the look's own
  defaults, so the console line gives the same floor without `maps.cfg`.
* Float values from the panel are rounded as the box shows them (the
  sliders' step made 1.7 1.7000000000000002, which a saved file kept).
* Checked in Forest Path and the Tunnel with a temporary key hook (the
  panel's buttons and the sliders' signals) through AutoPlay: changing,
  reverting a row, saving, the defaults loaded again at the next entry, the
  Tunnel unchanged by the forest's defaults while an unsaved change carried
  over, Reset, and a save with everything at the look's defaults removing
  the section and the file.
* **Rows that do nothing are greyed out** (`HDLook.inactive`) and their
  slider, box or switch locked; the label's tooltip says why. The ↺ still
  works (a value carried over from another floor can be put back). Greyed:
  `sun` and `sun_fog` on a floor without a sky (no daylight: the Tunnel),
  the drifting fog's rows while `drift` is 0, a flicker's speed while its
  amount is 0 (10.9), `relief`, `roughness` and `parallax` while
  `materials` is off.
* **The drifting fog in the mine is on, but it does not show** at the
  defaults: drift 1 and drift 0 differ by at most 1/255 in the Tunnel
  (AutoPlay shots at mark0, `--fixed-fps 60`). Its only light is the torch,
  at the eyes, and `fog_anisotropy` 0.45 scatters light forward, away from
  them: the fog sends back about a quarter of what isotropic fog would (a
  Henyey-Greenstein lobe at 180°). In the forest the daylight comes from
  above, from the side. The mine's drifting fog is also thinner (0.02 against
  0.05) and the Environment injects no ambient light into fog.
  * A negative anisotropy alone is not the answer: it is one value for all
    the volumetric fog (Godot has no per-volume anisotropy), so the faint
    haze over the whole floor (0.012 where a floor has no fog of its own,
    for the torch's halo) lights up too, an even veil from top to bottom.
    Measured with `fog_anisotropy=-0.6 drift=4 drift_height=0.5
    drift_scale=0.2 torch_fog=0.6`: the drifting fog (haze off, drift on vs
    off) changed only the frame's lower 40 % (up to 24/255); the haze (on vs
    off) the whole frame (up to 60/255).
  * The drifting fog does move and form puffs: with `fog=0` (the mine's
    haze off) `fog_anisotropy=-0.6 drift=10 drift_cover=0.55
    drift_scale=0.15 drift_height=1 torch_fog=2`, the floor shows patches
    of mist with clear gaps that shift between shots 3 s apart (up to
    72/255); with `drift_wind=0`, the same shots match within 2/255. At
    `drift_cover` 0.45 and `drift` 4 the mist is a smooth, faint sheet.
  * That is a floor's tuning, for its `maps.cfg` section; the look's
    default stays 0.45 for the daylight's shafts.

### 10.9 The torch's flicker (2026-11-04)

The torch flickered too fast and too randomly: five octaves of noise ran
through about ten times a second at ±15% of its energy, with a sway made the
same way. `Torch` now has three smooth motions (one octave each), with these
settings and a **Torch flicker** group in the tuning panel:

* `flicker` (0.1) and `flicker_speed` (1.2): a slow swell, at most that
  share of the energy up or down, turning about that often a second;
* `flutter` (0.025) and `flutter_speed` (7): a faster, fainter flicker over
  the swell;
* `sway` (0.01 units) and `sway_speed` (0.6): the light's drift on the
  camera, which moves its shadows.

Each motion moves along its noise by its own speed, so dragging a speed
slider changes the pace without a jump. Over ten seconds at 60 fps the
largest step from one frame to the next fell from 9.7% of the energy to
1.7%, with about the same range (±9%).

### 10.10 The heat haze (2026-11-04)

For a very hot place: the air shimmers, the far end of a corridor wavers and
softens. A pass over the whole frame (`heat_haze.gdshader`, `HDLook._make_haze`),
off by default (`haze` 0), with a **Heat haze** group in the tuning panel:

* `haze` (0; try 4–8): how far the image shifts at most, in pixels of a
  768-pixel frame;
* `haze_speed` (0.3) and `haze_scale` (6): how fast the ripples rise, and
  how fine they are;
* `haze_near` (2) and `haze_far` (24): no haze nearer than the first
  distance (units), all of it from the second;
* `haze_ground` (0.5): more of it at the floor than at the roof (0: the same
  at every height; 1: none at the roof), as heat rises from the ground;
* `haze_blur` (0.5): the distance blurred a little (a mipmap level of the
  frame at full strength; 1 already looks out of focus);
* `haze_tint` (0): a warm, sun-bleached grade over the frame.

How it works:

* A quad on the camera that the vertex shader spreads over the screen. It
  reads the frame drawn so far (the screen texture: the opaque surfaces, the
  sky and the volumetric fog) and the depth, and draws it again shifted by a
  rising noise.
* The noise is sampled by the view's direction, not the screen's position,
  so the ripples stay with the world while the camera turns.
* The shift grows with the surface's distance (`haze_near` to `haze_far`)
  and its nearness to the floor. Where a shift would land on a nearer surface,
  it is cut to that surface's: a near wall's edge stays sharp and does not
  smear over the distance behind it.
* It has the lowest render priority, so it is drawn first among the
  transparent objects. Everything drawn after it stays sharp: the legacy
  objects' quads, the battle (enemy, cards, bars), the rain and the embers.
  In a battle only the walls behind the enemy shimmer.
* With `materials=off` the walls are the legacy shader's (transparent, drawn
  after it), so only the sky shimmers.
* Hidden while `haze` is 0, it costs nothing then (no copy of the frame).
  When it is on, the cost was lost in run-to-run noise (Forest Path, uncapped,
  500–850 fps either way). The panel greys out the other rows while `haze`
  is 0.

Checked in Forest Path and the Tunnel through AutoPlay (haze 0, 6, and 12
with blur 2): the far walls and the wall tops against the sky waver, the
ripples move between shots 200 ms apart, near edges stay sharp, and a random
battle in Forest Path draws the HUD and the Boar unshifted.

### 10.11 Relief on roofs and floors; parallax dropped (2026-11-04)

The mine's walls had relief, but the beams of its roof stayed flat, and
raising `parallax` to give them depth stretched the seams between floor
quads.

* **Why parallax went.** It came first (10.3): Godot's deep parallax on
  every PBR material, from the brightness height map. Relief (10.6) replaced
  it on walls with a set's height map, and those walls dropped it. What it
  still covered (floors, roofs, walls without a set's height map) it did
  badly:
  * at its default (1) it did almost nothing: Godot scales
    `heightmap_scale` by 0.01, so the texture shifted by at most 1 % (5
    texels of 512);
  * raised enough to show, it smeared the seams. Every quad shows its
    texture once, clamped since 10.6, so near a quad's edge the shifted
    lookups fall outside the texture and repeat its edge texels: a stretched
    band along each seam. Parallax cannot see the next quad;
  * its height map was the brightness one, which makes the mine's rock
    blobby (10.3) and which relief does not use;
  * it cost frames (10.6: 137 fps with it on the walls, 154 with relief).

  So the `parallax` setting, its panel row and the materials' height map
  are gone. Surfaces without a set's height map keep their normal maps.
* **Relief on any quad.** `HDWalls.relief` now takes floors and roofs too:
  every quad whose texture has a set's `height.png` (`HDWalls.quads`, which
  replaces `wall_quads`). The grid sinks away from the cell: a roof's into
  the rock above, a floor's below. A floor's or roof's side fades to the
  plane unless it goes on into a quad of the same texture, and also where a
  wall stands on it (corridors side by side under one roof). DungeonFloor
  lays every floor and roof the same way round, so the height map wraps both
  ways and neighbouring quads meet without cracks. Walls are unchanged.
* **The mine roof** (`proto/hd/painted/Roofs/minecaveroof/`): `height.png`
  and `normal.png` from `wall_height.gd` (recipe `timber`, its defaults),
  and `material.cfg` with `relief_scale=5`, as the mine wall: the frame's
  beams stay in the plane and the rock panel sits 0.6 of the depth above
  them (0.075 units at the Tunnel's `relief` 0.025).
* Checked in the Tunnel at mark0 through AutoPlay with `relief` 0.025, 0
  and 0.1. At 0.1 the roof's beams hang with visible thickness below the
  rock, with no gaps at the roof seams or where walls meet the roof. Forest
  Path (no roofs) draws as before. `check_all.gd -- proto`: 8 scripts, 0
  failed.
* Not handled: carpets set no normal (DungeonFloor), so in the carpet pass
  they take the last wall's. `HDWalls.quads` therefore counts them as walls.
  No prototype floor has carpets.

Settings changed: `parallax` removed (`look hd-painted parallax=...` is now
an error).

### 10.12 Embers in the world, not around the camera (2026-11-04)

Standing still in the Tunnel, a cloud of embers formed round the camera.
Stepping back showed a clump of small embers where it had stood, and four
steps ahead there were almost none until a new cloud formed. The emitter
follows the camera (a box round it), but the embers stay where they were
emitted (world coordinates). So they gathered wherever the camera stood
for their 7 s lifetime, and a place the camera had just reached had
none.

Now the shader draws each ember within reach of the camera
(`ember.gdshader`, `reach`): one further away along x or z (it drifted out,
or the camera left it behind) is drawn a box's width over, on the other
side. The box they are emitted in is exactly that wide, so the drawn embers
are always as thick all round the camera however it moved. Each still
stays in its place in the floor while it is in reach. They fade out over
the last 2 units of the reach, where they jump. The simulation
(ParticleProcessMaterial, its turbulence) is unchanged. The pattern repeats
every box width (14 units by default), but no two copies are in reach at
once.

* `embers` is now a density: how many over each 10 × 10 units of floor
  (the old box), so the tuned values keep their look. The particle count
  is `embers` × (2 × `embers_reach`)² / 100: 314 at the defaults, 1,176 at
  the Tunnel's 600.
* `embers_reach` (7, panel row under `embers`): how far from the camera
  they are drawn, along the floor's axes. Before, it was 5 with no fade.
* Checked in the Tunnel through AutoPlay: two steps on, the shot at once
  and the one 5 s later show the same density; turned back to the start,
  the embers are even, with no clump. `check_all.gd -- proto`: 8 scripts,
  0 failed.

Settings changed: `embers` is a density (same numbers); new `embers_reach`.

### 10.13 The relief's shadows; occlusion maps (2026-11-04)

The relief is real geometry and casts shadows, yet it did not look as if
it did. Measured with a test scene: one mine wall (`HDWalls._relief_mesh`,
the Tunnel's depth 0.125), 2 units from the camera, and the torch's light:

| Light | Shadow bias | Shadows on against off |
|---|---|---|
| the torch's place | Godot's (0.1, normal 1.0) | no change (0.01/255 on average) |
| 1.5 units to the side | Godot's | no change (0.01/255) |
| the torch's place | 0.01, normal 0 | 5.6 % of pixels darker by > 8/255 |
| 1.5 units to the side | 0.01, normal 0 | 15 % darker |

* **The bias removes the relief's own shadows.** In the Tunnel the beams
  stand 0.075 in front of the rock, less than the omni light's default
  bias, so not even a light well to the side shadows the rock.
* **Without the bias, no beam shadows either:** the darker pixels are
  shadow acne, stair patterns along the grid's triangles (6 cm each). The
  shadow map cannot resolve relief this fine.
* **The torch is at the eyes** (0.46 units off): even a perfect shadow
  falls behind what casts it, about 4 pixels wide at 2 units.
* What the relief gives is silhouettes and parallax (the posts' sides down
  the corridor). Its normals are the flat grid's (10.6); the normal map
  shades it.

**Occlusion maps** darken the crevices instead, as baked occlusion does for
detail this size:

* `wall_height.gd ... ao_depth=0.125` also writes `ao.png`. For each texel,
  1 less the mean over 8 directions of the sine of the horizon's elevation
  (the steepest rise within `ao_radius` 32 texels, wrapping sideways), with
  the height map's full range `ao_depth` units deep on a 4-unit quad.
* Made from the full-size height map, the rock's own grain greyed all the
  rock with specks and the band by the beams hardly showed. Now:
  * the height map is averaged down 4 times first (`ao_scale`; trilinear,
    from the mipmaps; a plain resize picks texels and the specks stayed);
  * a rise counts only above 0.2 of the range (`ao_floor`). The beams stand
    0.6 over the rock and its grain 0.15, so the rock by the beams and the
    frame's corners darken, and open rock stays white;
  * true to the depth, that band darkened the lit rock by about 6 % at
    most, too little to read. It is baked 4 times exaggerated
    (`ao_strength`).
* The mine wall and roof have one (`ao_depth=0.125`, the Tunnel's relief
  0.025 × `relief_scale` 5; their height and normal maps came out byte for
  byte the same).
* `HDMaterials` already read `ao.png`, but StandardMaterial3D's occlusion
  darkens only the ambient light, which in the mine changed 0.11/255 on
  average. New setting `occlusion` (0.5; panel row under `roughness`):
  `ao_light_affect`, how much it darkens the lights too. The light is mixed
  linearly with the map, so 0.5 of the 4-times map is twice the true
  occlusion, and 1 is the panel's strongest.
* Checked in the Tunnel at mark0 through AutoPlay against `occlusion=0`:
  0.5 darkens 4.8 % of the pixels by more than 8/255, 1 darkens 8.2 %. That
  is the rock along the posts and braces and round the roof's cross-beams.
  `check_all.gd -- proto`: 8 scripts, 0 failed.
* Relief at another depth keeps the map baked for 0.125; bake again for a
  floor tuned much deeper. The forest wall has none yet.

Settings changed: new `occlusion`.

### 10.14 Door walls in relief (2026-11-04)

Walls with doors stayed flat while the walls round them had relief. They
come in two kinds:

* **A door's wall in the layout** (a `door` object's wall is a wall
  texture: the Tunnel's door 37, `minecavedoor0`; Forest Path's door 10,
  `forestdoor0`). Its texture had no height map in the set, so it stayed a
  flat PBR quad.
* **Hinder doors** (the Tunnel's 7, 51 and 53; Forest Path's 111). The
  legacy drawing draws one as a wall quad over the wall it is on (or where
  there is none, as at 53), with its open or its locked image
  (`HinderDoor.place_view`). They were still the legacy shader's quads.

Now:

* **Height maps for the six door images** in the painted set, made as the
  walls' are:
  * `minecavedoor0`/`1` and `minecavedoorbig0`/`1`: `wall_height.gd ...
    recipe=timber ao_depth=0.125 hole=0.04`, and `material.cfg` with
    `relief_scale=5`, as the mine wall has.
  * The timber recipe's new option `hole` (default 0: off): rock darker than
    it, in a patch at least 32 texels wide (`OPENING` 16), is an opening and
    sinks from the rock to 0 over `bevel`. Without it a doorway lay at the
    rock's 0.4 and looked like a painted panel. The mine wall's maps come out
    byte for byte the same at `hole=0.04`, so the rock's dark specks are
    left alone.
  * `forestdoor0`/`1`: recipe `stones` with `mortar=0.5246` and `0.2969`,
    the shares of their texels at or below the forest wall's mortar
    threshold (its darkest 20 %, brightness 0.27). At the default 0.2 the
    threshold fell inside `forestdoor0`'s dark doorway: no mortar line
    counted, and the stones merged into one slab.
* **Hinder doors as relief** (`HDLook._relief_doors`, `HDLook.show_object`).
  On a floor entered with `relief` above 0 and `materials` on, each hinder
  door whose images all have a height map in the set gets a relief quad per
  image (`HDWalls.wall_quad`, the quad `DungeonFloor._wall` builds for its
  cell and side):
  * it takes the place of the layout's wall there, which is left out of the
    flat mesh and the relief (`HDWalls.place_key`);
  * it counts as a wall for the fades, for back-to-back walls and for the
    sun blockers;
  * it sinks by its image's `relief_scale`, like any relief.
* **New hook `DungeonLook.show_object`** (game code).
  `DungeonScene.show_object` calls it for every object every frame, before
  the object's quad joins the batches:
  * the HD look shows the instance of the image the legacy door binds
    (`view.frame`: 0 open, 1 locked), and the scene leaves the quad out;
  * before a door's first draw, the instance of the image its `View` shows
    is visible.

  Otherwise a hinder door stays the legacy quad, as before: `relief` 0 at
  floor entry, `materials` off, or an image without a height map.
* **Checked through AutoPlay**, on `dungeon_tunnel_button`'s route with more
  shots and with `--start-node` views in Forest Path. The shots cover:
  * the Tunnel's door 53, from the corridor (the open door the review
    showed flat) and face on;
  * door 7, locked;
  * door 51, locked at entry and open after the lever: its image switches;
  * door 37;
  * Forest Path's door 10 (the arch) and 111 (locked: the filled doorway).

  The same shots in the legacy look show the hinder doors' images facing
  the same way. With `relief=0`, door 53 stays the legacy quad.
  `check_all.gd -- proto`: 8 scripts; `scenes/dungeons`: 10; 0 failed.
* **Not done:**
  * The albedo lift (`brightness`, `contrast`) makes a doorway's black a
    dark brown up close, as it does every texture's darks.
  * The parity cases were not recorded again. Without `--look` the scene's
    new call is skipped (`_look` is null).

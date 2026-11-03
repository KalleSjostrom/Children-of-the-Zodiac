# Villager sprites: uniform frames and sprite sheets

Two changes to the character images of villages and cutscenes, in this
order:

* **Plan A:** every frame of a walking character is 36×56.
* **Plan B:** one sprite sheet per character replaces its 16 PNGs.

A is useful on its own and makes B a plain grid. Neither should change what
the game shows or how it plays: both are checked with a full parity run.
Facts as of 2026-11-03, after phase 1's legacy village path was removed
(plan 6.9).

## What the code assumes today

* **Files.** `res/Village/<folder>/villagers/<Name>/<Name>1..16.png` and
  `res/Village/Characters/<Name>/<Name>1..16.png`. Files 1–4 face up, 5–8
  right, 9–12 down, 13–16 left (`Values.UP..LEFT` = 0..3). Walking shows
  `ia[i + dir * 4]`, 150 ms each; standing shows the direction's first
  frame (`Sprite._moveImpl`, `_standStillImpl`). With 1–3 images only
  image 1 shows.
* **Paths, not textures.** The legacy `Sprite` keeps frame paths
  (`animImages`), built by `Sprite.loadImages` / `loadImagesFromPath` /
  `loadPermImages` (`src/sprite/Sprite.gd:63-86`) and loaded by
  `ImageHandler` through `file_index.txt`. Callers: `Villager.loadImages`
  (the `.char` `image` line, once per villager; `char/` means
  `Characters/`), `PartyMember` (permanent), `LandPlayer` (Kin on the world
  map), `Actor` (cutscene actors `…/<Name>Extras[N]`), `AnimatedObjects`
  (`animobj`). The story event `kind=animation` puts
  `Characters/Animation/<name>.png` into `animImages[17]` (13 uses).
* **Drawing.** `Village.scene_sprites` turns the path into a texture
  (`ImageHandler.getTexture(path).getGodotTexture()`), and
  `ActorView.show_frame` (`scenes/common/ActorView.gd:48`) finds that
  texture in its `SpriteFrames` **by object identity**. A texture it does
  not know goes to an `extra` animation; party members, cutscene actors
  and the world map's player always take that path.
* **SpriteFrames.** 168 village `.tres` in `resources/sprite_frames/<folder>/`
  (the `Characters/` ones are shared between villages): animations `up`,
  `right`, `down`, `left`, 4 frames each, 150 ms. The removed converter
  wrote them. `ActorView` never plays them; they give the editor's preview
  and the identity lookup.
* **Size.** Nothing reads a frame's real size. The logic uses constants:
  `Sprite.STANDARD_WIDTH/HEIGHT` (36×56); `Player.getHeight/getWidth`
  (56/36) for the obstacle inflation (`ObstacleHandler.addObstacle`) and
  the background bounds; the 36/55 overlap test of the top layer
  (`DoubleBackground.overlapped_pieces`); the sitting villagers' `.char`
  size (`image <Name> 1 40 26`). The anchor is the top-left corner, and
  sorting uses the top edge.
* **Rendering.** Linear filtering (the project default), images imported
  lossless without mipmaps and with `fix_alpha_border`. A cutscene's
  `screenzoom` scales up to ×2 (26 `.seq` files), and full screen stretches
  1024×768 by a non-integer factor, so neighbouring pixels get sampled.

## The data

| Images | Sets | Frames | Size |
|---|---|---|---|
| walking characters | 198 | 16 | 106 at 36×55, 92 at 36×56 |
| single frames | 4 | 1 | 36×56 (Temeth, Haness, Kurt, Deel) |
| sitting villagers (Zazo `*sitting`) | 5 | 1 | 26×40 |
| Home of the Gods zodiac images | 12 | 1 | 28×113 |
| `ball` (cutscene prop, `ballExtras3`) | 1 | 3 | 16×16 |
| `Characters/KinSmall` | 1 | 16 | 18×27; files named `Kin1..16`, so it can't be loaded; unreferenced |
| `Characters/Kin.png`, `Celis.png` | – | – | 128×192 sheets of 32×48 cells; unreferenced |
| `Characters/Animation` | – | 19 images | cutscene poses, 25×41 to 56×56 (11 referenced) |

* No set mixes sizes, so no sprite jitters between frames today.
* **36×55 is not a cropped 36×56.** In 56-high frames the opaque feet end
  on row 52 and a soft shadow reaches the last row (55). In 55-high frames
  the feet end on row 51 and the last two rows are empty. Padding a
  55-high frame at the **bottom** keeps today's picture exactly. Padding at
  the **top** lines the feet up with the 56-high characters, but draws
  those characters 1 px lower.
* The party mixes the two: Kin, Celis and Borealis are 56 high, Zalzi 55.
* **Content quirks found on the way.** Don't fix these silently; they
  belong in `tickets/triage.md`:
  * Four villagers are invisible because their `.char` image path is wrong
    (Alares/Hilda, Pensara North District/GTthief, Zazo - Tent/Shaun,
    Civil House/Podd); their SpriteFrames are empty.
  * Zazo/Storygroup has empty frames 10–11 (unreferenced).
  * 31 sets are referenced by nothing, the 12 zodiac images among them.
  * Some sets are byte-identical copies: Borealis, Celis and Zalzi in The
    Prison Cell and in `Characters/`, plus 11 groups under different names
    (for example Petir = Ulph = Tito). Emma, Farl and Marcus exist twice
    with different art.

## Plan A: uniform 36×56 frames

**Goal:** every frame of a walking character is 36×56, the size the code
already assumes. Nothing moves on screen.

**Scope:**
* The 198 walking sets (106 change).
* The 4 single 36×56 frames (already right).
* The 5 sitting villagers: 26×40 → 36×56, padded right and bottom. Their
  `.char` size (40×26) stays, because it is logic, not art.

**Not in scope:**
* The zodiac images, `ball`, `animobj` and props: they are not characters.
* `Characters/Animation`: one-off cutscene poses up to 56 px wide. They
  stay single images in `animImages[17]`.

**Steps:**
1. **Decide the padding.** Bottom (recommended: identical picture) or top
   (feet aligned; 106 characters, Zalzi among them, drawn 1 px lower). Top
   padding is a visible change and its own decision. Either way the logic
   is unaffected, since it uses constants.
2. **Tool.** `tools/art/pad_character_frames.gd`, headless Godot using the
   `Image` API: load the frame, blit it at (0, 0) into a 36×56 RGBA8 image,
   `save_png`. It prints every set it changes and has a `--dry-run`. Keep
   each `.import` file (same path, same uid and settings), then run
   `Godot --headless --path . --import`.
3. **Optional cleanups**, each a separate decision:
   * delete KinSmall and the two unreferenced 128×192 sheets;
   * delete the unreferenced sets;
   * point `.char` lines of byte-identical copies at `char/<Name>`. This is
     a data change; check it with the `tour_*` cases.
4. **Verify.** Run `tools/check.sh`, then a full parity run against a
   baseline recorded just before. Expected result: identical. The only
   possible differences are zoomed cutscene shots of the 44 frames 36×55
   with pixels in their last row: the bilinear sample below that row was
   the clamped row and is now an empty row.

**Effort:** small. A ~60-line tool, one run, one parity cycle.

## Plan B: one sprite sheet per character

**Goal:** `<Name>/<Name>_sheet.png` replaces `<Name>1..16.png`. The sheet
has 4 columns (walk frames) and 4 rows (up, right, down, left: the file
order), with 36×56 cells. About 200 sheets replace about 3,200 PNGs and
their `.import` files, and each character becomes one file to edit.

**Approach:** keep the legacy frame paths as frame *names*, and resolve
each one to a region of its sheet. The legacy objects (Sprite, the story
timeline, Player) keep working with paths; only loading and the view's
lookup change. Rewriting `Sprite` to hold frame indices is the larger step
for when the actors become nodes.

**Layout:** a 40×60 pitch per cell (a 2 px empty gutter around each
36×56 cell) and `AtlasTexture.filter_clip = true`. A 4×4 sheet is then
160×240.
* The gutter stops `fix_alpha_border` and linear filtering from pulling
  colour from the next frame (cutscene zoom, full screen).
* `filter_clip` keeps sampling inside the region, as clamp-to-edge does
  for a separate texture.

**Steps:**
1. **Plan A first**, so every cell is the same size.
2. **Pack tool.** `tools/art/pack_character_sheets.gd`:
   * Write `<Name>_sheet.png` for every 16-frame set, with an `.import`
     like the frames' (lossless, no mipmaps, `fix_alpha_border`).
   * Check that every frame round-trips: cut its region back out and
     compare it with the file.
   * Sets with 1–3 frames stay single images.
   * Take the name from the folder, not from a digit pattern: `Man1`,
     `Man2`, `Sailor1` and `Sailor2` have files like `Man11..Man116`.
3. **Loading.** In `ImageHandler._loadTexture`
   (`src/graphics/ImageHandler.gd:97`): when a frame file is not in the
   index but `<dir>/<D>/<D>_sheet.png` is, return a `GameTexture` over an
   `AtlasTexture` (the sheet, frame n's region, `filter_clip`), cached by
   name.
   * This works set by set, so the migration can be gradual, and a missing
     sheet falls back to the frame files.
   * Check `GameTexture.getData` (`get_image()` on an AtlasTexture returns
     the region) and the width and height (the region's).
4. **ActorView.** Look frames up by a key instead of by identity: an
   AtlasTexture's key is its atlas (one object per sheet, cached by
   `ResourceLoader`) plus its region; any other texture is its own key.
   * Then the SpriteFrames' AtlasTextures and ImageHandler's match without
     being the same objects, and still match after ImageHandler drops a
     game mode's list.
   * This touches `_index_frames`, `show_frame` and `_add_extra_frame`.
5. **SpriteFrames.** Rewrite the 168 village `.tres` with a small tool:
   same animations, frames as AtlasTexture sub-resources of the sheet. The
   4 empty ones stay empty until their quirk is decided.
6. **Delete the frames.** Remove the PNGs and `.import` files of every
   packed set, regenerate `file_index.txt` (`python tools/gen_file_index.py`;
   it lists every file under `res/`, so drop unrelated new files from its
   output), and reimport.
7. **Optional, same mechanism:** the airship (`res/Landscape/Airship`, 16
   frames at 36×55) and the animated objects (the fountain has 4 frames).
8. **Verify:**
   * `tools/check.sh`.
   * A full parity run against a fresh baseline. Expected: identical. The
     zoomed shots (AutoPlay's `[zoom]` lines) are the ones to look at.
   * By hand: the party in a village, a cutscene with `Extras` actors and
     an `animation=17` pose, Kin on the world map, a store.
   * An export build: an export compiles scripts in a different order, and
     it finds images only through `file_index.txt`.
   * A look in full screen.

**Risks:**
* **Identity.** Other code that compares textures: check every user of
  `getGodotTexture()`.
* **Bleeding** at zoom or in full screen, if the gutter and `filter_clip`
  are not enough. The parity zoom shots show it; the fallback is to copy
  each cell's edge pixels into its gutter.
* **Paths.** Sheet paths go through the case-insensitive index like every
  legacy path.
* **Editing art.** The sheet becomes the source, so its grid and row order
  must be kept. A template image with the cell grid helps.

**Effort:** medium. Two tools, about 40 lines in ImageHandler and ActorView,
regenerated `.tres` files, one parity cycle.

## Order

Record a baseline before each plan. Do A, then B, each as its own change to
review.

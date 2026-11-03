# Villager sprites: uniform frames and sprite sheets

Two changes to the character images of villages and cutscenes, in this
order:

* **Plan A:** every frame of a walking character is 36×56.
* **Plan B:** one sprite sheet per character replaces its 16 PNGs.

A is useful on its own and makes B a plain grid. Neither should change what
the game shows or how it plays: both are checked with a full parity run.
Facts as of 2026-11-03, after phase 1's legacy village path was removed
(plan 6.9).

**Status (2026-11-03): A and B are done**, see "As built" under each plan.
The sections before them describe the files as they were before A; the
current layout is in `docs/ARCHITECTURE.md` section 9, "Character frames and
sheets". Where the facts below turned out different, they are corrected in
place (marked *Checked:*).

## What the code assumes today

* **Files.** `res/Village/<folder>/villagers/<Name>/<Name>1..16.png` and
  `res/Village/Characters/<Name>/<Name>1..16.png`. Files 1–4 face up, 5–8
  right, 9–12 down, 13–16 left (`Values.UP..LEFT` = 0..3). Walking shows
  `ia[i + dir * 4]`, 150 ms each; standing shows the direction's first
  frame (`Sprite._moveImpl`, `_standStillImpl`). With 1–3 images only
  image 1 shows. *Checked:* with n of 2–3 images a sprite moving up
  animates images 1..n (`ball` in a cutscene); any other direction keeps
  its images; with 1 image only image 1 shows.
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
* **SpriteFrames.** 168 village `.tres` (*checked:* 165, of 242 SpriteFrames
  with the animated objects' and the dungeon objects') in `resources/sprite_frames/<folder>/`
  (the `Characters/` ones are shared between villages): animations `up`,
  `right`, `down`, `left`, 4 frames each, 150 ms. The removed converter
  wrote them. `ActorView` never plays them; they give the editor's preview
  and the identity lookup.
* **Size.** Nothing reads a frame's real size (*checked:* only the drawing
  does: `Graphics.drawImage` draws a quad of the texture's size and
  `ActorView` an AnimatedSprite2D of it; the dead Java remnant
  `VillageAnimation.draw` cut 36×55 cells from a sheet at a 36 px row
  pitch and is never called). The logic uses constants:
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
  the feet end on row 51 and the last two rows are empty. *Checked*
  (alpha ≥ 0.5 counted as opaque): 56-high frames end on row 53 (1,032 of
  1,472) or 52 (366), and 976 have pixels in row 55; 55-high frames end on
  row 52 (1,135 of 1,696) or 53 (266), 1,310 leave rows 53–54 empty, 44
  have pixels in row 54 (Menthu, Passguard, RyoldMemory, Storygroup). Padding a
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
    *Checked:* 31 (not counting `Characters/Animation`, which the story's
    `kind=animation` names); four more (Berca's Benzer, the North District
    Library's Hanrry, Luna, Philiph) only by `.char` files no village
    places. All in `tickets/triage.md`, C1–C7.
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
1. **Padding: bottom** (decided 2026-11-03; the picture stays identical).
   Top padding would have lined the feet up but drawn 106 characters,
   Zalzi among them, 1 px lower. Either way the logic is unaffected, since
   it uses constants.
2. **Tool.** `tools/art/pad_character_frames.gd`, headless Godot using the
   `Image` API: load the frame, blit it at (0, 0) into a 36×56 RGBA8 image,
   `save_png`. It prints every set it changes and has a `--dry-run`. Keep
   each `.import` file (same path, same uid and settings), then run
   `Godot --headless --path . --import`.
3. **Cleanups:**
   * Decided: delete the two unreferenced 128×192 sheets
     (`Characters/Kin.png`, `Celis.png`). Files named `…_pixel` are
     pixel-art tests and stay.
   * Not decided, so not done: delete KinSmall; delete the unreferenced
     sets; point `.char` lines of byte-identical copies at `char/<Name>`
     (a data change; check it with the `tour_*` cases).
4. **Verify.** Run `tools/check.sh`, then a full parity run against a
   baseline recorded just before. Expected result: identical. The only
   possible differences are zoomed cutscene shots of the 44 frames 36×55
   with pixels in their last row: the bilinear sample below that row was
   the clamped row and is now an empty row.

**Effort:** small. A ~60-line tool, one run, one parity cycle.

**As built (2026-11-03): done.**
* `tools/art/pad_character_frames.gd` (with `tools/art/character_sets.gd`,
  the sets in scope: 198 walking sets and 9 single frames, no `_pixel`
  file) padded 111 sets, 1,701 frames: the 106 sets of 36×55 at the bottom,
  the 5 sitting villagers (26×40) at the right and bottom. 1,476 frames were
  already 36×56. Each padded frame was read back and checked (the old frame
  in the top-left, pixel for pixel; the rest transparent). The `.import`
  files are unchanged; a second run changes nothing.
* `Characters/Kin.png` and `Celis.png` (and their `.import`) are deleted;
  nothing referenced them (no path, no uid).
* Parity (410 cases with `bridge_test`, 7,685 shots; baseline `sbase`
  recorded on 5be3331f plus the two new cases `sprites_*`, A = `spadA`):
  same exit codes, shot counts and error lines in every case (2,453 error
  lines each); 106 shots in 9 cutscene cases differ, every one of them a
  zoomed shot (`[zoom]`), and every differing pixel lies on a padded
  sprite: the bottom edge of the 36×55 frames with pixels in their last row
  (Menthu, Passguard, RyoldMemory; 1,375 pixels, up to 54/255: the
  predicted difference), the right and bottom edge of the sitting
  villagers (`zazo_story_node1`, 4,205 pixels, up to 65/255: the same
  effect, also at the right), and ≤ 1/255 inside the 36×55 and sitting
  frames under the zoom (5,613 pixels: the texture is 56 rather than 55
  high, so the bilinear sample positions round differently, on whole
  rows; the plan did not predict this one).

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
* *Checked, and changed as the fallback below says:* `filter_clip` does
  not do that here. Its clamp lands a hair inside the edge texels, so a
  cell's last column and row blend with their neighbours by up to 3/255
  even unzoomed (and up to 15/255 zoomed; in a parity run of 9 cases 204
  of 416 shots differed, all of `sprites_party_walk` and `tour_parasne_0`).
  Without it the zoom bleeds the empty gutter in (up to 59/255). As built,
  the gutter holds each cell's edge pixels (extruded) and `filter_clip` is
  off: a frame at 1:1 is then exactly its frame file, and a zoomed one is
  within 2/255 of it (the sheet's size changes the bilinear rounding, as
  plan A's height did).

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

**As built (2026-11-03): done**, with the gutter fallback instead of
`filter_clip` ("Layout" above). How it works now: `docs/ARCHITECTURE.md`
section 9, "Character frames and sheets".
* `scenes/common/CharacterSheet.gd`: the layout (cell n's region), the
  sheet's path, a frame path's number (from the folder's name: Man1's
  `Man11..Man116`) and `frame_texture(path)`, the AtlasTexture of a frame
  path's cell (no `filter_clip`).
* `tools/art/pack_character_sheets.gd` wrote 198 sheets (all the walking
  sets, `KinSmall` aside), with the frames' import settings; every cell
  round-trips to its frame file, pixel for pixel, and the gutter is the
  cells' extruded edges (95 sheets have pixels on a cell's edge, the
  other 103 a transparent gutter either way). `--delete-frames` deleted
  the 3,168 frame files and their `.import` files. For a sheet without
  frame files it extrudes the gutter again when an edit left it stale.
* `ImageHandler._loadTexture`: a path that is not in the index goes to
  `CharacterSheet.frame_texture` before "image not found"; the
  `GameTexture` over the AtlasTexture is cached by the frame path in the
  mode's list. Through `GameTexture`: `getGodotTexture` is the
  AtlasTexture, `getWidth/getHeight` 36×56, `getData` the cell's image,
  `getImageTexCoords` the cell's coordinates in the sheet (the legacy
  drawing binds the AtlasTexture's RID, which is the sheet's: the world
  map's `--legacy=world_map` and the bridge test draw Kin that way).
* Users of `getGodotTexture()` checked: only `ActorView.show_frame`
  compares frame textures (the village's and the cutscene's sprites, the
  world map's player); the rest pass them to a node.
* `ActorView`: `_frame_key` (an AtlasTexture's atlas and region, any other
  texture itself) in `_index_frames`, `show_frame` and `_add_extra_frame`.
* `tools/art/rewrite_sprite_frames.gd` rewrote 152 of the 165 village
  SpriteFrames (2,432 frames; the animations, their order, 150 ms and the
  loop unchanged); the 13 others have no packed frame: the four empty ones
  and the 9 single frames.
* Files: character images 3,229 → 257 (8.96 → 6.33 MB), their `.import`
  files 3,229 → 257 (3.14 → 0.25 MB), village `.tres` 165 (0.48 → 0.54
  MB), `file_index.txt` 5,934 → 2,962 lines (294 → 129 KB).
* Parity (410 cases, 7,685 shots, B = `spB`, again `spB2`): B vs. B2
  identical (six cases at the end of the second recording crashed out of
  memory and were recorded again alone). B vs. A: same exit codes and shot
  counts; error lines the same except a "WASAPI: GetBufferSize error" (an
  audio device event) in one or two cases of each run. 300 shots of 14
  cutscene cases differ, every one zoomed, every differing pixel on a
  packed sprite: 72,410 pixels by 1–2/255 (bilinear rounding: the texture
  is the 160×240 sheet, not a 36×56 frame; on whole columns and rows) and
  5 pixels by 12–15/255 where that rounding moves an alpha of 5–51 across
  the scene's alpha test. No cell edge bleeds (3,061 of the pixels are on a
  cell's edge, all by 1/255). The baseline vs. B: plan A's differences
  plus these (304 shots).
* Checked by hand: the export (it finds the sheets through
  `file_index.txt`; a village and a cutscene run with no error), full
  screen (1440×1080; before vs. after within 2/255, no frame edge shows),
  the editor's previews (`scene_preview.gd`, Parasne and Zazo: identical),
  Parasne's load time in normal runs (the mode's init, first entry:
  512–632 → 254–397 ms; entering it again: about 175 → 165 ms).

## Order

Record a baseline before each plan. Do A, then B, each as its own change to
review.

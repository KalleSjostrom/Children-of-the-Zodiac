Implement docs/VILLAGER_SPRITES_PLAN.md in this Godot 4.7 project: Plan A (every frame of a
walking character becomes 36×56, padded at the bottom), then Plan B (one sprite sheet per
character replaces its 16 frame PNGs). Neither changes what the game shows or how it plays:
both must pass a full parity run against a baseline recorded before them.

Why: each character becomes one file to edit, about 3,200 frame PNGs (and as many .import
files) become about 200 sheets, and every cell has the size the code already assumes. The art
of the characters is going to be redrawn later; this prepares the files for that. It is not
part of this task.

Read first:
- docs/VILLAGER_SPRITES_PLAN.md, all of it: what the code assumes, the data, both plans, the
  risks;
- docs/ARCHITECTURE.md: sections 2, 3, 6, 7 and 9 (villages as scenes: ActorView, how the
  village hands the scene what the legacy drawing drew), the rest as needed;
- docs/MODERNIZATION_PLAN.md: 6.9 (closing phase 1, as built) and 12 (the risks, especially
  memory during recordings);
- docs/HANDOFF.md: how to run Godot, AutoPlay, tools/check.sh and the parity tool, and how to
  record a parity set from a copy of the project;
- docs/PORTING.md: the rules for legacy files you touch;
- docs/port_notes/villages.md and docs/port_notes/story.md;
- tickets/triage.md: the content quirks already listed.

State:
- Phase 1 is closed: the legacy village path, the village converter (vil_to_scene.gd), its
  data check and the background tiles are removed. The village scenes and their SpriteFrames
  (resources/sprite_frames/**) are edited by hand now. The removed converter wrote the
  SpriteFrames; its code is the reference for their format: git show
  1e0229df:tools/import/vil_to_scene.gd (around lines 455-525).
- Start from a clean, committed tree. This prompt file doesn't count.
- Files whose base name ends in "_pixel" or "_pixel<digits>" (res/Menu, res/Store, res/Story,
  and any that appear under res/Village) are pixel-art tests. Do not move, edit, pad, pack or
  delete them, and keep them out of file_index.txt (the current index leaves them out).
- The goldens in tools/parity/out are machine-specific; "vbase" is the last full set (on
  1e0229df). Record your own baseline.
- If the Godot editor is open on the project, it imports new files and generates .uid files.
  Close it while recording.
- Memory: the machine has 16 GB. An 8-job recording leaves about 3 GB. Run nothing beside a
  recording, not even a headless parity compare: both have run the machine out of memory
  (segfaults in AutoPlay's get_image, failed WebP decodes). Record from a copy of the project
  (tar without .git and tools/parity/out) if you want to keep editing meanwhile.
- A case that fails to start under load (exit 127, 0 s, empty log) is re-recorded alone. A
  lone 1/255 difference in a GPU particle (Dellna's snow) has been run-to-run noise:
  re-record that case alone before blaming your change.

Decisions:
- Padding: bottom. A 36×55 frame is blitted at (0, 0) into a 36×56 image, so the picture
  stays the same. The sitting villagers (26×40) are padded right and bottom to 36×56; their
  .char size (image <Name> 1 40 26) stays, because it is logic.
- The logic keeps its constants: Sprite.STANDARD_WIDTH/HEIGHT, Player.getHeight/getWidth and
  the obstacle inflation, the 36/55 overlap test of DoubleBackground.overlapped_pieces, the
  top-left anchor, the sort by the top edge.
- Sheet layout: <set folder>/<Name>_sheet.png, 4 columns (walk frames 1-4) × 4 rows (up,
  right, down, left: files 1-4, 5-8, 9-12, 13-16), 36×56 cells at a 40×60 pitch (a 2 px
  empty gutter around each cell; the sheet is 160×240), AtlasTexture.filter_clip on. If the
  parity zoom shots show bleeding, extrude each cell's edge pixels into its gutter instead,
  and say so.
- Approach: the legacy frame paths stay frame names. ImageHandler resolves a frame path whose
  file is not in the index, but whose set has a sheet, to a GameTexture over an AtlasTexture
  of that frame's region, cached by name. ActorView looks frames up by a key, not by object
  identity: an AtlasTexture's key is its atlas plus its region, any other texture is its own
  key. Do not rewrite Sprite to hold frame indices.
- Delete the two unreferenced 128×192 sheets, res/Village/Characters/Kin.png and Celis.png,
  with their .import files. Check first that nothing references them.
- Make no other decision the plan leaves open.

In scope:
- Plan A: the 198 walking sets (106 of them 36×55), the 4 single 36×56 frames (already
  right), the 5 sitting villagers.
- Plan B: every set of 16 frames under res/Village/**/villagers/ and res/Village/Characters/,
  and the village SpriteFrames that use them.

Not in scope:
- Sets of 1-3 frames as sheets (they stay single images), the Home of the Gods zodiac images,
  ball, the animated objects (animobj), the props (Stuff), Characters/Animation (the cutscene
  poses of the story's animation event), the airship (res/Landscape/Airship).
- KinSmall, the unreferenced sets, the byte-identical duplicates, the four invisible
  villagers (broken .char image paths) and Zazo/Storygroup's empty frames: list them as
  content quirks, do not fix or delete them.
- Any change to the art, the frame order, the timing or the logic. No step C.

Deliverables, in this order. Do (0) before changing any image, so that the baseline is
recorded on the current files.

0. Facts, coverage and the baseline
   - Verify the plan's "What the code assumes today" and "The data" before relying on them:
     the frame order and the standing frame, every caller that loads frames by path
     (Villager, PartyMember, LandPlayer, Actor with Extras[N], AnimatedObjects, the story's
     animation event into animImages[17]), that nothing reads a frame's real size, the
     counts and sizes per set, which sets are referenced (.char image lines, .seq actors),
     and the sets whose file prefix is not a plain "<Name><n>" (Man1, Man2, Sailor1,
     Sailor2: files Man11..Man116; take the name from the folder).
   - Coverage: find which cases show each of these, and add cases for what none shows: a
     55-high and a 56-high villager walking in all four directions and standing; the party
     walking, with Zalzi (55 high) and Kin (56 high); a sitting villager; a Characters/ set
     shared between villages; Man1/Man2 or Sailor1/Sailor2; a cutscene with Extras actors;
     the animation=17 pose; a cutscene zoom (screenzoom) with characters on screen; Kin on
     the world map; a store entered from a village. Plan routes with pos in headless probe
     runs. Record the new cases twice and show the self-diff is 0.
   - tools/check.sh reports 0 failed. Record the baseline of all cases
     (tools/parity/parity.sh record <set> --jobs=8, plus bridge_test, which is "extra").

1. Plan A: uniform 36×56 frames
   - tools/art/pad_character_frames.gd (headless Godot, the Image API): pads the frames in
     scope at the bottom (sitting villagers: right and bottom), prints every set it changes,
     has --dry-run, skips _pixel files, keeps each .import file (same path, uid and
     settings). Running it twice changes no file.
   - Delete Characters/Kin.png and Celis.png with their .import files.
   - Reimport (Godot --headless --path . --import), regenerate file_index.txt
     (python tools/gen_file_index.py, then drop the _pixel lines).
   - Parity: baseline vs. A, every case, shots and per-case error lines. Expected identical;
     the only acceptable differences are zoomed cutscene shots of 36×55 frames with pixels
     in their last row (the sample below that row was the clamped row, now an empty one).
     Explain every difference with its diff image.

2. Plan B: one sprite sheet per character
   - tools/art/pack_character_sheets.gd: writes <Name>_sheet.png for every 16-frame set in
     scope with an .import like the frames' (lossless, no mipmaps, fix_alpha_border), checks
     that every frame round-trips (cut its region back out and compare it with the frame
     file, pixel for pixel), skips _pixel files. Running it twice changes no file.
   - ImageHandler (src/graphics/ImageHandler.gd, _loadTexture) resolves packed frames as
     decided, set by set: a set without a sheet still loads its frame files. Check every
     GameTexture method a frame goes through (getGodotTexture, getWidth/getHeight: the
     region's; getData: get_image() of an AtlasTexture) and every place that compares
     textures (search the users of getGodotTexture()).
   - ActorView (scenes/common/ActorView.gd): the frame key in _index_frames, show_frame and
     _add_extra_frame.
   - A tool rewrites the village SpriteFrames .tres: the same animations (up, right, down,
     left, 4 frames, 150 ms, loop), the frames as AtlasTexture sub-resources of the sheet
     with filter_clip. The four empty ones stay empty. Running it twice changes no file.
   - Delete the frame PNGs and .import files of every packed set; reimport; regenerate
     file_index.txt as above. A villager's image path must not reach ImageHandler's "image
     not found" error.
   - Parity: A vs. B and baseline vs. B, every case, shots and per-case error lines:
     identical, except what you explain with its diff image. Record B a second time:
     identical. Look at the zoom shots (AutoPlay's [zoom] lines) for bleeding at the cell
     edges.

3. Checks parity does not cover
   - An export: Godot_v4.7-stable_win64_console.exe --headless --path . --export-debug
     "Windows Desktop" <scratch>/build/ChildrenOfTheZodiac.exe (about 1 minute), then run
     <scratch>/build/ChildrenOfTheZodiac.console.exe --headless --quit-after 600 with
     APPDATA pointed at a scratch folder and, after --, --load/--start for a village, then
     for a cutscene. An export compiles the scripts in another order (do not use := on the result
     of an untyped function in another script) and finds images only through
     file_index.txt.
   - Full screen: a village and a zoomed cutscene in a normal run, before and after, with
     screenshots; say whether any frame edge shows.
   - The editor: a village scene's villager previews (tools/import/scene_preview.gd).
   - Load time of a village with many villagers (Parasne), before and after, in a normal run.

4. Docs
   - ARCHITECTURE.md: the folder layout (tools/art/), section 9 (the frame files, the sheets,
     how a frame path becomes a region, ActorView's key, the tools and how to add or edit a
     character).
   - HANDOFF.md: the new state.
   - docs/VILLAGER_SPRITES_PLAN.md: mark what is done, with an "as built" note per plan.
   - tickets/triage.md: the content quirks of "Not in scope" that it does not list yet.
   - Where your findings contradict the plan, update it and tell me.

Constraints:
- Normal play must not change: same picture, same logic, same timing.
- Legacy files follow PORTING.md (Java names, no redesign; bridge members snake_case). New
  files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the scripts under scenes/ and tools/. Run
  Godot from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the tools and how to run them, the sheet layout, and how a
  frame path becomes a region on screen;
- the facts of deliverable 0 as you found them, where they differ from this prompt or the
  plan;
- the new cases and what each shows;
- the parity results, explaining every difference: baseline vs. A, A vs. B, baseline vs. B,
  B's self-diff, error lines per case;
- the file counts and sizes before and after (images, .import files, .tres, file_index.txt);
- the export, full screen, editor and load time checks;
- the content quirks you listed;
- anything that surprised you or that the plan got wrong.

Implement the pilot of phase 1 ("villages as scenes") of docs/MODERNIZATION_PLAN.md in
this Godot 4.7 project. Convert Zazo (all four .vil variants) and one interior,
"Zazo - Miner's Home", through step A (data) and step B (presentation). Convert no other
place in this task.

Read first:
- docs/MODERNIZATION_PLAN.md, sections 3, 6, 12 and 13;
- docs/ARCHITECTURE.md, all of it: the bridge, the rules for new code, the flags and the
  parity workflow;
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh;
- docs/PORTING.md: the rules for legacy files you touch;
- docs/port_notes/villages.md.
Phase 0 is committed (00e03a5). It added: Main's tree (World, LegacyLayer, UI,
Transition); GameMode.create_scene() and scene_root; deterministic runs (--seed);
tools/parity/; and the bridge test (--bridge-test).

Decisions (plan section 13):
- Decision 1, village variants: one inherited scene per .vil variant on a shared base
  scene, as the plan recommends.   <-- EDIT IF NEEDED
- Decision 6, time base: not made, and nothing in this task may need it. Step B views only
  mirror legacy state. Village particles use an interim LegacyParticles2D node that runs
  the legacy simulation, not GPUParticles2D.
- Make no other open decision. Delete no .vil file: decision 5 is open, and the data
  check needs the files.

Deliverables, in this order. Do (1) before converting anything, so that the goldens are
recorded on unconverted code.

1. Parity coverage, then goldens
   - Add AutoPlay scripts and entries in tools/parity/cases.txt for:
     * each Zazo variant ("Zazo - 0", "Zazo - 1", "Zazo at Night - 0",
       "Zazo at Night - 1"). Shots must show: the fade-in; walking far enough that the
       background scrolls on both axes; the player under a roof or treetop; the chimney
       smoke (smokesystemBarackZazo, smokesystemInnZazo, smokesystemmayorZazo, with wind);
       a dialog with a villager; entering and leaving a building; the menu thumbnail.
     * Zazo - Miner's Home, entered through its door in Zazo and left again;
     * at least two Zazo cutscenes, Zazonode1 and "Meeting with Gerbias" (mode-14 places
       in maps/Main/main.bank, started with --start=<name>). Take shots while actors
       move, during a dialog, and during any zoom, image mode or colour tint they use.
   - Facts to verify before relying on them:
     * VillageLoader.load picks the variant from Database.getStatusFor("Zazo") and from
       info "time" == "night".
     * Start.sav has "status Zazo 0" and Slot 1.sav has "status zazo 1".
     * No story sequence seems to start Zazo at night; only "Zazo - Teo" has night info.
     * Zazo's shops show "Closed due to the accident" and some house doors are locked,
       depending on the save.
     If a variant can't be reached from a shipped save plus --start, add a dev-only way to
     start in it, for example a flag that sets Database statuses or the start place's
     time. Document it in Main.gd's header and in ARCHITECTURE.md. Normal play must not
     change.
   - Routes: NPCs and the inflated obstacle rectangles block paths. Phase 0's Alares
     route needed several probes. A dev AutoPlay command that logs the player position
     (village pixels; positions are [y, x]) saves time. It must not change the existing
     log lines, because parity compares them.
   - Record goldens of all cases, old and new: tools/parity/parity.sh record golden.
     Record the new cases a second time and show the self-diff is 0.

2. Converter tools/import/vil_to_scene.gd (plan 6.2), run headless
   - Read each .vil with the same tokenizer as VillageLoaderMapLoader (AbstractMapLoader).
     Map every command to typed, exported node properties.
   - Child order = file order: doors and signs are searched in order, and the first one
     in range wins.
   - Write the scenes under scenes/villages/<Place>/, with the layout of plan 6.1 and the
     variant split of decision 1. Shared scene types (Door, Sign, Loot, ActorView, ...) go
     in scenes/common/, each script beside its scene, as ARCHITECTURE.md requires.
   - Stitch each background's 256 px tiles (and the night background) into one PNG.
     Import it lossless, without mipmaps, with the same filtering as the legacy tiles, so
     the pixels match.
   - Top pieces (top/top.info) become Sprite2D nodes under Overhead.
   - Generate one SpriteFrames resource per villager image set and per animObj series,
     in resources/sprite_frames/.
   - Save with PackedScene.pack() and ResourceSaver.save(). Every created node needs
     owner = root, or it is silently dropped.
   - The scenes must open in the editor and show the village: background, top layer,
     night layer, and markers for spawns, doors, signs, loot and obstacles.
   - Running the converter twice must produce identical files.

3. Step A: data from scenes (plan 6.3)
   - When a scene exists for the chosen .vil, VillageLoader builds the legacy objects from
     its nodes instead of parsing the .vil: obstacles (with the same inflation), doors,
     signs, loot, villagers, animated objects, particle names, buildings, start
     positions, music, wind, the inside flag. Leave the villager .char files as they are.
   - --legacy=villages (Main.is_legacy("villages")) keeps the old .vil path.
   - Write tools/import/verify_villages.gd. It builds each converted variant both ways and
     compares the resulting objects field by field.
   - Also run converter and verifier over all 89 .vil files as a dry run: data only, into
     a temporary folder outside the project, nothing committed. Report what fails.
   - Parity: golden vs. after step A must be identical for every case, shots and logs.

4. Step B: nodes draw the converted places (plan 6.4)
   - Village.create_scene() returns the variant's scene for converted places. It returns
     null for other places and under --legacy=villages. --bridge-test must keep working
     for unconverted villages: the bridge_test case uses Alares.
   - A Camera2D mirrors the legacy scroll every frame; the legacy scroll logic stays in
     charge.
   - ActorViews mirror each legacy sprite's position, direction and frame. Look sprites
     up through the identity-keyed sprite map (plan 12).
   - Overhead is always drawn, with alpha scissor 0.9 (plan 6.1, "Top layer"). Add the
     night layer.
   - Each particle system goes in its layer node as a LegacyParticles2D.
   - Village.draw keeps only the overlays that stay legacy until phase 3: emotions,
     dialogs, signs, fades.
   - Cutscenes switch in the same step. VillageStoryTimeLine
     (src/story/VillageStoryTimeLine.gd:601-674) draws:
     * the village through village.drawBottom, then its own actors sorted by y;
     * image modes (backflash, translucent over/under actor, cover-all, story image);
     * a colour tint (g.setFadeColor);
     * a zoom (translate/scale around staticPos).
     Its actors become ActorViews, image modes a StoryImage node, the zoom becomes
     Camera2D zoom, and the tint a modulate.
   - Facts to verify: VillageStory is its own GameMode. It either reuses the previous
     Village mode, or creates a Village with Village.new() that never becomes an
     Organizer mode (VillageStory.gd:10-45, overwritePreviousMode). The village's scene
     must therefore show while VillageStory is current, without two modes owning it:
     GameMode frees scene_root in NOTIFICATION_PREDELETE. Extend the bridge if needed and
     document the change in ARCHITECTURE.md.
   - Move every state change that lived in a removed draw() into update (plan 2.4 and 12;
     drawEmotions, for example). Grep every draw() you remove.
   - Parity, two checks:
     * Zazo cases: tools/parity/parity.sh ab "--legacy=villages" "" <cases>.
     * All other cases: golden vs. after; they must be identical.
     Aim for identical pixels for the background, top layer and actors: mirror the legacy
     int() truncation of positions. Choose any tolerance deliberately, and explain every
     remaining difference with its diff image.
   - Measure fps in Zazo from normal runs (parity runs are uncapped), legacy vs. scene.

5. Docs
   - Update ARCHITECTURE.md with any new conventions and the converter workflow.
   - Update HANDOFF.md with the new state.
   - Write a short how-to for converting the next place: commands, and what to check.
   - Where your findings contradict docs/MODERNIZATION_PLAN.md, update it and tell me.

Constraints:
- Convert only the Zazo variants and Zazo - Miner's Home.
- No step C: no physics, no Area2D logic, no per-delta movement. Gameplay and timing
  stay unchanged in normal runs.
- No GPUParticles and no new art. Keep the 1024x768 screen and the village pixel
  coordinates; cutscenes, saves, Cheater jumps and AutoPlay depend on them.
- Legacy files follow PORTING.md (Java names, no redesign). New files follow
  ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the new scripts under tools/. Run Godot
  from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), and the scene/resource layout the converter produces;
- the verify_villages results, for the pilot and for the 89-file dry run;
- the parity results: golden vs. after step A; golden vs. after step B for the other
  cases; legacy vs. scene for the Zazo cases. Explain every difference;
- the screenshots you checked and what each showed;
- fps in Zazo, before and after;
- what Village and VillageStoryTimeLine still draw through legacy code, and why;
- anything that surprised you or that the plan got wrong.

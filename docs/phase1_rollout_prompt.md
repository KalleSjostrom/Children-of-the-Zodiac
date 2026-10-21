Complete phase 1 ("villages as scenes") of docs/MODERNIZATION_PLAN.md in this Godot 4.7
project: convert every remaining place through step A (data) and step B (presentation).
That is 84 .vil variants in 61 places; Zazo and "Zazo - Miner's Home" are done.

Read first:
- docs/MODERNIZATION_PLAN.md: section 6 (6.7 has the pilot's results), 12 and 13;
- docs/ARCHITECTURE.md, all of it; section 9 holds the phase 1 conventions;
- docs/CONVERTING_VILLAGES.md: the per-place procedure the pilot left you;
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh;
- docs/PORTING.md: the rules for legacy files you touch.

State:
- The pilot is committed (e7987cd). It added the converter (tools/import/vil_to_scene.sh),
  the data check (verify_villages.gd), scene_preview.gd, the scene types in
  scenes/common/ and scenes/villages/, and the step A and B bridge in Village,
  VillageLoader, VillageStory and VillageStoryTimeLine. It also added
  --legacy=villages, --legacy=village_top_layer, --start-time, --status, AutoPlay
  `pos` and parity --ignore-world.
- Ticket fixes have landed since (COTZ-001 to 011). Among them: difficulty levels
  (the new-game flow changed), and holding Circle runs cutscenes at triple speed
  (COTZ-007: Organizer.update runs three times per drawn frame). The scripts
  newgame_to_forest, story_long and title_start changed. The goldens in
  tools/parity/out are therefore stale.
- Start from a clean, committed tree.

Decisions (plan section 13):
- Decision 1, village variants: one inherited scene per .vil variant on a shared base
  scene, as in the pilot.
- Decision 7 (new, from the pilot; add it to section 13): roofs and treetops are always
  drawn (plan 6.1, the pilot's default). The legacy rule draws a piece only where a
  sprite overlaps it, and the PNG pieces differ from the JPEG background under them.
  Keep --legacy=village_top_layer for parity runs.
- Decision 5, text formats: not made. Delete no .vil file, and keep the .vil path and
  --legacy=villages: the data check and the parity runs need them. Removing the
  legacy village path is a separate step after review (deliverable 6 only prepares
  it).
- Decisions 3 (step C) and 6 (time base): not made, and nothing in this task may need
  them. Particles stay LegacyParticles2D.
- Make no other open decision.

Deliverables, in this order. Do (1) before converting any place, so that the goldens
are recorded on unconverted code.

0. Baseline
   - tools/check.sh reports 0 failed. Record goldens of all existing cases
     (tools/parity/parity.sh record golden).
   - Record the six Zazo cases a second time and show the self-diff is 0.
   - Re-run the pilot's check on top of the ticket fixes:
     ab "--legacy=villages" "--legacy=village_top_layer" --ignore-world <zazo cases>.
     It must give what plan 6.7 reports: identical except the 13 zoom frames of
     Zazonode1.

1. Parity coverage, then goldens
   - A tour script for any village (e.g. tools/autoplay/village_tour.txt). It needs no
     per-place route: fade-in shots, a settled shot, a fixed walk in all four
     directions long enough to scroll a large village, `pos` lines, the menu
     thumbnail. Bumping into obstacles is fine; runs are deterministic. Add one case
     per remaining variant to tools/parity/cases.txt, as a named group. Reach each
     variant with a shipped save plus --start, --status=<Place>:<n> and
     --start-time=night. Interiors have their own main.bank places.
   - Hand-written cases for what the pilot never exercised. Its step B code for these
     is unparity-tested:
     * particles: Alares (smoke); Dellna (snow and four smokes); Home of Celis (day
       and night); Pensara North District (wind -10, turbulence 1); Pensara School
       District. Home of the Gods has bottom-layer stars under a transparent
       background (StarParticle draws without the system position) and offset
       512,384. It also has villager-layer systems that wait for a status, and door
       systems with a background image that are additive. Pass to Zazo has a fire
       system in the villager layer (master and slave, sorted with the sprites);
     * animObj: the Alares fountain, the Vincent's Office desk, the chairs in
       "Dellna - Ana's Home Memory";
     * background variants: back with as= or a third number (Alares, Berca, Home of
       the Gods, No Place, the Pensara districts); an extra image name (Dellna:
       Dellna2); "--" folders (Parasne--1, Port of Alares--_-_With_Boat);
       villagerFolder (Port of Alares - 1); own night images ("<Place> at
       Night.jpg", "<Place> at Night - 1.png", which scroll with the village);
     * cutscenes: StoryImage modes; take shots while actors move, during dialogs and
       during every image mode, tint, zoom or background swap used:
       - backflash: The Revelation of Elmer (Alares), Tutorial1 and Meeting With the
         Rebels (Rebel Hideout), Celis Memory - Ana's Reaction;
       - translucent under actor and a swapped village background: Prolog and Elder
         of Dellna Saves the Day (No Place);
       - colour tint (setcolor): Meanwhile - Menthu Kills Teo (Crossroad, night) and
         Elder of Dellna Saves the Day;
       - props on the bottom and top layers: Arrival at the Port Town of Parasne;
       - cover-all and story images, which stay legacy overlays: check that they
         still cover the scene;
       - fadeparticlesystem with rainCelissystem: Home of Celisnode1. Its
         rainparticle has no class, a legacy bug; see the plan appendix;
       - scroll text: Ending - Part 3;
       - one cutscene with Circle held (COTZ-007).
   - Places that only cutscenes reach have no main.bank place; cover them through their
     stories:
     * Alares - Celis: Someone's Calling;
     * Dellna - Ana's Home Memory: the Celis Memory stories;
     * Home of Celis - Memory: Celis Memory - Arrival at the New Home;
     * No Place: Prolog, The Farl Story, ...;
     * The Senate: The Senate of Pensara, ...;
     * The Ship Cabin - Story: On the Boat to Pensara;
     * Zazo - Teo: Meanwhile in Zazo, Zazonode2-4.
     Dorma's Tranquility and Menthu Battle seem unreachable (no place, story or door
     found). Verify this. If so, check them with the data check and a preview only,
     or add a dev-only start, documented in Main.gd and ARCHITECTURE.md. Normal play
     must not change.
   - Facts to verify before relying on them:
     * which existing cases will switch to scenes once their village is converted:
       village_walk, village, stores and menu_pages (Alares); story_long and
       newgame_to_forest (the prologue's villages); possibly others (check the logs'
       place= values);
     * which save reaches each status variant, and which variants are broken content.
       Example: "Zazo at Night - 0" quits the game unless its loot is taken.
       Document each such case; do not fix content.
   - Record goldens of all cases, old and new. Record the new cases a second time and
     show the self-diff is 0. A full ab run will take hours: run long jobs in the
     background, and never edit game code while a recording runs. Each case starts
     Godot fresh and would pick up the edit.

2. Convert
   - Run tools/import/vil_to_scene.sh for the remaining places, in batches if you like
     (interiors first, then the towns, plan 6.6). Read every converter warning and
     report them.
   - Make the converter handle what the pilot never met, still producing exactly what
     DoubleBackground draws:
     * places without a tile folder (the background is one image);
     * PNG backgrounds with alpha;
     * "as=1:1" (only tile x0y0 is drawn);
     * night images of their own;
     * the variants of a place that do not share the art.
   - Converting twice must change no file. Preview every variant with
     scene_preview.gd --debug-collisions and check background, top layer, night
     layer, villagers and markers. Open a few in the editor.

3. Step A
   - verify_villages.gd over all 89 variants with the saves "Slot 1" and "Start"
     (more if a variant needs them): every build passes. The dry run in plan 6.7
     passed on data-only scenes; this run is on the real ones.

4. Step B
   - For each converted place's cases:
     * ab "--legacy=villages" "--legacy=village_top_layer" --ignore-world must be
       identical except differences you explain;
     * ab "--legacy=villages" "" --ignore-world may differ only inside top-layer
       pieces that no sprite overlaps.
   - All other cases: golden vs. after, identical.
   - Choose any tolerance deliberately, and explain every remaining difference with its
     diff image. Known ones from the pilot: the legacy tile seams and bilinear rounding
     in zoomed frames.
   - Fix what fails in the bridge code (Village, VillageStoryTimeLine, VillageScene,
     the place_* methods), not in legacy logic. A removed draw path whose state
     changes are lost is the first suspect (plan 2.4); grep every draw method you
     stop calling.
   - The bridge test (case bridge_test) uses Alares, and a converted village shows its
     own scene. Move the test to the world map, which stays legacy until phase 4.1:
     Landscape.create_scene() returns BridgeTest.tscn under --bridge-test. It must
     still show the fade over the scene, removal while the mode is suspended (menu)
     and freeing at the next mode switch. Update its script, case and
     ARCHITECTURE.md section 8.
   - Measure fps from normal runs (parity runs are uncapped), legacy vs. scene, capped
     and uncapped: Dellna (snow), Home of the Gods (many systems), Alares, one more
     large town.

5. Docs
   - Update ARCHITECTURE.md (new conventions, converter changes), HANDOFF.md (the new
     state) and CONVERTING_VILLAGES.md (what the rollout taught).
   - Update plan sections 6.6, 6.7 and 13. Where your findings contradict the plan,
     update it and tell me.

6. Prepare closing phase 1 (do not do it)
   - List what removing the legacy village path would delete or change: the .vil
     loading, the village drawing in Village, DoubleBackground and the sprite
     classes, --legacy=villages and village_top_layer, verify_villages, and the .vil
     files themselves (decision 5). Include line counts and what still uses each part
     (the world map uses DoubleBackground).
   - List what would keep the exit criteria of plan 6.6 from being met.

Constraints:
- Convert villages only. No step C: no physics, no Area2D logic, no per-delta
  movement. Gameplay and timing stay unchanged in normal runs.
- No GPUParticles and no new art. Keep the 1024x768 screen and the village pixel
  coordinates; cutscenes, saves, Cheater jumps and AutoPlay depend on them.
- Do not change legacy game logic or content to make parity pass; content quirks stay.
  Dev-only flags are fine if documented, and normal play must not change.
- Legacy files follow PORTING.md (Java names, no redesign; bridge members snake_case).
  New files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the scripts under scenes/ and tools/.
  Run Godot from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), and any change to the scene layout or the converter;
- the converter warnings, and the verify_villages results for all 89 variants;
- the parity results, explaining every difference:
  * golden vs. after for the cases that stayed legacy;
  * legacy vs. scene, with both top-layer rules, for every converted case;
- the screenshots you checked and what each showed (contact sheets are fine);
- fps per measured place, before and after;
- the places or variants you could not reach or test, and why;
- the list from deliverable 6;
- anything that surprised you or that the plan got wrong.

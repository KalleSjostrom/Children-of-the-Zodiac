Complete phase 2 ("dungeons as scenes") of docs/MODERNIZATION_PLAN.md in this Godot 4.7
project: convert every remaining dungeon floor through step A (data) and step B
(presentation). That is 77 .map files in 19 areas; Forest of Reil (Forest Path, Deep
Forest) and The Great Mine--Tunnel are done.

Read first:
- docs/MODERNIZATION_PLAN.md: section 7 (7.7 has the pilot's results), 12 and 13; also
  6.8 and 6.9 (how the village rollout went and how its closing was prepared);
- docs/ARCHITECTURE.md, all of it; section 10 holds the dungeon conventions, including
  the 3D bridge;
- docs/CONVERTING_DUNGEONS.md: the per-floor procedure the pilot left you;
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh;
- docs/PORTING.md: the rules for legacy files you touch;
- docs/port_notes/labyrinth.md and docs/port_notes/inventory-weather.md.

State:
- The pilot is committed (<commit>).   <-- ADD THE COMMIT
  * It added the converter (tools/import/map_to_scene.sh), the data check
    (verify_dungeons.gd, also --meshes), dungeon_preview.gd and
    tools/parity/contact_sheet.gd.
  * It added the scene types in scenes/dungeons/ and scenes/dungeon_objects/.
  * It added the step A and B bridge in MapLoader, Labyrinth, Graph, the inventory
    classes, SaveSystem and WeatherSystem, and the 3D bridge in GLBackend
    (GLBackend.scene_3d).
  * It added --legacy=dungeons, --no-encounters, AutoPlay `pos` in labyrinths and 14
    dungeon_* parity cases.
- In the pilot, legacy vs. scene was identical to the pixel (tolerance 0) on all 189
  shots. That is the bar for every floor; plan 7.7 lists what it took.
- A dry run of all 80 files already passes: 80 convert (124 warnings), 160 of 160 data
  checks ("Slot 1", "Start"), 80 of 80 meshes. That was data only, outside the project.
  This task converts the 77 floors for the game.
- Ticket fixes may have landed since the pilot. The goldens in tools/parity/out are
  stale either way.   <-- EDIT IF NEEDED
- --seed runs read no game pad. Do not type while a recording runs: a new run's window
  takes the focus.
- If the Godot editor is open on the project, it reimports the .import files the
  converter changes. Close it while converting and recording.
- Start from a clean, committed tree. This prompt file doesn't count.

Decisions (plan section 13):
- Decision 2, dungeon lighting: the exact fixed-function look for every floor, as in the
  pilot (DungeonMaterials, dungeon_gl.gdshaderinc, values from the DungeonStyle).
  <-- EDIT IF NEEDED
- The emulation's glColor bug and the misplaced sky (plan 7.5) stay in this task: the
  scene reproduces GLBackend. The glColor bug: lit vertices are multiplied by the
  current glColor. Its symptoms:
  * walls show through walls on Deep Forest;
  * Empyrian Temple--Dark's walls are black;
  * objects are tinted yellow.
  Fixing them is a separate task, for both paths at once, with new goldens.
  <-- EDIT IF NEEDED
- Decision 6, time base: not made, and nothing in this task may need it.
  * The weather and the save points keep their legacy simulation and the interim nodes.
    No GPUParticles3D.
  * The camera stays at the origin, with the legacy modelview on the floor (plan 7.5).
- Decision 3 (step C) is not made: no Tweens for moving or turning, no signals replacing
  the polled logic.
- Decision 5, text formats: not made. Delete no .map file; keep the .map path and
  --legacy=dungeons. The data check and the parity runs need them. Removing the legacy
  dungeon path is a separate step after review (deliverable 6 only prepares it).
- Battles and riddles stay legacy, drawn into the scene's World3D by the 3D bridge, as in
  the pilot. Keep the legacy look; report what cannot be kept.
- Make no other open decision.

Deliverables, in this order. Do (1) before converting any floor, so that the goldens are
recorded on unconverted code.

0. Baseline
   - tools/check.sh reports 0 failed. Record goldens of all existing cases
     (tools/parity/parity.sh record golden --jobs=5).
   - Record the 14 dungeon_* cases a second time and show the self-diff is 0.
   - Re-run the pilot's check on top of whatever landed since:
     ab "--legacy=dungeons" "" --ignore-world 'dungeon_*' battle newgame_to_forest
     story_having_fun. It must give what plan 7.7 reports: 189 of 189 shots identical.

1. Parity coverage, then goldens
   - Tours of every remaining floor with tools/autoplay/dungeon_tour.txt, as in the
     pilot:
     * one case per floor and save ("Slot 1" and "Start"), group dungeon_tour_*;
     * start with --start=<place>-mark0 --no-encounters;
     * take the place names from main.bank: a few use underscores
       (East Passage--East_Mountain-mark0, Forest of Bri--East_Forest-mark0);
     * Boss--Test has no place and no size line. Check whether anything reaches it; if
       nothing does, cover it with the data check and a preview only.
   - Hand-written cases for what the pilot never drew through the scene path. Its
     step B code for these has never been tested by parity:
     * object kinds:
       - ladder doors and door--up/--down (Grivera, Mt. Cesadur): a floor change frees
         the old floor's mode and scene and loads the new one;
       - a floor button (Empyrian Temple--Dark or Light);
       - an ice button (Ice Cavern--Hall of Anguish or Hall of Confusion);
       - the ice combo button and the riddle door (Ice Cavern--Throne Room);
       - the Aegis combo button (Temple of Aegis--First Floor);
       - the additive hinder door (addDoor, Empyrian Temple--Hall of Wind, additive
         blending);
       - the hidden hinder door (Grivera--Omnious Hall);
       - a trigger door (Central Pass--West Part or Grivera--First Floor);
       - the if door and a mission chest (Fire Cavern--Passage of Ifrit);
       - a bomb (The Sewers);
       - a villager on another Great Mine floor;
       - a labyrinth boss (on six floors and Boss--Test). Check whether its battle runs
         inside the Labyrinth frame or as its own mode;
     * riddles: 21 on 6 floors. src/miniGames was never runtime-tested (HANDOFF).
       - Open one, show it, and leave it.
       - Dorma's Forest--Forest of Hate (rain) and Ice Cavern--Mysterious Forest (snow)
         have riddles under weather.
       - Check what a riddle draws in 2D before the front weather pass: the 3D bridge
         covers only the frame's first 3D chunk drawn before any 2D (ARCHITECTURE
         section 10);
     * the weather:
       - snow on Frozen Forest--Forest Passage, Ice Cavern--Frozen Field and Ice
         Cavern--Mysterious Forest: a walk, and a battle with the front pass over it;
       - rain also on Dorma's Forest--Forest of Hate and Pensara Forest--Forest;
       - no floor uses useFire;
     * the look:
       - carpets and pillars (Temple of Aegis, the S* textures);
       - the 18 floors with a sky, among them the ones with alpha 0.8 (Empyrian
         Temple--Light, Frozen Forest--Forest Passage, Ice Cavern--Frozen Field and
         Ice Cavern--Mysterious Forest);
       - an enemy colour in a battle (29 floors set one);
       - the missions of The Sewers, Pensara Prison and Fire Cavern;
     * size: the largest floors (Empyrian Temple--Light and Dark, 169 cells) and the floor
       with the most objects (Silent Ruin--The Great Ruins, 25);
     * saving inside a labyrinth and loading that save (COTZ-005: save anywhere);
     * entering a floor through the console's goto (COTZ-006).
     Plan routes with `pos` in headless probe runs (CONVERTING_DUNGEONS.md section 1).
   - Facts to verify before relying on them:
     * which existing cases switch to scenes once their floor is converted:
       - bridge_test (Grivera--First Floor);
       - story_meanwhile_in_zazo (Central Pass--North East Part);
       - story_menthu_kills_teo (Temple of Aegis);
       - story_senate_of_pensara (Grivera--Third Floor);
       - possibly others (check the logs' place= values).
       Their check becomes legacy vs. scene. The bridge test's BridgeTest.tscn is on the
       world map, which stays legacy; it must still pass;
     * three .map files have NUL bytes inside hinder door link names, e.g.
       "the_sewers--south-mark<NUL>0":
       - The Great Mine--The Hall:69;
       - The Sewers--South East:84, 86, 87;
       - The Sewers--South:99-101.
       Find what the legacy loader reads there, what the converter writes into the
       scene, and what using such a door does in the game. Keep the legacy behaviour.
       Make the converter warn about these lines;
     * which save reaches each object's states, and which floors or objects are broken
       content. Document each such case; do not fix content.
   - Record goldens of all cases, old and new. Record the new cases a second time and
     show the self-diff is 0. Never edit game code while a recording runs: each case
     starts Godot fresh and would pick up the edit.

2. Convert
   - Run tools/import/map_to_scene.sh for the remaining floors, in batches by area if you
     like. Read every converter warning and report them.
   - Run tools/check.sh after converting and before recording: it imports the changed
     .import files.
   - Converting twice must change no file, and the pilot's files must not change. The
     area styles are already computed from all of an area's .map files; if one changes,
     explain why.
   - Preview every floor with dungeon_preview.gd (rig and top views; contact sheets are
     fine). Check walls, floors, roofs, carpets, pillars, sky, objects and markers. Open
     a few in the editor.

3. Step A
   - Run verify_dungeons.gd --all on the real scenes with the saves "Slot 1" and "Start"
     (more if a floor needs them), and verify_dungeons.gd --meshes --all. Every build
     must pass.
   - Parity: golden vs. after step A, identical for every case, shots and logs.

4. Step B
   - For every dungeon case and every case that switched (deliverable 1):
     ab "--legacy=dungeons" "" --ignore-world must be identical at tolerance 0, as in the
     pilot. Choose any tolerance deliberately, and explain every remaining difference
     with its diff image.
   - All other cases: golden vs. after, identical.
   - Fix what fails in the bridge code, not in legacy logic. The bridge code is
     Labyrinth's scene path, DungeonScene and its nodes, the place_view and
     place_particles twins, and GLBackend's scene chunk.
   - Every Inventory class that overrides draw has a place_view twin. Check the
     subclasses that change what Inventory.draw does through other overrides. Grep every
     draw you stop calling for state changes (plan 2.4, 12).
   - Check that every floor change and every exit frees the old Labyrinth mode and its
     scene. The pilot fixed a reference cycle (ARCHITECTURE section 8).
   - Compare the exit-time leak reports with the goldens' logs. Every run has had them
     since before phase 2, so look for changes, not for zero.
   - Measure fps from normal runs, legacy vs. scene, capped and uncapped:
     * a snow floor (Ice Cavern--Frozen Field, 115 cells), and a battle there;
     * the largest floor (Empyrian Temple--Light);
     * Silent Ruin--The Great Ruins (25 objects);
     * Temple of Aegis--Base Level (carpets).
     Also measure the load time of the largest floor: its first frame builds the mesh.

5. Docs
   - Update ARCHITECTURE.md section 10, CONVERTING_DUNGEONS.md (what the rollout taught)
     and HANDOFF.md (the new state).
   - Update plan sections 7 (add 7.8, the rollout's results), 12 and 13. Where your
     findings contradict the plan, update it and tell me.

6. Prepare closing phase 2 (do not do it)
   - List what removing the legacy dungeon path would delete or change, with line counts
     and what still uses each part:
     * MapLoader's .map parsing (the converter and the data check read the .map files;
       Load reads saved floor maps);
     * init3D and the display list;
     * LabyrinthRenderer.draw and renderSky;
     * LabyrinthNode's draw methods (the scene path still calls drawOneWall and
       drawOneFloor through DungeonQuads);
     * Horizontal and PillarWalls;
     * Graph.drawInventory and the Inventory draw methods (place_view uses _drawQuad);
     * the legacy branches of Labyrinth.draw, WeatherSystem.draw and SaveSystem.draw
       (the battle's front pass still uses WeatherSystem.draw);
     * --legacy=dungeons and verify_dungeons.gd;
     * the .map files themselves (decision 5).
     Battles also read the GL fog and light state.
   - List what keeps the exit criteria of plan 7.6 from being met. For example, "src/
     labyrinth contains no GL calls" fails while the minimap, the overlays and the
     place_* twins still set GL state.

7. Optional, only if parity stays identical: the weather's cost without decision 6
   <-- DELETE IF NOT WANTED
   - In Forest Path, computing the back pass's quads takes ≈13 ms of a ≈33 ms frame.
     That is bridge code: WeatherSystem.place_particles and WeatherParticle.place_quad.
   - Make it faster without changing a single vertex, colour or random number: packed
     arrays, fewer allocations, work done once per frame instead of once per particle.
   - The simulation (WeatherSystem.update, ≈10 ms) is legacy code and stays as ported.
   - Measure before and after in normal runs (Forest Path, a snow floor). Show that the
     parity cases with weather are still identical.

Constraints:
- Convert dungeon floors only. No step C: no physics, no Tweens for movement, no signals
  replacing polled logic. Gameplay and timing stay unchanged in normal runs.
- No GPUParticles and no new art. Keep the dungeon units (4 per cell, the same axes), the
  cell addresses and the inventory database names. Saves, buttons linked across floors,
  the console's goto and AutoPlay depend on them.
- Do not change legacy game logic or content to make parity pass; content quirks stay.
  A port bug that the new coverage finds may be fixed before the goldens are recorded,
  as its own listed change. A port bug is a place where the GDScript does what the
  Java does not.   <-- EDIT IF NEEDED
- Dev-only flags are fine if documented; normal play must not change.
- Legacy files follow PORTING.md (Java names, no redesign; bridge members snake_case).
  New files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the scripts under scenes/ and tools/.
  Run Godot from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), and any change to the scene layout, the object kinds or
  the converter;
- the converter warnings, and the verify_dungeons results for all 80 floors;
- the parity results, explaining every difference:
  * golden vs. after for the cases that stayed legacy;
  * legacy vs. scene for every dungeon case and every case that switched;
- how battles, riddles and the weather look in the hybrid frame, with shots;
- the screenshots you checked and what each showed (contact sheets are fine);
- fps per measured floor, before and after, and the load time;
- the floors or objects you could not reach or test, and why;
- the list from deliverable 6;
- anything that surprised you or that the plan got wrong.

Implement the pilot of phase 2 ("dungeons as scenes") of docs/MODERNIZATION_PLAN.md in
this Godot 4.7 project. Convert the two floors of Forest of Reil ("Forest Path" and
"Deep Forest") and one floor of The Great Mine ("Tunnel") through step A (data) and
step B (presentation). Convert no other floor in this task.   <-- EDIT IF NEEDED

Why these floors: Forest Path has rain, fog, a sky gradient, a save point, a hinder door
and the existing battle cases; Deep Forest shares its area (one DungeonStyle for two
floors) and adds chests; Tunnel is indoors, without weather, and has a mission, a
villager, buttons and hinder doors whose database names link across floors.

Read first:
- docs/MODERNIZATION_PLAN.md: sections 2.3, 2.4, 3, 7, 12 and 13, and 6.7 to 6.9 (what
  phase 1 learned);
- docs/ARCHITECTURE.md, all of it: the bridge, the rules for new code, the flags, the
  parity workflow (section 7) and the village conventions (section 9), which the
  dungeon ones should mirror;
- docs/CONVERTING_VILLAGES.md: the procedure phase 1 settled on;
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh;
- docs/PORTING.md: the rules for legacy files you touch;
- docs/port_notes/labyrinth.md and docs/port_notes/inventory-weather.md.

State:
- Phase 1 is committed (<commit>): every village and cutscene draws from a scene
  (steps A and B); the .vil files and --legacy=villages stay.   <-- ADD THE COMMIT
- Tools from phase 1 you can reuse: parity.sh --jobs=<n> and case patterns ('tour_*');
  AutoPlay pos, heading, guard, the relative buttons and the [zoom] marker lines; the
  converter pattern (two stages with --import between, bootstrap files for inherited
  scenes, unique_ids removed, deterministic output); a data check that builds both
  ways and compares field by field.
- --seed runs read no game pad. Do not type while a recording runs: a new run's
  window takes the focus.
- Start from a clean, committed tree. This prompt file doesn't count.

Decisions (plan section 13):
- Decision 2, dungeon lighting: keep the exact fixed-function look for now. The floor
  scene uses a ShaderMaterial built from GLBackend's spatial shader: per-vertex
  lighting from light0/light1 and the material, per-fragment fog, the alpha test.
  Its values come from the floor's DungeonStyle. Godot lights (OmniLight3D,
  StandardMaterial3D) can come later behind a flag, once parity holds.   <-- EDIT IF NEEDED
- Decision 6, time base: not made, and nothing in this task may need it. The camera
  rig only mirrors LabyrinthPlayer's interpolated position and angle. The weather keeps
  its legacy simulation; an interim node draws its quads. No GPUParticles3D.
- Decision 3 (step C) is not made: no Tweens for moving or turning, no signals
  replacing the polled logic.
- Decision 5, text formats: not made. Delete no .map file; keep the .map path behind
  --legacy=dungeons. The data check and the parity runs need them.
- Battles stay legacy (plan 7.5). If the hybrid frame changes how a battle looks (fog,
  light, depth, the weather's front pass), show it and keep the legacy look wherever
  you can (for example by drawing the front pass through legacy code during battles).
  Report what cannot be kept. How battles should look in the hybrid period is my
  decision, not part of this task.
- Make no other open decision.

Deliverables, in this order. Do (1) before converting anything, so that the goldens are
recorded on unconverted code.

0. Baseline
   - tools/check.sh reports 0 failed. Record goldens of all existing cases
     (tools/parity/parity.sh record golden --jobs=5).

1. Parity coverage, then goldens
   - A tour for any dungeon floor (e.g. tools/autoplay/dungeon_tour.txt), with no
     route per floor: fade-in shots, a settled shot, then a fixed sequence of steps
     and turns both ways, with `pos` lines. End with the minimap visible and the menu
     thumbnail. Start each floor with --start=<Area>--<Floor>-mark0 (main.bank, mode 4)
     and a shipped save.
   - Random battles interrupt walks: steps are counted, and Forest Path has "steps 5 6".
     Labyrinth.noEncounters exists but nothing sets it. Add a dev-only way to switch
     random battles off for the tours: a flag or an AutoPlay command, documented in
     Main.gd and ARCHITECTURE.md. Normal play must not change. Battles get their own
     cases instead.
   - Extend AutoPlay `pos` to print the labyrinth position: node address, facing, and
     the camera's position and angle. Existing log lines must not change, because
     parity compares them.
   - Hand-written cases for what a tour does not show:
     * Forest Path: the rain and fog during a walk, a random battle with the rain's
       front pass over it (the existing battle case does this; check its shots), the
       save point and its particles, the hinder door;
     * Deep Forest: opening a chest; leaving through a door (the fade-out);
     * Tunnel: the mission display; the villager object (its dialog); pressing a button
       and the hinder door it opens; a battle without weather;
     * the menu's map page (LabyrinthMap.draw) after walking a floor;
     * entering Forest Path from the world map, and the newgame_to_forest arrival.
   - Facts to verify before relying on them:
     * The draw order: the display list, the inventory, the weather back pass, the
       battle (labDrawable), the weather front pass, the minimap (MapRenderer, in 3D
       with depth test off), then the 2D overlays (Labyrinth.draw, src/labyrinth/
       Labyrinth.gd:354-399). Battles and riddles are not Organizer modes.
     * init3D compiles the walls into a display list once. LabyrinthRenderer.renderSky
       draws the sky gradient; check whether it ends up in that list.
     * GLBackend's projection is gluPerspective(45, 4/3, 1, 75). Its spatial shader
       lights per vertex and fogs per fragment. light0 at position 0;0;0;1 is set
       while the modelview is the identity, so it is a headlamp. The 3D chunks are
       transparent SubViewports composited onto LegacyLayer.
     * Which existing cases go through the pilot floors (newgame_to_forest, battle;
       check the logs' place= values), and which floors bridge_test, boss and the
       story cases use. They must stay identical where they don't touch the pilot.
     * The Labyrinth mode is freed after it is left. A RefCounted cycle kept every
       world map mode alive until phase 1 fixed it (ARCHITECTURE.md section 8); the
       scene of a mode that never frees would leak too.
   - Record goldens of all cases, old and new. Record the new cases a second time and
     show the self-diff is 0. Never edit game code while a recording runs: each case
     starts Godot fresh and would pick up the edit.

2. Converter tools/import/map_to_scene.gd (plan 7.1 to 7.3), run headless
   - Read each .map with MapLoader's tokenizer and parsers, so every quirk reads the
     same. The village converter's warning style applies: name the file and the line
     of every token the legacy loader misreads.
   - Write:
     * a DungeonLayout .tres per floor: cells, their neighbours, per-cell textures,
       carpet and pillar flags;
     * a DungeonStyle .tres per area: texture slots, material, invMaterial, light0 and
       light1, fog, sky, enemy colour, the weather flags;
     * a DungeonScene per floor, with the layout of plan 7.2;
     * one scene per object kind in scenes/dungeon_objects/ (chest, door, hinder door,
       button, save point, villager, ...), each script beside its scene. Exports: the
       cell, facing, frames, statuses and the database name the legacy code derives
       (map name + kind + cell address).
   - DungeonFloor is an @tool node that builds the mesh with SurfaceTool, in the
     editor and at run time. Port it mechanically from LabyrinthNode
     (src/labyrinth/Node.gd: draw, drawOneWall, drawOneFloor, drawRoof), Horizontal
     (carpet floors) and PillarWalls: same vertices, texture
     coordinates, normals and winding as the legacy display list. The pilot floors
     have no carpets or pillars; Temple of Aegis has both. Build and preview one
     Temple of Aegis floor too, without converting it for the game.
   - The scenes must open in the editor and show the floor: walls, floors, roofs, the
     objects, and markers for the start positions (marks) and doors.
   - Running the converter twice must change no file.
   - Also run the converter and the data check over all 80 .map files as a dry run:
     data only, into a folder outside the project, nothing committed. Report what
     fails.

3. Step A: data from scenes (plan 7.4)
   - For a converted floor, Labyrinth.init builds the graph, the nodes, the textures
     and the inventory from the scene instead of from MapLoader: the same objects, in
     the same order, with the same Database reads and writes and the same random
     numbers. --legacy=dungeons (Main.is_legacy("dungeons")) keeps the .map path.
   - Write tools/import/verify_dungeons.gd. It builds each converted floor both ways
     and compares everything field by field: the graph and its links, walls,
     textures, carpet and pillar geometry data, the inventory with its database names,
     the mission, steps, music, look values, weather flags, and the Database
     afterwards. Run it with the saves "Slot 1" and "Start", for the pilot and in the
     dry run.
   - Parity: golden vs. after step A must be identical for every case, shots and logs.

4. Step B: nodes draw the converted floors (plan 7.5)
   - Labyrinth.create_scene() returns the floor's scene, and null under
     --legacy=dungeons. The scene is 3D, under World. Main's tree has hosted only 2D
     scenes so far: check that the main viewport renders it under the LegacyLayer
     overlays, and that Main's canvas-transform reset on a scene change leaves 3D
     alone.
   - A camera rig in the scene mirrors LabyrinthPlayer every frame (position, angle,
     the turn and move interpolation), with the legacy projection. The legacy movement
     logic stays in charge.
   - The converted path stops calling init3D, the display list and
     graph.drawInventory. The objects become Sprite3D / AnimatedSprite3D nodes that
     mirror the legacy Inventory state: frame, open or closed, visibility, height and
     offset as Inventory.setSettings computes them. Grep every draw() you stop
     calling for state changes (plan 2.4 and 12). Phase 1's rule applies: keep those
     changes where the drawing was, inside draw, not in update. In the frame in which
     the Organizer leaves a mode, its update runs but its draw does not.
   - Fog, light, material and sky follow decision 2. The values come from the
     DungeonStyle; the global GL state the legacy battle code reads stays set
     (LabyrinthRenderer.addFog/addLight).
   - Weather: an interim node draws the legacy simulation's particles, back and front
     passes, as one mesh per pass and frame (e.g. a MultiMesh), until a GPU preset
     can match (decision 6).
   - The minimap, the mission display, dialogs and card info stay legacy overlays in
     this task. Say whether the minimap should become a Control here or in phase 3.
   - Battles and riddles stay legacy (labDrawable), drawn by GLBackend on
     LegacyLayer over the scene. See the battle decision above.
   - Parity, two checks:
     * pilot cases: tools/parity/parity.sh ab "--legacy=dungeons" "" --ignore-world
       <cases>;
     * all other cases: golden vs. after, identical.
     Aim for identical pixels: same vertices, same shader, same filtering and
     projection. Choose any tolerance deliberately, and explain every remaining
     difference with its diff image. Expected suspects: rasterization in the main
     viewport vs. a per-chunk SubViewport, depth precision, MSAA, the battle no longer
     sharing the walls' depth buffer. Fix what fails in the bridge code (Labyrinth's
     scene path, the scene, the object views), not in legacy logic.
   - The bridge test (world map, then Grivera) must still pass; Grivera stays legacy.
   - Measure fps from normal runs, capped and uncapped, legacy vs. scene: Forest Path
     walking in the rain (HANDOFF: ~30 FPS), a battle there (20-28 FPS), and Tunnel.
     Say how much of the remaining cost is the weather simulation in GDScript.

5. Docs
   - ARCHITECTURE.md: a dungeon section next to section 9 (layout, converter, steps A
     and B, the 3D bridge), and the new flags.
   - HANDOFF.md: the new state.
   - docs/CONVERTING_DUNGEONS.md: the procedure for the next floors, as
     CONVERTING_VILLAGES.md does for villages.
   - Plan sections 7, 12 and 13. Where your findings contradict the plan, update it
     and tell me.

Constraints:
- Convert only Forest of Reil (both floors) and The Great Mine--Tunnel.
- No step C: no physics, no Tweens for movement, no signals replacing polled logic.
  Gameplay and timing stay unchanged in normal runs.
- No GPUParticles and no new art. Keep the dungeon units (4 per cell, the same axes),
  the cell addresses and the inventory database names. Saves, buttons linked across
  floors, the console's teleport and AutoPlay depend on them.
- Do not change legacy game logic or content to make parity pass; content quirks
  stay. Dev-only flags are fine if documented; normal play must not change.
- Legacy files follow PORTING.md (Java names, no redesign; bridge members snake_case).
  New files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the scripts under scenes/ and tools/.
  Run Godot from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), and the scene and resource layout the converter
  produces;
- the converter warnings, and the verify_dungeons results for the pilot and for the
  80-file dry run;
- the parity results: golden vs. after step A; golden vs. after step B for the other
  cases; legacy vs. scene for the pilot cases. Explain every difference;
- how battles look in the hybrid frame (fog, depth, the weather's front pass), with
  shots, and what you kept legacy for them;
- the screenshots you checked and what each showed (contact sheets are fine);
- fps per measured place, before and after;
- what Labyrinth still draws through legacy code, and why;
- anything that surprised you or that the plan got wrong.

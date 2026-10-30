Implement phase 4.1 ("world map and airship") of docs/MODERNIZATION_PLAN.md in this Godot
4.7 project: convert the world map (Landscape: world0.map West, world1.map East, world2.map
North) and the airship (AirLandscape: land1.map, land2.map) through step A (data from
scenes) and step B (nodes draw them).

Why both maps at once, without a separate pilot: there are five small map files (488 lines),
each with one background. There is no scroll and no zoom, and every piece has prior art: phase
1's stitched backgrounds, top layers and night layers, the ActorView for the walker and the
airship, and phase 3's UI conventions for the name plate. Take West all the way through parity
before the others (deliverable 4).

In scope:
- the world map (src/landscape: Landscape, LandscapeLoader, LandscapeNode, Road, LandPlayer,
  Visited): the background, the top layer and the night layer, the dots of the visited
  roads, the markers of the visited nodes, the player, and the name plate (Pieces/1.png and
  the node's name: Landscape.draw);
- the airship (src/landscape/airship): its background (World/World<airship status>), its
  top layer, the airship itself and its name plate (AirLandscape.draw);
- the data both modes load: the nodes and roads of world*.map, the nodes and zones of
  land*.map, and the index from a node's name to its map (LandscapeLoader.PlaceMapLoader).

Not in scope:
- the dialog ("We can't enter now!") and the fade: they are already phase 3's nodes;
- the menu and its map page (4.2);
- the stores, the title and the battle (4.2, 4.4);
- step C: walking along a Path2D, and the airship's motion as per-second rates.

Read first:
- docs/MODERNIZATION_PLAN.md:
  * 9.1, and 2.2's table row for the world map;
  * 3;
  * 6.1 to 6.4 and 6.7 to 6.9 (the village conversion that this one reuses, and what phase
    1's closing left to the world map);
  * 8.3 and 8.4 (phase 3's facts and UI rules);
  * 12, 13 and 14;
- docs/ARCHITECTURE.md, all of it. Section 8 covers the bridge test, which runs on the world
  map. Section 9 covers the village scenes, the converter, ActorView and the night layer.
  Section 12 covers the UI nodes, BaselineLabel, the twins and show_ui;
- docs/CONVERTING_VILLAGES.md, and docs/CONVERTING_UI.md (including the coverage probe);
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh, and how to record a
  parity set from a copy of the project;
- docs/PORTING.md: the rules for legacy files you touch;
- docs/port_notes/factories-landscape.md.

State:
- Phase 3's rollout is committed. Villages, labyrinths and cutscenes draw their overlays as
  nodes (ARCHITECTURE section 12). The world map and the airship still draw everything
  through Graphics, except the dialog and the fade.
- Parity coverage today:
  * landscape: Slot 1 at Alares, with roads in four directions, the menu and entering a
    place;
  * dialog_world_map;
  * dungeon_world_map_entry;
  * bridge_test.
  All of them show West by day. No case shows East, North, the night map, a closed road or
  the airship.
- The bridge test (ARCHITECTURE section 8) shows tools/bridge_test/BridgeTest.tscn instead
  of the world map's background tiles. It relies on the world map staying legacy.
- AirLandscapeLoader keeps its map loader, and the map loader refers back to it. This is the
  reference cycle that LandscapeLoader had (fixed in phase 0: LandscapeLoader.gd:29-33). Once
  the airship has a scene, the cycle keeps every airship mode and its scene alive after it is
  left.
- Left open, not part of this task:
  * the dungeons' 1/255 (plan 7.8, 8.3);
  * the minimap on the 3D bridge;
  * the closings of phases 1 to 3 (6.9, 7.9, 8.4).
- Record goldens on the commit you start from. r3gold1 in tools/parity/out was recorded on
  the rollout's code before it was committed.
  * A full run (383 cases and bridge_test, --jobs=8) takes about 13 minutes.
  * With more parallel jobs some runs fail to start (exit 127, an empty log). Re-record
    those cases.
  * Record from a copy of the project (HANDOFF) when you want to edit code meanwhile.
- In seeded runs an unseeded JRandom takes J.nextSeed(). A new generator seeded from that
  sequence shifts every later JRandom against the goldens. Seed anything new from a hash of
  the seed, as Main does.
- --seed runs read no game pad, and they advance a game clock by one fixed step per frame.
  J.currentTimeMillis() reads that clock, and the world map's walk is timed by it (Landscape:
  speed 40), so the walk repeats in seeded runs. Measure frame rates in normal runs.
- Do not type while a recording runs: a new run's window takes the focus.
- If the Godot editor is open on the project, it imports new files and generates .uid
  files. Close it while recording.
- If I change one of your files while you work, keep my change and tell me.
- Start from a clean, committed tree. This prompt file doesn't count.

Decisions (plan section 13):
- Step A (data) and step B (presentation) only. The legacy objects stay in charge of state,
  input and timing:
  * Road.movePlayer walks the line of 7 points per segment (Road.gd:61-86), one point per
    speed step of J.currentTimeMillis();
  * AirShip keeps its velocity per update and its wrap past the screen edges
    (AirShip.gd:36-65);
  * the nodes mirror their positions and frames.
  Decision 6 (time base) is therefore not needed. Plan 9.1 says the airship needs it: that
  is step C.
- Decision 3 (step C) is not made. Roads may become Path2D data, but nothing moves along
  them, and no signals replace the polled input.
- Decision 1 (village variants) does not apply. Each map file gets one scene. The night is a
  choice made at run time, not a file (Landscape.isNight() when the map loads). Choose how
  the scene shows it, and say why.
- Decision 5, text formats: not made. Keep the .map files: the converter, the data check
  and the legacy path read them.
- Decision 8, the UI look: not made. The name plate keeps its look, and
  BaselineLabel.oversampling stays 1.
- Decision 4, resolution: keep the 1024x768 virtual screen. The scenes use the maps' pixel
  coordinates.
- Make no other open decision.

Deliverables, in this order. Do (0) and (1) before converting anything, so that the goldens
are recorded on unconverted code.

0. Baseline
   - tools/check.sh reports 0 failed.
   - Record goldens of all existing cases and bridge_test.

1. Facts and coverage, then goldens
   - Facts to verify before relying on them:
     * What each mode draws, in order: Landscape.draw (Landscape.gd:232) and
       AirLandscape.draw (AirLandscape.gd:104). In order:
       - the background tiles (DoubleBackground.drawBottom with USE_CUT: the 256 px tiles of
         <W>folder);
       - the dots of the visited roads (in visitedRoads' order) and crossroad.png on every
         visited node, whatever its kind;
       - the player (LandPlayer: Kin's village images, at J.round(x - w/2),
         J.round(y - 9h/10));
       - the top layer (drawTop without sprites: every top.info piece, then the night
         layer);
       - the name plate: Pieces/1.png centred at y 10, and the name at y 60
         (drawSingleCenteredText). It is not drawn while walking or on a crossroad, and the
         name is cut at "-" (and at "land" on the airship);
       - the dialog and the fade.
       Find out which of these overlap and where their order shows.
     * What these draws change besides drawing: g.setColor(1), g.setFontSize(30), the text
       state the name leaves behind, and checkMenu's thumbnail. Twins must keep these.
     * The night. Landscape.isNight() is music_ != NORMAL, so it is also true for "continue".
       The only data that sets it is the door of Forest of Reil--Forest Path
       (land::continue::forest_of_reil--deep_forest-mark0). West has "West at Night - 1.png".
       East and North would ask for res/Landscape/standardOvernight.png, which does not
       exist. Find out whether anything reaches East or North at night. Add no content.
     * Where the data comes from:
       - the nodes, and the roads (address; source and destination with their directions;
         the co points; oc);
       - a road's closed state: the parser reads road<address>, which no save has, and then
         openClosedRoads reads Database's road<continent>-<address>;
       - the visited nodes and roads: the save, through Load and Visited;
       - the index from a node's name to its map: PlaceMapLoader parses all three world*.map
         files;
       - the airship's map: land<airship status>.map. There is no land0.map, and SQUARE
         boards only from status 1;
       - the airship nodes' zones (start west, east, north).
     * The airship:
       - Airship1..16 as an image set, like a villager's;
       - the wrap 55 px past each edge: what shows near an edge;
       - its name plate: only within 20 px of a node that is not a crossroad (checkNode).
     * What the scenes need from the bridge. Both modes are MenuStarters: the menu suspends
       them (the scene leaves the tree and keeps its state), and entering a place drops
       them. GameMode frees scene_root when the mode is freed, which the airship's cycle
       prevents today.
   - Coverage: run the coverage probe of CONVERTING_UI.md over every case. That means
     temporary prints in each part's draw (dots, node markers, the name plate, the night
     layer, the airship near an edge) and in AutoPlay's shot, in a copy of the project.
     Then write cases for what no shot shows:
     * each world map by day: West, East (for example --start=landParasne) and North
       (landDellna). Include:
       - walking roads in each direction;
       - a node reached for the first time (its marker and the road's dots appear);
       - the name plate on a village node and on a labyrinth node;
       - no name plate on a crossroad or while walking;
     * a closed road (a Database status: --status): not drawn, and not walkable;
     * the night West map: walk out of Forest Path's door, or use --start with the
       land::continue:: form if the Organizer takes it from --start;
     * the airship on land1 (Slot 1: SQUARE on the world map) and on land2
       (--status=airship:2). Include:
       - flying in each direction, and wrapping at the left or top edge and at the right or
         bottom edge;
       - the name plate over a node;
       - landing with CROSS (the fade to black);
       - the menu (TRIANGLE) and the map page (SQUARE) from the airship;
     * the menu thumbnail of both modes.
     AutoPlay's pos and heading know villages and labyrinths. If the routes need them,
     extend them for the world map and the airship without changing existing log lines.
     Plan the routes in headless probe runs.
   - Record goldens of all cases, old and new. Record the new cases a second time and show
     the self-diff is 0. Never edit game code while a recording runs from the project
     itself.

2. Converter tools/import/world_to_scene.gd (plan 9.1), run headless
   - Read each world*.map and land*.map with the legacy tokenizer and parsers
     (AbstractMapLoader's). Map every command to typed, exported node properties.
   - The art. Stitch each background's tiles as the village converter does: lossless, no
     mipmaps, the same filtering. Reuse its code rather than copying it. Each top.info line
     becomes a Sprite2D under the top layer node, in file order. Add the night layer.
   - Each node becomes a Marker2D (or a typed node) with its exported kind and name, in file
     order, because getNode returns the first match. Each road becomes a Path2D (or a typed
     node) with its exported address, source, destination and directions, and its co points
     exactly. The airship's nodes keep their zone.
   - Kin's image set and the airship's: make SpriteFrames only if the view needs them
     (ActorView.show_frame mirrors a legacy sprite's current image).
   - Write the scenes under one folder in scenes/: a template, and one scene per map file,
     following ARCHITECTURE.md. They must open in the editor and show the map, with markers
     for the nodes and the roads.
   - Running the converter twice must produce identical files.

3. Step A: data from scenes
   - LandscapeLoader and AirLandscapeLoader build the nodes, roads, zones and background
     choice from the scenes instead of parsing the .map files. The name-to-map index comes
     from the scenes too, or from a resource that the converter writes. The Database and
     Visited state stays as it is.
   - --legacy=world_map and --legacy=airship (Main.is_legacy) keep the .map path.
   - Write tools/import/verify_world_map.gd. It builds each map both ways and compares the
     objects field by field: nodes; roads with their line coordinates, angles, dots and
     closed state; zones; the index. Run it with Slot 1 and with Start.
   - Parity: golden vs. after step A must be identical on every case, shots and logs.

4. Step B: nodes draw them
   - Landscape.create_scene() and AirLandscape.create_scene() return the map's scene.
     Nodes and road dots show while they are visited. The player and the airship are views
     that mirror the legacy sprite's position, direction and image, with the legacy
     rounding.
   - The name plate is a UI node in scenes/ui/, built with phase 3's conventions:
     * a BaselineLabel;
     * a font size role in the Theme;
     * a twin that keeps the text state changes;
     * Graphics.show_ui.
   - Fix AirLandscapeLoader's reference cycle as LandscapeLoader's was fixed, so that the
     airship's scene is freed when its mode is. List it as a port fix.
   - The bridge test must keep working and stay comparable with its golden. The simplest
     way: --bridge-test implies --legacy=world_map, and BridgeTest shows in place of the
     background tiles, as today. Whatever you choose, update ARCHITECTURE section 8 and say
     why.
   - Convert West first and take it through parity, then East, North and the airship.
   - Parity:
     * ab "--legacy=world_map,airship" "" on the world map and airship cases: identical at
       tolerance 0;
     * golden vs. after on all other cases: identical;
     * the bridge test still passes ("BridgeTest: freed").
     Choose any tolerance deliberately, and explain every remaining difference with its
     diff image. Fix what fails in the bridge code (the nodes, the twins, the views), not in
     legacy logic.
   - Measure the frame rate in normal runs (no --seed), legacy vs. scene, capped and
     uncapped: walking on West, and flying the airship.

5. Docs
   - ARCHITECTURE.md:
     * a new section for the world map and the airship (the layout, the converter, the
       flags, what stays legacy);
     * the flags table in section 7, the bridge test in section 8, and the folders in
       section 2.
   - A short how-to for converting a map again: a section of ARCHITECTURE, or its own file.
   - HANDOFF.md: the new state.
   - Plan sections 9.1 (add the results), 12, 13 and 14. Where your findings contradict the
     plan, update it and tell me.

6. Prepare closing phase 4.1 (do not do it)
   - List what removing the legacy world map and airship paths would delete or change, with
     line counts and what still uses each part:
     * the parsers;
     * the draws: Landscape.draw, AirLandscape.draw, Road.drawRoad, MoveDot.draw,
       LandscapeNode.draw, LandPlayer.draw;
     * the flags;
     * the .map files;
     * DoubleBackground's landscape path.
   - Plan 6.9 kept parts of DoubleBackground and Sprite for the world map and the airship.
     Update that table where they were the reason a part stayed.

Constraints:
- Convert only the world map and the airship. No step C: no Tweens or Timers, no Path2D
  movement, no signals replacing polled logic. Gameplay, input and timing stay unchanged in
  normal runs.
- No new art and no restyling: decision 8 waits.
- Do not change legacy game logic or content to make parity pass; content quirks stay. A
  port bug that the new coverage finds may be fixed before the goldens are recorded, as its
  own listed change. A port bug is a place where the GDScript does what the Java does not
  (the Java is in _java_reference/src/).
- Dev-only flags are fine if documented. Normal play must not change.
- Legacy files follow PORTING.md (Java names, no redesign; bridge members snake_case).
  New files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the scripts under scenes/ and tools/. Run
  Godot from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the scene layout the converter produces, and where each
  node is drawn (World, UI);
- the facts of deliverable 1 as you found them, where they differ from this prompt or plan
  9.1;
- the verify_world_map results;
- the parity results, explaining every difference:
  * golden vs. after step A;
  * legacy vs. scene on the world map and airship cases;
  * golden vs. after step B on the other cases;
  * the bridge test;
- what the two modes still draw through legacy code, and why;
- the screenshots you checked and what each showed (contact sheets are fine);
- fps per measured place, legacy vs. scene;
- the cases you could not reach or cover, and why;
- the list from deliverable 6;
- anything that surprised you or that the plan got wrong.

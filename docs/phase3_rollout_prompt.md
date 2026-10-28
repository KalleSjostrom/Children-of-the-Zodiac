Complete phase 3 ("shared UI and transitions") of docs/MODERNIZATION_PLAN.md in this Godot
4.7 project: convert, through step B (presentation), the legacy overlays that villages,
labyrinths and cutscenes still draw. The dialog family (dialog box, message box, card info
popup) and the fade are done (plan 8.1). Plan 8.2 lists what is left, with each overlay's
place in the frame.

In scope, in this order:
- the emotion bubbles (Sprite.drawEmotions; Actor.drawEmotion in cutscenes);
- the mission display (labyrinth/mission: Mission and its subclasses);
- "Paused" and "game pad lost" (GameCore.testDraw);
- the cutscene images drawn over the actors: cover-all, story image (with drawTextBack),
  village image, translucent over actor (VillageStoryTimeLine.drawTop, ImageSettings);
- the story texts (Text.draw) and the scroll texts (ScrollableTexts, the credits);
- the tutorials' top layer (Tutorial.drawTopLayer: trigger doors, the stores' tutorials,
  the battle's tutorial, the menu's TutorialPage all call it);
- the minimap (MapRenderer, 3D), last.

Not in scope: a battle's or riddle's top layer and the riddle's fade (phase 4), the menu
pages and the stores' menus (4.2), the world map and the airship (4.1).

Read first:
- docs/MODERNIZATION_PLAN.md: section 8 (8.1 has the pilot's results and facts, 8.2 the
  rollout's list and the minimap experiment), 2.4, 12 and 13; 7.5 and 7.8 (the minimap
  and the 1/255); 6.9 and 7.9 (how the closing of phases 1 and 2 was prepared);
- docs/ARCHITECTURE.md, all of it: section 12 holds the UI conventions (the Theme,
  BaselineLabel, the twins, how a UI node takes its place in the legacy frame); sections 9
  and 10 the village and dungeon scenes the overlays are drawn over;
- docs/CONVERTING_UI.md: the procedure the pilot left you, including the coverage probe;
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh, and how to record a
  parity set from a copy of the project;
- docs/PORTING.md: the rules for legacy files you touch;
- docs/port_notes/story.md, villages.md, labyrinth.md and menu.md.

State:
- The phase 3 pilot is committed. It added:
  * resources/theme/game_theme.tres (the two fonts, a size per role, Text20 … Text50, the
    papers and Pieces/10.png as StyleBoxTextures);
  * scenes/ui/: BaselineLabel, Dialog, SignBox, CardInfo (UI layer), Fade (Transition);
  * the twins in Dialog, DeckPage.show_card_info, AbstractCard.place_card,
    Graphics.show_fade, and Graphics.show_ui / GLBackend.show_ui (a node's slot in the
    frame's 2D order; the legacy 2D after it goes to its layer, after it);
  * --legacy=dialog and --legacy=fades, and nine dialog_* parity cases.
- The pilot's bar: legacy vs. node identical at tolerance 0 on every case (6,999 shots),
  golden vs. node too. It is the bar for every overlay here.
- Left open, not part of this task unless the minimap removes it: legacy vs. scene differs
  by 1/255 on 84 of the dungeon shots (plan 7.8). Plan 8.2 found that the minimap's batches
  in the floor's world cause it: without the minimap those shots are identical.
- Coverage gaps the pilot left: no case reaches an image fade (FADE_TO_IMAGE, set only by
  Menthu1.kill and Menthu2.kill: res/test.png) or "game pad lost" (seeded runs read no
  pad).
- The goldens in tools/parity/out (p3golden, p3node1 …) were recorded on the pilot's code.
  Record your own on the commit you start from.
- A full parity run (370 cases and bridge_test, --jobs=8) takes about 12-15 minutes. Record
  from a copy of the project (HANDOFF) when you want to edit code meanwhile.
- In seeded runs an unseeded JRandom takes J.nextSeed(): a new generator seeded from that
  sequence shifts every later JRandom against the goldens. Seed anything new from a hash
  of the seed, as Main does.
- --seed runs read no game pad and advance a game clock by one fixed step per frame, so
  blocking work does not show in their timings. Measure frame rates in normal runs. Do not
  type while a recording runs: a new run's window takes the focus.
- If the Godot editor is open on the project, it imports new files and generates .uid
  files. Close it while recording. If I change one of your files while you work, keep my
  change and tell me.
- Start from a clean, committed tree. This prompt file doesn't count.

Decisions (plan section 13):
- This is presentation only (step B). The legacy objects (Sprite and its emotions, the
  missions, the timeline, Text, ScrollableTexts, Tutorial, MapRenderer, GameCore) stay in
  charge of state, input and timing; the nodes draw what the legacy drawing would have
  drawn in that frame. Keep the legacy look.
- Decision 8, the UI look: not made. No look changes: BaselineLabel.oversampling stays 1,
  the TODO.md UI items wait.
- Decision 6, time base: decided for particles only. Nothing in this task may need it: the
  emotions' shake, the texts' fades, the scroll speed and the images' scroll keep their
  legacy steps; no Tween or Timer drives them.
- Decision 3 (step C) is not made: no signals replacing the polled logic.
- Decision 5, text formats: not made. The .seq, .tut, .help and .map files stay; no BBCode
  converter (the tutorials' coloured words are drawn as the legacy draws them).
- Decision 4, resolution: keep the 1024x768 virtual screen; the nodes use the legacy
  coordinates.
- Make no other open decision.

Deliverables, in this order. Do (0) and (1) before converting anything, so that the goldens
are recorded on unconverted code.

0. Baseline
   - tools/check.sh reports 0 failed. Record goldens of all existing cases and
     bridge_test.
   - Re-run the pilot's check on top of whatever landed since: ab "--legacy=dialog,fades" ""
     on every case must be identical at tolerance 0 (plan 8.1).

1. Facts and coverage, then goldens
   - Facts to verify before relying on them, per overlay:
     * where each is drawn in each mode's frame and what is drawn after it (plan 8.2 has a
       first list; check it against the code);
     * what its drawing changes: plan 2.4 names drawEmotions (the shake's counter), and
       Text.updateFadeValue runs in both update and draw (plan appendix); check Mission and
       its subclasses (BombMission, FireMission, TimeMission, VillagerMission),
       ScrollableTexts, ImageSettings, Tutorial, Row, Icon and MapRenderer (pushState,
       popState, hide);
     * how its text is placed: Text and ScrollableTexts centre their lines
       (drawMultiCenteredText, drawSingleCenteredText: the advance width, J.round of half
       of it); the credits set the bold font and leave it on; the tutorials' rows of
       coloured words and icons (Row.drawRows, ColorTextLoader); which positions come from
       Graphics.getStringWidth (JOGL's ink bounds);
     * the transform: the cutscene's zoom scales the modelview at the start of
       VillageStoryTimeLine.draw, and drawTop's images are drawn with it, the dialog after
       loadIdentity is not; find out whether the actors' emotions are;
     * the layer each node needs: a node of the UI layer must not follow one of
       Transition in a frame (GLBackend warns, plan 12). The story texts, the scroll texts
       and the translucent-over-actor image are drawn after the cutscene's fade, "Paused"
       and "game pad lost" after the mode's fade: they belong on Transition (or a layer
       above it), not on UI;
     * the emotions: plan 8 item 2 makes them children of their ActorView with a z_index
       above Overhead and Effects. The legacy draws them after the whole village (also
       over the night layer) and under every legacy overlay. Check that a node in World
       can keep that, at night, under roofs, in a cutscene zoom; else make them UI nodes;
     * the minimap: what it draws (MapRenderer: the disk, the arrow, the cells; gluDisk in
       3D, the depth test off, after the weather and a battle's 3D), and where a node can
       draw it: plan 7.5 recommends a 3D node on the rig. Plan 8.2's experiment says the
       1/255 comes from its batches in the floor's world: find out whether a node drawn
       there keeps it.
   - Coverage: run the coverage probe of CONVERTING_UI.md over every case (temporary
     prints in each overlay's draw and in AutoPlay's shot, in a copy of the project) and
     write cases for what no shot shows, in every mode that draws the overlay:
     * emotions: a villager's and a party member's, over a roof and at night, shaking;
       in a cutscene, also during a zoom;
     * the mission display of each mission kind (The Sewers' bombs, Pensara Prison, Fire
       Cavern's; plan 7.8), hidden while a dialog shows and back after it;
     * "Paused" in a village, a labyrinth and a cutscene; "game pad lost" with a
       documented dev-only way to simulate a lost pad, with its menu moved;
     * each cutscene image mode drawn over the actors, a scrolled one, one under a zoom,
       and a story image with its text back;
     * a story text fading in and out (and a whispered one if there is any), a scroll
       text (the credits of "Ending - Part 3");
     * the tutorial of a trigger door, of a store, of a battle and the menu's tutorial
       page, paged through, with coloured words and icons;
     * the minimap while walking and turning, after a dialog hid it, on a floor with fog
       and a sky, over a battle;
     * an image fade (Menthu1 or Menthu2 dying: find a route; if none exists without a
       long fight, a documented dev-only way).
     Plan the routes with pos in headless probe runs.
   - Record goldens of all cases, old and new. Record the new cases a second time and
     show the self-diff is 0. Never edit game code while a recording runs from the
     project itself.

2. Convert, one overlay at a time, in the order above
   - For each: a scene in scenes/ui/ (or a node of the scene it is drawn over, where the
     facts say so), a twin in the legacy draw method with every state change its drawing
     made, a flag that keeps the legacy drawing: --legacy=emotions, mission, pause,
     story_images, story_texts, tutorials, minimap. Use the Theme; add font size roles
     there, nothing restyled.
   - Parity after each overlay:
     * ab "--legacy=<overlay>" "" on the cases that show it, identical at tolerance 0;
     * all other cases: golden vs. after, identical.
     Choose any tolerance deliberately, and explain every remaining difference with its
     diff image. Fix what fails in the bridge code (the nodes, the twins, GLBackend's
     slots), not in legacy logic.
   - The minimap: if its node cannot reach tolerance 0 legacy vs. scene, the bar is the
     state before it (the 1/255 on exactly plan 7.8's shots, nothing more). Report what
     the node changed about the 1/255.

3. Parity at the end
   - ab "--legacy=<every phase 3 flag>" "" on every case: identical at tolerance 0; the
     run with every flag equals the golden.
   - Golden vs. after on every case: identical.
   - The bridge test must still pass.
   - Measure the frame rate in normal runs (no --seed), legacy vs. node, capped and
     uncapped: a cutscene with images and texts (the Prolog or "The Farl Story"), the
     credits, a labyrinth with the mission display and the minimap (The Sewers), a
     village with emotions.

4. Docs
   - ARCHITECTURE.md section 12 (the new nodes, layers and flags, what stays legacy),
     CONVERTING_UI.md (what the rollout taught) and HANDOFF.md (the new state).
   - Plan sections 8 (add 8.3, the rollout's results), 12, 13 and 14. Where your findings
     contradict the plan, update it and tell me.

5. Prepare closing phase 3 (do not do it)
   - List what removing the legacy overlay paths would delete or change, with line counts
     and what still uses each part: the draw methods the twins replaced (Dialog's,
     drawMessages, drawCardInfo, fadeOldSchool's callers, the emotions, missions, texts,
     images, tutorials, the minimap), the flags, and the Graphics text API that is then
     left to battles, riddles, the menu, the stores and the world map.
   - Say what keeps phase 3's exit ("villages, dungeons and cutscenes have no draw(g) left
     except battles and riddles") from being met after this task (plan 8.2 has a first
     list).

Constraints:
- Convert only the overlays listed above. No step C: no Tweens or Timers, no signals
  replacing polled logic. Gameplay, input and timing stay unchanged in normal runs.
- No new art and no restyling: decision 8 waits.
- Do not change legacy game logic or content to make parity pass; content quirks stay. A
  port bug that the new coverage finds may be fixed before the goldens are recorded, as
  its own listed change. A port bug is a place where the GDScript does what the Java does
  not.
- Dev-only flags are fine if documented; normal play must not change.
- Legacy files follow PORTING.md (Java names, no redesign; bridge members snake_case).
  New files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the scripts under scenes/ and tools/. Run
  Godot from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the node layout of the new scenes, and where each node
  takes its place in the frame (layer, slot, or World);
- the facts of deliverable 1 as you found them, overlay by overlay, where they differ from
  this prompt or plan 8.2;
- the parity results, explaining every difference:
  * legacy vs. node for each overlay on its cases;
  * every flag vs. none on every case, and golden vs. after;
  * the minimap and the 1/255;
- what still draws over or under the converted overlays through legacy code, and why;
- the screenshots you checked and what each showed (contact sheets are fine);
- fps per measured place, legacy vs. node;
- the cases you could not reach or cover, and why;
- the list from deliverable 5;
- anything that surprised you or that the plan got wrong.

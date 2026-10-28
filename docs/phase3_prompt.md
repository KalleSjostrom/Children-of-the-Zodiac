Implement the pilot of phase 3 ("shared UI and transitions") of docs/MODERNIZATION_PLAN.md
in this Godot 4.7 project: the dialog family and the mode fade. Convert, through step B
(presentation), the legacy Dialog (villages/utils/Dialog.gd: the dialog box, the signs it
draws with drawMessages, questions, gifts, the input question), the card info popup
(DeckPage.drawCardInfo) and the fade every game mode draws last (GameMode.draw's
fadeOldSchool). Build the game's Theme for them. Convert no other overlay in this task.

Why these: the Dialog is one singleton that nine modes draw (villages, cutscenes,
labyrinths, stores, the world map, boss battle areas, riddles, trigger doors), so one
node replaces it everywhere and settles how a UI node finds its place in the legacy
frame. The card info is drawn right after the dialog in three modes. The mode fade is
drawn last in every mode, and what may cover it is the question the Transition layer
has to answer.

Read first:
- docs/MODERNIZATION_PLAN.md: sections 2.1, 2.4, 3, 8, 12 and 13; 6.7 to 6.9 and 7.7 to
  7.9 (what phases 1 and 2 learned, and how their closing was prepared); 6.10 and 6.12
  (the particle phases: how a node of new code took its place in the legacy 3D order);
- docs/ARCHITECTURE.md, all of it: the bridge (section 4: World, LegacyLayer, UI,
  Transition), the rules for new code, the flags, the parity workflow (section 7), and
  sections 9 to 11, whose step B conventions this phase mirrors;
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh, and how to record a
  parity set from a copy of the project;
- docs/PORTING.md: the rules for legacy files you touch;
- docs/port_notes/villages.md, docs/port_notes/menu.md and docs/port_notes/story.md.

State:
- Phases 1 and 2 and the particles phase P are committed (36d0b35e, 150c6b6d,
  4b74ade3). P2 is committed: the dungeon weather, the save points and the
  card and enemy effects drawn as particles run on the GPU (plan 6.12).
- Left open, not part of this task: legacy vs. scene differs by 1/255 on 84 of 3,046
  dungeon shots (tolerance 1, unexplained, plan 7.8); loading the largest floor takes
  about 180 ms; verify_villages.gd --all passes 111 of 117 builds ("Zazo at Night - 0"'s
  loot, and "Dellna - 1" and "Dellna - 2", whose scenes 4b74ade3 re-saved with snow
  systems their .vil files do not build). Both sides of this task's comparisons draw
  the floors and villages through their scenes, so none of these should show here.
- The goldens in tools/parity/out are stale: p2golden and p2shown were recorded before
  P2, whose effects decide a battle's waits with a smaller pool (battle shots move by
  up to about 0.1 s).
- Every particle system now runs on the GPU and repeats exactly in seeded runs (the
  GPU path recorded twice is identical), so the particles may stay shown in this
  task's recordings; --hide-particles hides them all if a comparison needs that.
- Tools you can reuse: parity.sh --jobs=<n> (8 on this machine), case patterns,
  --ignore-world, --tolerance; AutoPlay pos, heading, guard, the relative buttons,
  console, loopuntil (which also matches "dialog" in labyrinths and the battle mode in
  a boss battle area, without printing them); --start-node, --status, --start-time,
  --no-encounters, --hide-particles; the console's cast and --casts (cards played on a
  party member's turn); tools/parity/contact_sheet.gd; recording from a copy of the
  project (HANDOFF), so that code can be edited while a set records.
- Prior art for the ordering question of deliverable 1, in 3D: GLBackend.show_node
  (a node of new code kept in the frame's 3D chunk, in a batch slot of the legacy
  order) and Graphics.reserve_scene_slot (a scene node sorted between the 3D bridge's
  batches). The 2D canvas items of GLBackend are ordered by their draw index.
- In seeded runs an unseeded JRandom takes J.nextSeed(): a new generator seeded from
  that sequence shifts every later JRandom (the steps to a random battle) against the
  goldens. Seed anything new from a hash of the seed, as Main does.
- --seed runs read no game pad and advance a game clock by one fixed step per frame,
  so blocking work does not show in their timings. Measure frame rates in normal runs.
  Do not type while a recording runs: a new run's window takes the focus.
- If the Godot editor is open on the project, it imports new files and generates .uid
  files. Close it while recording. If I change one of your files while you work, keep
  my change and tell me.
- Start from a clean, committed tree. This prompt file doesn't count.

Decisions (plan section 13):
- This is presentation only (step B). The legacy Dialog, DialogSequence, Fadeable and
  the modes stay in charge of state, input and timing; the nodes draw what the legacy
  drawing would have drawn in that frame. Keep the legacy look: the same papers, fonts,
  sizes, positions, colours and alphas.
- The UI items in TODO.md (replace the papyrus font, a vertical Yes/No, the papers that
  look "not in world") are look changes. Not in this task: once parity holds, they are
  my decision.
- Decision 4, resolution: keep the 1024x768 4:3 virtual screen (stretch mode
  canvas_items). The UI nodes use the coordinates the legacy drawing uses.
- Decision 6, time base: decided for particles only. Nothing in this task may need it:
  the fade draws the legacy fadeValue; no Tween, no Timer drives a fade or the dialog's
  fade-in.
- Decision 3 (step C) is not made: no signals replacing the polled logic (the modes'
  checkButtons, Dialog.move, isFinished stay as they are).
- Decision 5, text formats: not made. The dialogs keep coming from the .seq, .vil, .map
  and .trig files.
- Battles keep their own boss dialogs (battle/bosses/Dialog.gd, part of the battle) and
  the battle's 2D: phase 4.
- Make no other open decision.

Deliverables, in this order. Do (0) and (1) before converting anything, so that the
goldens are recorded on unconverted code.

0. Baseline
   - tools/check.sh reports 0 failed. Record goldens of all existing cases
     (tools/parity/parity.sh record golden --jobs=8, and bridge_test, which is "extra").
   - Record the cases that show dialogs (story_*, the dungeon_use_* and
     dungeon_trigger_* cases, stores, boss) a second time and show the self-diff is 0.

1. Parity coverage, then goldens
   - Facts to verify before relying on them:
     * The draw order around the dialog in each mode, and what each mode draws after
       it in the same frame:
       - Village.drawOverlays (src/villages/Village.gd:552-564): the emotion bubbles,
         the dialog, a sign's text (Dialog.drawMessages), the card info of a loot;
       - VillageStoryTimeLine.drawTop (src/story/VillageStoryTimeLine.gd:703-760): the
         village's overlays, the cover-all and story images, the dialog, then its own
         fadeOldSchool, then the scroll texts and images drawn over that fade;
       - Labyrinth.draw (src/labyrinth/Labyrinth.gd:529-545): the mission, the dialog,
         the card info, a battle's or riddle's top layer, the tutorials' top layer,
         then the mode fade;
       - Building.drawStandard and draw (src/store/Building.gd:131-160),
         Landscape.draw (src/landscape/Landscape.gd:252), BossBattleArea.draw
         (src/battle/BossBattleArea.gd:76-101), RiddleGame.drawTopLayer
         (src/miniGames/RiddleGame.gd:93-97: its own fadeOldSchool and image), and
         TriggerDoor (src/labyrinth/inventory/TriggerDoor.gd).
       A node on the UI layer (CanvasLayer 2) is drawn above everything on
       LegacyLayer: whatever the legacy frame draws after the dialog would end up
       under it. Choose how a UI node takes its place in the legacy order (for
       example a split point like GLBackend.scene_3d, after which the frame's legacy
       2D goes to a canvas above the node, or a slot among GLBackend's canvas items
       as GLBackend.show_node keeps one among the 3D batches), or move what comes
       after it too. Document the mechanism in ARCHITECTURE.md.
     * The fades: Graphics.fadeOldSchool with FADE_TO_BLACK, FADE_TO_WHITE and
       FADE_TO_IMAGE (setFadeImage), fadeOldSchoolColor, fadeOldSchoolColorWhite,
       dim. Which modes draw something after GameMode.draw's fade (the story images
       above), and GameCore.testDraw's "game pad lost" overlay, which fades the frame
       and writes over it.
     * State changed while drawing: Dialog._drawCurrent steps the dialog's fade-in
       alpha by speed in every draw; check the rest of Dialog, DialogSequence,
       MenuHand (the hand cursor) and DeckPage.drawCardInfo. Phases 1 and 2 keep such
       changes where the drawing was, inside draw (in the frame in which the
       Organizer leaves a mode, its update runs but its draw does not).
     * How the legacy text is placed: baselines, Graphics.getStringWidth's JOGL-style
       ink bounds, drawMultiString and the centred and right-aligned variants, the
       even sizes 20-50, bold, Graphics.setTextColor. The legacy text goes through
       Font.draw_string on canvas items, so a node can draw the same glyphs.
     * Where the 1024x768 legacy canvas sits in the window (stretch canvas_items),
       that the UI and Transition layers share it, and what Graphics.copyFrame (the
       menu's thumbnail of the frame) captures of each layer.
   - Hand-written cases for what the existing cases do not show, in every mode that
     draws a dialog: a plain line; a speaker's name; both papers (dialog1, dialog2);
     a whisper (Labyrinth.drawDialog); a question with the hand cursor moved (an inn,
     a store); the input question (DialogSequence.setInputQ, src/villages/Villager.gd:376:
     find the villager); a gift line; a sign; a card received from a chest and from a
     village loot (the card info); the world map's "We can't enter now!"; a boss battle
     area's dialog; a dialog fading in and out; a dialog during a mode fade; a cutscene
     dialog under a story image and under the cutscene's own fade. Plan the routes
     with pos in headless probe runs.
   - Record goldens of all cases, old and new. Record the new cases a second time and
     show the self-diff is 0. Never edit game code while a recording runs from the
     project itself: each case starts Godot fresh and would pick up the edit (record
     from a copy of the project to keep working).

2. Theme (plan 8, item 1)
   - resources/theme/game_theme.tres: the game's two fonts (res/Main/font.ttf,
     boldfont.ttf) at the even sizes 20-50 that setFontSize allows; StyleBoxTextures
     from the dialog papers and the menu pieces (res/Menu/Pieces/) that the converted
     nodes use. Nothing is restyled.

3. The dialog family (step B)
   - scenes/ui/Dialog.tscn (Control, its script beside it): it draws the state of the
     legacy Dialog and DialogSequence for the frame: paper, name, lines, question and
     hand cursor, input question, gift line, alpha. Then the sign box
     (Dialog.drawMessages) and the card info popup (DeckPage.drawCardInfo), as scenes
     of their own or parts of the dialog's, as fits. The scene keeps no strong
     reference to a game mode (ARCHITECTURE section 4).
   - Each mode hands the node the state where its draw drew the dialog, with every
     state change that drawing made (the 3D bridge's rule, applied to 2D). Grep every
     draw you stop calling for state changes (plan 2.4 and 12).
   - --legacy=dialog (Main.is_legacy("dialog")) keeps the legacy drawing.
   - Parity:
     * the cases that show a dialog: tools/parity/parity.sh ab "--legacy=dialog" ""
       <cases>, identical at tolerance 0;
     * all other cases: golden vs. after, identical.
     Choose any tolerance deliberately, and explain every remaining difference with its
     diff image. Fix what fails in the bridge code (the nodes and the modes' handing
     over), not in legacy logic.

4. The mode fade (step B)
   - The Transition layer (CanvasLayer 3) draws GameMode.draw's fade: a ColorRect or a
     TextureRect for setFadeImage, with the legacy fadeValue and fade colour of the
     frame. The fades drawn in the middle of a frame (a cutscene's, a riddle's, the
     game pad overlay's) stay legacy unless the ordering mechanism of deliverable 1
     makes them safe to move; report which you moved.
   - --legacy=fades keeps the legacy drawing.
   - Parity: ab "--legacy=fades" "" on every case (every case fades), identical at
     tolerance 0; then ab "--legacy=dialog,fades" "" on every case.
   - The bridge test must still pass.

5. Docs
   - ARCHITECTURE.md: a UI section (the Theme, the nodes, how a UI node takes its place
     in the legacy frame, the new flags, what stays legacy).
   - HANDOFF.md: the new state.
   - docs/CONVERTING_UI.md: the procedure for the next overlays, as
     CONVERTING_VILLAGES.md and CONVERTING_DUNGEONS.md do.
   - Plan sections 8, 12, 13 and 14. Where your findings contradict the plan, update it
     and tell me.

6. Prepare phase 3's rollout (do not do it)
   - List the remaining legacy overlays of villages, labyrinths and cutscenes, with
     their place in each mode's frame and what blocks each: the emotion bubbles, the
     mission display, the minimap (plan 7.5 recommends a 3D node on the rig; check
     whether that removes the 1/255 of plan 7.8), the tutorials' top layer, the story
     texts, scroll texts and images, "Paused" and "game pad lost", the menu pages.
   - Say what keeps phase 3's exit ("villages, dungeons and cutscenes have no draw(g)
     left except battles and riddles") from being met after the rollout.

Constraints:
- Convert only the dialog family, the card info popup and the mode fade.
- No step C: no Tweens or Timers for fades or the dialog's fade-in, no signals replacing
  polled logic. Gameplay, input and timing stay unchanged in normal runs.
- No new art and no restyling: the TODO.md UI items wait (see Decisions).
- Do not change legacy game logic or content to make parity pass; content quirks stay.
  A port bug that the new coverage finds may be fixed before the goldens are recorded,
  as its own listed change. A port bug is a place where the GDScript does what the Java
  does not.
- Dev-only flags are fine if documented; normal play must not change.
- Legacy files follow PORTING.md (Java names, no redesign; bridge members snake_case).
  New files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the scripts under scenes/ and tools/.
  Run Godot from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the node layout of the new scenes, and how a UI node
  takes its place in the legacy frame;
- the facts of deliverable 1 as you found them, mode by mode, where they differ from
  this prompt;
- the parity results, explaining every difference:
  * golden vs. after for the cases without a dialog;
  * legacy vs. node for the dialog cases, and for the fades on every case;
- what still draws over or under the dialog and the fade through legacy code, and why;
- the screenshots you checked and what each showed (contact sheets are fine);
- fps of a dialog-heavy cutscene and a labyrinth dialog, legacy vs. node, in normal
  runs;
- the list from deliverable 6;
- anything that surprised you or that the plan got wrong.

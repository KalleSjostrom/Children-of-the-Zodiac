Implement the pilot of phase 4.4 ("battle, cards, effects") of docs/MODERNIZATION_PLAN.md in
this Godot 4.7 project: the battle's 2D top layer, through step B (presentation). That is
what BattleManager.drawTopLayer draws after the labyrinth's mission and dialog: an enemy's
red flash, the result screen, the spoils screen with its level-up bars, and the legend's
button icons. Convert nothing of the battle's 3D drawing in this task (the enemies, the
info panels, the deck, the hand, the legend's gradient and lines, the effects, the attack
text, the clock): deliverable 5 prepares its rollout.

Why this first: plan 9.4 ("Prepared after closing phase 4.2") recommends it. The top layer
is 2D after every 3D chunk of the frame, in the slot where the riddles' nodes are, and
phase 4.2 built nodes for nearly all of it (ShadowText, the Fade node on UI, LevelBar,
CardView, MenuBackground images). It is the last caller of four of the five legacy
helpers that closing phase 4.2 kept for the battles (drawWithShadow stays for the clock
and the attack name, which are drawn among the 3D chunks). It also gives the level-up
screen its first cases.

Read first:
- docs/MODERNIZATION_PLAN.md:
  * 9.4, above all "Prepared after closing phase 4.2" (the battle's frame, the helpers kept
    for it by caller, the nodes to reuse, the order), and 9.3 (why 4.3 waits);
  * 9.2: the stores' and the mini-games' results (the Fade node on UI, LevelBar, the
    riddles' place in the labyrinth's frame) and "Closing phase 4.2";
  * 2.4's battle rows, 2.5, 6.12 (the battle effects on the GPU and their waits), 7.5 and
    8.3 (the battle in the hybrid period, the 3D bridge, the minimap's 1/255);
  * 12, 13 and 14;
- docs/ARCHITECTURE.md: sections 4 (the bridge), 6 (bridge members), 7 (the flags and the
  parity workflow), 11 (the battle effects), 12 (UI nodes in the legacy frame, show_ui,
  the Fade node, the twins), 14 (the whole 2D modes, above all "The stores" and "The
  riddles": the nodes this task reuses);
- docs/CONVERTING_UI.md, all of it (section 5 for what 4.2 added, including its closing);
- docs/HANDOFF.md: running Godot, AutoPlay, tools/check.sh, recording from a project copy;
- docs/PORTING.md: the rules for legacy files you touch.

State:
- Phase 4.2 is closed and committed: its legacy paths and its eleven --legacy= flags are
  gone (plan 9.2, "Closing phase 4.2"). If git status shows the closing uncommitted, stop
  and tell me. Start from a clean, committed tree; this prompt file doesn't count.
- The only --legacy= flags left are the battle effects' (battle_effects, effect_waits).
- tools/parity/out holds one set: c42after (the closing's final run: 428 cases, 8,096
  shots; 3 script errors and 2,421 errors in all, the exit leak reports only in the five
  effects_* cases). Record
  your baseline on the commit you start from and compare it with c42after (shots, logs,
  per-case error and leak lines): it should be identical. out/_work holds the helper
  scripts (errcounts.py: per-case error and leak line counts of two sets; flags.sh and
  flags_riddle.sh as examples of per-flag runs; probe_riddle_patch.py and
  legacy2d_patch.py as examples of a coverage probe and of the "no legacy 2D" check).
  * Make project copies under tools/parity/out/_<name> with robocopy (HANDOFF), never in
    the session scratchpad.
  * A full run (428 cases) takes about 23 minutes with 4 jobs. Check the free memory first
    (about 5.5 to 6 GB free at idle: 4 jobs were reliable); run nothing beside a
    recording, not even a headless compare. Only the effects_* cases print an exit leak
    report (7 objects).
  * A full set is about 5.6 GB; delete intermediate sets once compared and keep only your
    final run at the end.
- What the top layer draws (verify every fact before relying on it):
  * Labyrinth.draw (src/labyrinth/Labyrinth.gd) calls drawExtra(g, true) after the
    mission and the dialog, before its top-layer items and the mode fade:
    labDrawable.drawTopLayer → BattleManager.drawTopLayer (src/battle/BattleManager.gd:188):
    each object's drawTopLayer (the enemies: BattleEnemy.drawTopLayer,
    src/battle/enemy/BattleEnemy.gd:120: fadeOldSchoolColorWhite(.8, 0, 0, .5) while a
    critical hit hides the enemy), then Battle.drawTopLayer (src/battle/Battle.gd:212).
  * Battle.drawTopLayer: in RESULT mode ResultScreen.drawResult
    (src/battle/resultScreen/ResultScreen.gd:50), in SPOILS mode SpoilsScreen.drawSpoils
    (src/battle/resultScreen/SpoilsScreen.gd:154); then Legend.drawTopLayer
    (src/battle/Legend.gd:66: six button icons at an x that slides with the legend); then
    the tutorial (phase 3's node).
  * The result screen: ResultScreenBase.drawBackground (src/battle/resultScreen/Screen.gd:44:
    fadeOldSchool(.5), setColor(1), resultBack.png at (170, 190) scaled 1.1), size 26,
    drawWithShadow for the labels and the names, drawValueWithShadow (red or green) for
    the damage, AbstractCard.drawCard for the played cards (175 + i × 80, 385).
  * The spoils screen: the same background; "Result", the gold and experience lines, per
    character its name, its experience or "Level up!" or "Max level" in a colour, and its
    bar (SpoilsScreen.drawBars: LevelUpBar.draw, src/battle/bars/LevelUpBar.gd:22:
    emptyBar, blueBar and overlay through drawImage's percent part, red when it cannot
    level up); "You found …" for a dropped item; the lines appear step by step (a
    Scheduler tick every 700 ms, CROSS skips ahead).
  * Graphics' helpers: drawWithShadow (src/graphics/Graphics.gd:626), drawValueWithShadow
    (:615), fadeOldSchool (:701), fadeOldSchoolColorWhite (:756), drawImage (:372).
- Coverage: battle, boss, the dungeon_battle_* and effects_* cases show battles. Which
  shots show the result screen, the spoils screen, a level up, "Max level", a dropped
  item, the red flash or the legend's icons is not known: the probe will tell. The
  level-up screen has no case (HANDOFF). A lost battle goes to the game over (boss).
- The battle's own decks, hand and scroll bar are not MenuNode's (AbstractDeck, GLHand,
  BattleScrollBar); the game pad lost menu over a battle is a MenuList already.
- --seed runs read no game pad and advance a game clock by one fixed step per frame
  (Scheduler and J.currentTimeMillis read it): the spoils screen's steps are seeded too.
  Measure frame rates in normal runs.
- In seeded runs an unseeded JRandom takes J.nextSeed(): seed anything new from a hash of
  the seed, as Main does (ParticleSystem.gpu_rand).
- Do not type while a recording runs. If the Godot editor is open on the project, close it
  while recording. If I change one of your files while you work, keep my change and tell
  me.

Decisions (plan section 13):
- Step B only. The legacy objects keep the state, the input and the timing (the battle's
  modes, the spoils screen's steps and Scheduler tick, the legend's slide, the enemies'
  hide timers). No Tweens, Timers, signals or InputMap (decision 3; phase 4.3).
- Decision 6 is not needed: the nodes mirror the legacy values each frame.
- Decision 8 (the UI look) is not made: keep the images, fonts, sizes, positions, colours
  and alphas. BaselineLabel.oversampling stays 1. Decision 4: the 1024x768 screen.
- The battle's 3D (Battle.tscn under the camera rig, the cards, the enemies, the effects'
  scenes) is the rollout, not this task.
- Make no other open decision.

Deliverables, in this order. Do (0) and (1) before converting anything.

0. Baseline: tools/check.sh reports 0 failed; record all cases; compare with c42after.

1. Facts and coverage, then goldens
   - Verify the facts above and add what the prompt misses: the order of the top layer's
     parts and what overlaps (the flash over the result screen? the legend's icons over
     the spoils screen?), the state changes in the draws (the colours, the font size 26,
     drawWithShadow's text colours and setColor(color), the fade colour and the fade
     image's bind of fadeOldSchool and fadeOldSchoolColorWhite, the images' binds,
     LevelUpBar's setImageColor and setColor), what state the top layer starts from and
     leaves (the alpha test of a floor's weather or save point, the font size, the text
     colour), whether any draw changes game state (the bars' lazy creation in drawBars).
     Compare the 2D state the riddles' top layer met (plan 9.2).
   - Coverage: the probe of CONVERTING_UI (prints in a project copy, headless where it
     needs no picture) in the top layer's draws (the mode, the screen's step, each
     character's state, the flash, the legend's x) and in AutoPlay's shot, over every
     battle case. Then cases for what no shot shows: the result screen of a normal attack
     and of an attack on all (the damage in red and green, the played cards), the spoils
     screen step by step with a level up, "Max level", a character who died (red name),
     a dropped item, CROSS skipping ahead; the red flash of a critical hit; the legend's
     icons (sliding in and out, support and offense); "Paused" over a result screen. Use
     the console's casts (--casts, `cast next`), `gold`, `give`, statuses or a dev-only
     console command for states no seeded route reaches; document any new one.
   - Record goldens of all cases, old and new; record the new cases a second time
     (identical).

2. The top layer (step B)
   - Twins at the call sites, as the riddles' (ARCHITECTURE section 14): the dim
     (Graphics.show_fade on the UI layer), the red flash (a Fade node with
     fadeOldSchoolColorWhite's colour; check how Graphics.show_fade and the Fade node
     take a colour, and add what is missing), resultBack.png at 1.1 (a LevelBar quad:
     scaled images are not exact as TextureRects, plan 12), the lines over their shadows
     (ShadowText, or a node that holds a screen's lines in order), the played cards
     (CardView through AbstractCard.place_at), the level-up bars (LevelBar through
     Graphics.place_image_part's percent part, as LevelUpBar.place_static does for the
     Church), the legend's icons (MenuBackground images through Graphics.place_image).
     Every state change of the drawing in its order. New nodes only where nothing covers
     a part.
   - Flags: one --legacy=<part> per kind of part (for example battle_screens,
     battle_flash, battle_legend), in ARCHITECTURE section 7. With all of them on, the
     frame is drawn exactly as before.
   - Parity: golden vs. after on every case (identical at tolerance 0; logs, per-case
     error and leak lines too); each flag alone and all of them vs. after and vs. the
     golden on the battle cases; every flag on vs. the golden on every case. A run with
     prints in Graphics._drawText and _emit2D shows no legacy text or quad left in the
     top layer with the flags off. Choose any tolerance deliberately and explain every
     difference with its diff image; fix the bridge code, not legacy logic.
   - The frame rate in normal runs, legacy vs. nodes, capped and uncapped: a result
     screen and a spoils screen.

3. The helpers: after the conversion, list which of the five helpers closing 4.2 kept
   still have a caller (drawWithShadow: the clock's "Fleeing" and the attack name), and
   which are only Graphics' API now (they stay until phase 5).

4. Docs: ARCHITECTURE (section 6's bridge members, 7's flags, a battle section: the top
   layer's nodes and their place in the frame), CONVERTING_UI (what the battle adds),
   plan 9.4 (the results, as 9.2 records the stores'), 12, 13, 14, HANDOFF (the new state).

5. Prepare the rollout (do not do it): the battle's 3D frame part by part (the enemies, the
   info panels, the deck and cards, the hand, the legend's gradient and lines, the
   clock and its bars, the attack text and name, the effects that are not particles),
   with what each draws, the state it changes, what the 3D bridge does for it today, the
   coverage, the cases still needed, and an order with sizes. Say what the 2D text among
   the 3D chunks needs (ARCHITECTURE section 12: a UI node before a 3D chunk) and what
   the minimap's 1/255 (8.3) means for it.

Constraints:
- Convert only the battle's top layer. No step C. Gameplay, input and timing unchanged.
- Do not change legacy game logic or content; a port bug found on the way may be fixed as
  its own listed change with new goldens (the Java is in _java_reference/src/).
- Dev-only flags and console commands are fine if documented. Normal play must not change.
- Legacy files follow PORTING.md; new files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed. Run Godot from bash with < /dev/null. Screenshots
  need a window (not --headless). Ad-hoc runs end themselves (AutoPlay quit,
  --quit-after-ms).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the nodes and their place in the frame;
- the facts of deliverable 1 where they differ from this prompt or plan 9.4;
- the parity results, every difference explained (golden vs. after, legacy vs. nodes per
  flag, every flag on vs. the golden, the new cases twice);
- what the battle still draws through legacy code, and why; deliverable 3's list;
- the screenshots you checked (contact sheets are fine); fps legacy vs. nodes;
- the cases you could not reach, and why;
- deliverable 5's list and proposed order;
- anything that surprised you or that the plan got wrong.

Implement the pilot of phase 4.2 ("title, game over, mini-games, stores, menu") of
docs/MODERNIZATION_PLAN.md in this Godot 4.7 project: the title screen (TitleScreen) and the
game over screen (GameOver), through step B (presentation), and with them the menu list
(MenuNode with its MenuHand) as a node. Convert no store, menu page or mini-game in this
task: deliverable 4 prepares their rollout.

Why these: they are the two smallest modes (209 lines) and the first that nothing but UI
draws: no world under them. Converting them settles where a mode's nodes live when its
whole frame is 2D, which the stores and the menu pages need next. The title also draws
the shared menu list that the stores, the menu pages and the church draw in many
variants (prices, numbers, equipment, active children, a scroll bar, a dimmed hand). Phase
3 showed the list's plainest form as nodes ("game pad lost": LabelList and a hand); the
pilot builds the list node the rollout extends.

Read first:
- docs/MODERNIZATION_PLAN.md:
  * 9.2, and 2.4's table rows for the title and game over, the menu, the stores and the
    mini-games;
  * 2.5 (the title logo is one of the per-update systems);
  * 3, 4 (the target tree: menu pages on the UI layer);
  * 8 to 8.4 (phase 3: the UI conventions, the facts it found, its closing);
  * 9.1 (phase 4.1: the last step B, how it was checked, its closing);
  * 12, 13 and 14;
- docs/ARCHITECTURE.md, all of it. Section 4 covers the bridge (World and the layers), 7
  the flags and the parity workflow, 8 the bridge test, 12 the UI nodes, BaselineLabel,
  LabelList, show_ui and the twins, 13 the world map;
- docs/CONVERTING_UI.md, including the coverage probe;
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh, and how to record a
  parity set from a copy of the project;
- docs/PORTING.md: the rules for legacy files you touch;
- docs/port_notes/menu.md, and docs/DIFFICULTY.md (the title's difficulty choice and the
  save slots, COTZ-004 and COTZ-005).

State:
- Phase 4.1 is committed: the world map and the airship draw through scenes (ARCHITECTURE
  section 13). If git status shows its files uncommitted, stop and tell me.
- The title, game over, menu, stores, riddles and battles still draw through Graphics,
  except phase 3's nodes: the dialog, the message box, the card info, the fade,
  "Paused", "game pad lost" and the tutorials.
- The game starts at the title when there is no --start. title_start, story_long and
  newgame_to_forest start there. dungeon_save_load and two Celis memories (COTZ-036)
  return to it. Only boss reaches the game over screen. The coverage probe will tell
  which shots show what.
- Left open, not part of this task:
  * the dungeons' 1/255 (plan 7.8, 8.3);
  * the minimap on the 3D bridge;
  * the closings of phases 1 to 4.1 (6.9, 7.9, 8.4, 9.1);
  * the quirks in tickets/triage.md (W1 to W4 from phase 4.1).
- Do not run tools/import/vil_to_scene.sh --all. It rewrites three village scenes that
  the editor saved by hand in 4b74ade3 (plan 12).
- Record goldens on the commit you start from. g41gold in tools/parity/out was recorded
  on phase 4.1's unconverted code, and the world map cases now log world=<map>.
  * A full run (392 cases and bridge_test, --jobs=8) takes about 13 minutes.
  * The machine has 16 GB of memory, and an 8-job recording leaves about 3 GB. Run
    nothing windowed beside a recording: in phase 4.1 four extra windows made one run
    crash and others fail to decode textures with their shots unchanged. Compare each
    case's error lines, not only the shots.
  * With more parallel jobs some runs fail to start (exit 127, an empty log). Re-record
    those cases.
  * Record from a copy of the project (HANDOFF) when you want to edit code meanwhile.
- In seeded runs an unseeded JRandom takes J.nextSeed(). A new generator seeded from that
  sequence shifts every later JRandom against the goldens. Seed anything new from a hash
  of the seed, as Main does.
- --seed runs read no game pad and advance a game clock by one fixed step per frame.
  Scheduler.sleep (the game over's 22 s) and J.currentTimeMillis read it. Measure frame
  rates in normal runs.
- Seeded runs read only the shipped saves and write to user://saves_deterministic/, which
  is emptied at start. The title's Continue list therefore shows "Empty" for every slot.
  A slot saved during a run shows its file's modification time (SaveSlots.saved_at),
  which is wall-clock time and differs between two recordings.
- Do not type while a recording runs: a new run's window takes the focus.
- If the Godot editor is open on the project, it imports new files and generates .uid
  files. Close it while recording.
- If I change one of your files while you work, keep my change and tell me.
- Start from a clean, committed tree. This prompt file doesn't count.

Decisions (plan section 13):
- Step B (presentation) only. The legacy objects stay in charge of state, input and
  timing:
  * the title logo's fade steps .005 per update (TitleScreen.update), and CROSS skips it;
  * the fades step per drawn frame (Fadeable; the game over's fadeInSpeed .01);
  * the game over's 22 s timer is a Scheduler coroutine;
  * MenuNode keeps the cursor, and GameAction the key repeat.
  The nodes draw what the legacy drawing would have drawn in that frame.
- Decision 6 (time base) is therefore not needed. Plan 9.2's "Control + Tween" for the
  title and game over is step C.
- Decision 3 (step C) is not made: no Tweens or Timers, no signals or InputMap replacing
  the polled input. The InputMap wrapper and the Game autoload are phase 4.3.
- Decision 8, the UI look: not made. Keep the legacy images, fonts, sizes, positions,
  colours and alphas. BaselineLabel.oversampling stays 1.
- Decision 4, resolution: keep the 1024x768 virtual screen. The nodes use the legacy
  screen coordinates.
- Make no other open decision.

Deliverables, in this order. Do (0) and (1) before converting anything, so that the goldens
are recorded on unconverted code.

0. Baseline
   - tools/check.sh reports 0 failed.
   - Record goldens of all existing cases and bridge_test.

1. Facts and coverage, then goldens
   - Facts to verify before relying on them:
     * What each mode draws, in order:
       - TitleScreen.draw (src/title/TitleScreen.gd:124): setColor(1) and setFontSize(24);
         the background loggasten.png at (78, 59);
       - when not fading in, drawTitle: loggatext.png, tinted by setColor(1, 1, 1, index)
         while index < .9;
       - when the logo is done (index > .9), activeNode.drawAllChildren (MenuNode.draw,
         src/menu/Node.gd:84, with MenuHand.drawHand), then:
         · on the difficulty list, the highlighted level's description
           (drawDifficultyInfo: drawWithShadow at (450, 728), size 20);
         · on the Continue list, the slots' dates (SaveSlots.draw_dates_beside,
           scenes/common/SaveSlots.gd);
       - then GameMode.draw's fade (already a node).
       - GameOver.draw (src/title/GameOver.gd:51): setColor(1) and setFontSize(24), the
         background GameOver<the party's names>.jpg at (0, 0), the fade.
       Find out what overlaps, where the order shows, and what the frame draws around
       them: "Paused" (the title is not pausable; the game over is).
     * What these draws change besides drawing: the colour drawTitle leaves; the font
       sizes; the text colours (MenuNode's enable and disable colours; drawWithShadow
       sets black, then the colour); drawString's setColor(color); MenuHand's dim
       (dimmed); every image's bind; MenuNode.draw's cursor fix-up (previousChild when
       the cursor is past the last child), which is game state changed in a draw. Twins
       must keep these. Compare MenuNode.place_all_children and MenuHand.place_hand
       (phase 3, the game pad lost overlay): what they keep, and what they assert they
       do not support.
     * The title's menus: the root (Start, Continue), the difficulty list (Start, the
       cursor on Medium), the Continue list (the autosave when there is one, then the
       three slots), CIRCLE back to the root. Which MenuNode features the title uses
       (active children, the "character" filter, the bounding box and scroll bar, prices,
       numbers, equipment), and which the stores, the menu pages and the church use
       (deliverable 4).
     * The game over's image per party: res/Title has five (Kin; Kin and Celis; with
       Borealis; with Zalzi; with both). Which saves reach which party ("Start", "Start
       demon1", "Start demon2", "Start Menthu1", "Slot 1"), and how a seeded run reaches
       the game over screen (a lost battle; the console's dev commands). Its exits are
       CROSS or the 22 s timer, each fading out to the title.
     * Where a mode's nodes live when nothing else draws its world:
       - the mode's own scene (GameMode.scene_root, shown by Main under World: kept while
         the mode is suspended, freed with the mode);
       - UI nodes in the frame's order (Graphics.show_ui, pooled per frame);
       - something else.
       Check each against the title and the game over. Check them too against what the
       rollout's modes need: the stores and the menu pages draw 3D cards as SubViewport
       chunks between their 2D; the dialog and the card info are UI nodes in the same
       frames; the menu shows a thumbnail of the frame before. Check also how
       Graphics.copyFrame and the fades see each option. Choose, say why, and write it
       down in ARCHITECTURE.md for the rollout. Plan 4 puts the menu pages on the UI
       layer.
   - Coverage: run the coverage probe of CONVERTING_UI.md over every case. That means
     temporary prints, in a copy of the project, in the title's and the game over's
     draws (the logo's index, the menu shown and its cursor, the description, the dates,
     the fade value, the game over image) and in AutoPlay's shot. Then write cases for
     what no shot shows:
     * the title:
       - the background alone while the mode fades in;
       - the logo fading in (several index values), and CROSS skipping it;
       - the root menu with the cursor on each entry;
       - the difficulty list with each level highlighted and its description;
       - CIRCLE back to the root;
       - the Continue list ("Empty" slots, in a seeded run) with the cursor moved;
       - starting a new game, and loading a slot, through the fade-out;
     * the game over screen:
       - its fade-in;
       - one party's image per party that a save reaches;
       - CROSS, and the 22 s timeout, to the title;
       - "Paused" over it.
     If a case would show a date of a slot saved during the run, the shot is not
     reproducible: keep the cases on "Empty" slots, or give seeded runs a reproducible
     date as a documented dev-only change.
     For a state no seeded route reaches, add a documented dev-only way, preferably a
     debug console command AutoPlay's console runs. Plan the routes in headless probe
     runs.
   - Record goldens of all cases, old and new. Record the new cases a second time and
     show the self-diff is 0. Never edit game code while a recording runs from the
     project itself.

2. The menu list (step B)
   - A node in scenes/ui/ that shows a MenuNode menu as its legacy drawing would: the
     choices (BaselineLabel, a theme role per size), their colours, and the hand
     (MenuHand, dimmed or not). Build it for what the title uses. Design it so that the
     rollout's variants can be added (prices, numbers, equipment, active children's
     lists, the bounding box with its scroll bar): list each with what it draws.
   - The twin: MenuNode.place_all_children and MenuHand.place_hand, or a successor that
     keeps every state change of MenuNode.draw in its order. The game pad lost overlay
     (phase 3) may move onto the new node if its parity holds; report whether it did.

3. The title and the game over (step B)
   - The nodes of the two modes in the place deliverable 1 chose: the title's
     background, logo (its index as alpha), the menu list, the difficulty description
     (drawWithShadow: the black copy 1 px down and right, then the text) and the slots'
     dates; the game over's image.
     * ARCHITECTURE section 2's naming rule applies: TitleScreen and GameOver are legacy
       class names.
     * The theme gets roles for their sizes (24 and 20).
     * The nodes keep no reference to a mode.
   - Twins in the legacy draws, at the point where each part was drawn, with every state
     change of deliverable 1. The menu's cursor fix-up stays in the draw.
   - Flags: one --legacy=<name> per converted part (for example title, game_over,
     menu_list), in ARCHITECTURE section 7's table. With all of them on, the frame is
     drawn exactly as before.
   - The bridge test must still pass.
   - Parity:
     * ab "--legacy=<this task's flags>" "" on the cases that show the title or the game
       over: identical at tolerance 0;
     * golden vs. after on all other cases: identical, logs and error lines too;
     * with every flag on, the run equals the golden.
     Choose any tolerance deliberately, and explain every remaining difference with its
     diff image. Fix what fails in the bridge code (the nodes, the twins), not in legacy
     logic.
   - Measure the frame rate in normal runs (no --seed), legacy vs. nodes, capped and
     uncapped: the title's menu, and the game over screen.

4. Prepare the rollout (do not do it)
   - For the mini-games, the stores and the menu, list per mode:
     * what each draw draws, in order;
     * what is 2D, and what is 3D: the cards' quads in SubViewport chunks, and which
       parts wait for phase 4.4's cards;
     * the state changes in the draws;
     * what is shared with other modes: the menu backgrounds of AbstractPage and
       Building, the menu list variants, ScrollBar, the confirm dims, the keeper's
       dialog, the card info, the tutorials, the Church's HelpText rows, the thumbnail;
     * the existing coverage, by the probe;
     * the cases each still needs.
     The modes:
     * the mini-games: RiddleGame and the puzzles, which run inside a labyrinth's frame
       (labDrawable) with their own fade;
     * the stores: Building, AbstractStore, CardStore, WeaponStore, Inn, Church;
     * the menu: MainMenu and its pages Start, Status, Equip, Deck, Map (the automap,
       LabyrinthMap.draw), Bestiary, Help and Tutorial.
   - Propose an order and how many sessions, with what blocks each part.

5. Docs
   - ARCHITECTURE.md:
     * the place of a mode's nodes when its whole frame is 2D, and the menu list node;
     * the title's and the game over's nodes;
     * the theme roles, and the flags in section 7.
   - docs/CONVERTING_UI.md: what the rollout of whole 2D modes adds to the procedure.
   - HANDOFF.md: the new state.
   - Plan sections 9.2 (add the results and deliverable 4's list), 12, 13 and 14. Where
     your findings contradict the plan, update it and tell me.

Constraints:
- Convert only the title, the game over screen and the menu list they draw. No step C:
  no Tweens or Timers, no signals or InputMap replacing polled logic. Gameplay, input and
  timing stay unchanged in normal runs.
- No new art and no restyling: decision 8 waits.
- Do not change legacy game logic or content to make parity pass; content quirks stay. A
  port bug that the new coverage finds may be fixed before the goldens are recorded, as
  its own listed change. A port bug is a place where the GDScript does what the Java does
  not (the Java is in _java_reference/src/).
- Dev-only flags and console commands are fine if documented. Normal play must not
  change.
- Legacy files follow PORTING.md (Java names, no redesign; bridge members snake_case).
  New files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the scripts under scenes/ and tools/. Run
  Godot from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the node layout of the new scenes, and where a mode's
  nodes live when its whole frame is 2D, and why;
- the facts of deliverable 1 as you found them, where they differ from this prompt or
  plan 9.2;
- the parity results, explaining every difference:
  * golden vs. after on the cases without the title or the game over;
  * legacy vs. nodes on the cases with them;
  * every flag on vs. the golden;
  * the bridge test;
- what the two modes still draw through legacy code, and why;
- the screenshots you checked and what each showed (contact sheets are fine);
- fps of the title's menu and the game over screen, legacy vs. nodes;
- the cases you could not reach or cover, and why;
- the list and the proposed order from deliverable 4;
- anything that surprised you or that the plan got wrong.

Start the rollout of phase 4.2 ("title, game over, mini-games, stores, menu") of
docs/MODERNIZATION_PLAN.md in this Godot 4.7 project: convert the menu (MainMenu and its
pages) through step B (presentation). This is the first of the rollout's three parts; plan
9.2 orders them the menu, the stores, the mini-games. The stores and the mini-games are not
in this task, but the menu builds the parts the stores reuse, so build those for both.

Why the menu first: it is covered best (every village and dungeon tour opens it), it blocks
nothing, and it builds what the stores need next: the menu background pieces, the menu list
variants with their scroll bar, the status and equipment helpers, the deck of card images.

In scope, in this order:
- the frame every page shares: MainMenu.draw (src/menu/MainMenu.gd:193),
  AbstractPage.drawStandard (back.jpg and the page's pieces, drawMenuBackgroundStatic,
  AbstractPage.gd:208, 235), StartPage.drawInfo (gold, steps, time), StartPage.drawScreenShot
  (the thumbnail), the pages' titles and their help lines (button icons and labels,
  drawHelp per page);
- MenuList's variants the pages use (docs/ARCHITECTURE.md section 14's table): numbers,
  equipment with "down", the bounding box and its scroll bar (MenuScrollBar,
  src/menu/ScrollBar.gd), an active child's list, the dimmed hand; and the scroll bars the
  deck page makes directly;
- StartPage (StartPage.gd:207): the root list, Key Items, the Save list with the dates under
  each slot (SaveSlots.draw_dates_under), the character select, the status lines
  (StatusPage.drawTop, drawSlots), the saving box (drawConfirmBuyDialog);
- TutorialPage (TutorialPage.gd:98; its tutorial is a node since phase 3) and HelpPage
  (HelpPage.gd:90: the options, the difficulty list, the wrapped difficulty text);
- EquipPage (EquipPage.gd:113): the status with the comparison (drawStatus, drawChange),
  the item (StatusPage.drawEquip), the slots list and the equipment list, both hands;
- DeckPage (DeckPage.gd:225): the decks' titles, the decks (Deck.drawDeck,
  src/equipment/Deck.gd:199: card images; the passive deck at .5 while editing), the Edit and
  Back list, the status line drawn instead of a missing card's info, the scroll bars, the
  flying cards (DeckPage.Animator), the help lines; the card info is a node since phase 3;
- MapPage (MapPage.gd:199) with the automap (src/info/LabyrinthMap.gd:77): the lists, all
  floors under a scaled modelview or one floor, the floors' names, "Explored".

Not in scope: StatusPage.draw3D and BestiaryPage.draw3D (unreachable: plan Appendix; their
static helpers are in scope), the stores and the Church (they reuse what you build, next
part), the riddles, the battles, the Cheater's lists (dev only), HelpPage's volume options
(logic, not drawing; they never match, as in the original).

Read first:
- docs/MODERNIZATION_PLAN.md:
  * 9.2: the pilot's results, and "The rollout of 4.2": the menu's draws, state changes,
    shared parts, coverage by the probe and the cases still needed; and the variants;
  * 2.4's menu row, 8 to 8.4 (phase 3: the UI conventions, the overlays), 9.1;
  * 12 (the risks: pooled nodes keep their textures, Godot's transforms round differently,
    a Control's culling rect), 13 and 14, and the Appendix (the menu's dead code);
- docs/ARCHITECTURE.md, all of it. Section 12 has the UI nodes, BaselineLabel, LabelList,
  show_ui and the twins; section 14 where a whole 2D mode's nodes live (UI nodes in the
  frame's order), MenuList and its variants, the title's nodes;
- docs/CONVERTING_UI.md, section 5 above all (whole 2D modes) and the coverage probe;
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh, and how to record a parity
  set from a copy of the project;
- docs/PORTING.md: the rules for legacy files you touch;
- docs/port_notes/menu.md.

State:
- Phase 4.2's pilot is committed: scenes/ui/Title, MenuList, ShadowText, SlotDates,
  GameOverScreen; MenuNode.show_all_children, SaveSlots.show_dates_beside,
  Graphics.place_with_shadow; --legacy=title, game_over, menu_list; the game pad lost
  menu on MenuList; the dev-only game-clock dates of seeded runs (SaveSlots.note_saved); the
  title_* and game_over* cases. If git status shows its files uncommitted, stop and tell me.
- The menu, the stores, the riddles and the battles still draw through Graphics, except the
  nodes of phases 3 and 4.2 (dialog, message box, card info, fade, "Paused", "game pad
  lost", the tutorials, the title, the game over, MenuList on the title).
- The menu draws nothing in 3D: its cards are 2D images (AbstractCard.drawCard, drawImage).
- Coverage by the pilot's probe (plan 9.2): 337 menu shots in 279 cases, StartPage 300 of
  them; no shot of the equipment list, the help page's difficulty list, the Save list
  after a save, the saving box, Key Items scrolled, cards flying or a list scrolled in its
  bounding box.
- Left open, not part of this task:
  * the riddle fade's port bug (plan Appendix; fix it before the mini-games);
  * the dungeons' 1/255 (plan 7.8, 8.3), the minimap on the 3D bridge;
  * the closings of phases 1 to 4.1;
  * the quirks in tickets/triage.md (W1 to W4, R1).
- Do not run tools/import/vil_to_scene.sh --all. It rewrites three village scenes that
  the editor saved by hand in 4b74ade3 (plan 12).
- Record goldens on the commit you start from. g42gold in tools/parity/out was recorded on
  the pilot's unconverted code with the pilot's cases.
  * A full run (401 cases and bridge_test, --jobs=8) takes about 14 minutes.
  * The machine has 16 GB of memory, and an 8-job recording leaves about 3 GB. Run nothing
    windowed beside a recording (headless probe runs are fine beside nothing else).
    Compare each case's error lines, not only the shots: a game pad or audio device event
    during a run adds WASAPI or HIDAPI lines (and changes that run's exit leak counts);
    those are not differences of the code.
  * With more parallel jobs some runs fail to start (exit 127, an empty log). Re-record
    those cases.
  * Record from a copy of the project (HANDOFF) when you want to edit code meanwhile.
- In seeded runs an unseeded JRandom takes J.nextSeed(). A new generator seeded from that
  sequence shifts every later JRandom against the goldens. Seed anything new from a hash
  of the seed, as Main does.
- --seed runs read no game pad and advance a game clock by one fixed step per frame. Seeded
  runs read only the shipped saves and write to user://saves_deterministic/, which is
  emptied at start; a slot saved during the run is dated by the game clock from 1 Jan 2000,
  so the Save list's dates can be shot. Measure frame rates in normal runs.
- A shot shows the frame before it (AutoPlay reads the viewport after the frame's drawing).
- Do not type while a recording runs: a new run's window takes the focus.
- If the Godot editor is open on the project, it imports new files and generates .uid
  files. Close it while recording.
- If I change one of your files while you work, keep my change and tell me.
- Start from a clean, committed tree. This prompt file doesn't count.

Decisions (plan section 13):
- Step B (presentation) only. The legacy objects stay in charge of state, input and
  timing: MainMenu and its pages, MenuNode (the cursor), GameAction (the key repeat), the
  deck's Animator, the saving box's Scheduler timers, the BestiaryPage's coroutine. The
  nodes draw what the legacy drawing would have drawn in that frame.
- Where the nodes live is decided (ARCHITECTURE section 14): UI nodes in the frame's order
  (Graphics.show_ui). A page may be one node or several; a drawing between two parts that
  is still legacy, or a phase 3 node (the card info, the tutorial), needs its own slot.
- Decision 3 (step C) is not made: no Tweens or Timers, no signals or InputMap replacing
  the polled input. The InputMap wrapper and the Game autoload are phase 4.3.
- Decision 5, text formats: not made. The .tut and .help files stay; no BBCode converter.
- Decision 6 (time base) is not needed: nothing here moves by itself but the flying cards
  and the saving box's dots, which stay legacy.
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
   - Re-run the pilot's check on top of whatever landed since: --legacy=title,game_over,
     menu_list vs. the goldens, on every case: identical at tolerance 0.

1. Facts and coverage, then goldens
   - Facts to verify before relying on them (plan 9.2 has a first list; check it against
     the code):
     * What each page draws, in order, in each of its sub-states, and what MainMenu and
       GameCore draw around it: MainMenu.draw's setColor(1), setAlphaFunc(.02) and size 22
       (the alpha test the nodes' materials must keep), the page, the fade (a node; the
       menu fades only when it loads a game), "Paused" (is the menu pausable?), "game pad
       lost". Where the order shows: what overlaps (the hand over the pieces, the card
       info over the decks, the status lines over the pieces, the thumbnail's frame).
     * What the draws change besides drawing: the cursor fix-up (it plays the cursor
       sound; an empty list keeps the cursor at -1); MenuScrollBar's lazy init and its
       loadIdentity; StatusPage.drawTop and drawEquip adding their offset to a static y
       array and replacing it (EquipPage.y is MenuValues.STATUS_Y itself);
       AbstractPage.BUTTON_ICONS loaded on first use; DeckPage's setImageColor(.5) lasting
       until the next drawString; drawDeck turning the bold font off; the automap leaving
       size 22 and black text; the text colours (Key Items' disable colour is black);
       drawString's setColor(color); startText's alpha (the current mode's fade value) for
       the deck titles. Twins must keep these, in their order.
     * The transforms: MapPage.drawAll draws every floor under push, translate(25, 80),
       scale(1/3) and a translate per floor; images go through the modelview, text does
       not (the names are placed by hand). Phase 3 found that Godot's transforms round small
       textures differently from the legacy CPU transform (up to 2/255: the emotion
       bubbles draw the legacy quad, Graphics.screen_points; CutsceneImage's large images
       were exact under a Node2D transform). Find out which the automap's pieces need.
     * The thumbnail: where it is taken (MenuStarter.checkMenu at the end of the
       labyrinth's, village's, world map's and airship's draw: Values.getMenuScreenShot,
       Graphics.copyFrame of the frame before, scaled to 183 x 137), how it is drawn
       (StartPage.drawScreenShot: an Image through ImageHandler.getGameTexture), and that a
       node draws the same pixels.
     * The text: which positions are measured (calcAlignRight for the numbers, centred
       floor names, HelpPage.wrapText's widths), the font sizes (22, 20 for numbers and
       equipment, 34 for a single floor's name, 24 in the overview), bold.
     * MenuNode's variants the pages use, call site by call site (plan 9.2's list), and
       what each draws in which order (ARCHITECTURE section 14's table): design the
       successor of place_all_children that keeps every state change of MenuNode.draw
       for them, without changing what the title and the game pad lost menu get.
     * Which of these parts the stores draw too (the pieces with a store's mask,
       StatusPage and EquipPage's helpers in the Weapon Store, Deck.drawDeck in the Card
       Store, the Inn's StartPage.drawInfo): build those so the stores can reuse them, and
       write down how.
   - Coverage: run the coverage probe of CONVERTING_UI.md over every case: temporary
     prints, in a copy of the project, in MainMenu.draw (the page and its sub-state), each
     page's draw (what it draws: the lists by name, the decks, the automap's mode), in
     MenuNode.draw (its flags, name, cursor, the bounding box's offset), ScrollBar.draw,
     Deck.drawDeck, the Animator and AutoPlay's shot. Then write cases for what no shot
     shows, at least:
     * StartPage: Key Items scrolled with "(n)" numbers, the Save list after a save (the
       game-clock dates) and the saving box, the character select for Deck and Equip;
     * EquipPage: the equipment list with numbers, scrolled in its bounding box, the
       comparison's red and green changes, the slots with the equipped names;
     * DeckPage: editing a deck (the passive deck at .5, the dimmed hand), cards flying
       both ways, the card info and the status line instead of a missing card, a deck
       scrolled;
     * MapPage: the labyrinth list scrolled, the overview of a labyrinth with several
       floors, one floor zoomed in, the player's floor in green;
     * HelpPage: the difficulty list with a harder level grey, the wrapped text;
     * TutorialPage: its list scrolled;
     * the menu opened from a village, a labyrinth, the world map and the airship (the
       thumbnail).
     For a state no seeded route reaches, add a documented dev-only way, preferably a
     debug console command AutoPlay's console runs. Plan the routes in headless probe runs.
   - Record goldens of all cases, old and new. Record the new cases a second time and show
     the self-diff is 0. Never edit game code while a recording runs from the project
     itself.

2. The shared parts (step B)
   - Nodes in scenes/ui/ for the frame's shared parts (the background and pieces of a
     page's layout, the info, the thumbnail, the title line, the help line) and MenuList's
     variants (with a scroll bar node). Theme roles per size where text is added.
   - Twins at the point where each part was drawn, with every state change of deliverable
     1. A drawing that the stores share gets a node the stores can show with their own
     state (a store's mask, its positions).
   - Parity after this step on the cases that show the menu (see 4).

3. The pages (step B), in the order of the scope list
   - For each page: its nodes in the place ARCHITECTURE section 14 gives (UI nodes in the
     frame's order; the card info and the tutorial keep their slots), the twins, the
     state changes. The nodes keep no reference to a mode or a legacy object.
   - Flags: one --legacy=<name> per converted part (for example menu_frame, status, deck,
     automap; menu_list for the list variants), in ARCHITECTURE section 7's table. Choose
     the split so the stores can use the same flags for the parts they share. With all of
     them on, the frame is drawn exactly as before.
   - Parity after each page on its cases (see 4). If the session ends before every page is
     done, stop after a page whose parity holds and report where you stopped.

4. Parity
   - ab "--legacy=<this task's flags>" "" on the cases that show the menu (by the probe):
     identical at tolerance 0; each flag alone on its parts' cases too.
   - Golden vs. after on all other cases: identical, logs and error lines too.
   - With every flag on (this task's and the pilot's), the run equals the golden.
   - The bridge test must still pass (it opens the menu twice).
   - Choose any tolerance deliberately, and explain every remaining difference with its
     diff image. Fix what fails in the bridge code (the nodes, the twins), not in legacy
     logic.
   - Measure the frame rate in normal runs (no --seed), legacy vs. nodes, capped and
     uncapped: StartPage (the thumbnail and three status lines), DeckPage while editing,
     MapPage's overview of a labyrinth with several floors.

5. Prepare the stores (do not convert them)
   - Update plan 9.2's stores entry: what this task built that they reuse, how a store
     shows each shared node, what is left for them (the keeper, the confirm boxes and
     dims, the card store's merge page, the Church's bless page with HelpText's rows and
     LevelUpBar), the cases they need first (no store sub-page is covered), and the
     sessions it takes.

6. Docs
   - ARCHITECTURE.md: the menu's nodes, the shared parts and how the stores use them,
     MenuList's variants as built, the theme roles, the flags in section 7.
   - docs/CONVERTING_UI.md: what the menu added to section 5.
   - HANDOFF.md: the new state.
   - Plan sections 9.2 (the results), 12, 13 and 14. Where your findings contradict the
     plan, update it and tell me.

Constraints:
- Convert only the menu and the parts listed above. No step C: no Tweens or Timers, no
  signals or InputMap replacing polled logic. Gameplay, input and timing stay unchanged in
  normal runs.
- No new art and no restyling: decision 8 waits.
- Do not change legacy game logic or content to make parity pass; content quirks stay. A
  port bug that the new coverage finds may be fixed before the goldens are recorded, as
  its own listed change. A port bug is a place where the GDScript does what the Java does
  not (the Java is in _java_reference/src/).
- MenuNode.draw and its callers outside the menu (the stores, the battles, the riddles,
  the Cheater) keep drawing as before: switch at the menu's call sites, not inside
  MenuNode.
- Dev-only flags and console commands are fine if documented. Normal play must not change.
- Legacy files follow PORTING.md (Java names, no redesign; bridge members snake_case).
  New files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the scripts under scenes/ and tools/. Run
  Godot from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the node layout of the new scenes, where each takes its
  place in the menu's frame, and how the stores will use the shared ones;
- the facts of deliverable 1 as you found them, where they differ from this prompt or plan
  9.2;
- the parity results, explaining every difference:
  * legacy vs. nodes per flag on its cases, and all flags together;
  * golden vs. after on all other cases;
  * every flag on vs. the golden;
  * the bridge test;
- what the menu still draws through legacy code, and why;
- the screenshots you checked and what each showed (contact sheets are fine);
- fps per measured page, legacy vs. nodes;
- the cases you could not reach or cover, and why;
- deliverable 5's update for the stores;
- anything that surprised you or that the plan got wrong.

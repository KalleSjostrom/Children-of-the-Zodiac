Continue the rollout of phase 4.2 ("title, game over, mini-games, stores, menu") of
docs/MODERNIZATION_PLAN.md in this Godot 4.7 project: convert the stores (the Weapon Store, the
Card Store, the Inn and the Church) through step B (presentation). This is the second of the
rollout's three parts (plan 9.2: the menu, the stores, the mini-games). The menu is done; it
built most of what the stores draw. The mini-games are not in this task.

Why the stores now: they reuse the menu's nodes (the pieces, the lists, the status helpers, the
deck, the info lines, the confirm box), so most of their frame needs call sites and state, not
new nodes; what is new is small (the confirm dim, the merge page, the bless page). Their
coverage is the weak point: no case shows a store's sub-page today.

In scope, in this order:
- the frame every store shares: Building.draw (src/store/Building.gd:144: setColor(1), size 22,
  setAlphaFunc(.02), black text), Building.drawStandard (:131: the store's background, the
  keeper's dialog (a phase 3 node), the keeper (drawCenteredImage, y 205; the Church 105), the
  menu pieces with the store's mask: drawMenuBackground :125, AbstractPage.drawMenuBackgroundStatic),
  the title line, the root list, the tutorials (phase 3 nodes) and the fade (node);
- the confirm boxes: AbstractStore.drawConfirmDialog (src/store/AbstractStore.gd:96: the dim
  fadeOldSchool(.5), setColor(1), piece 14 or 3, the texts, the price right-aligned to 630, the
  Yes/No list) and WeaponStore.drawConfirmSellDialog (src/store/WeaponStore.gd:220);
- WeaponStore.draw3D (:192): the equipment lists (price and "down"; the sell lists' bounding
  boxes), the parent list beside them, the status and the item (EquipPage.drawStatus,
  drawEquip: the menu's EquipStatus and EquipItem), drawInfo (:242: Equipped, Total, Gold);
- CardStore.draw3D (src/store/CardStore.gd:254): the buy page (drawBuy :302: Deck.drawDeck with
  gold and large cards, the card info at −23 (node), drawInfo :315, its scroll bar over two
  lines), the merge page (drawMerge :279: pieces 13 and 12, the deck with the merge map: the
  numbers over their shadows in bold, the scroll bar, the merge preview: two cards at size 1.0,
  the second at the next level, "x 5 merges to" at size 40), the confirms;
- Inn.draw3D (src/store/Inn.gd:205): the title, StartPage.drawInfo, the price list, the rest
  confirm, the prize message (Dialog.drawGiftStatic: phase 3's nodes), the trade list ("Sell
  Map", a bounding box);
- Church.draw3D (src/store/Church.gd:319): the save list with the dates under each slot
  (SaveSlots.draw_dates_under: the menu's SlotDates), the bless page (pieces 6, 5 and 3, "Cost"
  at 30 and each character's cost at 26, LevelUpBar.drawStatic per character
  (src/battle/bars/LevelUpBar.gd:35: parts of images, drawImage with a percent and with a
  range), the bless hands (Church.drawHand :382: dimmed, or drawn twice: white, then the
  hand's colour at .3), HelpText.drawTopLayer (src/menu/tutorial/HelpText.gd:15: Row.drawRows,
  whose twin Row.place_rows exists since phase 3), "Total cost", the bless list at size 26,
  the copy of the info lines, the help line (drawHelp :392)), the tutorials.

Not in scope: the menu (done), the mini-games and the riddles (next part), the battles, the
Cheater's lists (dev only), Door (draws nothing), CardStore.drawMergedCard (never called: plan
Appendix), the Church's "Resurrect" branch (no menu entry: plan Appendix).

Read first:
- docs/MODERNIZATION_PLAN.md:
  * 9.2: the stores entry (their draws, state changes, shared parts, coverage, and "Prepared by
    the menu": what is built and how a store shows each node, what is left, the cases needed),
    "Results of the menu" (facts, the theme role lookup, the automap's Zoom, the memory
    incident), the menu list variants;
  * 2.4's stores row, 8 to 8.4 (phase 3: the UI conventions, the overlays, the fades), 9.1;
  * 12 (the risks, especially: pooled nodes keep their textures, Godot's transforms, a
    Control's culling rect, theme lookups that cannot fail, shared legacy helpers, memory
    during recordings), 13 and 14, and the Appendix;
- docs/ARCHITECTURE.md, all of it. Section 12 has the UI nodes, BaselineLabel, LabelList,
  show_ui, the Fade node and the twins; section 14 where a whole 2D mode's nodes live, the
  menu's nodes and twins, MenuList's variants as built (the price variant is built but no case
  has shown it), and "The stores": how each store is meant to show the shared nodes;
- docs/CONVERTING_UI.md, section 5 above all (whole 2D modes, and what the menu added) and the
  coverage probe;
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh, and how to record a parity
  set from a copy of the project;
- docs/PORTING.md: the rules for legacy files you touch;
- docs/port_notes/cards-store.md.

State:
- The menu's rollout is committed: scenes/ui/MenuBackground, MenuTitle, MenuInfo,
  MenuThumbnail, HelpLine, MenuText, MenuBox, PageScrollBar, StatusLine, EquipStatus,
  EquipItem, DeckView, CardView, Automap, AutomapFloor, ImageList, HelpLineCapture; MenuList
  with every variant (MenuNode.place_children, show_children_freely); the twins in
  AbstractPage, StartPage, StatusPage, EquipPage, Deck, AbstractCard, MenuScrollBar, SaveSlots,
  LabyrinthMap; Graphics.place_image, place_centered_image; MenuText.role; --legacy=menu_frame,
  menu_list, menu_text, status, deck, automap; the console's give; the menu_* cases. If git
  status shows its files uncommitted, stop and tell me.
- The stores still draw everything through Graphics except phase 3's nodes (the keeper's
  dialog, the card info, the tutorials, the Inn's prize message, the fade). Their call sites
  of the shared helpers are legacy on purpose: MenuNode.draw*, EquipPage.drawStatus and
  drawEquip, Deck.drawDeck, MenuScrollBar.draw, StartPage.drawInfo, drawMenuBackgroundStatic,
  SaveSlots.draw_dates_under. Their twins exist; switch the stores' call sites.
- The stores draw nothing in 3D (their cards are 2D images) and open no menu (no thumbnail).
- Coverage by the probe (plan 9.2): 50 shots in 6 cases (stores, dialog_card_store,
  dialog_store_fade, tutorial_store, the Zazo night Inns), every list a shot shows a store's
  root menu (the Inn's with its prices). The cases enter the stores through the debug
  console's cheater (tools/autoplay/stores.txt) or a village's building door.
- Known gaps in what is built, for you to fill: AbstractCard.place_at draws the card's own
  level (the merge preview draws level + 1); place_image covers whole images (LevelUpBar draws
  parts: GameTexture.drawPart's percent and drawPartRange's range); MenuHand.place_hand covers
  the dim, not the Church's hand drawn twice in two colours; Graphics.show_fade shows its Fade
  node on Transition, but a store's confirm dim comes before the box and its list (UI nodes):
  the levels only rise in a frame, so the dim needs a Fade node on the UI layer.
- Left open, not part of this task:
  * the riddle fade's port bug (plan Appendix; fix it before the mini-games);
  * the dungeons' 1/255 (plan 7.8, 8.3), the minimap on the 3D bridge;
  * the closings of phases 1 to 4.1;
  * the quirks in tickets/triage.md (W1 to W4, R1).
- Do not run tools/import/vil_to_scene.sh --all. It rewrites three village scenes that the
  editor saved by hand in 4b74ade3 (plan 12).
- Record goldens on the commit you start from. m1gold in tools/parity/out was recorded on the
  menu's unconverted code with the menu's cases.
  * A full run (407 cases and bridge_test, --jobs=8) takes about 15 minutes.
  * The machine has 16 GB of memory, and an 8-job recording leaves about 3 GB. Run nothing
    beside a recording: no windowed run, and not even a headless `parity.sh compare` (in the
    menu's session one ran the machine out: four runs crashed in AutoPlay's get_image, four
    logged WebP decode errors with identical shots). Compare each case's error lines, not only
    the shots: a game pad or audio device event during a run adds WASAPI or HIDAPI lines (and
    changes that run's exit leak counts); those are not differences of the code.
  * With more parallel jobs some runs fail to start (exit 127, an empty log). Re-record those
    cases.
  * Record from a copy of the project (HANDOFF) when you want to edit code meanwhile.
- In seeded runs an unseeded JRandom takes J.nextSeed(). A new generator seeded from that
  sequence shifts every later JRandom against the goldens. Seed anything new from a hash of
  the seed, as Main does.
- --seed runs read no game pad and advance a game clock by one fixed step per frame. Seeded
  runs read only the shipped saves and write to user://saves_deterministic/, which is emptied
  at start; a slot saved during the run is dated by the game clock from 1 Jan 2000, so the
  Church's save list can be shot. Measure frame rates in normal runs.
- A shot shows the frame before it (AutoPlay reads the viewport after the frame's drawing).
- Do not type while a recording runs: a new run's window takes the focus.
- If the Godot editor is open on the project, it imports new files and generates .uid files.
  Close it while recording.
- If I change one of your files while you work, keep my change and tell me.
- Start from a clean, committed tree. This prompt file doesn't count.

Decisions (plan section 13):
- Step B (presentation) only. The legacy objects stay in charge of state, input and timing:
  the stores (Building, AbstractStore and the four stores), MenuNode (the cursor), GameAction
  (the key repeat), the Church's hands and bless animation, the Inn's prize. The nodes draw
  what the legacy drawing would have drawn in that frame.
- Where the nodes live is decided (ARCHITECTURE section 14): UI nodes in the frame's order
  (Graphics.show_ui). A drawing between two parts that is still legacy, or a phase 3 node (the
  keeper's dialog, the card info, the tutorials, the prize message), needs its own slot.
- Decision 3 (step C) is not made: no Tweens or Timers, no signals or InputMap replacing the
  polled input. The InputMap wrapper and the Game autoload are phase 4.3.
- Decision 5, text formats: not made. The .help files stay; no BBCode converter.
- Decision 6 (time base) is not needed: the bless hands' animation stays legacy.
- Decision 8, the UI look: not made. Keep the legacy images, fonts, sizes, positions, colours
  and alphas. BaselineLabel.oversampling stays 1.
- Decision 4, resolution: keep the 1024x768 virtual screen. The nodes use the legacy screen
  coordinates.
- Make no other open decision.

Deliverables, in this order. Do (0) and (1) before converting anything, so that the goldens are
recorded on unconverted code.

0. Baseline
   - tools/check.sh reports 0 failed.
   - Record goldens of all existing cases and bridge_test.
   - Re-run the menu's check on top of whatever landed since: --legacy=title,game_over,
     menu_list,menu_frame,menu_text,status,deck,automap vs. the goldens, on every case:
     identical at tolerance 0.

1. Facts and coverage, then goldens
   - Facts to verify before relying on them (plan 9.2's stores entry has a first list; check it
     against the code):
     * What each store draws, in order, in each of its sub-states (the menu modes of each
       store: root, buy, sell, merge, confirms, tutorial; the Church's save and bless modes;
       the Inn's rest, prize and trade), and what Building.draw and GameCore draw around it:
       its state resets (colour, size, alpha test, text colour: not the blending or the bold
       font), the fade (does a store fade in and out on entry and exit, and with which
       image?), "Paused" (is a store pausable?), "game pad lost". Where the order shows: what
       overlaps (the keeper over the background and under the pieces, the lists' hands over
       the pieces, the dim over everything before it, the box and its list over the dim, the
       card info over the deck, the bless page's rows, bars and hands).
     * What the draws change besides drawing: the Church's totalCost (summed in its draw, read
       by Cross on "Done") and its hands' positions (set in the draw); the cursor fix-up (with
       its sound; an empty sell list); the scroll bars' lazy init and loadIdentity; drawDeck's
       bold font and text colour; AbstractStore.drawConfirmDialog's fadeOldSchool(.5) (the fade
       mode's image: black, white or an image) and setColor(1); LevelUpBar.drawStatic's
       setColor calls; the merge preview's setFontSize(40) and back; drawStringSetSize's sizes;
       the Inn's prize (its currentLoot, the gift message). Twins must keep these, in their
       order.
     * The images drawn in parts: LevelUpBar.drawStatic draws three images of a bar
       (drawImage(name, x, y, 200, 20, scale, percent) and the range form): GameTexture.drawPart
       and drawPartRange, their rects and texture coordinates; find a node that draws the same
       pixels (a TextureRect with an AtlasTexture region, a draw_texture_rect_region, or the
       legacy quad) and check it.
     * The text: which positions are measured (calcAlignRight for the prices at 985 and the
       confirm's at 630, the card store's numbers right-aligned in bold), the sizes (22, 20
       for prices, 26 and 30 on the bless page, 40 for the merge preview, 26 and 28 for the
       numbers), the bold font.
     * Which variant of MenuNode.draw each store's list uses, call site by call site (plan
       9.2's list), and whether MenuList's price variant, built in the menu's part but never
       shown, draws what drawWithPrice draws.
     * Which parts the mini-games draw too (MenuHand, the button icons, a fadeOldSchool dim):
       build those so the mini-games can reuse them, and write down how.
   - Coverage: run the coverage probe of CONVERTING_UI.md over every case: temporary prints, in
     a copy of the project, in Building.draw (the store, its mode and sub-state), each store's
     draw3D (what it draws: the lists by name, the decks, the confirm kind, the bless mode), in
     MenuNode.draw (its flags, name, cursor, the bounding box's offset), ScrollBar.draw,
     Deck.drawDeck (gold, large, map), LevelUpBar.drawStatic, the Church's drawHand, the confirm
     boxes and AutoPlay's shot. Then write cases for what no shot shows, at least:
     * the Weapon Store: the buy list scrolled with its prices and the comparison (red and
       green), the sell list in its bounding box scrolled, the buy confirm, "You can't afford
       that!", the sell confirm (Keep/Sell), "No one can equip that.", both lists' hands;
     * the Card Store: the buy page past two lines (its scroll bar) with grey cards it cannot
       afford, the card info, a buy confirm; the merge page with and without the preview (a
       card at level 3), its numbers, "Can't merge that card." and a merge confirm;
     * the Inn: the rest confirm, the prize message and its card, the trade list (in its
       bounding box);
     * the Church: the save list before and after a save (the game-clock dates), the bless page
       with the hands moved (both hands, one dimmed, the bless animation), its costs, rows and
       help line, its tutorials;
     * each store's fade in and out, and "Paused" over a store if it is pausable.
     For a state no seeded route reaches, add a documented dev-only way, preferably a debug
     console command AutoPlay's console runs (the console's give gives items and equipment;
     extend it for gold or cards if a case needs them; --status sets a Database status, e.g. a
     place's "blessing"). Plan the routes in headless probe runs.
   - Record goldens of all cases, old and new. Record the new cases a second time and show the
     self-diff is 0. Never edit game code while a recording runs from the project itself.

2. The shared parts (step B)
   - The store's frame: the background, the keeper and the pieces with the store's mask
     (MenuBackground, place_menu_background_static), the title line (MenuTitle), the info lines
     (MenuInfo with the store's own lines), the help line (HelpLine), the lists (MenuList with
     the price variant), the confirm dim (a Fade node on UI) and box (MenuBox) with its list.
   - Twins at the point where each part was drawn, with every state change of deliverable 1.
     Nodes only where the menu's do not cover a part (the bars' image parts, the Church's
     two-colour hands, the merge preview's next level); theme roles per size where text is
     added (look roles up with MenuText.role: Theme.has_font_size is true for any type).
   - Parity after this step on the cases that show a store (see 4).

3. The stores (step B), in the order of the scope list
   - For each store: its nodes in the place ARCHITECTURE section 14 gives (UI nodes in the
     frame's order; the dialog, the card info, the tutorials and the prize message keep their
     slots), the twins, the state changes. The nodes keep no reference to a mode or a legacy
     object.
   - Flags: use the menu's flags for the parts the stores share with it (menu_frame for the
     frame, the info, the title and the help line; menu_list for the lists; status for the
     Weapon Store's status and item; deck for the decks, their scroll bars and the merge
     preview; menu_text for the boxes' texts and the dates) and add one --legacy=<name> per new
     kind of part (for example store_frame, confirm, bless), in ARCHITECTURE section 7's table.
     With all of them on, the frame is drawn exactly as before.
   - Parity after each store on its cases (see 4). If the session ends before every store is
     done, stop after a store whose parity holds and report where you stopped.

4. Parity
   - ab "--legacy=<the flags the stores use>" "" on the cases that show a store (by the probe):
     identical at tolerance 0; each flag alone on its parts' cases too.
   - Golden vs. after on all other cases: identical, logs and error lines too.
   - With every flag on (this task's, the menu's and the pilot's), the run equals the golden.
   - The bridge test must still pass.
   - Choose any tolerance deliberately, and explain every remaining difference with its diff
     image. Fix what fails in the bridge code (the nodes, the twins), not in legacy logic.
   - Measure the frame rate in normal runs (no --seed), legacy vs. nodes, capped and uncapped:
     the Weapon Store's buy list with the comparison, the Card Store's buy page, the Church's
     bless page.

5. Prepare the mini-games (do not convert them)
   - Update plan 9.2's mini-games entry: what the menu and this task built that they reuse (the
     hand, the button icons, the dim, the box), how a riddle shows each, what is left for them
     (the tiles and markers, the riddles' texts, Cesadur's letters and two hands, the riddle's
     image and fade; the fade's port bug first, as its own change with new goldens), the cases
     they need first, and the sessions it takes.

6. Docs
   - ARCHITECTURE.md: the stores' nodes and frames, the new parts, the flags in section 7.
   - docs/CONVERTING_UI.md: what the stores added to section 5.
   - HANDOFF.md: the new state.
   - Plan sections 9.2 (the results), 12, 13 and 14. Where your findings contradict the plan,
     update it and tell me.

Constraints:
- Convert only the stores and the parts listed above. No step C: no Tweens or Timers, no
  signals or InputMap replacing polled logic. Gameplay, input and timing stay unchanged in
  normal runs.
- No new art and no restyling: decision 8 waits.
- Do not change legacy game logic or content to make parity pass; content quirks stay. A port
  bug that the new coverage finds may be fixed before the goldens are recorded, as its own
  listed change. A port bug is a place where the GDScript does what the Java does not (the
  Java is in _java_reference/src/).
- The shared helpers' legacy drawing stays for their other callers (the battles, the riddles,
  the Cheater, the legacy paths of the menu's flags): switch at the stores' call sites, not
  inside the helpers.
- Dev-only flags and console commands are fine if documented. Normal play must not change.
- Legacy files follow PORTING.md (Java names, no redesign; bridge members snake_case). New
  files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the scripts under scenes/ and tools/. Run Godot
  from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the node layout of the new scenes, where each takes its place
  in each store's frame, and how the mini-games will use the shared ones;
- the facts of deliverable 1 as you found them, where they differ from this prompt or plan 9.2;
- the parity results, explaining every difference:
  * legacy vs. nodes per flag on its cases, and all flags together;
  * golden vs. after on all other cases;
  * every flag on vs. the golden;
  * the bridge test;
- what the stores still draw through legacy code, and why;
- the screenshots you checked and what each showed (contact sheets are fine);
- fps per measured page, legacy vs. nodes;
- the cases you could not reach or cover, and why;
- deliverable 5's update for the mini-games;
- anything that surprised you or that the plan got wrong.

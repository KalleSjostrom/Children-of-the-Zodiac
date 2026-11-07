Finish the rollout of phase 4.2 ("title, game over, mini-games, stores, menu") of
docs/MODERNIZATION_PLAN.md in this Godot 4.7 project: convert the mini-games (the riddles of
the dungeons) through step B (presentation). This is the last of the rollout's three parts
(plan 9.2: the menu, the stores, the mini-games). The menu and the stores are done; they built
what the riddles draw besides their tiles and texts.

Why now: the riddles are the last legacy 2D of a dungeon frame besides the battles (phase 4.4)
and the minimap (the 3D bridge's, plan 8.4). They reuse the stores' dim (the Fade node on UI),
the box (MenuBox), the hands (MenuHand.place_hand_image) and the help line (HelpLine), so what
is new is small: the tiles and markers, the riddles' texts, the riddle's image. Their coverage
is the weak point: no case shows a riddle fading in or out, solved, or Cesadur's dimmed hand.

In scope, in this order:
- First, as its own change with its own goldens: the riddle fade's port bug (plan Appendix:
  RiddleGame.fade steps by .1 in a 64-bit float, so the fade-in stops at 1.1 after 11 updates
  where the Java's 32-bit float stops at 1.0000001 after 10). Fix it the Java's way and record
  new goldens before any conversion; it changes the dungeon_riddle_* shots, so explain every
  difference against the old goldens.
- RiddleGame.drawTopLayer (src/miniGames/RiddleGame.gd: the dim fadeOldSchool(1 − fade × the
  image's alpha), setColor(1, 1, 1, fade), the riddle's image: RiddleLoader's name, x, y, scale);
- the puzzles: Puzzle and RubicsPuzzle, RubicsPuzzle19 (Tile.draw: the tiles at xs/ys, the
  marker NxNsingle.png, horizontal/vertical.png);
- AegisRiddle and GriveraRiddle (their centred texts at size 28, black: Aegis at alpha 1,
  Grivera at the riddle's fade; startText(alpha, 0, 28), drawMultiCenteredText);
- HateRiddle (its digits at size 36 through startText(fade, −1), its code centred, its hand);
- CesadurRiddle (its letters and rows, drawMultiString at the labyrinth's fade value and the
  size earlier drawing left; its two hands, one dimmed; its help: button icons and four
  labels).

Not in scope: RotatePuzzle (no map uses it: plan Appendix); the labyrinth around the riddle
(phase 2's scene, phase 3's dialog and fade, the minimap on the 3D bridge); the battles;
closing phase 4.2 (deleting its legacy paths and flags is its own step afterwards).

Read first:
- docs/MODERNIZATION_PLAN.md:
  * 9.2: the mini-games entry (their draws, state changes, shared parts, coverage, and
    "Prepared by the menu and the stores": what is built and how a riddle shows each node,
    what is left), "Results of the stores" (facts, the dim on UI, LevelBar's image parts, the
    disk and memory notes), "Results of the menu";
  * 8 to 8.4 (phase 3: the overlays, the fades), the labyrinth's frame in 7.5 and 8.3 (the
    mission display, the dialog's slot, the top layer, the fade);
  * 12 (the risks: pooled nodes, Godot's transforms, a Control's culling rect, theme lookups,
    shared legacy helpers, memory and disk during recordings, zero-sized atlas regions), 13,
    14 and the Appendix (the fade's port bug).
- docs/ARCHITECTURE.md, all of it; section 14's "The stores" above all (the dim on UI,
  show_box, show_pieces, place_hand_image), section 12 (UI nodes in the frame's order) and
  section 10 (a dungeon frame: the scene under World, the legacy 2D after it).
- docs/CONVERTING_UI.md, section 5 (whole 2D modes, what the menu and the stores added) and
  the coverage probe.
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh, how to record from a copy of
  the project.
- docs/PORTING.md: the rules for legacy files you touch.

State:
- The stores' part is committed: scenes/ui/LevelBar, BlessPage, BlessRow; the twins in
  Building, AbstractStore, the four stores, AbstractPage.show_pieces, StartPage.show_info,
  MenuHand.place_hand_image and place_hand_with_color, LevelUpBar.place_static,
  HelpText.place_top_layer, AbstractCard.place_at's level, Graphics.place_image_part and
  show_fade's layer; --legacy=dim and bless; the console's gold and give card; the store_*
  cases. If git status shows the stores' files uncommitted, stop and tell me.
- Phases 1 to 4.1 are closed; the flags left are phase 4.2's (title, game_over, menu_list,
  menu_frame, menu_text, status, deck, automap, dim, bless) and the battle effects'
  (battle_effects, effect_waits).
- The riddles draw everything through Graphics. A riddle is the labyrinth's labDrawable
  (Labyrinth.enterRiddle; push hides the minimap and the mission); its drawTopLayer runs
  after the labyrinth's dialog (a phase 3 node on UI) and before the labyrinth's topLayer
  items and its fade (Transition); it ends when its fade-out reaches 0 (exitRiddle).
- Coverage by the probe (plan 9.2): 36 shots in the 9 dungeon_riddle_* cases, every kind
  shown; none fading in or out, solved, with Cesadur's dimmed hand or letter pool, or Hate's
  code entered.
- Left open, not part of this task: the minimap on the 3D bridge; the quirks in
  tickets/triage.md (W1 to W4, R1: Silent Ruin's 4 x 4 magic square counts as solved on the
  first move, a content quirk that stays); the stores' side findings (plan Appendix: selling
  the last entry of a Weapon Store sell list).
- The look prototypes (res://proto/, --look, --village; docs/LOOK_PROTOTYPES_PLAN.md) are dev
  only. Leave them alone; tools/check.sh compiles res://proto too, and other sessions may be
  editing it: if a failure there is not yours, tell me.
- Record goldens on the commit you start from. The only set in tools/parity/out is
  st2node (the stores' final node run: 417 cases, 7,817 shots, identical to the stores'
  golden, which was deleted with every older set): compare your baseline with st2node
  (shots, logs, error and leak lines); it should be identical. out/_work holds the stores'
  helper scripts (errcounts.py: per-case error and leak line counts of two sets; flags.sh,
  fps.sh as examples).
  * Make project copies under tools/parity/out/_<name> with robocopy (HANDOFF), never in
    the session scratchpad: Windows' temp cleanup deleted the old files of two scratchpad
    copies while the disk was full (plan 12).
  * A full run (417 cases) takes about 20 minutes with --jobs=5. Check the free memory
    first: with 7 GB free at idle an 8-job run crashed (exit 139 in AutoPlay's get_image);
    run nothing beside a recording, not even a headless compare. Compare each case's error
    lines (SCRIPT ERROR, ERROR, the exit leak lines, WASAPI/HIDAPI device events), not only
    the shots. Only the effects_* cases print an exit leak report (7 objects).
  * The disk: a full set is about 5.5 GB (the disk was 97% full during the stores' part,
    before the old sets were deleted). Delete your intermediate sets once compared, and
    at the end keep only what the next step needs (your final node run).
  * With more parallel jobs some runs fail to start (exit 127, an empty log). Re-record those.
- In seeded runs an unseeded JRandom takes J.nextSeed(); seed anything new from a hash of the
  seed, as Main does. --seed runs read no game pad and advance a game clock by one fixed step
  per frame (the riddle's fade steps per update: deterministic). Measure frame rates in
  normal runs.
- A shot shows the frame before it. Do not type while a recording runs. If the Godot editor
  is open on the project, close it while recording. If I change one of your files while you
  work, keep my change and tell me. Start from a clean, committed tree; this prompt file
  doesn't count.

Decisions (plan section 13):
- Step B only. The legacy riddles stay in charge of state, input and timing (the fade, the
  cursors, the tiles' moves, Cesadur's word, Hate's code, the solved status).
- Where the nodes live is decided (ARCHITECTURE section 14): UI nodes in the frame's order
  (Graphics.show_ui), after the labyrinth's dialog.
- Decision 3 (step C) is not made: no Tweens or Timers, no signals or InputMap.
- Decision 6 is not needed: the riddle's fade stays legacy (per update).
- Decision 8, the UI look: not made. Keep the legacy images, fonts, sizes, positions, colours
  and alphas. BaselineLabel.oversampling stays 1.
- Decision 4: keep the 1024x768 virtual screen and the legacy screen coordinates.
- Make no other open decision.

Deliverables, in this order. Do (0) to (2) before converting anything.

0. Baseline: tools/check.sh reports 0 failed; record goldens of all existing cases; re-run
   every phase 4.2 flag (--legacy=title,game_over,menu_list,menu_frame,menu_text,status,deck,
   automap,dim,bless) vs. the goldens on every case: identical at tolerance 0.

1. The fade's port bug (its own listed change): fix RiddleGame's fade as the Java's 32-bit
   float steps it; record the dungeon_riddle_* cases and compare with (0): explain each
   difference (the dim's alpha, the image's, Grivera's text, one update less of fade-out);
   every other case identical. Then record the goldens again on top of it.

2. Facts and coverage, then goldens
   - Facts to verify (plan 9.2's mini-games entry has a first list): what each riddle kind
     draws, in order, in each state (fading in, shown, the cursor or hand moved, solved,
     fading out), what the labyrinth draws around it (the dialog's slot before, the topLayer
     items and the fade after; is the riddle pausable? "game pad lost"?), what overlaps;
     the state its draws change (none of the game's by the plan: check), the GL and text
     state left behind (the colour (1, 1, 1, fade), sizes 28/36, black text) that the
     labyrinth's next drawing inherits; which texts are measured (calcAlignCenter at 512) and
     at which alpha (startText's: 1, the riddle's fade, the labyrinth's fade value).
   - Coverage: the probe over every case (prints in RiddleGame.drawTopLayer with the kind and
     fade, each kind's drawTopLayer, Tile.draw, the hands, AutoPlay's shot). Cases for what no
     shot shows, at least: each kind fading in and out; a puzzle solved (its door's status);
     Hate's code entered right and wrong; Cesadur's letter pool, its word and its dimmed hand;
     Aegis's and Grivera's pages turned; "Paused" over a riddle if it is pausable. Dev-only
     ways where no seeded route reaches a state (the console; --start-node puts the party in
     front of a riddle).
   - Record goldens of all cases, old and new; record the new cases twice: self-diff 0.

3. The riddles (step B), in the order of the scope list: the dim as a Fade node on UI
   (Graphics.show_fade(value, Graphics.UI_LAYER)), the image (a placed image: show_box with a
   scale, or a node), the tiles and markers (ImageList through place_image), the texts
   (MenuText lines with their alignment and alpha), the hands (place_hand_image), Cesadur's
   help (AbstractPage.draw_help); every state change of deliverable 2 kept in its order. The
   nodes keep no reference to a riddle or the labyrinth. Flags: dim for the backdrop (the
   same kind of part as the stores' confirm dims), menu_frame for the help line, and one new
   --legacy=riddle for the rest, in ARCHITECTURE section 7's table; with all of them on the
   frame is drawn exactly as before.

4. Parity
   - ab "--legacy=dim,riddle,menu_frame" "" on the cases that show a riddle (by the probe):
     identical at tolerance 0; each flag alone on its cases too.
   - Golden vs. after on all other cases: identical, logs and error lines too.
   - With every phase 4.2 flag on, the run equals the golden.
   - No new exit leak report.
   - Choose any tolerance deliberately and explain every remaining difference with its diff
     image. Fix what fails in the bridge code, not in legacy logic.
   - Measure the frame rate in normal runs (no --seed), legacy vs. nodes, capped and
     uncapped: a puzzle (Puzzle), Cesadur's riddle.

5. Prepare closing phase 4.2: list what deleting its legacy paths and flags would remove
   (per flag: the legacy drawing it keeps, its callers, the shared helpers whose legacy
   drawing only the battles still call), what the battles still need of them (phase 4.4),
   and the cases that cover each part. Do not delete anything.

6. Docs: ARCHITECTURE.md (the riddles' nodes and frame, the flag), CONVERTING_UI.md (what the
   riddles added), HANDOFF.md (the new state), plan 9.2 (the results), 12, 13, 14 and the
   Appendix (the fade bug fixed). Where your findings contradict the plan, update it and tell
   me.

Constraints:
- Convert only the riddles and the parts listed above. No step C.
- No new art and no restyling: decision 8 waits.
- Do not change legacy game logic or content to make parity pass; content quirks stay. The
  fade's port bug is the one listed fix (deliverable 1); a port bug the new coverage finds
  may be fixed before the goldens, as its own listed change. A port bug is a place where the
  GDScript does what the Java does not (the Java is in _java_reference/src/).
- The shared helpers' legacy drawing stays for their other callers (the battles): switch at
  the riddles' call sites, not inside the helpers.
- Dev-only flags and console commands are fine if documented. Normal play must not change.
- Legacy files follow PORTING.md; new files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed. Run Godot from bash with < /dev/null. Screenshots need
  a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the nodes and where each takes its place in a riddle's frame;
- the fade fix and its differences, explained;
- the facts of deliverable 2 as you found them, where they differ from this prompt or plan
  9.2;
- the parity results, explaining every difference: legacy vs. nodes per flag and together;
  golden vs. after on all other cases; every flag on vs. the golden; the exit leak reports;
- what the riddles still draw through legacy code, and why;
- the screenshots you checked and what each showed (contact sheets are fine);
- fps per measured riddle, legacy vs. nodes;
- the cases you could not reach or cover, and why;
- deliverable 5's list for closing phase 4.2;
- anything that surprised you or that the plan got wrong.

Continue the rollout of phase 4.4 ("battle, cards, effects") of docs/MODERNIZATION_PLAN.md in
this Godot 4.7 project: the battle's 3D, part 3, the deck and the hand (GLDeck, AbstractDeck,
GLWeapon, GLSlot, WeaponModeIcon, GLCard, FlatObj, GLHand) and the legend's gradient, through
step B. First their facts and coverage, then the conversion. The enemy (part 1) and the info
panels with the rows' gradients (part 2) are done; the texts among the chunks (the attack name,
the deck's and the legend's lines, the attack texts) and the effects that are not particles are
later parts (plan 9.4).

Why the deck next: plan 9.4's order, confirmed by part 2. The deck's 3D follows the panels in
the floor's scene chunk up to its texts (the frame's first 2D unless the attack name shows),
the hand and the legend's gradient come after them in a SubViewport, and part 2 showed that
nodes in their batches' slots draw the same pixels, merges included.

Read first:
- docs/MODERNIZATION_PLAN.md:
  * 9.4, all of it, above all "Prepared after the pilot" (the table of the 3D parts: rows 3, 4
    and 5), "Results of the rollout, part 1" (the walls, the probe), "Results of the rollout,
    part 2" (the panels: the merge that depends on the state, the probe, the twins) and
    "Prepared after part 2" (the deck and the hand);
  * 7.5 and 7.8 (the 3D bridge), 8.3 (the minimap's node), 6.11 and 6.12 (nodes in a chunk's
    slot), 12 ("Order-dependent blending", "History in the 3D bridge", "Batches that merge only
    in some states"), 13, 14 and the Appendix;
- docs/ARCHITECTURE.md: sections 6 and 7, 10 (the dungeon scene, the 3D bridge, the walls'
  order), 11, 12 (MinimapPart), 15 (the top layer and "The battle's 3D": EnemyView, "The info
  panels": PanelQuad, show_panel_quad's merge, Graphics.place_quad, place_gradient,
  batch_mark, Utils3D.place_3d, place_3d_part);
- docs/CONVERTING_UI.md, all of it (section 2's last bullets: a 3D part as a node of its own,
  a 3D part of several batches);
- docs/HANDOFF.md: running Godot, AutoPlay, tools/check.sh, recording from a project copy (its
  check.sh first, the memory watchdog beside multi-job runs);
- docs/PORTING.md: the rules for legacy files you touch.

State:
- Phase 4.4's pilot and the rollout's parts 1 and 2 are done and committed. If git status
  shows part 2 uncommitted, stop and tell me. Start from a clean, committed tree; this prompt
  file doesn't count.
- The --legacy= flags left: battle_effects, effect_waits (ARCHITECTURE section 11),
  battle_screens, battle_flash, battle_legend, battle_enemy, battle_panels (section 15).
- tools/parity/out holds one set of yours: f2node (part 2's node run: 437 cases, 9,044 shots;
  3 script errors, the errors and 12 exit leak lines of e2node: the effects_* cases and
  battle_result). c42after is mine; leave it. Record your baseline on the commit you start
  from and compare it with f2node (shots, logs, per-case error and leak lines): it should be
  identical. Audio-device events (WASAPI lines) come and go with the machine's audio output:
  out/_work/errcounts.py counts them apart. out/_work holds the helper scripts:
  errcounts.py, battle_cases2.txt (the 36 cases that draw a battle), probe_panels_patch.py
  and probe_panels_report.py (part 2's probe: per panel batch its chunk, index, merge and
  render state, per frame the rows' and creatures' states), legacy3d_panels_patch.py (the
  "no legacy quad while the panels draw" check), fps_panels.sh and fps/ (frame rates in
  normal runs), full_runs2.sh (the full recordings, one after another).
  * Make project copies under tools/parity/out/_<name> with robocopy (HANDOFF), never in the
    session scratchpad. Run the copy's own tools/check.sh (0 failed) before you probe or
    record from it, and keep tools/parity/watchdog.ps1 running beside multi-job runs.
  * A full run (437 cases) takes about 23 minutes with 4 jobs at 6 GB free, about 30 with 3
    jobs; check the available memory first (part 2 had only 4.6 GB and used 3 jobs). Run
    nothing beside a recording, not even a headless compare.
  * A full set is about 6.3 GB; delete intermediate sets once compared and keep only your
    final run at the end. Quote paths in bash: the project's path has spaces (an unquoted
    redirect or `xargs` splits it).
- What the deck and the hand draw (plan 9.4, "Prepared after part 2"; verify every fact
  before relying on it):
  * GLDeck.draw: the weapon (GLWeapon.draw: its slide; WeaponModeIcon and each GLSlot call
    update() in their draw, so a slot's flip steps per draw; loadIdentity, translate, rotate
    about y, the front with draw3D or the back with draw3DBackside; setAlphaFunc(.5) around the
    weapon's cards, then 0), the hand's slots (transball.png per slot, save.png), the shown
    cards (the selected one raised, the pointer hand2.png under it), the saved card, the pile's
    top card, then while cards are shown the gradient (drawGradient with popPush) and the
    deck's texts (2D).
  * GLCard.draw: loadIdentity, translate, rotate; both sides while turning or on the pile
    (BOTH_SIDES), else the front: the picture (gray when the card fits no free slot) and its
    level's balls (one to three quads of one texture), the back of CARD_BACK. The cards move
    and turn in Battle's update (updatePos), not in the draw.
  * GLHand.draw: hand1.png at the target, turned by -90 degrees for a party member.
  * Legend.draw: a gradient (drawGradient with popPush) and six lines twice (2D).
  * The first frame's initDraw draws stray quads (GLSlot.initDraw: both sides of each slot)
    and sets the alpha test to 0 (AbstractDeck.initDraw).
  * Chunks: on a floor the deck's 3D in the scene chunk after the panels, up to its texts;
    the hand and the legend's gradient in a SubViewport after them; all of it in SubViewports
    while the attack name shows and in boss areas.
- Coverage known (plan 9.4): the slots flipped and back frame by frame, discards, the deck
  emptied and shuffled (battle_panels), cards into slots (the effects_* cases), the deck, the
  pointer and the hand on an enemy in every battle shot, three enemies (battle_rows). Not
  probed yet: the cards flying into the slots and turning frame by frame, the saved card with
  its pointer, gray cards, cards of levels 2 and 3, a pile of 10 to 19 cards and an empty
  pile, the deck and the weapon sliding frame by frame, the hand on a party member (support)
  and on each of three enemies, the hand hidden.
- --seed runs read no game pad and advance a game clock by one fixed step per frame. In
  seeded runs an unseeded JRandom takes J.nextSeed(): seed anything new from a hash of the
  seed. Measure frame rates in normal runs.
- Do not type while a recording runs. If the Godot editor is open on the project, close it
  while recording. If I change one of your files while you work, keep my change and tell me.

Decisions (plan section 13):
- Step B only. The legacy objects keep the state, the input and the timing (the slots'
  update in the draw, the cards' moves and turns in the update, the slides). No Tweens,
  Timers, signals or InputMap.
- Decision 8 (the look) is not made, and decision 2's exact look stays: the textures, the
  colours, the gradients, the GL state as GLBackend draws them.
- The place: nodes in the chunk and slot of the batches they replace (Graphics.show_node, as
  EnemyView and PanelQuad), not Battle.tscn under the camera rig yet. One node per legacy
  batch, never one instance with a surface per batch; a batch of several quads (a card's
  balls, merges that depend on the state) is one node with all of them, as part 2's
  show_panel_quad keeps them (make it a shared helper if the deck needs it).
- The party's red screen stays as part 2 left it unless I decide otherwise.
- A tolerance is my decision. Since the walls are drawn in a fixed order no part needed one;
  a difference now is the change's. Explain it with diff images and ask me before accepting
  any.
- Make no other open decision. If you find a place that keeps parity and is closer to the
  plan's Battle.tscn, propose it before building it.

Deliverables, in this order. Do (0) and (1) before converting anything.

0. Baseline: tools/check.sh reports 0 failed; record all cases; compare with f2node.

1. Facts and coverage of the deck, the hand and the legend's gradient, then goldens
   - Verify the facts above and add what they miss: per batch what it draws, its render state
     (texture, blending, alpha test, depth test and write, culling, fog, colour), its chunk
     and index, what merges into it (a card's balls; the hand's slots; slots of one image;
     across cards and with the panels before and the texts after), the state each draw changes
     (the slots' rotation, the alpha test) and the state the deck starts from and leaves; the
     gradients' batches; initDraw's stray quads.
   - Coverage: part 2's probe (probe_panels_patch.py, extended to the deck's, the hand's and
     the legend's batches and states) over the battle cases, per-frame checks. Then cases for
     what no shot shows (the list above). Use the console's casts, heal, kill, give, statuses,
     or a dev-only console command for states no seeded route reaches; document any new one.
   - Record goldens of all cases, old and new; record the new cases a second time
     (identical).

2. The deck, the hand and the legend's gradient (step B)
   - Twins in their draws: the same state changes in the same order (the slots' update, the
     matrix calls, the colours, the binds and texture coordinates, the alpha test), and nodes
     in scenes/battle/ (a script beside each, or part 2's PanelQuad where a batch is plain
     quads) shown through Graphics.show_node in the chunk and slot of each batch they replace,
     with GLBackend's material for the render state.
   - Flags: --legacy=battle_deck (the deck and the hand) and --legacy=battle_legend_back (the
     legend's gradient), in ARCHITECTURE section 7. With them the frame is drawn exactly as
     before.
   - Parity: golden vs. after on every case (identical at tolerance 0; logs, per-case error
     and leak lines); each flag vs. after and vs. the golden on the battle cases; all phase
     4.4 flags (battle_deck, battle_legend_back, battle_panels, battle_enemy, battle_screens,
     battle_flash, battle_legend) vs. the golden on every case, and with
     --legacy=battle_effects added on the battle cases (vs. a golden with it). A run with
     prints in Graphics' 3D emission while the deck, the hand and the legend's gradient draw
     shows none of their quads left with the flags off. Explain every difference with its
     diff image; fix the bridge code, not legacy logic.
   - The frame rate in normal runs, legacy vs. node, capped and uncapped: a battle on a floor
     and in a boss area.

3. Docs: ARCHITECTURE (section 6's bridge members, 7's flags, 15: the deck's and the hand's
   nodes, their chunks and slots), CONVERTING_UI (what two-sided, rotating parts add), plan
   9.4 (the results, as parts 1 and 2), 12, 13, 14, HANDOFF (the new state).

4. Prepare the next part (the texts among the chunks, plan 9.4's order, or another if the
   deck's results say so): what each text draws and where (the attack name, the deck's and
   the legend's lines, the attack texts: GLBackend's 2D between the 3D chunks), what a UI node
   or a Label3D there would change in the chunks (a UI node before a 3D chunk turns it into a
   SubViewport at its layer), the state they change, the coverage, the cases still needed,
   and whether Battle.tscn under the camera rig can come with them.

Constraints:
- Convert only the deck, the hand and the legend's gradient. No step C. Gameplay, input and
  timing unchanged.
- Do not change legacy game logic or content; a port bug found on the way may be fixed as its
  own listed change with new goldens (the Java is in _java_reference/src/).
- Dev-only flags and console commands are fine if documented. Normal play must not change.
- Legacy files follow PORTING.md; new files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed. Run Godot from bash with < /dev/null. Screenshots need
  a window (not --headless). Ad-hoc runs end themselves (AutoPlay quit, --quit-after-ms).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the nodes and their places in the frame and the chunks;
- the facts of deliverable 1 where they differ from this prompt or plan 9.4;
- the parity results, every difference explained (golden vs. after, legacy vs. node, every
  flag on vs. the golden, the new cases twice);
- the screenshots you checked (contact sheets are fine); fps legacy vs. node;
- the cases you could not reach, and why;
- deliverable 4's list and proposed next step;
- anything that surprised you or that the plan got wrong.

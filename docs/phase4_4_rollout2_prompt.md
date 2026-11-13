Continue the rollout of phase 4.4 ("battle, cards, effects") of docs/MODERNIZATION_PLAN.md in
this Godot 4.7 project: the battle's 3D, part 2, the info panels (CharacterRow, EnemyRow and
their creatures: CreatureRow, Creature3D, Character3D, Enemy3D, BattleProgressBar) through
step B. First their facts and coverage, then the conversion. The enemy is done (part 1); the
deck and the hand, the legend's and the rows' gradients if you leave them, the texts among
the chunks and the effects that are not particles are later parts (plan 9.4).

Why the panels next: plan 9.4's order, confirmed by part 1. They follow the enemy in the
floor's scene chunk (in a SubViewport while the attack name shows, and in boss areas), and
part 1 removed what made such a change risky: the floor's walls are drawn in a fixed order
now, so a node in a batch slot moves nothing else on the screen.

Read first:
- docs/MODERNIZATION_PLAN.md:
  * 9.4, all of it, above all "Prepared after the pilot" (the table of the 3D parts: row 2
    and 2b), "Results of the rollout, part 1" (the facts, the 1/255 and the walls, the
    probe) and "Prepared after part 1" (the panels);
  * 7.5 and 7.8 (the 3D bridge), 8.3 (the minimap's node), 6.11 and 6.12 (nodes in a
    chunk's slot), 12 ("Order-dependent blending", "History in the 3D bridge"), 13, 14 and
    the Appendix;
- docs/ARCHITECTURE.md: sections 6 and 7, 10 (the dungeon scene, the 3D bridge, the walls'
  order: `DungeonFloor.WALL_SORTING_STEP`), 11, 12 (MinimapPart), 15 (the top layer and
  "The battle's 3D": EnemyView, the enemy's batch and slot);
- docs/CONVERTING_UI.md, all of it (section 2's last bullets: 3D in a 3D chunk, a 3D part
  as a node of its own in its chunk);
- docs/HANDOFF.md: running Godot, AutoPlay, tools/check.sh, recording from a project copy
  (its check.sh first, the memory watchdog beside multi-job runs);
- docs/PORTING.md: the rules for legacy files you touch.

State:
- Phase 4.4's pilot and the rollout's part 1 are done and committed. If git status shows
  part 1 uncommitted, stop and tell me. Start from a clean, committed tree; this prompt
  file doesn't count.
- The --legacy= flags left: battle_effects, effect_waits (ARCHITECTURE section 11),
  battle_screens, battle_flash, battle_legend, battle_enemy (section 15).
- tools/parity/out holds one set of yours: e2node (part 1's node run: 435 cases, 8,918
  shots; 3 script errors, 2,421 errors and 12 exit leak lines: the effects_* cases and
  battle_result). c42after is mine; leave it. Record your baseline on the commit you
  start from and compare it with e2node (shots, logs, per-case error and leak lines): it
  should be identical. out/_work holds the helper scripts: errcounts.py, battle_cases.txt
  (the 34 cases that draw a battle), probe_3d_patch.py and probe_3d_report.py (part 1's
  probe of the battle's 3D: each part's batches with chunk, index and merges, the enemy's
  render state, per-frame states and coincidences), legacy3d_enemy_patch.py (the "no
  legacy quad while the enemy draws" check), exp_patch.py (part 1's 1/255 experiments),
  fps_enemy.sh and fps/ (frame rates in normal runs), full_runs.sh and full_compare.sh
  (the full recordings and compares, one after another).
  * Make project copies under tools/parity/out/_<name> with robocopy (HANDOFF), never in
    the session scratchpad. Run the copy's own tools/check.sh (0 failed) before you probe
    or record from it, and keep tools/parity/watchdog.ps1 running beside multi-job runs:
    a probe copy with a parse error made four headless runs eat all memory and locked my
    machine up twice.
  * A full run (435 cases) takes about 23 minutes with 4 jobs at 6 GB free. Check the free
    memory first; run nothing beside a recording, not even a headless compare.
  * A full set is about 6.2 GB; delete intermediate sets once compared and keep only your
    final run at the end.
- What the panels draw (plan 9.4; verify every fact before relying on it):
  * CreatureRow.draw (src/battle/character/CreatureRow.gd): translate (the row's slide:
    Hideable), drawBack (Graphics.drawGradient: untextured, black from the top alpha to the
    bottom; EnemyRow's height by its creature count), then per Creature3D its draw,
    translateCreature, setColor(1).
  * Creature3D.draw: the tint (setColor(.75) and alpha .2 while the creature is not active
    and not a support target, else alpha .7), drawImage (Character3D: the portrait,
    drawTex; translated and scaled while it has the turn; Enemy3D: its own), the progress
    bar (progressBar.update(getProgress) in the draw; BattleProgressBar.draw: emptyBar,
    white.png tinted blue, green with haste, red with slow at the alpha, to the percent,
    overlay: Utils3D.draw3DPart), the info texture (Creature3D.updateTexture in the draw
    when mustUpdateText: name, "Elem:", life drawn into an Image by GraphicHelp, then
    GameTexture.updateImage), the element icon (bound, but drawn with the info texture's
    coordinates: original), the boosts' cards (Cards/<n>.png; an enemy's scaled .9 and
    moved).
  * Character3D.draw while a hit hides the character: nothing, or on a critical hit the
    party's red screen (setImageColor, drawImage of a 1024 x 768 white image under the 3D
    projection at z 0): behind the near plane, never visible (the Java too), but it is a
    batch in the chunk.
  * Part 1's probe: the character row is 15 to 25 batches, the enemy row 1 to 9, in the
    scene chunk on a floor after the enemy, the attack background and the enemy's card; in
    a SubViewport while the attack name shows and in boss areas.
- Coverage known (plan 9.4): the inactive tint on every turn, haste and slow bars and
  boosts (battle_panels), slow in boss and effects_magic_5, element icons of three elements
  (Frozen Forest, the Tunnel, the effects_* cases), a party member hidden by a hit
  (battle_enemy, battle_panels), a support target (battle_panels, battle_result). Not
  probed yet: a creature's life under 20 % (red), a dead party member's panel during a
  battle, the rows sliding in at a battle's start and out for a boss's words frame by
  frame, a group of three enemies (the enemy row's height), the frames the info texture is
  rebuilt in.
- --seed runs read no game pad and advance a game clock by one fixed step per frame. In
  seeded runs an unseeded JRandom takes J.nextSeed(): seed anything new from a hash of the
  seed. Measure frame rates in normal runs.
- Do not type while a recording runs. If the Godot editor is open on the project, close it
  while recording. If I change one of your files while you work, keep my change and tell
  me.

Decisions (plan section 13):
- Step B only. The legacy objects keep the state, the input and the timing (the bars'
  update in the draw, the rows' slide, the hide timers, the info texture's rebuild, which
  stay in the twins). No Tweens, Timers, signals or InputMap.
- Decision 8 (the look) is not made, and decision 2's exact look stays: the textures, the
  colours, the gradients, the GL state as GLBackend draws them.
- The place: nodes in the chunk and slot of the batches they replace (Graphics.show_node,
  as EnemyView and MinimapPart), not Battle.tscn under the camera rig yet. A node whose
  drawing was several batches that overlap must not be one instance with several surfaces
  (they would tie in Godot's transparent sort, as the walls did): one instance per legacy
  batch in its own slot, or one surface where the batch was one material. Keep the info
  texture's Image as the node's texture first (exact).
- The party's red screen: nothing shows it. Keeping its batch, making it a node or dropping
  it are all possible; tell me what you find and ask before dropping it.
- A tolerance is my decision. With the walls in a fixed order part 1 needed none; a
  difference now is the change's. Explain it with diff images and ask me before
  accepting any.
- Make no other open decision. If you find a place that keeps parity and is closer to the
  plan's Battle.tscn, propose it before building it.

Deliverables, in this order. Do (0) and (1) before converting anything.

0. Baseline: tools/check.sh reports 0 failed; record all cases; compare with e2node.

1. Facts and coverage of the panels, then goldens
   - Verify the facts above and plan 9.4's row 2 and add what they miss: per panel batch
     what it draws, its render state (texture, blending, alpha test, depth test and write,
     fog, colour), its chunk and index, what merges into it (consecutive triangles of one
     material are one batch: across creatures too?), the state each draw changes and the
     state the rows start from and leave; the gradient's and the info texture's batches;
     the red screen's batch.
   - Coverage: part 1's probe (probe_3d_patch.py, extended to the panels' batches and
     states) over the battle cases, per-frame checks. Then cases for what no shot shows: a
     life under 20 %, a dead member's panel, the rows' slides frame by frame, three
     enemies, the info texture's rebuild. Use the console's casts, heal, kill, exp,
     statuses, or a dev-only console command for states no seeded route reaches; document
     any new one.
   - Record goldens of all cases, old and new; record the new cases a second time
     (identical).

2. The panels (step B)
   - Twins in the panels' draws: the same state changes in the same order (the matrix
     calls, the colours and Graphics.color, the binds and texture coordinates, the bars'
     update, the info texture's rebuild), and nodes in scenes/battle/ (a script beside
     each) shown through Graphics.show_node in the chunk and slot of each batch they
     replace, with GLBackend's material for the render state (Graphics.material_3d,
     eye_points, eye_normal as EnemyView).
   - Flag: --legacy=battle_panels, in ARCHITECTURE section 7. With it the frame is drawn
     exactly as before.
   - Parity: golden vs. after on every case (identical at tolerance 0; logs, per-case
     error and leak lines); the flag vs. after and vs. the golden on the battle cases; all
     phase 4.4 flags (battle_panels, battle_enemy, battle_screens, battle_flash,
     battle_legend) vs. the golden on every case, and with --legacy=battle_effects added
     on the battle cases (vs. a golden with it). A run with prints in Graphics' 3D
     emission while the panels draw shows none of their quads left with the flag off.
     Explain every difference with its diff image; fix the bridge code, not legacy logic.
   - The frame rate in normal runs, legacy vs. node, capped and uncapped: a battle on a
     floor and in a boss area.

3. Docs: ARCHITECTURE (section 6's bridge members, 7's flags, 15: the panels' nodes, their
   chunks and slots), CONVERTING_UI (what several batches of one part add), plan 9.4 (the
   results, as part 1's), 12, 13, 14, HANDOFF (the new state).

4. Prepare the next part (the deck and the hand, plan 9.4's order, or another if the
   panels' results say so): what it draws (GLDeck, GLSlot's rotation with its update in
   the draw, the cards' two sides, the mode icon, the pointer, the deck's texts among the
   chunks), the state it changes, its chunks and batches, the coverage, the cases still
   needed, and whether the panels' results change the order or the place.

Constraints:
- Convert only the panels. No step C. Gameplay, input and timing unchanged.
- Do not change legacy game logic or content; a port bug found on the way may be fixed as
  its own listed change with new goldens (the Java is in _java_reference/src/).
- Dev-only flags and console commands are fine if documented. Normal play must not change.
- Legacy files follow PORTING.md; new files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed. Run Godot from bash with < /dev/null. Screenshots
  need a window (not --headless). Ad-hoc runs end themselves (AutoPlay quit,
  --quit-after-ms).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the nodes and their places in the frame and the chunks;
- the facts of deliverable 1 where they differ from this prompt or plan 9.4;
- the parity results, every difference explained (golden vs. after, legacy vs. node,
  every flag on vs. the golden, the new cases twice);
- the screenshots you checked (contact sheets are fine); fps legacy vs. node;
- the cases you could not reach, and why;
- deliverable 4's list and proposed next step;
- anything that surprised you or that the plan got wrong.

Continue the rollout of phase 4.4 ("battle, cards, effects") of docs/MODERNIZATION_PLAN.md in
this Godot 4.7 project: the battle's 3D, part 4, the texts among the chunks (the attack name,
the deck's lines, the legend's lines, the attack texts) with the last legacy quads of row 1b
(AttackBackground, EnemyCard), through step B. First their facts and coverage, then the
conversion. The enemy (part 1), the info panels (part 2) and the deck, the hand and the legend's
gradient (part 3) are done; the effects that are not particles are the next part (plan 9.4).

Why the texts next: plan 9.4's order, confirmed by part 3 ("Prepared after part 3"): every 3D
part between the texts is nodes now but two small quads and the effects, and a UI node in a
text's slot keeps every chunk's content and order (only the later chunks' composite moves to
the UI layer). Battle.tscn under the camera rig does not come with them (it would draw the
battle's 3D under every text: a look change for later).

Read first:
- docs/MODERNIZATION_PLAN.md:
  * 9.4, all of it, above all "Prepared after the pilot" (the table: rows 1b, 3, 5, 7),
    "Results of the pilot" (the top layer's text nodes), the results of the rollout's parts 1
    to 3 and "Prepared after part 3" (the layouts, what each text draws, what a UI node
    changes);
  * 7.5 and 7.8 (the 3D bridge), 8.1 and 8.3 (text nodes, BaselineLabel, the levels), 9.2
    (ShadowText, MenuText), 12 ("Order-dependent blending", "History in the 3D bridge",
    "Batches that merge only in some states"), 13 (decision 8: the look), 14 and the
    Appendix;
- docs/ARCHITECTURE.md: sections 6 and 7, 10 (the 3D bridge), 12 (show_ui, the levels, a UI node
  before a 3D chunk), 14 (ShadowText, MenuText, BaselineLabel), 15 (the top layer and "The
  battle's 3D": the parts done, Utils3D.show_quad, Object2D.show_tex);
- docs/CONVERTING_UI.md, all of it (section 1: text placement; section 2: text nodes, a 3D part
  as a node of its own, two-sided parts);
- docs/HANDOFF.md: running Godot, AutoPlay, tools/check.sh, recording from a project copy (its
  check.sh first, the memory watchdog beside multi-job runs);
- docs/PORTING.md: the rules for legacy files you touch.

State:
- Phase 4.4's pilot and the rollout's parts 1 to 3 are done and committed. If git status
  shows part 3 uncommitted, stop and tell me. Start from a clean, committed tree; this prompt
  file doesn't count.
- The --legacy= flags left: battle_effects, effect_waits (ARCHITECTURE section 11),
  battle_screens, battle_flash, battle_legend, battle_enemy, battle_panels, battle_deck,
  battle_legend_back (section 15).
- tools/parity/out holds one set of yours: d2node (part 3's node run: 440 cases, 9,408 shots;
  3 script errors, 2,421 errors and 12 exit leak lines: the effects_* cases and
  battle_result). c42after is mine; leave it. Record your baseline on the commit you start
  from and compare it with d2node (shots, logs, per-case error and leak lines): it should be
  identical. Audio-device events (WASAPI lines) come and go with the machine's audio output:
  out/_work/errcounts.py counts them apart. out/_work holds the helper scripts:
  errcounts.py, battle_cases3.txt (the 39 cases that draw a battle), probe_panels_patch_head.py
  and probe_deck_patch.py (part 3's probe, applied in that order to a copy of the code after
  part 2: per battle frame the chunks, batches, merges and render states of the rows and the
  deck, the GL state between the parts, the deck's, the hand's and the legend's state; on
  the code after part 3 some of the deck patch's anchors are split by the twins' flag checks:
  adapt them, run the copy's check.sh, and smoke-run one case before the full probe),
  probe_deck_report.py, chunk_layout.py (each frame's 3D chunks and 2D texts in order),
  hand_trace.py, deck_batches.py, legacy3d_deck_patch.py with legacy3d_deck_runs.sh (the "no
  legacy quad while the deck draws" check: flags off, then on through the copy's cases.txt),
  fps_deck.sh and fps/ (frame rates in normal runs), full_runs3.sh (the full recordings, one
  after another).
  * Make project copies under tools/parity/out/_<name> with robocopy (HANDOFF), never in the
    session scratchpad. Run the copy's own tools/check.sh (0 failed) before you probe or
    record from it, and keep tools/parity/watchdog.ps1 running beside multi-job runs. A probe
    patch written for older code may find an anchor twice (a legacy path and its twin):
    probe_panels_patch_head.py patches every occurrence.
  * A full run (440 cases) takes about 25 minutes with 4 jobs at 7.5 GB free; check the
    available memory first. Run nothing beside a recording, not even a headless compare.
  * A full set is about 6.4 GB; delete intermediate sets once compared and keep only your
    final run at the end. Quote paths in bash: the project's path has spaces (an unquoted
    redirect or `xargs` splits it).
- What the texts draw (plan 9.4, "Prepared after part 3"; verify every fact before relying on
  it):
  * The attack name (Attack.draw, while an enemy attacks): AttackBackground's quad first;
    setFontSize(46); pos += SPEED per draw (state in the draw); drawWithShadow twice (a black
    copy 3 px down and right of a point sliding in from the other side, then the white line):
    four drawString lines at alpha 1.
  * The deck's lines (GLDeck.draw, while cards are shown): startText at the mode's fade value;
    black copies 2 px down and right, then white: the card's name at 34, the pile's count at
    50 (centred; 5 px left for 10 to 19 cards; none for an empty pile), two info lines and
    "Deck" at 24, at a y that slides with the deck.
  * The legend's lines (Legend.draw, every frame, off the screen while hidden): six lines at
    24, black, then white 2 px up and left, at an x that slides with the legend.
  * The attack texts (AttackText.draw, from Battle.drawBattle and, during ANIMATE, also from
    Animation.draw: each text twice a frame): per text setColor(colour, life),
    setBlendFunc(ONE_MINUS_SRC_ALPHA), the text at the screen point of its eye-space position
    (draw3DText: translate(0, 0, -2), scale(0.8); the font size scaled to the projection).
  * AttackBackground (every frame, off the screen while hidden) and EnemyCard (the enemy's
    card, while it attacks): one drawTex each, three stray quads each in initDraw.
  * The layouts per frame (S the floor's scene chunk, V a SubViewport, T text): S (enemy,
    attack background, enemy card, rows, deck) T (deck) V (hand, legend's gradient) T (legend)
    [V (effects) T (attack texts ×2)] V (the weather's front pass, the minimap); while the
    attack name shows the S chunk ends after the attack background; in a boss area every 3D
    chunk is a V.
- Coverage known (plan 9.4): every text in many shots, the legend in support mode, the
  pile's count for 10 to 19 cards and an empty pile, three enemies' attack names
  (battle_rows), a boss's attacks in his area. Not probed yet: the attack name sliding in
  frame by frame (its pos per draw), "Miss!", "Critical Hit!", the shuffle's text, support
  numbers (green), several texts at once, a text fading out frame by frame, the deck's lines
  while the deck slides, each text's font size and position.
- --seed runs read no game pad and advance a game clock by one fixed step per frame. In
  seeded runs an unseeded JRandom takes J.nextSeed(): seed anything new from a hash of the
  seed. Measure frame rates in normal runs.
- Do not type while a recording runs. If the Godot editor is open on the project, close it
  while recording. If I change one of your files while you work, keep my change and tell me.

Decisions (plan section 13):
- Step B only. The legacy objects keep the state, the input and the timing (the attack name's
  slide in its draw, the texts' life in their update, the slides). No Tweens, Timers, signals
  or InputMap.
- Decision 8 (the look) is not made, and decision 2's exact look stays: the fonts, sizes,
  colours, alphas and positions as GLBackend draws them (JOGL's TextRenderer: baselines;
  oversampling 1), the GL state as GLBackend draws the quads.
- The place: the texts as UI nodes in the frame's 2D order where each was drawn
  (Graphics.show_ui, as the top layer's), not Label3D and not Battle.tscn under the camera rig;
  AttackBackground and EnemyCard as PanelQuads in their batches' slots (Object2D.show_tex).
  Reuse the nodes that exist (ShadowText, MenuText, BaselineLabel) before making new ones; a
  new node only where nothing covers a part (the attack texts at their projected points and
  sizes).
- The party's red screen stays as part 2 left it unless I decide otherwise.
- A tolerance is my decision. Since the walls are drawn in a fixed order no part needed one;
  a difference now is the change's. Explain it with diff images and ask me before accepting
  any.
- Make no other open decision. If you find a place that keeps parity and is closer to the
  plan's Battle.tscn, propose it before building it.

Deliverables, in this order. Do (0) and (1) before converting anything.

0. Baseline: tools/check.sh reports 0 failed; record all cases; compare with d2node.

1. Facts and coverage of the texts and the two quads, then goldens
   - Verify the facts above and add what they miss: per text what it draws (strings, font,
     size, colour, alpha, positions: baselines, centring), its place in the frame's 2D order
     (between which chunks, on which layer), the state it changes and the state it starts from
     and leaves (font size, text colour, the colour and blend function the attack texts leave
     for the weather's front pass and the minimap); per quad its batch, chunk, index, merges
     and render state; initDraw's stray quads.
   - What a UI node in each text's slot changes in the chunks: which later chunks move to the
     UI layer, per layout; whether any later legacy 2D or node expects LegacyLayer; whether
     the composite on the UI layer draws the same pixels (check with one text first).
   - Coverage: part 3's probe extended to the texts (the strings, sizes, positions, colours
     and alphas per frame, the attack name's pos, the attack texts' life) over the battle
     cases, per-frame checks. Then cases for what no shot shows (the list above). Use the
     console's casts, heal, kill, statuses, or a dev-only console command for states no
     seeded route reaches; document any new one.
   - Record goldens of all cases, old and new; record the new cases a second time
     (identical).

2. The texts and the two quads (step B)
   - Twins in their draws: the same state changes in the same order (the font size, the text
     colours, startText/finishText, the attack name's pos, the attack texts' colour, blend
     function and matrix calls), and UI nodes in the frame's order (Graphics.show_ui with
     Graphics.canvas_material and the 2D state where each text was drawn); PanelQuads for
     AttackBackground and EnemyCard (and their initDraw quads).
   - Flags: one per text kind and one for the two quads (for example --legacy=battle_attack_name,
     battle_deck_text, battle_legend_text, battle_attack_text, battle_enemy_quads), in
     ARCHITECTURE section 7. With them the frame is drawn exactly as before.
   - Parity: golden vs. after on every case (identical at tolerance 0; logs, per-case error
     and leak lines); each flag vs. after and vs. the golden on the battle cases; all phase
     4.4 flags vs. the golden on every case, and with --legacy=battle_effects added on the
     battle cases (vs. a golden with it). A run with prints in Graphics._drawText,
     AttackText.draw3DText and Graphics' 3D emission while the texts and the two quads draw
     shows none of them left legacy with the flags off. Explain every difference with its
     diff image; fix the bridge code, not legacy logic.
   - The frame rate in normal runs, legacy vs. node, capped and uncapped: a battle on a floor
     and in a boss area, with an enemy attacking (the attack name) and a card's damage (the
     attack texts).

3. Docs: ARCHITECTURE (section 6's bridge members, 7's flags, 15: the texts' nodes and their
   places in the frame's order, the chunks they lift to the UI layer), CONVERTING_UI (what text
   among 3D chunks adds), plan 9.4 (the results, as parts 1 to 3), 12, 13, 14, HANDOFF (the new
   state).

4. Prepare the next part (the effects that are not particles, plan 9.4's order, or another if
   the texts' results say so): what each draws and where (the spheres: Demolish's gluSphere,
   lit; the image and slow systems: Death, Slow; the enemy colour system), their coroutines and
   what the battle waits on, the state they change, their chunks and batches, the coverage,
   the cases still needed; and what is left of the battle on the 3D bridge after it (the red
   screen), so that the minimap's node, the closing of 4.4 and step C can be planned.

Constraints:
- Convert only the texts and AttackBackground and EnemyCard. No step C. Gameplay, input and
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

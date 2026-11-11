Start the rollout of phase 4.4 ("battle, cards, effects") of docs/MODERNIZATION_PLAN.md in
this Godot 4.7 project: the battle's 3D, part 1. Two things, in this order: the facts and
the coverage of the whole battle 3D (cases for every part the rollout will convert, recorded
on unconverted code), then the first part through step B (presentation): the enemy
(BattleEnemy.draw and drawSlice). Its particle systems are GPU nodes already (phase P2);
the rest of BattleEnemy.draw (the attack name, AttackBackground, EnemyCard), the info
panels, the deck, the hand, the legend, the effects that are not particles and the attack
texts are later parts (plan 9.4, "Prepared after the pilot").

Why the enemy first: plan 9.4's order. It is the battle frame's first legacy 3D (right after
the floor's scene and the weather's back pass), so in a labyrinth it lands in the 3D
bridge's scene chunk, in the floor's World3D: it meets the bridge's open problem (the 1/255
of plan 8.3) on the smallest part, and it is the most visible one. The coverage comes first
because the probe of phase 4.4's pilot printed only the top layer: several 3D states have
no shot yet.

Read first:
- docs/MODERNIZATION_PLAN.md:
  * 9.4, all of it, above all "Results of the pilot" and "Prepared after the pilot" (the
    table of the 3D parts, the 3D bridge, the text among the chunks, the 1/255, the
    coverage, the order and sizes);
  * 7.5, 7.7 and 7.8 (the 3D bridge, the renderer details parity rests on, the 1/255 of
    7.8), 8.3 (the minimap's node and the 1/255 it caused in later battle frames), 6.11
    and 6.12 (the battle effects on the GPU: nodes in a chunk's slot);
  * 2.4's battle rows, 12, 13, 14 and the Appendix (the pilot's findings);
- docs/ARCHITECTURE.md: sections 4, 6 and 7, 10 (the dungeon scene, the 3D bridge,
  SceneChunk, sorting offsets), 11 (EffectParticles3D: Graphics.show_node,
  render_state_3d, the materials), 12 (MinimapPart: begin_capture_3d, show_node), 15 (the
  battle's top layer);
- docs/CONVERTING_UI.md, all of it (its last parts: the battle's top layer; section 2's
  last bullet: 3D in a chunk);
- docs/HANDOFF.md: running Godot, AutoPlay, tools/check.sh, recording from a project copy;
- docs/PORTING.md: the rules for legacy files you touch.

State:
- Phase 4.4's pilot (the battle's 2D top layer) is done and committed. If git status shows
  it uncommitted, stop and tell me. Start from a clean, committed tree; this prompt file
  doesn't count.
- The --legacy= flags left: battle_effects, effect_waits (ARCHITECTURE section 11),
  battle_screens, battle_flash, battle_legend (section 15).
- tools/parity/out holds one set: c44node (the pilot's node run: 432 cases, 8,257 shots;
  3 script errors and 2,421 errors in all; exit leak reports of 7 objects in the five
  effects_* cases and battle_result: the console's cast cards). Record your baseline on the
  commit you start from and compare it with c44node (shots, logs, per-case error and leak
  lines): it should be identical. out/_work holds the helper scripts: errcounts.py
  (per-case error and leak line counts of two sets), battle_cases.txt (the 31 cases that
  draw a battle), flags_battle.sh (per-flag runs on them), probe_battle_patch.py (the
  pilot's probe of the top layer), probe_overlap.py (which parts coincide, per frame, over
  a probe's logs), legacy2d_battle_patch.py (the "no legacy 2D" check), fps_battle.sh and
  fps/fps_battle.txt (frame rates in normal runs).
  * Make project copies under tools/parity/out/_<name> with robocopy (HANDOFF), never in
    the session scratchpad.
  * A full run (432 cases) takes about 25 minutes with 5 jobs at 8 GB free (4 jobs at 6
    GB). Check the free memory first; run nothing beside a recording, not even a headless
    compare.
  * A full set is about 5.6 GB; delete intermediate sets once compared and keep only your
    final run at the end.
- What the enemy draws (verify every fact before relying on it):
  * BattleEnemy.draw (src/battle/enemy/BattleEnemy.gd:133): unless killed, loadIdentity,
    translate(shakeoffx, shakeoffy + risey, its .enemy file's DEPTH), setColor3(usedColor);
    while visible (TimeHideable: a hit hides it for 200 ms) drawTex(currentList) or, while
    an effect's destroyEnemySlice runs (ParticleSystem.update), drawSlice: two quads, the
    top one sliding by xs, at alpha life (life -= sliceFade, xsSpeed, xs, test1 and test2
    change in the draw). Then loadIdentity, its particle systems (GPU nodes), setColor(1),
    the alpha test on at GREATER .1, attack_.draw (AttackBackground's quad, then the attack
    name's 2D text: the frame's first 2D while it shows), setAlphaFunc(0), card.draw
    (EnemyCard's quad), setColor(1).
  * Its frame (currentList), shake, rise and colour change in Scheduler coroutines (its
    attacks, the colour's recovery) and through EnemySystem (the Elements card sets
    usedColor; unreachable, plan 9.4).
  * In a labyrinth it is in the 3D bridge's scene chunk (GLBackend.scene_3d: batches as
    MeshInstance3D children of the scene's Legacy node, sorting offsets from 1e6); in a
    boss area (Serphia, Menthu, Memory Salmonman: BossBattleArea sets no use_scene_3d) in
    a SubViewport chunk. GLBackend merges consecutive triangles of one material into one
    batch (GLBackend.Chunk3D.add_triangles): a node in a slot can split a batch.
  * Lighting is off for the battle, the GL fog of the floor on (Labyrinth.init_scene_3d);
    a node takes GLBackend's material for the render state (Graphics.render_state_3d,
    GLBackend.material_3d), as the effects' nodes do.
- The 1/255 (plan 8.3): drawing the minimap's batches with nodes in the floor's world made
  41 battle shots after them differ by 1/255 (the bridge's pool instances render later
  batches 1/255 apart; the mechanism was not found). Expect the same here: the enemy's
  node changes which pool instance draws the batches after it. Compare the frames after
  the change, not only those of the enemy.
- Coverage known (plan 9.4): the enemy, the panels, the deck, the hand and the legend are
  in every battle shot, the attack name in 144 shots of 14 cases, the effects in the
  effects_* cases, the legend's slide frame by frame (battle_result), a critical hit's
  hide (battle_flash), the inactive creatures' 0.75 tint. Not probed yet: the enemy's
  slice, its attack frames, shake and rise frame by frame, haste and slow bars, the boosts'
  cards and the element icons on a panel, a slot's flip (R2) frame by frame, the deck's
  shuffle, a boss's words over its battle (TALKING). Never shown (plan Appendix): the
  party's red screen, the clock, the enemy colour system.
- --seed runs read no game pad and advance a game clock by one fixed step per frame
  (Scheduler and J.currentTimeMillis read it). In seeded runs an unseeded JRandom takes
  J.nextSeed(): seed anything new from a hash of the seed, as Main does
  (ParticleSystem.gpu_rand). Measure frame rates in normal runs.
- Do not type while a recording runs. If the Godot editor is open on the project, close it
  while recording. If I change one of your files while you work, keep my change and tell
  me.

Decisions (plan section 13):
- Step B only. The legacy objects keep the state, the input and the timing (the enemy's
  coroutines, its hide timer, the slice's per-draw steps, which stay in the twin). No
  Tweens, Timers, signals or InputMap (decision 3; phase 4.3).
- Decision 6 is not needed: the node mirrors the legacy values each frame.
- Decision 8 (the look) is not made, and decision 2's exact look stays: the textures, the
  colours, the slice, the fog and the GL state as GLBackend draws them.
- The place: the node in the chunk and slot where the enemy's batch was
  (Graphics.show_node, as the effects and MinimapPart), not Battle.tscn under the camera
  rig yet: 3D moved out of its chunk is drawn under every 2D text of the frame, also the
  texts drawn before it (plan 9.4). If you find a place that keeps parity and is closer to
  the plan's Battle.tscn, propose it before building it.
- A tolerance is my decision. If the 1/255 of 8.3 appears on batches the change does not
  draw, explain it with diff images and 8.3's experiments, try what 8.3 did not, and ask
  me before accepting it.
- Make no other open decision.

Deliverables, in this order. Do (0) and (1) before converting anything.

0. Baseline: tools/check.sh reports 0 failed; record all cases; compare with c44node.

1. Facts and coverage of the battle's 3D, then goldens
   - Verify plan 9.4's table of the 3D parts and add what it misses: for every part what it
     draws, the state it changes in its draw, the 2D among it, the chunk each of its
     batches lands in (the scene chunk or which SubViewport) and how GLBackend batches it.
     For the enemy in detail: its quads, the slice's two quads, the render state of each
     (texture, blending, alpha test, depth test and write, fog), its slot among the
     batches, what is merged into its batch, and the state it starts from and leaves.
   - Coverage: the probe of CONVERTING_UI (prints in a project copy, headless where it
     needs no picture) in each part's draw (the enemy's frame, visibility, slice, colour,
     shake and rise, killed; the panels' bar modes, boosts and elements; the slots'
     rotation; the shuffle; TALKING; the chunk of each part's first batch) and in AutoPlay's
     shot, over the battle cases; probe_overlap.py-style per-frame checks. Then cases for
     what no shot shows: the enemy's slice and its attack frames, shake and rise frame by
     frame; a haste and a slow bar, boosts and element icons on the panels; a slot's flip
     frame by frame; the deck's shuffle; a boss's words over its battle; the enemy in a
     scene chunk with and without weather and in a boss area. Use the console's casts
     (--casts, `cast`, `cast next`), `heal`, `kill`, `exp`, statuses, or a dev-only
     console command for states no seeded route reaches; document any new one.
   - Record goldens of all cases, old and new; record the new cases a second time
     (identical).

2. The enemy (step B)
   - A twin in BattleEnemy.draw and drawSlice: the same state changes in the same order
     (the matrix calls, the colour, the binds and texture coordinates, life, xsSpeed, xs,
     test1, test2), and a node (a quad, two for the slice, with GLBackend's material for the
     render state) shown through Graphics.show_node in the chunk and slot of the enemy's
     batch. The rest of BattleEnemy.draw stays as it is. New files follow ARCHITECTURE.md
     (scenes/battle/ or scenes/common/, a script beside each).
   - Flag: --legacy=battle_enemy, in ARCHITECTURE section 7. With it the frame is drawn
     exactly as before.
   - Parity: golden vs. after on every case (identical at tolerance 0; logs, per-case
     error and leak lines too); the flag vs. after and vs. the golden on the battle cases;
     every phase 4.4 flag on (battle_enemy, battle_screens, battle_flash, battle_legend)
     vs. the golden on every case, and with --legacy=battle_effects added on the battle
     cases. A run with prints in Graphics' 3D emission while the enemy draws shows none
     of the enemy's quads left with the flag off. Explain every difference with its diff
     image; fix the bridge code, not legacy logic.
   - The frame rate in normal runs, legacy vs. node, capped and uncapped: a battle on a
     floor (the scene chunk) and in a boss area.

3. Docs: ARCHITECTURE (section 6's bridge members, 7's flags, section 15: the battle's 3D
   nodes, their chunks and slots), CONVERTING_UI (what a 3D part in a chunk adds), plan 9.4
   (the results, as the pilot's), 12, 13, 14, HANDOFF (the new state).

4. Prepare the next part (the info panels, plan 9.4's order; or another if the enemy's
   results say so): what it draws, the state it changes, its chunks and batches, the
   coverage, the cases still needed, and whether the enemy's results change the order or
   the place (show_node vs. Battle.tscn).

Constraints:
- Convert only the enemy's quads. No step C. Gameplay, input and timing unchanged.
- Do not change legacy game logic or content; a port bug found on the way may be fixed as
  its own listed change with new goldens (the Java is in _java_reference/src/).
- Dev-only flags and console commands are fine if documented. Normal play must not change.
- Legacy files follow PORTING.md; new files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed. Run Godot from bash with < /dev/null. Screenshots
  need a window (not --headless). Ad-hoc runs end themselves (AutoPlay quit,
  --quit-after-ms).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the node and its place in the frame and the chunk;
- the facts of deliverable 1 where they differ from this prompt or plan 9.4;
- the parity results, every difference explained (golden vs. after, legacy vs. node,
  every flag on vs. the golden, the new cases twice);
- the screenshots you checked (contact sheets are fine); fps legacy vs. node;
- the cases you could not reach, and why;
- deliverable 4's list and proposed next step;
- anything that surprised you or that the plan got wrong.

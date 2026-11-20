Continue the rollout of phase 4.4 ("battle, cards, effects") of docs/MODERNIZATION_PLAN.md in
this Godot 4.7 project: the battle's 3D, part 5, the card effects that are not particles
(Demolish's spheres, Death's images, Slow's clock; the Elements colour), through step B. First
their facts and coverage, then the conversion. The enemy (part 1), the info panels (part 2), the
deck, the hand and the legend's gradient (part 3) and the texts among the chunks with the
attack's background and the enemy's card (part 4) are done; after this part only the party's red
screen (never visible) is left of the battle on the 3D bridge, and the closing of 4.4 follows
(plan 9.4, "Prepared after part 4").

Why these next: plan 9.4's order, confirmed by part 4 ("Prepared after part 4"): the texts moved
nothing on the screen, and these effects are the last battle drawing that emits legacy batches.
Battle.tscn under the camera rig does not come with them (it would change the order of the
battle's 3D and its texts, and the weather's front pass: a look change for step C).

Read first:
- docs/MODERNIZATION_PLAN.md:
  * 9.4, all of it, above all "Prepared after part 4" (what each effect draws, where, its
    coroutine and what the battle waits on, the lights), the results of the rollout's parts 1
    to 4, and 6.11 and 6.12 (the effects that are particles: EffectParticles3D, the waits);
  * 7.5 and 7.8 (the 3D bridge, the dungeon shader, the look decisions), 8.3 (the minimap's
    node, Graphics.begin_capture_3d / end_capture_3d), 12 ("Logic timed by effects",
    "Order-dependent blending", "Batches that merge only in some states", "Global state read
    at render time"), 13 (decisions 2, 6 and 8), 14 and the Appendix;
- docs/ARCHITECTURE.md: sections 6 and 7, 10 (the 3D bridge), 11 (battle effects on the GPU:
  ParticleSystem.gpu_path, show_gpu, the waits, --legacy=battle_effects and effect_waits), 12
  (show_node, MinimapPart), 15 ("The battle's 3D": the parts done, PanelQuad,
  Utils3D.show_quad, Graphics.place_quad);
- docs/CONVERTING_UI.md, section 2 (a 3D part as a node of its own, parts of several batches,
  merges) and "What the texts among the battle's 3D chunks added";
- docs/CONVERTING_PARTICLES.md (the effects' GPU conversion and its waits);
- docs/HANDOFF.md: running Godot, AutoPlay, tools/check.sh, recording from a project copy (its
  check.sh first, the memory watchdog beside multi-job runs);
- docs/PORTING.md: the rules for legacy files you touch.

State:
- Phase 4.4's pilot and the rollout's parts 1 to 4 are done and committed. If git status shows
  part 4 uncommitted, stop and tell me. Start from a clean, committed tree; this prompt file
  doesn't count.
- The --legacy= flags left: battle_effects, effect_waits (ARCHITECTURE section 11),
  battle_screens, battle_flash, battle_legend, battle_enemy, battle_panels, battle_deck,
  battle_legend_back, battle_attack_name, battle_deck_text, battle_legend_text,
  battle_attack_text, battle_enemy_quads (section 15).
- tools/parity/out holds one set of yours: t2node (part 4's node run: 441 cases, 9,787 shots;
  3 script errors, 2,421 errors and 12 exit leak lines: the leak lines in battle_result and
  five effects_* cases, the errors outside the battle, most in Zazo's tent and nights and
  world_east_night).
  c42after is mine; leave it. Record your baseline on the commit you start from and compare it
  with t2node (shots, logs, per-case error and leak lines): it should be identical.
  Audio-device events (WASAPI lines) come and go with the machine's audio output:
  out/_work/errcounts.py counts them apart. out/_work holds the helper scripts: errcounts.py,
  battle_cases4.txt (the 40 cases that draw a battle), probe_panels_patch_head.py and
  probe_text_patch.py (part 4's probe, applied in that order to a copy of the code after part
  3: per battle frame the 3D log of every part with its chunk, batch, merge and render state,
  each 2D text, and the effect systems of each packet tagged X<class>: XSphere, XImage, XSlow,
  XEnemy, Xg for the GPU systems; on the code after part 4 some anchors are split by the twins'
  flag checks: adapt them, run the copy's check.sh, and smoke-run one case before the full
  probe), probe_text_report.py and probe_text_runs.py (its reports), legacy_text_patch.py (the
  "nothing left legacy" counters), fps_texts.sh with fps/ (frame rates in normal runs),
  full_runs4.sh (the full recordings, one after another, then the compares).
  * Make project copies under tools/parity/out/_<name> with robocopy (HANDOFF), never in the
    session scratchpad. Run the copy's own tools/check.sh (0 failed) before you probe or
    record from it, and keep tools/parity/watchdog.ps1 running beside multi-job runs. A probe
    patch written for older code may find an anchor twice (a legacy path and its twin).
  * A full run (441 cases) takes about 26 minutes with 4 jobs at 7.5 GB free; check the
    available memory first. Run nothing beside a recording, not even a headless compare.
  * A full set is about 6.9 GB; delete intermediate sets once compared and keep only your
    final run at the end. Quote paths in bash: the project's path has spaces (an unquoted
    redirect or `xargs` splits it).
- What the effects draw (plan 9.4, "Prepared after part 4"; verify every fact before relying
  on it):
  * all of them in Animation.draw (a card's effect, during ANIMATE), in the SubViewport after
    the legend's lines (composited on the UI layer since part 4), before the attack texts; in
    a boss area in its SubViewports;
  * Demolish (SphereParticleSystem: effects_magic_4, effects_area_2): per particle with
    z >= -6 a lit, untextured gluSphere(size, 50, 50); start pushes the matrix and the lighting
    attributes and sets light 2, the material and the colour; end pops them. Consecutive
    spheres merge into one batch up to 60,000 vertices. GLBackend's lights and material are
    global shader parameters read when the frame renders, after end popped them: the spheres
    are lit by the restored state, not by light 2 (and GLBackend has no specular term);
  * Death (ImageParticleSystem: effects_magic_5): one quad a frame, one of three images; its
    first draw starts a coroutine (the life up, 500 ms, four image flips, plainDestroy: the
    hit, the life down: isDead);
  * Slow (SlowParticleSystem: effects_magic_5, battle_panels, boss): three quads a frame (the
    clock, the hour and the minute hand rotated by update's angles), three batches; its
    coroutine as Death's, 750 ms before plainDestroy;
  * Elements (EnemySystem): draws nothing (it sets the enemy's colour); unreachable;
  * SwordBackground (Battle Card's "ground"): never drawn (ParticleSystem.drawable is never
    assigned, as in the Java).
- Coverage known (plan 9.4): Demolish 3 on a floor and in Serphia's area, Death 3 and Slow 3
  on Memory Taur, Slow in battle_panels and boss. Not probed yet: Death's image flips frame by
  frame, Slow's hands frame by frame, Demolish 1 and 2, the spheres' merges per frame, each
  effect's last frames (its fade to 0), an effect in a boss area's first frames.
- --seed runs read no game pad and advance a game clock by one fixed step per frame (the
  coroutines' Scheduler.sleep reads it). In seeded runs an unseeded JRandom takes J.nextSeed():
  seed anything new from a hash of the seed. Measure frame rates in normal runs.
- One normal run of part 4's node code segfaulted at exit (Serphia's area, uncapped, after
  AutoPlay's quit; plan 9.4, "Found on the way"), not reproduced in 20 repeats. Check every
  run's exit code; if a crash comes back, note the case, mode and flags and tell me.
- Do not type while a recording runs. If the Godot editor is open on the project, close it
  while recording. If I change one of your files while you work, keep my change and tell me.

Decisions (plan section 13):
- Step B only. The legacy systems keep the state, the logic and the timing (the particles'
  update, the coroutines, plainDestroy, the waits the battle reads, the angles of Slow's hands).
  No Tweens, Timers, signals or InputMap; no AnimatedSprite3D or SphereMesh look of its own yet.
- Decision 2's exact look stays: the batches as GLBackend draws them, in GLBackend's material of
  the render state where they were drawn (Graphics.material_3d), so the spheres keep the light
  state the frame ends with. The original's lit purple spheres with their highlight are a look
  change (decisions 2 and 8): describe it, do not build it.
- The place: each legacy batch a node in the chunk and slot of its batch (Graphics.show_node:
  PanelQuad through Utils3D.show_quad for Death's and Slow's quads; the spheres' triangles
  through Graphics.begin_capture_3d / end_capture_3d, one node per captured batch, as the
  minimap's MinimapPart), not Battle.tscn under the rig. Reuse the nodes that exist before
  making new ones.
- The party's red screen stays as part 2 left it unless I decide otherwise.
- A tolerance is my decision. Since the walls are drawn in a fixed order no part needed one; a
  difference now is the change's. Explain it with diff images and ask me before accepting any.
- Make no other open decision. If you find a place that keeps parity and is closer to the
  plan's effect scenes (fx/<Card>.tscn), propose it before building it.

Deliverables, in this order. Do (0) and (1) before converting anything.

0. Baseline: tools/check.sh reports 0 failed; record all cases; compare with t2node.

1. Facts and coverage of the effects, then goldens
   - Verify the facts above and add what they miss: per effect its batches (chunk, index,
     merges, render state, the vertices' count), the state its draw starts from and leaves
     (the matrix and attribute stacks, the lights and material it sets and pops, the colour,
     the bound texture, the alpha test and blending the attack texts after it start from), its
     coroutine's steps and what the battle waits on (isDestroyed, isReady, isDead, frame by
     frame against the legacy systems' state), and the light state the spheres are rendered
     with (the global shader parameters at the frame's end).
   - Coverage: part 4's probe extended to the effects (per frame each system's state: life,
     image, angles, particles drawn, coroutine step) over the battle cases, per-frame checks.
     Then cases for what no shot shows (the list above). Use the console's casts, heal, kill,
     or a dev-only console command for states no seeded route reaches; document any new one.
   - Record goldens of all cases, old and new; record the new cases a second time (identical).

2. The effects (step B)
   - Twins in their draws: the same state changes in the same order (the pushes and pops, the
     lights and material, the colour, the binds, the matrix calls, the coroutines' start, the
     particle's life raised and set back), and nodes in the chunk and slot of each legacy batch
     with the merges kept.
   - Flags: one per kind or one for all (for example --legacy=battle_effect_draw), in
     ARCHITECTURE section 7. With them the frame is drawn exactly as before.
   - Parity: golden vs. after on every case (identical at tolerance 0; logs, per-case error and
     leak lines); each flag vs. after and vs. the golden on the battle cases; all phase 4.4
     flags vs. the golden on every case, and with --legacy=battle_effects added on the battle
     cases (vs. a golden with it). A run with prints in Graphics' 3D emission while the effects
     draw shows none of their batches left legacy with the flags off. Explain every difference
     with its diff image; fix the bridge code, not legacy logic.
   - The frame rate in normal runs, legacy vs. node, capped and uncapped: Demolish 3 on a floor
     and in a boss area, Death and Slow.

3. Docs: ARCHITECTURE (section 6's bridge members, 7's flags, 11 and 15: the effects' nodes and
   their slots), CONVERTING_PARTICLES or CONVERTING_UI (what the effects added), plan 9.4 (the
   results, as parts 1 to 4), 12, 13, 14, HANDOFF (the new state).

4. Prepare the closing of 4.4 (plan 9.4, "Prepared after part 4"): the minimap's node as the
   default (8.4; check its battle frames on the code after this part), the party's red screen
   (keep, node or drop: list what each needs for my decision), the flags and the legacy drawing
   the closing removes (every --legacy= name of 4.4 with battle_effects and effect_waits, the
   legacy particle quads, the helpers only they call), what the closing's parity needs, and what
   step C of the battle needs decided (decisions 3, 6 and 8: Battle.tscn under the rig, the
   texts' order, the weather's front pass); so that the closing can be its own prompt.

Constraints:
- Convert only the effects that are not particles. No step C. Gameplay, input and timing
  unchanged.
- Do not change legacy game logic or content; a port bug found on the way may be fixed as its
  own listed change with new goldens (the Java is in _java_reference/src/).
- Dev-only flags and console commands are fine if documented. Normal play must not change.
- Legacy files follow PORTING.md; new files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed. Run Godot from bash with < /dev/null. Screenshots need a
  window (not --headless). Ad-hoc runs end themselves (AutoPlay quit, --quit-after-ms).
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

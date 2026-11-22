Close phase 4.4 ("battle, cards, effects") of docs/MODERNIZATION_PLAN.md in this Godot 4.7
project: fix the exit crash first, make the minimap's node the default, settle the party's red
screen as I decide below, then delete the legacy drawing that phase 4.4's thirteen `--legacy=`
flags and the battle effects' two flags keep, the flags themselves, and the code that only
those paths reach. Step B is done for every part of the battle (plan 9.4: the pilot and the
rollout's five parts); the node paths are the default and have passed parity against the
legacy paths, so closing must not change a pixel.

Why now: plan 9.4, "Prepared after part 5": with the flags off nothing of a battle is drawn
through the 3D bridge but the party's red screen (never visible); the flags double every
converted call site and every parity run; phases 1 to 4.2 were closed the same way (plan 6.9,
7.9, 8.4, 9.1, 9.2, "Closing phase 4.2"). The minimap was kept on the 3D bridge only because
the battles drawn after it were (plan 8.3, 8.4).

In scope, in this order:
- The exit crash (plan 9.4, "Results of the rollout, part 5", "Found on the way"; 12,
  "Pending callbacks at quit"): a `Scheduler.after` lambda pending at quit segfaults at exit.
  Fix it as its own listed change: clear Scheduler's pending tasks (and its deterministic
  timers) at the start of `Main._exit_tree`, before the scenes and ExitCleanup. Reproduce it
  first with a copy of `battle_effects_chrono` whose last `wait 300` is removed (7 of 7 crashed
  on part 5's code, headless), then show it gone (several runs, windowed and headless). No
  frame changes; every case's exit code must be 0 afterwards.
- The minimap's node as the default (plan 8.4; 9.4, "Prepared after part 5"):
  `Labyrinth.draw` calls `MapRenderer.show_map` (the legacy drawing captured, a `MinimapPart`
  per batch in its slot); `Main.minimap_node` and `--minimap-node` go. Part 5 checked its
  battle frames (see plan 9.4); check every labyrinth case before the switch.
- The party's red screen (`Character3D.draw`): make it a node.
- The flags and their legacy branches, flag by flag: battle_screens, battle_flash,
  battle_legend, battle_enemy, battle_panels, battle_deck, battle_legend_back,
  battle_attack_name, battle_deck_text, battle_legend_text, battle_attack_text,
  battle_enemy_quads, battle_effect_draw; then battle_effects (the legacy simulation's quads:
  `ParticleSystem.draw`'s drawParticle path, `ShatterParticleSystem`'s, the Flame's pre-run;
  `ParticleSystem.gpu_path()` always true) and effect_waits (dev: the whole legacy pool;
  `reduce_for_waits` always applies). Plan 9.4, "Prepared after part 5", lists the legacy
  branches and the helpers that lose their last caller (`AbstractCard.drawCard`,
  `LevelUpBar.draw` with drawImage's percent part, `Graphics.drawValueWithShadow`,
  `fadeOldSchoolColorWhite`, `drawWithShadow`, `AttackText.draw3DText`,
  `BattleEnemy.drawSlice`, the effects' `drawParticle`s, `Utils3D.draw3DPart`,
  `draw3DBackside`, `Object2D.drawTex` where only battle quads call it): grep each before you
  delete it (plan 12, "Callers that cannot run"). Where a wrapper only chose between a legacy
  drawing and its twin, its call sites call the twin (as phase 4.2's closing did).
- Dead code the closing exposes or the plan lists: `Clock.gd` (`Clock.draw` has no caller, the
  Java neither: check what else the battle reads from the clock first), `SwordBackground`
  (never drawn: `ParticleSystem.drawable` is never assigned), `ScrollBar.gd`
  (`BattleScrollBar`: no user).

Not in scope: step C of the battle (signals, Tweens, Battle.tscn under the camera rig, the
texts' order, the weather's front pass over the battle, the spheres' original look: decisions
3, 6 and 8 are open); `Graphics`' own API (it goes whole in phase 5: leave its methods even
where no game code calls them any more; `Graphics.gluSphere` stays, the spheres' twin captures
it); `--hide-particles` (it keeps hiding the GPU systems); the minimap built from the state
instead of the captured legacy drawing (later); the content quirks and side findings of the
Appendix: tickets, not this task.

Read first:
- docs/MODERNIZATION_PLAN.md: 9.4, above all "Prepared after part 5" (the list this task works
  from) and the results of the pilot and of the rollout's five parts (what each flag keeps and
  the cases that cover it); 8.3 and 8.4 (the minimap's node); 6.11 and 6.12 (the battle effects'
  flags); 9.2, "Closing phase 4.2", 6.9, 7.9, 8.4, 9.1 (how the earlier closings were done and
  recorded); 12 ("Callers that cannot run", "A removed flag is silently ignored", "Pending
  callbacks at quit"), 13, 14 and the Appendix.
- docs/ARCHITECTURE.md, sections 6 (the bridge members), 7 (the flag table), 11 (the battle
  effects on the GPU), 12 ("Flags (removed)": the pattern for a closed phase; the minimap's
  node), 15 (the battle's top layer and 3D).
- docs/CONVERTING_UI.md, docs/CONVERTING_PARTICLES.md section 5, docs/HANDOFF.md (running
  Godot, AutoPlay, tools/check.sh, recording from a project copy, the memory watchdog),
  docs/PORTING.md (the rules for legacy files you touch).

State:
- Phase 4.4's rollout part 5 is committed. If git status shows it uncommitted, stop and tell
  me. Start from a clean, committed tree; this prompt file doesn't count.
- tools/parity/out holds one set of yours: p3node (part 5's final node run: 445 cases, 11,468
  shots; 3 script errors, 2,421 errors and 16 exit leak lines: the leak lines in battle_result,
  five effects_* cases, battle_effects_demolish and battle_effects_area; the errors outside the
  battle). c42after is mine; leave it. Record your baseline on the commit you start from and
  compare it with p3node (shots, logs, per-case error and leak lines): it should be identical.
  Audio-device lines (WASAPI) come and go with the machine's audio output: out/_work/
  errcounts.py counts them apart. out/_work holds the helper scripts: errcounts.py,
  battle_cases5.txt (the 44 cases that draw a battle), full_runs5.sh (full recordings one
  after another, then the compares), legacy_fx_patch.py (counters of legacy emission while an
  effect draws), probe_fx_patch.py and probe_fx_report.py (part 5's effects probe),
  timing_fx_patch.py (per-frame times of the effects' draw: seeded runs pair frame by frame,
  where `fps=` is a one-second average), fps_fx.sh with fps/.
  * Make project copies under tools/parity/out/_<name> with robocopy from PowerShell with
    backslash paths (HANDOFF; from bash with forward slashes its /XD did not match and it
    began copying tools/parity/out into the copy), never in the session scratchpad. Run the
    copy's own tools/check.sh (0 failed) before you record or probe from it, and keep
    tools/parity/watchdog.ps1 running beside multi-job runs.
  * A full run (445 cases) takes about 35 minutes with 3 jobs at about 5.5 GB free;
    check the available memory first. Run nothing beside a recording, not even a headless
    compare. A full set is about 8 GB; delete intermediate sets once compared and keep only
    your final run at the end. Quote paths in bash (the project's path has spaces) and write
    `rm -rf "${OUT:?}/${set:?}"`, not a bare variable.
- Do not type while a recording runs. If the Godot editor is open on the project, close it
  while recording. If I change one of your files while you work, keep my change and tell me.

Decisions:
- The party's red screen: as stated above (plan 9.4 lists keep, node and drop with what each
  needs).
- No other open decision of plan section 13 is needed: the closing changes no picture and no
  timing; the exit-crash fix changes no frame.
- Delete, do not comment out: the git history is the archive.

Deliverables, in this order:

0. Baseline: tools/check.sh reports 0 failed; record all cases; compare with p3node.

1. The exit crash: reproduce, fix, show it gone (its own change; every case exits 0 in the
   following runs).

2. The minimap's node: `--minimap-node` vs. the baseline on every case that shows a labyrinth
   (identical at tolerance 0, or explain every difference with its diff image and ask me before
   accepting any); then the switch and the flag's removal.

3. The red screen as decided (a case for it if it becomes a node: a critical hit on the party).

4. The closing, flag by flag (tools/check.sh 0 failed after each): the legacy branches, the
   flags, the wrappers, the dead helpers and classes. grep for every removed name (callers in
   src/, scenes/, tools/; strings in AutoPlay scripts and cases.txt). A smoke set (a battle's
   result and spoils screens, the effects_* cases, a boss area, the part 5 cases, a dungeon
   tour) before the full run.

5. Parity: every case vs. the baseline: identical at tolerance 0, logs and per-case error and
   leak lines too (the leak lines may only go down if a removed path held a cycle: explain each).
   A `--legacy=<removed name>` run on the battle cases must behave as no flag. With
   `--hide-particles`, the battle cases against a baseline recorded with it.

6. Docs: ARCHITECTURE sections 6, 7 (the fifteen names removed, as the closed phases' entry),
   11, 12 (the minimap's node is the default) and 15 (the legacy paths gone, what stays: the
   legacy state, input and timing for step C); CONVERTING_UI and CONVERTING_PARTICLES; plan 9.4
   (the closing's results, as 9.2 records 4.2's), 8.4 (the minimap), 12, 13, 14 (the table: 4.4
   closed) and the Appendix; HANDOFF (the new state).

7. Prepare the next phase: what plan 14 leaves (4.3: input, audio, saves, the Game autoload;
   step C of the converted modes, the battle's first; phase 5: what still draws through
   Graphics), what step C of the battle needs decided (decisions 3, 6 and 8: the list in plan
   9.4, "Prepared after part 5"), and a recommendation which comes first and why.

Constraints:
- Do not change legacy game logic or content; the node paths' behaviour must stay exactly as it
  is. A port bug found on the way may be fixed as its own listed change with new goldens.
- Legacy files follow PORTING.md; new files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed. Run Godot from bash with < /dev/null. Screenshots need a
  window (not --headless). Ad-hoc runs end themselves (AutoPlay quit, --quit-after-ms).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- the exit crash: the cause, the fix, the runs that show it gone;
- what was deleted and changed (files, line counts per flag), what stays and why (step C's
  legacy state and timing, Graphics' API), the minimap's switch, the red screen;
- the parity results (baseline vs. after, every case; the removed names; the error and leak
  lines);
- anything the plan's list got wrong, and anything that surprised you;
- deliverable 7's preparation and recommendation.

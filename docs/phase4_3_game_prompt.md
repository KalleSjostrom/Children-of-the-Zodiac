Start phase 4.3's second part ("the `Game` autoload") of docs/MODERNIZATION_PLAN.md in this
Godot 4.7 project: the Organizer's place registry, mode switching and state move into a `Game`
autoload, and the 49 `Organizer.getOrganizer()` calls and the field reads of the Organizer go
through it. Nothing the game does may change: every case's shots and logs (`mode=` and
`place=` at every shot and log) stay identical.

Why now: the input wrapper (phase 4.3's first part) is done and closed (plan 9.3, "Results of
the input wrapper"). Plan 9.3, "Prepared after the input wrapper", recommends the autoload
next: parity checks it on every case, it needs no decision while the registry stays main.bank
read at start (decision 5 keeps the `.bank` files as the data), and phase 5 (plan 10) makes the
Organizer this autoload. Step C of the battle waits for decisions 3, 6 and 8; audio and saves
wait for my answers to 9.3's questions.

In scope, in this order:
- The facts (deliverable 1): check plan 9.3's "Prepared after the input wrapper" (and its
  survey, tools/parity/out/_work/game_autoload_survey.md) against the code, and add what the
  move needs: every reader of an info dictionary's keys that the Organizer writes at run time
  (`startNode` from `land<node>`/`air<node>`, even on a mere check; `nextPlace` from
  `updateNextPlaceFor`; `time` from `--start-time`) and whether a later read depends on an
  earlier write; who mutates the dictionaries `getInformationFor` hands out; the frames in
  which a switch happens (`Organizer.update`, `draw`'s loading gate, `Main._update_organizer`'s
  repeats, `Main._sync_world`); every static that holds a mode or the Organizer
  (`Organizer.o`, `MainMenu.menu`, `ImageHandler`'s modes, …) and what `Main._exit_tree` and
  `ExitCleanup` free; the console's and the Cheater's ways into the Organizer; `GameCore`'s
  parts (the input devices, `testDraw`'s pause and pad lost overlay, `exitGame`,
  `setFullScreen`) and where each belongs once `Organizer extends GameCore` is gone.
- The dead code and the ghost entries, as their own change: `Organizer.getGameMode`,
  `continueMusic` and the branch it guards, `GameCore.enterCheat` and its statics, the
  Cheater's `setNext` calls (`update` overwrites `next`) and its unreachable Battle and
  Landscape tests, the five `Values.getClassMap` entries without a class, and `ClassRegistry`'s
  `organizer.Game`, `FPSAnimator`, `GraphicUI`, `Screen` (no files; `organizer.Game` would clash
  with the autoload's name). Grep every removed name.
- The registry (new code, ARCHITECTURE section 3): main.bank read once at start into typed
  places (the `var` substitutions, the names as `Organizer.convert` makes them, the `land::`,
  `land<node>` and `air<node>` prefixes); the run-time changes as an overlay instead of writes
  into the parsed data, with today's effects kept exactly (if a check that leaves `startNode`
  behind changes a later read, keep that and list it). The legacy modes keep reading their
  info as the dictionaries they read today.
- The `Game` autoload (project.godot `[autoload]`, new code): the Organizer's state and rules
  (current and previous mode, the suspended stack, the place asked for last, the loading gate,
  exit after the fade with `finishOff` before the exit mode and place are read, `jump_to`,
  `open_cheater`, the update and the draw) and Main's start flags (`--start`, `--load`,
  `--start-node`, `--start-time`, `--status`). The 49 calls and the field reads (Main's
  `organizer`, AutoPlay's `_state`, `_hidden_state` and positions, the console's
  `_organizer()`) go through it; `place=` keeps its meaning (the place asked for last). The
  music policy stays where it is (`GameMode`), as do the rules inside the modes (the fade's
  `done` set in the draw): they move with step C.
- Prepare what comes next: step C of the battle if I have decided 3, 6 and 8 by then, or
  audio and saves if I have answered 9.3's questions; else a recommendation.

Not in scope: step C of any mode (signals, Tweens, `_process(delta)`; decisions 3, 6, 8 are
open); moving the rules out of `GameMode` (later, with step C); audio and saves (9.3's
questions); a resource file generated from main.bank (decision 5 keeps the `.bank` files; ask
me if the registry seems to need one); phase 5 (`Graphics`, GLBackend); the content quirks and
side findings of the Appendix (an unknown `land<node>` failing, the pause that does not stop
the game: tickets, not this task).

Read first:
- docs/MODERNIZATION_PLAN.md: 9.3 (all of it: the infrastructure, "Prepared after closing phase
  4.2", the input wrapper's facts and results, "Prepared after the input wrapper"), 10, 12
  (above all "Memory during recordings", "A removed flag is silently ignored", "RefCounted
  cycles", "Pending callbacks at quit", "The devices' OR"), 13 (decisions 3 and 5) and 14.
- docs/ARCHITECTURE.md sections 3 (new code style), 4 (the main scene, a mode's scene and its
  lifetime), 6 and 7 (flags, determinism, the parity workflow), 16 (input).
- docs/HANDOFF.md (running Godot, AutoPlay, tools/check.sh, project copies, the memory
  watchdog), docs/PORTING.md (the rules for legacy files you touch), src/main/AutoPlay.gd's
  header.

State:
- Phase 4.3's first part (the input wrapper) is committed. If git status shows it uncommitted,
  stop and tell me. Start from a clean, committed tree; this prompt file doesn't count.
- tools/parity/out holds one set of yours: i2after (the input wrapper's final run: 446 cases,
  11,656 shots; 3 script errors, 2,421 errors and 16 exit leak lines, the same in every case as
  before). c42after is mine; leave it. Record your baseline on the commit you start from and
  compare it with i2after (shots, logs, per-case error and leak lines): it should be identical.
  out/_work holds the helper scripts (errcounts.py; in_base.sh, in_after.sh and in_close.sh:
  a file per group of recording stages, each with its compare; probe_input_patch.py for the probe pattern).
  * Make project copies under tools/parity/out/_<name> with robocopy from PowerShell with
    backslash paths (HANDOFF), never in the session scratchpad. Run the copy's own
    tools/check.sh (0 failed) before you record or probe from it, and keep
    tools/parity/watchdog.ps1 running beside multi-job runs.
  * A full run (446 cases) takes about 35 minutes with 3 jobs at about 5 GB free; check the
    available memory first. Run nothing beside a recording, not even a headless compare or
    tools/check.sh. A full set is about 8 GB; delete intermediate sets once compared and keep
    only your final run at the end. Never edit a script a background run is executing (give
    each stage its own file).
- If the Godot editor is open on the project, close it while recording (it rewrites
  project.godot when it saves, the `[input]` section and a new `[autoload]` one too). If I
  change one of your files while you work, keep my change and tell me.

Decisions (proposed in plan 9.3; change them here before you run this):
- The registry reads main.bank at start (no generated resource file); the run-time changes
  are an overlay.
- The autoload is named `Game` and is new code; `Organizer.gd` is deleted at the end of the
  part (what of `GameCore` stays, and where, is deliverable 1's proposal; ask me if it is not
  obvious).
- No `--legacy=` flag: the Organizer cannot run beside the autoload without doubling its state;
  parity against the baseline after each step is the check.
- Delete, do not comment out: the git history is the archive.

Deliverables, in this order:

0. Baseline: tools/check.sh reports 0 failed; record all cases; compare with i2after.

1. The facts (above), in plan 9.3, where they add to or differ from it; the target layout
   (the autoload's API, what the registry hands out, where `GameCore`'s parts go).

2. The dead code and ghost entries (its own change): a smoke set vs. the baseline.

3. The registry: every case vs. the baseline, identical at tolerance 0, logs and per-case
   error and leak lines too.

4. The `Game` autoload and the calls: every case vs. the baseline, identical. A normal run (no
   `--seed`, the music on) through the title (new game, continue), a village, a store, the
   menu, a labyrinth and the world map, and the console's `goto`, `boss` and `cheater`: the
   same mode switches (`mode=`, `place=`) as the same script on the baseline's code; a real
   Escape (AutoPlay `key Escape`) quits with exit code 0.

5. Docs: ARCHITECTURE (a section for the autoload and the registry; section 4's tree and the
   mode lifetime; section 6's entry points), plan 9.3 (the results, as the input wrapper's are
   recorded), 10, 12, 13, 14, HANDOFF (the new state), the README if the developer options
   change.

6. Prepare the next part: step C of the battle, or audio and saves, by what I have decided;
   else a recommendation.

Constraints:
- Do not change legacy game logic or content; what a mode switch does, and when, must stay
  exactly as it is. A port bug found on the way may be fixed as its own listed change with new
  goldens.
- Legacy files follow PORTING.md; new files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed. Run Godot from bash with < /dev/null. Screenshots need a
  window (not --headless). Ad-hoc runs end themselves (AutoPlay quit, --quit-after-ms). Check
  every run's exit code.
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what the Organizer does today and what the plan had wrong;
- what was built, deleted and changed (files, line counts), and what stays and why;
- the parity results (baseline vs. after, every case, after each step; the error and leak
  lines; the normal run);
- anything that surprised you;
- the next part's preparation and the recommendation.

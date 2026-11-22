Start phase 4.3 ("input, audio, saves, the Game autoload") of docs/MODERNIZATION_PLAN.md
in this Godot 4.7 project with its first part: the input wrapper. Every button the
game reads goes through Godot's InputMap, a thin wrapper keeps `GameAction`'s three
behaviours, and AutoPlay presses buttons through `Input.parse_input_event` instead of
its `FakeInputManager`. Nothing the game does with a button may change: every case's
shots and logs stay identical (AutoPlay drives every case through the input path, key
repeat included). Then prepare the `Game` autoload (the second part) and list what
audio and saves need decided.

Why now: phases 1 to 4.4 are through step B and closed (plan 9.4, "Results of the
closing"): every mode draws through nodes, and what is left before phase 5 is step C
of the converted modes (signals, Tweens, real cameras) and phase 4.3. Step C needs
decisions 3, 6 and 8 (plan 13; the battle's list in 9.4, "Prepared after the
closing") and the input wrapper (9.3: no step B needs it, every step C does); the
wrapper needs no decision and changes no picture. Plan 9.4, "Prepared after the
closing", recommends it first.

In scope, in this order:
- The facts (deliverable 1): how the game reads input today. `src/input` (6 files,
  573 lines): `GameAction` (NORMAL, DETECT_INITAL_PRESS_ONLY, DETECT_AS_KEY_LISTENER:
  once, then after 480 ms every 90 ms, on `J.currentTimeMillis`: the game clock in
  seeded runs), `InputManager` and `InputManagers` (all devices; the lost pad),
  `InputKeyBoardManager` (the keys, Escape, F, 6/7/8 emergency saves),
  `InputGamePadManager` and `GamePadController` (polled every 40 ms), and
  `FakeInputManager` (AutoPlay's). The 130 `gameActions[…]` reads in 22 files, the
  `changeBehavior`/`changeBehaviorBack` calls (who switches a button to key-listener
  repeat, when), `isPressed` vs. `isPressedDontReset`, `resetAllGameActions`, the
  frames in which input is read (Main's order: input, Scheduler, update, draw), the
  developer console's and Main's own keys (`_input`: Alt+Enter, the console key),
  `GameCore.init2` (seeded runs read no pad), the "game pad lost" overlay and the
  console's `padlost`. Where AutoPlay's `press`/`tap`/`release` and `key` enter, and
  which cases hold a button long enough to repeat (menus, stores).
- The InputMap actions (project.godot: one per PlayStation-style button of
  `GameMode`, with today's keys and pad buttons and axes) and the wrapper: the same
  `GameAction` objects fed from the actions (or `GameAction` reading them), so the
  130 call sites stay as they are (step C replaces them). The game pad through
  Godot's joypad events (the 40 ms polling, the stick as directions, the lost pad
  and its overlay kept as they behave). Escape, F, the emergency saves and the
  console key keep working.
- AutoPlay through `Input.parse_input_event` (action events), in the same frame
  and order its scripts press today; `key` (a real key event) as now.
- Delete what the wrapper replaces (the managers' own key and pad mapping, the
  `FakeInputManager` if AutoPlay no longer needs it); grep every removed name.
- Prepare the second part (the `Game` autoload, plan 9.3 and 10): what `Organizer`,
  `GameCore`, `GameMode`, `GameModeQueue` and `ResourceLoader` do today, the 49
  `Organizer.getOrganizer()` calls in 17 files, the place registry from `main.bank`
  (with `land::`, `land<node>`, `air<node>` and `updateNextPlaceFor`), the loading
  gate, the suspended modes, the exit-after-fade rule and the music policy; what
  parity checks of it (every case's `mode=`/`place=`); the order and size.
- List what audio and saves need decided (plan 9.3: the Music autoload and buses;
  the save format: JSON, a Resource, or the text kept with a schema, the shipped and
  the tickets' `.sav` files the user edits by hand) as questions for me.

Not in scope: step C of any mode (decisions 3, 6, 8 are open); the `Game` autoload
itself, audio and saves (prepared, not built); phase 5 (`Graphics`, GLBackend); new
buttons or rebinding UI; the content quirks and side findings of the Appendix.

Read first:
- docs/MODERNIZATION_PLAN.md: 9.3 (the infrastructure, "Prepared after closing phase
  4.2"), 9.4's "Results of the closing" and "Prepared after the closing", 10, 12
  (above all "Memory during recordings", "A removed flag is silently ignored",
  "Pending callbacks at quit"), 13 (decisions 3 and 6) and 14.
- docs/ARCHITECTURE.md sections 3 (new code style), 4 (the main scene and the
  bridge), 6 and 7 (flags, determinism: `--seed`'s game clock and pad, the parity
  workflow).
- docs/HANDOFF.md (running Godot, AutoPlay, tools/check.sh, project copies, the
  memory watchdog), docs/PORTING.md (the rules for legacy files you touch),
  src/main/AutoPlay.gd's header (the script commands).

State:
- Phase 4.4's closing is committed. If git status shows it uncommitted, stop and tell
  me. Start from a clean, committed tree; this prompt file doesn't count.
- tools/parity/out holds one set of yours: z2after (the closing's final run: 446
  cases; see plan 9.4 for its shots and its error and leak lines). c42after is mine;
  leave it. Record your baseline on the commit you start from and compare it with
  z2after (shots, logs, per-case error and leak lines): it should be identical.
  out/_work holds the helper scripts (errcounts.py, close_runs*.sh, close_edit.py,
  battle_cases_close.txt: the 45 cases that draw a battle).
  * Make project copies under tools/parity/out/_<name> with robocopy from PowerShell
    with backslash paths (HANDOFF), never in the session scratchpad. Run the copy's
    own tools/check.sh (0 failed) before you record or probe from it, and keep
    tools/parity/watchdog.ps1 running beside multi-job runs.
  * A full run (446 cases) takes about 35 minutes with 3 jobs at about 5.5 GB free;
    check the available memory first. Run nothing beside a recording, not even a
    headless compare. A full set is about 8 GB; delete intermediate sets once
    compared and keep only your final run at the end. Never edit a script a
    background run is executing (give each stage its own file).
- Do not type while a recording runs: with the wrapper, keyboard events reach a run's
  window through the InputMap too. If the Godot editor is open on the project, close
  it while recording (it also rewrites project.godot's input section when it saves).
  If I change one of your files while you work, keep my change and tell me.

Decisions:
- The button layout stays today's (keys, pad buttons, the stick); a rebinding UI is
  later.
- Key repeat stays `GameAction`'s (480 ms, then 90 ms, on the game clock), not the
  OS's echo events.
- Delete, do not comment out: the git history is the archive.

Deliverables, in this order:

0. Baseline: tools/check.sh reports 0 failed; record all cases; compare with z2after.

1. The facts (above), in plan 9.3, where they add to or differ from it.

2. The InputMap actions and the wrapper, the game pad through Godot's events, AutoPlay
   through `Input.parse_input_event`; a flag `--legacy=input` that keeps today's
   managers and `FakeInputManager` for the parity runs (ARCHITECTURE section 7).

3. Parity: every case with the wrapper vs. the baseline and vs. `--legacy=input`:
   identical at tolerance 0, logs and per-case error and leak lines too. A normal run
   (no `--seed`) with the keyboard and, if you can, with the game pad: the menus'
   repeat, the battle's R2 + L2 flee, the pad lost overlay (ask me to unplug it).

4. The closing of the part: the flag and the replaced managers deleted, grep every
   removed name, a smoke set, then a full run vs. the baseline.

5. Docs: ARCHITECTURE (a section for input: the actions, the wrapper, AutoPlay's
   injection; section 7's flag entry), plan 9.3 (the results, as 9.4 records the
   battle's), 12, 13, 14, HANDOFF (the new state), the README's key list if it
   changes.

6. Prepare the next part: the `Game` autoload's survey, order and size, and the
   questions for audio and saves (above); a recommendation what comes next (the
   autoload, or step C of the battle if I have decided 3, 6 and 8 by then).

Constraints:
- Do not change legacy game logic or content; what a button does, and when, must stay
  exactly as it is. A port bug found on the way may be fixed as its own listed change
  with new goldens.
- Legacy files follow PORTING.md; new files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed. Run Godot from bash with < /dev/null.
  Screenshots need a window (not --headless). Ad-hoc runs end themselves (AutoPlay
  quit, --quit-after-ms). Check every run's exit code.
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- how input is read today and what the plan had wrong;
- what was built, deleted and changed (files, line counts), and what stays and why;
- the parity results (baseline vs. after, every case; the flag; the error and leak
  lines; the normal runs);
- anything that surprised you;
- the next part's preparation, the questions for audio and saves, and the
  recommendation.

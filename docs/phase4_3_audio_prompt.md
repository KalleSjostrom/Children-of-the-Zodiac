Start phase 4.3's third part ("audio") of docs/MODERNIZATION_PLAN.md in this Godot 4.7
project: the music moves from `OggStreamer`'s 100 ms fade steps and its finished signal to a
`Music` autoload (intro and loop, Tween fades, the FAST, SLOW and HALF rules) and the sound
effects to an SFX bus, with the music policy of the mode switches kept exactly. Nothing the
game shows may change: every case's shots and logs stay identical; what you hear changes only
as the decisions below say.

Why now: the `Game` autoload (phase 4.3's second part) is done (plan 9.3, "Results of the Game
autoload"). Plan 9.3, "Prepared after the Game autoload", recommends audio next: the switches
are `Game`'s now, so the music policy that `GameMode` applies at each switch has one caller
to follow; parity cannot check sound (its runs are `--mute`), so this part brings its own
check (an audio log). Saves wait for my answers to 9.3's questions; step C of the battle for
decisions 3, 6 and 8.

In scope, in this order:
- The facts (deliverable 1): check plan 9.3's audio list and questions against the code and
  add what the move needs: `OggStreamer`'s fade (the step every 100 ms of game time,
  `_incrementVolume`'s law, `fadeThreads`: a second fade of the same track ends the first),
  its pause, resume and kill, the intro's `finished` and the loop; who makes and keeps a
  player (`GameMode._initMusic`'s "continue" and same-track reuse of the previous mode's
  player, `switchMusic`, `BattleManager`, `BossBattleArea`, `VillageStoryTimeLine`'s own
  players, the menu's HALF), when each starts (`Scheduler.waitUntil`: the previous one faded
  down and the mode loaded), `GameMode.mute` and `--mute` (no player is made at all),
  `Values`' music and sound settings (`HelpPage`'s volume options never match: Appendix),
  `SoundPlayer`'s pool of 12 and its volumes, `OggStreamer.tickAll` in `Main._process`,
  `stopAll` at quit and at the window's close, and what `Main._exit_tree` and `ExitCleanup`
  free. Which cases make music and which sounds (with the music on).
- The audio log (new code, dev only): `--audio-log` prints every music and sound call (the
  track or sound, the game time, the fade's kind, length and target, the volume when it ends,
  pause, resume, kill), comparable between runs. Record it on every case before the change
  with the music on (no `--mute`) and Godot's Dummy audio driver (`--audio-driver Dummy`, an
  engine option: no device, the players still run); check first that such runs give the same
  shots and logs as the `--mute` set (if not, list why: the music's `Scheduler` waits,
  `isMusicFadingDown` gates).
- The `Music` autoload (project.godot `[autoload]`, new code, ARCHITECTURE section 3) and the
  buses (`default_bus_layout.tres`: Master, Music, SFX): the players, the intro and loop, the
  fades as the decisions say, the volume steps; `OggStreamer`'s callers go through it (or
  `OggStreamer` becomes a thin legacy facade over it, if that keeps the call sites: say
  which). `SoundPlayer` plays on the SFX bus. The policy (continue, the same track, FAST,
  SLOW, HALF) stays in `GameMode` and calls the autoload; moving it out is step C.
- Mind ARCHITECTURE section 17, "Tools": a `--script` tool that names a game class must be a
  launcher of a `_job.gd`; a second autoload is instantiated in every `--script` run too.
- Prepare what comes next: saves if I have answered 9.3's questions, step C of the battle if I
  have decided 3, 6 and 8; else a recommendation.

Not in scope: the switch policy itself (kept exactly unless the decisions say otherwise);
volume options in the menu (a new UI: decision 8's, later); `TODO.md`'s audio items (the
world map's water sound, two tracks at the Zodiac place after the shadow bosses, the cards'
and hits' sounds: tickets after this part, with the audio log as their check); saves; step C;
phase 5.

Read first:
- docs/MODERNIZATION_PLAN.md: 9.3 (the audio item, "Prepared after closing phase 4.2", "How
  the Organizer worked before the autoload", "Results of the Game autoload", "Prepared after
  the Game autoload" with the audio questions), 10, 12 (above all "Memory during recordings",
  "Parity cannot see what no case does", "Pending callbacks at quit", "Tools compiled before
  the autoloads"), 13 (decisions 6 and 8) and 14.
- docs/ARCHITECTURE.md sections 3 (new code style), 4 (the main scene; Audio), 6 and 7
  (flags, determinism, the parity workflow), 17 (the Game autoload, "Tools").
- docs/HANDOFF.md (running Godot, AutoPlay, tools/check.sh, project copies, the memory
  watchdog), docs/PORTING.md (the rules for legacy files you touch), src/sound/*.gd,
  src/organizer/GameMode.gd's music, src/main/AutoPlay.gd's header.

State:
- Phase 4.3's second part (the `Game` autoload) is committed. If git status shows it
  uncommitted, stop and tell me. Start from a clean, committed tree; this prompt file doesn't
  count.
- tools/parity/out holds one set of yours: g3game (the autoload's final run: 446 cases,
  11,656 shots; 3 script errors, 2,421 errors and 16 exit leak lines, the same in every case
  as before). c42after is mine; leave it. Record your baseline on the commit you start from
  and compare it with g3game (shots, logs, per-case error and leak lines): it should be
  identical. out/_work holds the helper scripts (errcounts.py; g_base.sh, g_dead.sh, g_reg.sh,
  g_game.sh: a file per group of recording stages, each with its compare; norm_game.txt and
  norm_game.sh: the normal run through the title, a village, a store, the menu, a labyrinth,
  the world map and the console's jumps, with an APPDATA of its own; tooltest.sh: the split
  tools run in a copy).
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
  project.godot when it saves: the `[input]` and `[autoload]` sections). If I change one of
  your files while you work, keep my change and tell me.

Decisions (proposed in plan 9.3; change them here before you run this):
- The fades (question 1): Tweens in the `Music` autoload, every frame on the game clock, over
  the same lengths (FAST 1500 ms, SLOW 2500 ms, the menu's HALF 0.6 of full) and the same
  curve (`_incrementVolume`'s law as a function of time), not the 100 ms steps.
- The intro and the loop (question 2): gapless (`<Name>1.ogg` then `<Name>2.ogg` looped
  without the frame's gap: an `AudioStreamInteractive` that auto-advances, or what the facts
  show works); a track without a second part loops its first, as now.
- Buses (question 3): Master, Music and SFX; volume options in the menu later (a new UI).
- The switch policy (question 4): kept exactly.
- The check (question 5): the audio log on every case before and after (the same calls,
  times within a frame, fades with the same lengths and targets), then I listen to a list of
  transitions you give me (the title to a new game, a village to a store and back, the menu
  over a labyrinth, a battle's start and end, a cutscene that continues the music).
- `TODO.md`'s audio items (question 6): tickets after this part.
- No `--legacy=audio` flag unless the facts show the old path must run beside the new one
  for the check; delete, do not comment out: the git history is the archive.

Deliverables, in this order:

0. Baseline: tools/check.sh reports 0 failed; record all cases; compare with g3game.

1. The facts (above), in plan 9.3, where they add to or differ from it; the target layout
   (the autoload's API, the buses, what stays in `OggStreamer`, `SoundPlayer` and
   `GameMode`).

2. The audio log and the Dummy-driver runs: the log on every case on the baseline's code;
   the shots and logs of those runs vs. the baseline (identical, or the differences
   explained).

3. The `Music` autoload, the buses and the callers: every case vs. the baseline, identical
   (shots, logs, per-case error and leak lines); the audio log vs. the baseline's, the
   differences only the decisions' (listed by kind and count). A normal run (no `--seed`,
   the music on, a real audio device) through the transitions above: no error, exit code 0,
   and the list for me to listen to.

4. Docs: ARCHITECTURE (a section for the audio autoload and the buses; section 4's tree;
   section 6's entry points; section 7's flags: `--audio-log`), plan 9.3 (the results, as the
   autoload's are recorded), 10, 12, 13, 14, HANDOFF (the new state), the README if the
   developer options change.

5. Prepare the next part: saves, or step C of the battle, by what I have decided; else a
   recommendation.

Constraints:
- Do not change legacy game logic or content; what a mode switch does to the music, and
  when, must stay as it is (only the decisions' changes). A port bug found on the way may be
  fixed as its own listed change.
- Legacy files follow PORTING.md; new files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed. Run Godot from bash with < /dev/null. Screenshots need a
  window (not --headless). Ad-hoc runs end themselves (AutoPlay quit, --quit-after-ms). Check
  every run's exit code. A normal run's saves go to an APPDATA scratch folder, never to my
  user://saves/.
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- how the music and sounds work today and what the plan had wrong;
- what was built, deleted and changed (files, line counts), and what stays and why;
- the parity results (baseline vs. after, every case; the error and leak lines; the audio
  log's differences; the normal run);
- the transitions for me to listen to;
- anything that surprised you;
- the next part's preparation and the recommendation.

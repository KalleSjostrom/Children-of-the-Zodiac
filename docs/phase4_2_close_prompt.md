Close phase 4.2 ("title, game over, mini-games, stores, menu") of docs/MODERNIZATION_PLAN.md in
this Godot 4.7 project: delete the legacy drawing that its eleven `--legacy=` flags keep, the
flags themselves, and the code that only those paths reach. Step B is done for every part of
the phase (plan 9.2: the pilot, the menu, the stores, the mini-games); the node paths are the
default and have passed parity against the legacy paths, so closing must not change a pixel.

Why now: the flags double every converted call site and every later parity run; phases 1 to 4.1
were closed the same way (plan 6.9, 7.9, 8.4, 9.1). The battles (phase 4.4) still draw through
some of the shared legacy helpers: those stay.

In scope, in this order:
- The eleven flags and their legacy branches, flag by flag: title, game_over, menu_list,
  menu_frame, menu_text, status, deck, automap, dim, bless, riddle. Plan 9.2's "Closing phase
  4.2" lists, per flag, every `Main.is_legacy` call site, the legacy branch it keeps, the helpers
  that only those branches reach (they go too), the helpers other callers still need (they
  stay) and the cases that cover each part.
- The wrappers that only chose between the two paths become plain calls of the twin, or the
  twin moves into its caller where that is the only one (AbstractPage.draw_list, draw_title,
  draw_help, StartPage.draw_screen_shot, draw_info, StatusPage.draw_top, AbstractStore.draw_dim,
  RiddleGame.draw_dim, DeckPage/CardStore's _draw_deck and _draw_bar, …). Keep the bridge
  members' names (snake_case, ARCHITECTURE section 6) where they stay.
- Dead code the closing exposes: the unreachable StatusPage and BestiaryPage pages (plan
  Appendix: opened only from themselves, `MainMenu.initStatusPage`/`initBestiaryPage`) keep
  `StatusPage.draw`, `drawTop`, `drawAttributes`, `drawSlots`, `StartPage.drawInfo`,
  `drawScreenShot` and `MenuNode.drawAllChildren` referenced: delete the two pages' drawing (or
  the pages with their init functions; check what else references them first), and the
  helpers they alone kept. `CardStore.drawMergedCard` (never called) and the Church's
  "Resurrect" branch (no menu entry) go as well.
- The Cheater (dev only, the console's `cheater`): `Cheater.draw` calls `MenuNode.drawChildren`,
  the last caller of `MenuNode.draw`, `drawChildren` and (through them) `MenuHand.drawHand` and
  `MenuScrollBar.draw` once the flags are gone. Switch it to `MenuNode.show_children` (written
  for drawChildren and never called yet), so that the legacy list drawing can go; add a shot of
  the Cheater's menu to a case first (12 store cases pass through it, none shoots it) and record
  it before the switch.

Not in scope: the battles (phase 4.4) and the legacy helpers they call, which stay:
`Graphics.drawWithShadow` (the result and spoils screens, `Attack`, `Clock`),
`AbstractCard.drawCard` (`ResultScreen`), `Graphics.fadeOldSchool` (`Screen`), `LevelUpBar.draw`
with drawImage's 7-argument part (`SpoilsScreen`); the battle effects' flags (`battle_effects`,
`effect_waits`); `Graphics`' own API (it goes whole in phase 5: leave its methods even where no
game code calls them any more, e.g. `drawStringRightWithReg`, `drawSingleCenteredText`, which
tools/render_test.gd uses); the minimap on the 3D bridge; step C; the content quirks and side
findings of the Appendix (selling a sell list's last weapon, `Puzzle`'s scramble, the Church's
save list spacing, "Paused" stopping nothing): tickets, not this task.

Read first:
- docs/MODERNIZATION_PLAN.md: 9.2, above all "Closing phase 4.2" (the list this task works
  from) and the Results of the pilot, the menu, the stores and the mini-games (what each flag
  keeps and the cases that cover it); 6.9, 7.9, 8.4 and 9.1 (how the earlier closings were done
  and recorded); 12 ("Shared legacy helpers", "Pooled UI nodes"), 13, 14 and the Appendix.
- docs/ARCHITECTURE.md, sections 6 (the bridge members), 7 (the flag table), 12 ("Flags
  (removed)": the pattern for a closed phase) and 14 (the title, the game over, the menu, the
  stores, the riddles).
- docs/CONVERTING_UI.md section 5, docs/HANDOFF.md (running Godot, AutoPlay, tools/check.sh,
  recording from a project copy), docs/PORTING.md (the rules for legacy files you touch).

State:
- The mini-games' part is committed: src/miniGames, scenes/ui/LevelBar.gd, the riddle_*
  cases and their scripts. If git status shows them uncommitted, stop and tell me. Start
  from a clean, committed tree; this prompt file doesn't count.
- tools/parity/out holds one set: r3node (the mini-games' node run: 427 cases, 8,083
  shots, identical to their golden). Record your baseline on the commit you start from and
  compare it with r3node (shots, logs, per-case error and leak lines): it should be
  identical. out/_work holds the helper scripts (errcounts.py: per-case error and leak line
  counts of two sets; flags.sh, flags_riddle.sh, fps scripts as examples) and
  close42_list.md, the survey behind plan 9.2's list with file:line references (as of the
  mini-games; check them against the code you start from).
  * Make project copies under tools/parity/out/_<name> with robocopy (HANDOFF), never in the
    session scratchpad.
  * A full run (427 cases) takes about 23 minutes with 4 jobs. Check the free memory first
    (about 6 GB free at idle during the mini-games: 4 jobs were reliable); run nothing beside a
    recording, not even a headless compare. Only the effects_* cases print an exit leak report.
  * A full set is about 5.6 GB; delete intermediate sets once compared and keep only your final
    run at the end.
- Phases 1 to 4.1 are closed; after this only the battle effects' flags remain.
- Do not type while a recording runs. If the Godot editor is open on the project, close it
  while recording. If I change one of your files while you work, keep my change and tell me.

Decisions:
- No open decision of plan section 13 is needed (closing changes no picture and no timing).
- Delete, do not comment out: the git history is the archive.

Deliverables, in this order:

0. Baseline: tools/check.sh reports 0 failed; record all cases; compare with r3node.

1. The Cheater's shot: a case (or a shot in an existing store case) that shows the Cheater's
   menu; record it on the unchanged code (twice: identical).

2. The closing, flag by flag (tools/check.sh 0 failed after each): the legacy branches, the
   flags, the wrappers, the dead helpers and pages, the Cheater's switch. grep for every
   removed name (callers in src/, scenes/, tools/; strings in AutoPlay scripts and cases.txt).
   A smoke set of a few cases (a title, the menu, a store, the bless page, a riddle, the game
   over) before the full run: headless checks miss some failures.

3. Parity: every case vs. the baseline: identical at tolerance 0, logs and per-case error and
   leak lines too; the Cheater's shot identical to deliverable 1's. No new exit leak report. A
   `--legacy=<removed flag>` run must behave as no flag (Main.is_legacy only knows the battle
   effects' flags).

4. Docs: ARCHITECTURE sections 6, 7 (the eleven flags removed, as the closed phases' entry),
   12 and 14 (the legacy paths gone, what stays for the battles, the Cheater on MenuList);
   CONVERTING_UI section 5; plan 9.2 (the closing's results, as 6.9 records phase 1's), 12, 14
   (the table: 4.2 closed) and the Appendix; HANDOFF (the new state).

5. Prepare the next phase: what plan 14 leaves (4.3: input, audio, saves, the Game autoload; 4.4:
   the battles), what the closing left for the battles (the shared helpers kept, their callers),
   and a recommendation which comes first and why, in plan 9.3/9.4.

Constraints:
- Do not change legacy game logic or content; the node paths' behaviour must stay exactly as it
  is. A port bug found on the way may be fixed as its own listed change with new goldens.
- Legacy files follow PORTING.md; new files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed. Run Godot from bash with < /dev/null. Screenshots need a
  window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what was deleted and changed (files, line counts per flag), what stays and why (the battles,
  Graphics' API), the Cheater's switch;
- the parity results (baseline vs. after, every case; the Cheater's shot; the error and leak
  lines);
- anything the plan's list got wrong, and anything that surprised you;
- deliverable 5's preparation and recommendation.

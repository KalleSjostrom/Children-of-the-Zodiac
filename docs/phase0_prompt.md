Implement phase 0 ("groundwork") of docs/MODERNIZATION_PLAN.md in this Godot 4.7 project.

Read first: docs/MODERNIZATION_PLAN.md (sections 3, 4, 5 and 11), docs/HANDOFF.md
(how to run Godot, AutoPlay and tools/check.sh) and docs/PORTING.md. The project is a
1:1 port of a Java/JOGL game. Everything renders through an OpenGL 2 emulation
(src/graphics/Graphics.gd + GLBackend.gd), called from src/main/Main.gd.

Phase 0 converts no content and must not change how the game looks or plays. Its job
is to make later phases safe. There are four deliverables, in this order. Do (1)
before touching rendering, so (2) can be checked against goldens recorded on
unmodified code.

1. Deterministic runs + parity tool (tools/parity/)
   - A deterministic mode, e.g. `--seed=<n>` together with the existing
     `--fixed-step`, that makes two runs of the same AutoPlay script produce the same
     screenshots. Known sources of nondeterminism:
     * Unseeded randomness: J._rng (src/util/J.gd), every JRandom.new() without a
       seed (82 call sites; derive their seeds from one seeded generator), and 11
       direct randf/randi calls.
     * Wall-clock reads that bypass the game's elapsed time: J.currentTimeMillis()
       and Time.get_ticks_msec() in util/Scheduler.gd, input/GameAction.gd,
       organizer/GameCore.gd, landscape/Landscape.gd, villages/VillageLoader.gd,
       store/Inn.gd and battle/enemy/BattleEnemy.gd.
     In deterministic mode these should read a game clock advanced by Main's elapsed
     time. Normal play must behave exactly as now.
   - A script (bash wrapper + a headless Godot script for the image diff, so no
     Python packages are needed) that:
     * runs an AutoPlay script under two argument sets (e.g. with and without
       `--legacy=<subsystem>`);
     * compares the screenshots pairwise with a tolerance;
     * writes diff images and a pass/fail summary.
     Screenshots need a window (not --headless).
   - Record goldens for the existing scripts in tools/autoplay/ (at least
     village_walk, village, story_long, newgame_to_forest, battle, stores,
     menu_pages, landscape). Prove a self-diff of two runs is 0, or near 0 with
     every remaining difference explained.

2. The bridge: a game mode can own a Godot scene
   - Main.tscn gets the tree from plan section 4:
     * World: the active mode's scene goes here;
     * LegacyLayer (CanvasLayer 1) with a Node2D child: GLBackend parents its canvas
       items to that Node2D instead of to Main (GLBackend._init uses
       host.get_canvas_item(); the 3D SubViewports can stay children of Main);
     * UI (CanvasLayer 2) and Transition (CanvasLayer 3): empty for now.
   - GameMode gets `var scene_root: Node` and `func create_scene() -> Node`, which
     returns null by default. Facts to verify before relying on them:
     * Modes are created in Organizer._initNext and pushed onto GameModeQueue when
       suspended.
     * _goBackToSuspendedMode pops the stack or swaps current/previous (the Cheater
       path).
     * Modes are RefCounted (GameMode → Fadeable → RefCounted) and are never
       explicitly freed; they are just dropped.
     * Organizer.draw does nothing while the mode isLoading().
   - Visibility rule, synced every frame:
     * World shows the current mode's scene_root only when the mode exists and is
       not loading. Otherwise the scene flashes unfaded during the black loading
       screen.
     * Suspended/previous modes' scenes are removed from the tree but not freed, so
       their state survives store/menu/battle round trips.
     * A mode's scene is freed when the mode is freed (NOTIFICATION_PREDELETE).
       Scene nodes must not hold strong references to their mode: that is a cycle
       that would leak both.
   - `--legacy=<comma list>` flag plus a helper (e.g. `Main.is_legacy("villages")`)
     that later phases use to keep the old path for parity runs. Nothing uses it
     yet.
   - Verify with the parity tool against the goldens from (1): every script must
     match. The reparenting must be invisible.

3. Bridge test (dev only, behind `--bridge-test`)
   - Village.create_scene() returns tools/bridge_test/BridgeTest.tscn. It contains:
     * a full-screen coloured panel;
     * a label that counts frames, to prove the node keeps its state;
     * a current Camera2D with a non-zero offset.
   - The village skips only its background tiles (DoubleBackground.drawBottom).
     Everything else stays legacy-drawn on top: sprites, roofs, emotions, dialogs,
     fades.
   - tools/autoplay/bridge_test.txt (`--load="Slot 1" --start=<a town>`) takes shots
     that show:
     * the fade-in covering the scene;
     * walking: the legacy sprites and roofs over the scene, unmoved by the
       Camera2D;
     * a dialog;
     * entering and leaving a store, with the scene gone and then back with its
       counter continued;
     * opening the menu, with the thumbnail including the scene;
     * leaving to the world map, after which World is empty and the scene was freed
       (log it).

4. Docs
   - Write docs/ARCHITECTURE.md: conventions for new (non-legacy) code. Cover:
     * typed GDScript, snake_case, one scene per concept, signals;
     * no J.* helpers in new code;
     * the folder layout from plan section 4;
     * the data → presentation → logic steps;
     * how new code calls legacy code (Java-named API) and vice versa;
     * the flags (--seed, --fixed-step, --legacy, --bridge-test) and the parity
       workflow.
   - Point PORTING.md and HANDOFF.md to it.
   - Update HANDOFF.md with the phase 0 state.
   - If anything you find contradicts the plan, update docs/MODERNIZATION_PLAN.md
     and tell me.

Constraints:
- Do not convert any village, dungeon or other content. Do not make the plan's open
  decisions (section 13).
- Do not change gameplay or timing in normal runs. Determinism hooks apply only in
  deterministic mode.
- Keep the PORTING.md rules for legacy files you touch (Java names, no
  redesign). Follow ARCHITECTURE.md for new files.
- tools/check.sh must report 0 failed. Run Godot from bash with `< /dev/null`.
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why);
- the parity results: goldens vs. after, plus the self-diff;
- any nondeterminism that remains and why;
- the bridge test screenshots you checked and what each showed;
- anything that surprised you or that the plan got wrong.
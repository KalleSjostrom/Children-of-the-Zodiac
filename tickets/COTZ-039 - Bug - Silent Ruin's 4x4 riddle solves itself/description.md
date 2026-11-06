The riddle at node 86 in Silent Ruin accepts any arrangement.

**Priority:** Medium (triage D3). The Java has the same check (`RubicsPuzzle19.java`).

**Where:** `maps/Labyrinth/Silent Ruin--The Great Ruins.map:192` `inv riddle 86 3 1 Images/1-9small.png puzzle44 RubicsPuzzle19 ...`: it uses the 4×4 tile set. `src/miniGames/RubicsPuzzle19.gd` checks the magic square only for N = 3 (sum 15) and N = 5 (sum 65); for N = 4 `found` stays false, which counts as solved.

**Effect:** any key solves it.

**Fix idea:** add the 4×4 case (34 for the numbers 1–16; check which numbers the `puzzle44` set holds). Then check that the puzzle's start can reach a magic square with its moves, or the riddle becomes unsolvable.

**Note (2026-11-06):** the `.vil` and `.map` files this ticket names are deleted (decision 5; `docs/MODERNIZATION_PLAN.md` 6.9, 7.9, 9.1; the git history up to aab714c9 has them). Their data is in the scenes, which a fix edits: a village variant in `scenes/villages/<Place>/<file>.tscn`, a floor in `scenes/dungeons/<Area>/<Floor>.tscn` (with `resources/dungeon_layouts/` and `resources/dungeon_styles/`), a world map in `scenes/world_map/<file>.tscn`. The line numbers above are the old files'.

Frozen Forest--Forest Passage has eight `dir` lines twice, and the dungeon scene keeps the extra count.

**Priority:** Low (triage D8). The Java original has the same repeats.

**Where:** `maps/Labyrinth/Frozen Forest--Forest Passage.map`, repeated: `dir 137 1 153`, `141 1 157`, `153 1 169`, `157 1 173`, `169 2 170`, `170 2 171`, `171 2 172`, `172 2 173`. `scenes/dungeons/DungeonCell.gd:41` `extra_links` keeps the legacy count.

**Effect:** the repeated links count as neighbours, which picks other carpet and pillar shapes for those cells.

**Fix idea:** drop the repeated lines and the `extra_links` count, if the shapes then look right (compare shots of those cells before and after).

**Note (2026-11-06):** the `.vil` and `.map` files this ticket names are deleted (decision 5; `docs/MODERNIZATION_PLAN.md` 6.9, 7.9, 9.1; the git history up to aab714c9 has them). Their data is in the scenes, which a fix edits: a village variant in `scenes/villages/<Place>/<file>.tscn`, a floor in `scenes/dungeons/<Area>/<Floor>.tscn` (with `resources/dungeon_layouts/` and `resources/dungeon_styles/`), a world map in `scenes/world_map/<file>.tscn`. The line numbers above are the old files'.

Frozen Forest--Forest Passage has eight `dir` lines twice, and the dungeon scene keeps the extra count.

**Priority:** Low (triage D8). The Java original has the same repeats.

**Where:** `maps/Labyrinth/Frozen Forest--Forest Passage.map`, repeated: `dir 137 1 153`, `141 1 157`, `153 1 169`, `157 1 173`, `169 2 170`, `170 2 171`, `171 2 172`, `172 2 173`. `scenes/dungeons/DungeonCell.gd:41` `extra_links` keeps the legacy count.

**Effect:** the repeated links count as neighbours, which picks other carpet and pillar shapes for those cells.

**Fix idea:** drop the repeated lines and the `extra_links` count, if the shapes then look right (compare shots of those cells before and after).

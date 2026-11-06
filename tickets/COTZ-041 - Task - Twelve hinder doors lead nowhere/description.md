Twelve hinder doors lead to `_`: locked doors that go nowhere, probably scenery.

**Priority:** Low (triage D6; it counted ten). The Java original has the same doors.

**Where:**

* `Forest of Reil--Forest Path.map:43` (node 111)
* `Menthu's Lair--Room of Doubt.map:53` (148), `Menthu's Lair--Room of Turmoil.map:60` (62)
* Pensara Prison's side cells: Floor 1:41 (153), Floor 2:37-38 (57, 153), Floor 3:41 (57), Floor 4:37-38 (57, 153), Floor 5:38 (57), Floor 6:41-42 (57, 153)

**Fix idea:** none, unless one of them should open. Close as intended otherwise.

**Note (2026-11-06):** the `.vil` and `.map` files this ticket names are deleted (decision 5; `docs/MODERNIZATION_PLAN.md` 6.9, 7.9, 9.1; the git history up to aab714c9 has them). Their data is in the scenes, which a fix edits: a village variant in `scenes/villages/<Place>/<file>.tscn`, a floor in `scenes/dungeons/<Area>/<Floor>.tscn` (with `resources/dungeon_layouts/` and `resources/dungeon_styles/`), a world map in `scenes/world_map/<file>.tscn`. The line numbers above are the old files'.

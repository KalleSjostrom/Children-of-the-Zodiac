Two leftover dungeon floors that nothing leads to.

**Priority:** Low (triage D7). Both are in the Java original.

**Where:**

* `maps/Main/main.bank:441-443`: the Fire Cavern--First Floor `-mark0`, `-mark1` and `-save` places name `Fire Cavern--First Floor.map`, which does not exist. Nothing else names the floor.
* `maps/Labyrinth/Boss--Test.map` and `scenes/dungeons/Boss/Test.tscn`: no place, size line or textures (the converter warns about it; `tools/parity/cases.txt:193`).

**Fix idea:** delete the three main.bank lines and the test floor (`.map`, `.tscn`), and the note in cases.txt.

**Note (2026-11-06):** the `.vil` and `.map` files this ticket names are deleted (decision 5; `docs/MODERNIZATION_PLAN.md` 6.9, 7.9, 9.1; the git history up to aab714c9 has them). Their data is in the scenes, which a fix edits: a village variant in `scenes/villages/<Place>/<file>.tscn`, a floor in `scenes/dungeons/<Area>/<Floor>.tscn` (with `resources/dungeon_layouts/` and `resources/dungeon_styles/`), a world map in `scenes/world_map/<file>.tscn`. The line numbers above are the old files'.

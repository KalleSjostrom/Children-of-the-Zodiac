Two leftover dungeon floors that nothing leads to.

**Priority:** Low (triage D7). Both are in the Java original.

**Where:**

* `maps/Main/main.bank:441-443`: the Fire Cavern--First Floor `-mark0`, `-mark1` and `-save` places name `Fire Cavern--First Floor.map`, which does not exist. Nothing else names the floor.
* `maps/Labyrinth/Boss--Test.map` and `scenes/dungeons/Boss/Test.tscn`: no place, size line or textures (the converter warns about it; `tools/parity/cases.txt:193`).

**Fix idea:** delete the three main.bank lines and the test floor (`.map`, `.tscn`), and the note in cases.txt.

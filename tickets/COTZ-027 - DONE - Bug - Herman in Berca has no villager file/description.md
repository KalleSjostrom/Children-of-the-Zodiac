Berca - 1 names a villager Herman, but there is no `Herman.char` and no Herman images anywhere in the project.

**Priority:** Medium (triage V2). The Java original has the same line.

**Where:** `maps/Village/Berca/Berca - 1.vil:233` `villager Herman`.

**Effect:** a script error every update (1,464 in the `tour_berca_1` parity log: `getExtraDirection` on null). Herman is not shown.

**Repro:** `--load="Slot 1" --start="Berca" --status="Berca:1"` (parity case `tour_berca_1`).

**Fix idea:** remove the line (and from the village's `.tscn` under `scenes/villages/Berca/`), or write Herman: a `.char` and images.

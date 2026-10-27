In Silent Ruin--The Great Ruins, the door at node 29 leads to `-mark12`, a place main.bank lacks.

**Priority:** High (triage D1): the player reaches it, and unsaved progress is lost. The Java original has the same data.

**Where:** `maps/Labyrinth/Silent Ruin--The Great Ruins.map:178` `inv door 29 1 dontopen Silent_Ruin--The_Great_Ruins-mark12` (and the floor's `.tscn`); main.bank has `-mark0` to `-mark11` only (`maps/Main/main.bank:471-482`).

**Effect:** using the door drops the game to the title screen ("unknown place").

**Repro:** `--load="Slot 1" --start="Silent Ruin--The Great Ruins-mark11" --seed=1`: mark11 is the start at door 29 itself (see below), so turn round and use the door.

**Fix idea:** add the missing place:
`place mode="4" name="Silent Ruin--The Great Ruins-mark12" start="12" music="Silent Cave" map="Silent Ruin--The Great Ruins.map"`.
A start index is the door's position in load order (`InventoryDoor.doorCount`, which hinder doors share; `Graph.doorLocation`). The floor's doors come in pairs: door 19 → mark2 ↔ hinder door 35 → mark1, ..., door 29 → mark12 ↔ hinder door 45 → mark11. So start 12 is the 13th door, hinder door 45, and the door at 29 should take the player there. Check that the `.tscn`'s door order matches the `.map`.

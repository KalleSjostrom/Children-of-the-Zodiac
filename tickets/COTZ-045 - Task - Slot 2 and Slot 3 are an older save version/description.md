The shipped saves "Slot 2" and "Slot 3" come from an older data version.

**Priority:** Low (triage G1). Both files are identical to the Java original's.

**Where:** `maps/Banks/Slot 2.sav`, `maps/Banks/Slot 3.sav`.

**Effect:** their labyrinth nodes no longer exist: loading asserts for each one (22 for "Slot 2") and goes on, at Dellna on the world map (Java quit the game). In the editor that is 22 debugger stops.

**Related, from reading the code (not checked in play):** `Load.parseFile` falls back to `maps/Banks/` when `user://saves/` has no such slot, and the title screen's Continue lists Slot 1–3 always (`SaveSlots.loadable`). So on a fresh install, an "Empty" slot may load the shipped dev save of that name ("Slot 1" is far into the game).

**Fix idea:** delete them, or strip the stale `node` lines. Check whether the Continue list should load the shipped saves at all.

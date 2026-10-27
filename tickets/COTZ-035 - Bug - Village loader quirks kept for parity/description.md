Three village loader behaviours from the Java, kept so the port matched it.

**Priority:** Low (triage V10). Not checked in play.

**Where:** `src/villages/VillageLoader.gd` and the village converter (docs/MODERNIZATION_PLAN.md 6.3).

**Effect:**

* A two-line sign is listed twice.
* A taken loot's `lootLine`s go to the previous loot.
* Unknown commands and stray text are ignored silently (that is how COTZ-031's typos went unseen).

**Fix idea:** a loader fix each. Each changes parity for the villages concerned. A warning for unknown commands would have caught COTZ-031.

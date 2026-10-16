# Port notes: cards-store

Files ported in this round: `character/Bestiary.gd`, `character/Enemy.gd`,
`store/Church.gd`, `store/Door.gd` (class_name `StoreDoor`), `store/Inn.gd`,
`store/WeaponStore.gd`. (`cards/offense`, `cards/support`, `equipment`,
`Character`, `Creature`, `AbstractStore`, `Building`, `CardStore` were
already ported and left unchanged.)

`tools/check.sh src/cards/offense src/cards/support src/character src/store src/equipment`
→ `CHECKED 39 scripts, 0 failed`.

## API notes for callers

* `Bestiary.getBestiary()` – lazily created singleton.
* `Bestiary.getStats(x = null)` merges the Java overloads: no argument → the
  `Dictionary` int → `Bestiary.Stats` (used by Save); `int` → the index:th
  added enemy; `String` → by enemy db name; an `Enemy` → by its db name.
* `Bestiary.Stats.getInfo()` returns an Array of Strings (the Java debug
  prints were dropped).
* `Enemy.getCardPreference(name)` returns -1 when there is no preference.
  Card preference maps are Dictionaries (String → int).
* `Enemy.copy()` copies via `get_script().new(...)` (same as `new Enemy`).
* `StoreDoor.LOCKED == -1`; `getMode()` returns -1 when locked.
  `getToPos()` returns null or a 4-element float Array (Java order kept).
* `Church.mode` / `WeaponStore.mode` are `mode_` (GameMode.mode is a
  different variable), see skeleton_report.
* `Inn.prizes` is created lazily in `Inn.init` (Java: static initializer),
  because `Card.createCard` needs other classes' static state.

## Not ported 1:1

* `Inn.checkExit()`: Java blocked the main loop for 7 s
  (`Values.sleep(7000)`) after the fade when the party slept. Here the exit is
  postponed for 7 s instead (`NO_MODE_IS_SELECTED` is returned until 7 s
  after the mode was first seen done), and `Inn.update` ignores input during
  that time. The screen keeps being drawn (faded) instead of freezing.
* Inn's "sleep sound" thread → `Scheduler.after(100, …)` +
  `Scheduler.waitUntil(not isMusicFadingDown, …)`.
* Church's saving thread → coroutine `_saveThread(choice)` using
  `await Scheduler.sleep(500)` (local helper).
* Church: Java has a dead `update(long)` overload (the Organizer calls
  `update(float)`); only `update(float)` is ported.
* `Enemy` constructor: `new Random(abs(hashCode())).nextInt(70)` →
  `JRandom.new(absi(get_instance_id())).nextInt(70)` (start progress is still
  pseudo random per instance, not the same numbers as Java).
* Bug kept from the original: in `Inn.createPrices` the "Frozen Forest" loot
  sets the content name of `aegisLoot` ("Resurrect"), as in Java.

## Cross-unit issues

None seen.

# Content quirks: triage

Every content quirk the docs list (HANDOFF.md, CONVERTING_VILLAGES.md,
CONVERTING_DUNGEONS.md, MODERNIZATION_PLAN.md 6.3, 6.8 and 7.8,
tools/parity/cases.txt), gathered on 2026-10-22 so each can become a ticket
or be closed as intended. They were kept during the phases for parity; none
is fixed here unless it says so.

"Effect" is the game as of this list: the game's code no longer quits
anywhere (Java's `System.exit` checks are asserts now). A failed assert
stops the editor's debugger; a console run prints a SCRIPT ERROR and goes
on; a release build skips it.

Priority is a first guess: **High** breaks play in a place the player
reaches, **Medium** is visible but playable, **Low** is unreachable,
dev-only or cosmetic.

## Fixed already

* **Pensara - The North District - Farmer House quit on entry** (COTZ-023):
  Dido's patrol ended 5 px right of its start. Fixed in her `.char`.
* **Omer in Berca drifted 5 px down and right per loop**: his patrol
  (`maps/Village/Berca/villagers/Omer.char`) did not close, but Java's check
  (up - down + right - left) let it through. Fixed in his `.char`;
  `Instructions.check` now tests each axis, and all 245 `.char` files pass.

## Villages

### V2. Berca - 1 names a villager Herman without a `.char` file — Medium

* **Where:** `maps/Village/Berca/Berca - 1.vil:233` `villager Herman`; no
  `Herman.char` and no Herman images anywhere in the project.
* **Effect:** a script error every update (1,464 in the `tour_berca_1`
  parity log: `getExtraDirection` on null); Herman is not shown.
* **Fix idea:** remove the line, or write Herman (a `.char` and images).

### V3. Zazo - Tent: Shaun has no images there — Medium

* **Where:** `maps/Village/Zazo - Tent/Zazo - Tent - 0.vil:24` `villager
  Shaun 2`; his images are only in `res/Village/Zazo/villagers/Shaun`.
* **Effect:** an error every frame; Shaun is not drawn in the tent.
* **Fix idea:** copy or point the tent's Shaun to Zazo's images.

### V4. Pensara Civil House: Podd's image path cannot resolve — Medium

* **Where:** `maps/Village/Pensara - The North District - Civil House/`
  (`villager Podd 4 5`, `villagers/Podd.char`); the images are in
  `res/Village/Pensara - The North District/villagers/Podd`.
* **Effect:** Podd's images are not found in the Civil House (not checked in
  play).
* **Fix idea:** as V3.

### V5. Villages without obstacles — Medium

* **Where:** Alares - 1, Dellna - 2, Parasne - 2, Kin's Place, Zazo - Farl's
  House and several night variants (HANDOFF.md).
* **Effect:** the player walks through buildings, trees and furniture.
* **Fix idea:** copy the obstacles of the variant with the same background
  (the day / `- 0` file). Check whether any of them is meant to be empty.

### V6. Door signs with a misspelled command (`doorSignFL`, `sigin`) — Low

* **Where:** `doorSignFL` (the loader knows `doorSignFl`):
  `Pensara - The North District - 0.vil:218-238` (six doors: "The resident
  of Vincent af Kinstone.", "Locked.", "Shut tight."), `Port of Alares -
  0.vil:38` and `- 1.vil`; `sigin` (for `sign`): `Berca - 1.vil:216`.
* **Effect:** those lines are ignored: the doors show no sign text, and the
  Berca sign does not exist.
* **Fix idea:** fix the spelling in the data; or make the command names case
  insensitive.

### V7. Zazo, Pass to Zazo and Port of Zazo at night: no story leads there — Low

* **Where:** their `at Night` `.vil` variants; night variants are reached
  only by stories.
* **Effect:** the night variants are never seen (only `--start-time=night`).
  Zazo at night also has V1 and V8.
* **Fix idea:** decide whether they should be reachable; if not, nothing to
  do.

### V8. Zazo's night stores name images that do not exist — Low

* **Where:** `Zazo at Night - 0.vil:169` and `- 1.vil:169` `building Inn
  inn.jpg burt.png Kurt ...`.
* **Effect:** the inn at night has no images. Unreachable (V7).
* **Fix idea:** use the day inn's images.

### V9. Places nothing reaches: Dorma's Tranquility, Menthu Battle, Tutorial1 — Low

* **Where:** `maps/Village/Dorma's Tranquility`, `maps/Village/Menthu
  Battle` (no place, story, door or world map node names them);
  `maps/Story/Sequences/Chapter 1 - Running Away From Home/Tutorial1.seq`
  (no main.bank entry).
* **Effect:** none in play; only the data check and previews use them.
* **Fix idea:** wire them up or delete them.

### V10. Village loader quirks kept for parity — Low

* **Where:** `VillageLoader` / the village converter (MODERNIZATION_PLAN.md
  6.3).
* **Effect:** a two-line sign is listed twice; a taken loot's `lootLine`s
  go to the previous loot; unknown commands and stray text are ignored (see
  V6). Not checked in play.
* **Fix idea:** a loader fix each, changing parity for the villages
  concerned.

## Cutscenes

### S1. Two Celis memories go on to a place that does not exist — Low

* **Where:** `maps/Main/main.bank:156-157`: "Celis Memory - Someone's
  Comming" and "Celis Memory - Ana's Reaction" have `nextPlace="Running Away
  From Home"`; the place is "Running Away From Home - Part 1".
* **Effect:** at their end the title screen follows. Nothing leads to these
  two cutscenes, so only `--start` or the console reaches them.
* **Fix idea:** decide where they belong in the story first; then set the
  right `nextPlace`.

## Dungeons

### D1. Silent Ruin's door at node 29 leads to a mark main.bank lacks — High

* **Where:** Silent Ruin--The Great Ruins, door at node 29 → `-mark12`;
  main.bank has `-mark0` to `-mark11` (`maps/Main/main.bank:471-482`).
* **Effect:** using the door drops the game to the title screen ("unknown
  place"), losing unsaved progress.
* **Fix idea:** add the `-mark12` place if the floor has that start, or
  point the door at an existing mark.

### D2. Three Great Mine levers name objects that do not exist — Medium

* **Where:** The Great Mine: Great Deep's lever 189 names
  `The_Great_Mine--Mine_Core…` (the floor is "The Mine Core"); Mine Shaft's
  lever 29 names a Tunnel lever 189; the Mine Core's lever 189 names a Mine
  Shaft lever 28. None of those exist.
* **Effect:** Great Deep's lever opens neither the Mine Core's door 9 nor
  flips its lever (the Mine Core's own lever opens that door, so progress is
  not blocked there); the other two do nothing.
* **Fix idea:** correct the names.

### D3. Silent Ruin's 4×4 riddle solves itself — Medium

* **Where:** Silent Ruin, node 86 (`RubicsPuzzle19`): it uses the 4×4 tile
  set; the magic square check knows only 3×3 and 5×5.
* **Effect:** any key solves it (the Java too).
* **Fix idea:** add the 4×4 check.

### D4. With `--mute`, or on a "No Music" floor, some boss wins raise a script error — Low

* **Where:** `BattleManager.dontFadeBattleMusic` → `overwriteStarterMusic`
  on a labyrinth without a music player (Memory Taur's case).
* **Effect:** a script error, nothing visible. The Java would throw too.
* **Fix idea:** a null check (code, not data).

### D5. Two dungeon areas have no enemy group — Low

* **Where:** Ice Cavern--Mysterious Forest and Dorma's Forest have no entry
  in `maps/Banks/enemyBank.bank`.
* **Effect:** no random battles there.
* **Fix idea:** decide whether that is intended.

### D6. Ten hinder doors lead to `_` — Low

* **Where:** Pensara Prison's side cells, Menthu's Lair, Forest Path.
* **Effect:** locked doors that lead nowhere; probably scenery.
* **Fix idea:** none, unless one of them should open.

### D7. Fire Cavern--First Floor and Boss--Test — Low

* **Where:** main.bank has Fire Cavern--First Floor places without a `.map`
  file; Boss--Test has a `.map` but no place, size line or textures.
* **Effect:** nothing leads to either.
* **Fix idea:** delete the entries / the test floor.

### D8. Frozen Forest--Forest Passage repeats some `dir` lines — Low

* **Where:** `scenes/dungeons/DungeonCell.gd` `extra_links` keeps the
  legacy count.
* **Effect:** the repeated links count as neighbours, which picks other
  carpet and pillar shapes for those cells.
* **Fix idea:** drop the repeated lines and the count, if the shapes then
  look right.

### D9. Parity tours that start in a dialog (not a bug) — Low

* **Where:** `tools/parity/cases.txt`: the tours of Central Pass--West Part
  and Grivera--First Floor start at a trigger door whose dialogs hold the
  keys; Menthu's Lair--Hall of Memories' tour walks onto its save point.
* **Effect:** those tours mostly show the dialogs.
* **Fix idea:** close as intended, or give those tours a route.

## Saves

### G1. "Slot 2" and "Slot 3" are an older data version — Low

* **Where:** `maps/Banks/Slot 2.sav`, `Slot 3.sav`.
* **Effect:** their labyrinth nodes no longer exist: loading asserts for each
  one (22 for "Slot 2") and goes on, at Dellna on the world map (Java quit
  the game). In the editor that is 22 debugger stops.
* **Fix idea:** delete them, or strip the stale `node` lines.

## Seen while fixing COTZ-023, not checked

* The Farmer House chimney's smoke (`smokesystemHut`, Pensara - The North
  District) shows as a bright white glow, like a light beam (the COTZ-023
  screenshot). Compare with the original before filing.

Code-side findings (dead code, latent bugs) are in MODERNIZATION_PLAN.md,
"Appendix: side findings".

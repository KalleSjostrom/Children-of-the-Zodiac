# Content quirks: triage

Every content quirk the docs list (HANDOFF.md, CONVERTING_VILLAGES.md
(removed with the village converter; git history up to 1e0229df),
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
* **Menthu's Lair--Hall of Memories, chest 165 stopped on opening**: it held
  `cards.magic.Quake`, a card that never existed (in Java either). It holds
  `cards.magic.Colliding 1 true` now (`.map` and `.tscn`), as the other
  floors hold Tornado and Flare; parity case `dungeon_chest_hall_of_memories`.
* **Tito in Pensara - The Trade District gave `cards.offense.CrushingBlow`**
  for 400 kills, an old name of CrushingSaber (its Java comment calls it a
  "crush blow" card). Fixed in his `.char`. `Card.createCard` asserts on an
  unknown card now; every card name in maps/ resolves.
* **With `--mute`, or on a "No Music" floor, some boss wins raised a script
  error** (D4): `overwriteStarterMusic` called `exit()` on a null music
  player. `Labyrinth` and `BossBattleArea` check for null now (043a660c).

## Ticketed (2026-10-23)

Each remaining entry is a ticket now, checked against the data that day;
the tickets say which ones the Java original has too. The ticket has the
details; this list only maps the old IDs.

| ID | Ticket | Priority |
|---|---|---|
| V2 | COTZ-027 Herman in Berca has no villager file | Medium |
| V3 | COTZ-028 Shaun is not drawn in the Zazo tent | Medium |
| V4 | COTZ-029 Podd's images are not found in the Civil House | Medium |
| V5 | COTZ-030 Some villages have no obstacles | Medium |
| V6 | COTZ-031 Door signs and signs lost to typos (adds Zazo at Night's unprefixed sign text) | Low |
| V7 | COTZ-032 Zazo, Pass to Zazo and Port of Zazo at night are unreachable | Low |
| V8 | COTZ-033 Zazo's night inn and church have no images | Low |
| V9 | COTZ-034 Dorma's Tranquility, Menthu Battle and Tutorial1 are reached by nothing | Low |
| V10 | COTZ-035 Village loader quirks kept for parity | Low |
| S1 | COTZ-036 Two Celis memories end at the title screen | Low |
| D1 | COTZ-037 Silent Ruin's door at node 29 drops to the title screen | High |
| D2 | COTZ-038 Three Great Mine levers name the wrong objects | Medium |
| D3 | COTZ-039 Silent Ruin's 4x4 riddle solves itself | Medium |
| D5 | COTZ-040 No random battles in Mysterious Forest and Dorma's Forest | Low |
| D6 | COTZ-041 Twelve hinder doors lead nowhere (the list said ten) | Low |
| D7 | COTZ-042 Remove Fire Cavern--First Floor and Boss--Test | Low |
| D8 | COTZ-043 Frozen Forest--Forest Passage repeats some dir lines | Low |
| D9 | COTZ-044 Parity tours that start in a dialog | Low |
| G1 | COTZ-045 Slot 2 and Slot 3 are an older save version | Low |
| — | COTZ-046 Farmer House chimney smoke glows white (seen in COTZ-023) | Low |

## Found in phase 4.1 (2026-10-29), not ticketed

The world map and the airship (MODERNIZATION_PLAN.md 9.1); kept for parity.

| ID | Quirk | Java too | Priority |
|---|---|---|---|
| W1 | SQUARE boards the airship on any world map node once the Database status `airship` is 1 or more, but nine nodes have no node on the airship maps (the seven crossroads, Fire Cavern--Inferno-mark2, Silent Ruin--The Great Ruins-mark0): `AirLandscape.init` gets no node, raises script errors and leaves the airship at (0, 0) without a current node | yes (NullPointerException) | Medium |
| W2 | East and North at night would draw `res/Landscape/standardOvernight.png`, which does not exist (an error every frame, no night layer); no data reaches them at night (only Forest Path's door names a `land::continue::` place, on West) | yes | Low |
| W3 | A closed road (`road<map>-<address>` 0) that the save lists as visited keeps its dots (`Landscape.init` shows the visited roads without the closed check); it is not walkable. No data closes a road the save visited | yes | Low |
| W4 | `land2.map`'s Empyrian Temple node has no `land` prefix: landing there enters the labyrinth directly instead of a world map node (likely intended: the sky temple has no world map node) | yes | Low |

## Found in phase 4.2 (2026-10-30), not ticketed

The survey of the stores, the menu and the mini-games (MODERNIZATION_PLAN.md
9.2); kept.

| ID | Quirk | Java too | Priority |
|---|---|---|---|
| R1 | Silent Ruin--The Great Ruins (line 192) pairs the magic square riddle `RubicsPuzzle19` with `puzzle44` (4 x 4 tiles): its check knows only 3 x 3 and 5 x 5 (sums 15 and 65), so the riddle counts as solved on the first move, and it is never scrambled | yes | Low |

## Found with the character sprite sheets (2026-11-03), not ticketed

The villagers' and cutscene characters' images (docs/VILLAGER_SPRITES_PLAN.md,
"The data"); kept, none fixed or deleted. Shaun in Zazo - Tent (COTZ-028) and
Podd in the Civil House (COTZ-029) are the other two invisible villagers.

| ID | Quirk | Java too | Priority |
|---|---|---|---|
| C1 | Alares' Hilda1 (`maps/Village/Alares/villagers/Hilda1.char`, `image Hilda`) is invisible: the image path names `res/Village/Alares/villagers/Hilda/`, which does not exist (Hilda's images are Zazo's). She is there at her status 4 (no parity case reaches it): nothing is drawn, ImageHandler logs "image not found" for each of the 16 frames; her SpriteFrames is empty | yes (same data) | Medium |
| C2 | Pensara - The North District's "Thieving looking guy" (`image GTthief`) is invisible: the image path names the district's `villagers/GTthief/`, but the set is Alares' (`res/Village/Alares/villagers/GTthief/`). He is there at his status 6 or 8 (no parity case reaches it); as C1 | yes | Medium |
| C3 | `res/Village/Zazo/villagers/Storygroup` has two empty frames (10 and 11: facing down); nothing references the set | yes | Low |
| C4 | `res/Village/Characters/KinSmall`: 16 frames of 18x27 named `Kin1..16`, which no legacy path can name (a set's files are named after its folder); nothing references it | yes | Low |
| C5 | 31 sets are referenced by nothing (no `.char` image line, no cutscene actor, not the party): Alares' GTstorekeeper, GTwagon, GTyellowhair; Berca's Civilian; Characters' Alarescommander, Althair with helm, KinSmall, rebelpurplebald, rebelredbald, Seacaptain; the 12 zodiac images of Home of the Gods (their `.char` lines are `image _ 0`); Parasne's Merchant Amy, Merchant Dave, Merchant Pert, Merchant Willy; The Prison Cell's Celis; Zazo - Miner's Home's Marcus; Zazo - Miner's Home2's Berulf, Greghild; Zazo's Storygroup. Four more are referenced only by `.char` files that no village places: Berca's Benzer and Pensara - The North District - Library's Hanrry, Luna and Philiph (the Library's `.vil` has no villagers; `Zazo - Farl's House/villagers/Farl.char` is unplaced too) | yes | Low |
| C6 | Byte-identical sets under other names or places: Borealis, Celis and Zalzi in The Prison Cell and in `Characters/`; GTyellowhair = Shaun; Petir = Ulph = Tito; Tilly = Smallie = Ludna; Gilo = Milo; Gregory = Podd; Amy = Merchant Amy, Dave = Merchant Dave, Pert = Merchant Pert, Willy = Merchant Willy; Farmer Bob = Felix; Juha = Earl. Pointing their `.char` lines at one set is a data change (check it with the `tour_*` cases) | yes | Low |
| C7 | Emma (Zazo, Pensara - The School District), Farl (Zazo, `Characters/`) and Marcus (Zazo - Miner's Home, `Characters/`) exist twice with different art | yes | Low |

Code-side findings (dead code, latent bugs) are in MODERNIZATION_PLAN.md,
"Appendix: side findings".

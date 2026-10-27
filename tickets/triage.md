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

Code-side findings (dead code, latent bugs) are in MODERNIZATION_PLAN.md,
"Appendix: side findings".

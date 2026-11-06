The Farmer House chimney's smoke in Pensara - The North District shows as a bright white glow, like a light beam. Seen in COTZ-023's screenshot (`tickets/COTZ-023 - DONE - CTD - Entering building shuts down the game/`), not checked since.

**Priority:** Low, cosmetic (triage, "Seen while fixing COTZ-023").

**Where:** `maps/Village/Pensara - The North District/Pensara - The North District - 0.vil:21` `particlesystem smokesystemHut smokesystemArmory`, and its `.tscn`.

**First step:** compare with the original; if the Java's smoke looks the same, close as intended. Celis's house smoke had a speed fix (TODO.md, Village), so check that this one isn't the same problem.

**Note (2026-11-06):** the `.vil` and `.map` files this ticket names are deleted (decision 5; `docs/MODERNIZATION_PLAN.md` 6.9, 7.9, 9.1; the git history up to aab714c9 has them). Their data is in the scenes, which a fix edits: a village variant in `scenes/villages/<Place>/<file>.tscn`, a floor in `scenes/dungeons/<Area>/<Floor>.tscn` (with `resources/dungeon_layouts/` and `resources/dungeon_styles/`), a world map in `scenes/world_map/<file>.tscn`. The line numbers above are the old files'.

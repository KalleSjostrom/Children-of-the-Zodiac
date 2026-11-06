The `at Night` variants of Zazo, Pass to Zazo and Port of Zazo exist, but no story leads to them. Night variants are reached only by stories.

**Priority:** Low (triage V7).

**Where:** `maps/Village/Zazo/Zazo at Night - 0.vil` and `- 1.vil`, `Pass to Zazo at Night - 0.vil`, `Port of Zazo at Night - 0.vil`.

**Effect:** the night variants are never seen in play; only `--start-time=night` shows them (parity cases `zazo_night_0`, `zazo_night_1`). Zazo at night also has COTZ-031's blank sign and COTZ-033's missing store images.

**Fix idea:** decide whether they should be reachable. If not, nothing to do (or delete them).

**Note (2026-11-06):** the `.vil` and `.map` files this ticket names are deleted (decision 5; `docs/MODERNIZATION_PLAN.md` 6.9, 7.9, 9.1; the git history up to aab714c9 has them). Their data is in the scenes, which a fix edits: a village variant in `scenes/villages/<Place>/<file>.tscn`, a floor in `scenes/dungeons/<Area>/<Floor>.tscn` (with `resources/dungeon_layouts/` and `resources/dungeon_styles/`), a world map in `scenes/world_map/<file>.tscn`. The line numbers above are the old files'.

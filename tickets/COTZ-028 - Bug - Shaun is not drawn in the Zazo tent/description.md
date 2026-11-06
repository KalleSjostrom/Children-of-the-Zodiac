Shaun has no images in Zazo - Tent, so he is never drawn there.

**Priority:** Medium (triage V3). The Java original has the same data.

**Where:** `maps/Village/Zazo - Tent/Zazo - Tent - 0.vil:24` `villager Shaun 2`; his `.char` there says `image Shaun`, which resolves under `res/Village/Zazo - Tent/villagers/`. His images are only in `res/Village/Zazo/villagers/Shaun`.

**Effect:** a script error every frame; Shaun is invisible in the tent.

**Repro:** `--load="Slot 1" --start="Zazo - Tent"` (parity case `tour_zazo_tent_0`).

**Fix idea:** copy Zazo's images into the tent's folder, or point the tent's `Shaun.char` at Zazo's images.

**Note (2026-11-06):** the `.vil` and `.map` files this ticket names are deleted (decision 5; `docs/MODERNIZATION_PLAN.md` 6.9, 7.9, 9.1; the git history up to aab714c9 has them). Their data is in the scenes, which a fix edits: a village variant in `scenes/villages/<Place>/<file>.tscn`, a floor in `scenes/dungeons/<Area>/<Floor>.tscn` (with `resources/dungeon_layouts/` and `resources/dungeon_styles/`), a world map in `scenes/world_map/<file>.tscn`. The line numbers above are the old files'.

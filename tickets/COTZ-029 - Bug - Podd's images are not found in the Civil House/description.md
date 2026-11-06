Podd's image path in the Pensara Civil House cannot resolve.

**Priority:** Medium (triage V4). The Java original has the same data. Not checked in play.

**Where:** `maps/Village/Pensara - The North District - Civil House/villagers/Podd.char:1` `image /Pensara_-_The_North_District/villagers/Podd`. `Villager.loadImages` puts the village's own `villagers/` folder in front of it. The images are in `res/Village/Pensara - The North District/villagers/Podd`. The house names him at `Civil House - 0.vil:46` `villager Podd 4 5`, so he is only there at status 4 or 5.

**Effect:** Podd's images are not found in the Civil House.

**Repro:** `--load="Slot 1" --start="Pensara - The North District - Civil House"` (parity case `tour_pensara_the_north_district_civil_house_0`), with Podd's status at 4 or 5.

**Fix idea:** as COTZ-028: copy the images, or make the path resolve.

**Note (2026-11-06):** the `.vil` and `.map` files this ticket names are deleted (decision 5; `docs/MODERNIZATION_PLAN.md` 6.9, 7.9, 9.1; the git history up to aab714c9 has them). Their data is in the scenes, which a fix edits: a village variant in `scenes/villages/<Place>/<file>.tscn`, a floor in `scenes/dungeons/<Area>/<Floor>.tscn` (with `resources/dungeon_layouts/` and `resources/dungeon_styles/`), a world map in `scenes/world_map/<file>.tscn`. The line numbers above are the old files'.

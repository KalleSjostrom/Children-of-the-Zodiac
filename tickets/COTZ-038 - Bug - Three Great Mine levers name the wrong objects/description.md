Three levers in The Great Mine name doors or partner levers that do not exist.

**Priority:** Medium (triage D2): progress is not blocked. The Java original has the same data.

**Where** (a lever line is node, direction, image, then the hinders it opens and its partner lever; each is also in the floor's `.tscn` `hinders` array):

* `The Great Mine--Great Deep.map:61` lever 189 names `The_Great_Mine--Mine_Core.maphinderDoor9` and `...Mine_Core.mapbutton155`; the floor is "The Mine Core" (`The_Great_Mine--The_Mine_Core`). Scene: `scenes/dungeons/The Great Mine/Great Deep.tscn:88`.
* `The Great Mine--Mine Shaft.map:51` lever 29 names `The_Great_Mine--Tunnel.mapbutton189`; its partner is the Mine Core's lever 189 (that lever opens the same two doors). Scene: `Mine Shaft.tscn:72`.
* `The Great Mine--The Mine Core.map:77` lever 189 names `The_Great_Mine--Mine_Shaft.mapbutton28`; its partner is the Mine Shaft's lever 29. Scene: `The Mine Core.tscn:129`.

**Effect:** Great Deep's lever opens neither the Mine Core's door 9 nor flips the Mine Core's lever 155 (the Mine Core's own lever opens that door). The other two do not flip their partner.

**Fix idea:** correct the names: `The_Mine_Core` in Great Deep's line, `The_Mine_Core.mapbutton189` in the Mine Shaft's, `Mine_Shaft.mapbutton29` in the Mine Core's. Check in play that each pair now flips together.

**Note (2026-11-06):** the `.vil` and `.map` files this ticket names are deleted (decision 5; `docs/MODERNIZATION_PLAN.md` 6.9, 7.9, 9.1; the git history up to aab714c9 has them). Their data is in the scenes, which a fix edits: a village variant in `scenes/villages/<Place>/<file>.tscn`, a floor in `scenes/dungeons/<Area>/<Floor>.tscn` (with `resources/dungeon_layouts/` and `resources/dungeon_styles/`), a world map in `scenes/world_map/<file>.tscn`. The line numbers above are the old files'.

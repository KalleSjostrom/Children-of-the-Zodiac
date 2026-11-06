Zazo at night's inn and church name store images that do not exist.

**Priority:** Low (triage V8): unreachable in play (COTZ-032). The Java original has the same lines.

**Where:** `Zazo at Night - 0.vil:166, 169` and `- 1.vil:166, 169`:
`building Church church.jpg _ Pastor_Pai ...` and `building Inn inn.jpg burt.png Kurt ...`. No `church.jpg`, `inn.jpg` or `burt.png` exists; the day variant (`Zazo - 0.vil:187, 190`) uses `zazoChurch.jpg` / `zazoPastorHent.png` and `zazoInn.jpg` / `zazoInnKeeperCivler.png` in `res/Store/`.

**Effect:** the night inn and church have no images.

**Repro:** `--load=Start --start=Zazo --start-time=night --status=Zazoname:1` (parity case `zazo_night_0`).

**Fix idea:** use the day stores' images (keeping the night keepers' names, or the day's).

**Note (2026-11-06):** the `.vil` and `.map` files this ticket names are deleted (decision 5; `docs/MODERNIZATION_PLAN.md` 6.9, 7.9, 9.1; the git history up to aab714c9 has them). Their data is in the scenes, which a fix edits: a village variant in `scenes/villages/<Place>/<file>.tscn`, a floor in `scenes/dungeons/<Area>/<Floor>.tscn` (with `resources/dungeon_layouts/` and `resources/dungeon_styles/`), a world map in `scenes/world_map/<file>.tscn`. The line numbers above are the old files'.

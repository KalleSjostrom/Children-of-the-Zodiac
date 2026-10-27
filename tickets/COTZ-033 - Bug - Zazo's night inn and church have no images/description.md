Zazo at night's inn and church name store images that do not exist.

**Priority:** Low (triage V8): unreachable in play (COTZ-032). The Java original has the same lines.

**Where:** `Zazo at Night - 0.vil:166, 169` and `- 1.vil:166, 169`:
`building Church church.jpg _ Pastor_Pai ...` and `building Inn inn.jpg burt.png Kurt ...`. No `church.jpg`, `inn.jpg` or `burt.png` exists; the day variant (`Zazo - 0.vil:187, 190`) uses `zazoChurch.jpg` / `zazoPastorHent.png` and `zazoInn.jpg` / `zazoInnKeeperCivler.png` in `res/Store/`.

**Effect:** the night inn and church have no images.

**Repro:** `--load=Start --start=Zazo --start-time=night --status=Zazoname:1` (parity case `zazo_night_0`).

**Fix idea:** use the day stores' images (keeping the night keepers' names, or the day's).

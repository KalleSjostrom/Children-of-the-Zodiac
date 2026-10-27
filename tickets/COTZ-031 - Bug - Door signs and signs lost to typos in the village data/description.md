Some sign lines use a misspelled command, so the loader ignores them.

**Priority:** Low (triage V6). The Java original has the same typos.

**Where:**

* `doorSignFL` (the loader knows `doorSignFl`): `Pensara - The North District - 0.vil:218-238` (six doors: "The resident of Vincent af Kinstone.", "Locked." ×4, "Shut tight."), `Port of Alares - 0.vil:38`, `Port of Alares - 1.vil:73`.
* Found while checking: `Zazo at Night - 0.vil:195-196` and `- 1.vil:195-196` have the sign's two text lines without `signL` ("Cheap stolen goods. Find me in desert town and remember: / "A stubborn man gets his wish"."), so the sign outside the inn is empty. Zazo at night is unreachable (COTZ-032).

**Effect:** those doors show no sign text and the Zazo night sign is blank. (A `sigin` line in the old Berca - 1 went with that file in COTZ-027.)

**Fix idea:** fix the spelling in the data (and the `.tscn`s), or make command names case insensitive (that covers `doorSignFL` only).

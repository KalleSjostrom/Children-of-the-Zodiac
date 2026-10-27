Shaun has no images in Zazo - Tent, so he is never drawn there.

**Priority:** Medium (triage V3). The Java original has the same data.

**Where:** `maps/Village/Zazo - Tent/Zazo - Tent - 0.vil:24` `villager Shaun 2`; his `.char` there says `image Shaun`, which resolves under `res/Village/Zazo - Tent/villagers/`. His images are only in `res/Village/Zazo/villagers/Shaun`.

**Effect:** a script error every frame; Shaun is invisible in the tent.

**Repro:** `--load="Slot 1" --start="Zazo - Tent"` (parity case `tour_zazo_tent_0`).

**Fix idea:** copy Zazo's images into the tent's folder, or point the tent's `Shaun.char` at Zazo's images.

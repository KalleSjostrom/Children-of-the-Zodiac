Two Celis memory cutscenes go on to a place that does not exist, so the title screen follows them.

**Priority:** Low (triage S1): nothing leads to these two cutscenes; only `--start` or the console's cutscene list (`src/organizer/Cheater.gd:75-76`) reaches them. The Java original has the same lines.

**Where:** `maps/Main/main.bank:156-157`: "Celis Memory - Someone's Comming" and "Celis Memory - Ana's Reaction" have `nextPlace="Running Away From Home"`. The place is "Running Away From Home - Part 1" (`main.bank:22`), which "Celis Memory - Having Fun" (`main.bank:21`) leads to.

**Repro:** `--load=Start --start="Celis Memory - Ana's Reaction"`, watch it to the end.

**Fix idea:** decide where they belong in the story first (they may be cut content), then set the right `nextPlace`, or wire them into the chain.

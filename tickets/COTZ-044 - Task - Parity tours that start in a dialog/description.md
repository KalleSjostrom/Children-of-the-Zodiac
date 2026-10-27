Some dungeon tours in the parity suite mostly show dialogs instead of the floor. Not a game bug.

**Priority:** Low (triage D9).

**Where:** `tools/parity/cases.txt`: `dungeon_tour_central_pass_west_part(_start)` and `dungeon_tour_grivera_first_floor(_start)` start at a trigger door whose dialogs hold the tour's keys; `dungeon_tour_menthus_lair_hall_of_memories(_start)` walks onto its save point. Menthu's Lair--Hall of Memories changed in 043a660c (its bosses went), so check its goldens too.

**Fix idea:** close as intended, or give those tours a route (a `--start-node`, or a script that closes the dialogs first).

# Port notes: inventory-weather (`labyrinth.inventory`, `weather`)

All 28 skeleton files are ported. `AbstractDoor`, `Door` and `Inventory` were
already ported and were not changed. `tools/check.sh src/labyrinth/inventory src/weather`
reports 31 scripts checked, 0 failed.

## API notes for callers

* **Merged `draw(gl, dir = null)`** (Inventory, HinderDoor, FloorButton, Boss, Save):
  `dir == null` is Java's `draw(Graphics)`. A non-null `dir` is the inherited
  `Inventory.draw(GL2, int)` quad emitter. The exception is **`InventorySave`**:
  there a non-null `dir` is Java's `Save.draw(Graphics g, int dir)` (the particle
  effect, where `dir` is the player angle). So `Graph.drawInventory` must call
  `inv.draw(g, labyrinth.getPlayerAngle())` for `InventorySave` and `inv.draw(g)`
  for everything else, as the Java code does.
* **`HinderDoor.enter(lab, info = null)`**: `info == null` is Java's protected
  `HinderDoor.enter(Labyrinth)` (it leaves the labyrinth through the door). A
  non-null `info` runs `AbstractDoor.enter(lab, info)` (it only plays the sound).
  Do not call `enter(lab, null)` on a hinder door when you only want the sound.
* Internally, the no-argument Java `setHaveBeen()` is called as `_setHaveBeen()`
  (Inventory) in HinderDoor and IfDoor.
* **Renamed fields**: `DummyDoor.dataBaseName_` (hides `Inventory.dataBaseName`),
  `RiddleDoor.showingDialog_`, `WeatherParticle.var_`, and the static
  `RainParticle.color_/size_` and `WeatherSnowParticle.color_/size_`.
* `InventoryButton.updateDoorStatus` and `FloorButton.updateDoorStatus` are static
  and do the same as in Java (set the status vs. add to it).
* `MissionChest`, `MissionBomb`, `InventoryVillager` and `SimpleRiddle` store their
  dialogs as an Array of `[speaker, line1, line2]` arrays. They expect
  `Mission.getFinishedDialogs()` to return the same format (Java
  `ArrayList<String[]>`), or null.
* `TriggerDoor.arrive` calls `lab.drawDialog(seq)` with an **Array of
  DialogSequence** (Java `ArrayList<DialogSequence>`), and `Chest` calls it with a
  single `DialogSequence`. The merged `Labyrinth.drawDialog` must dispatch on
  `is Array` and `is DialogSequence`. Other calls pass `(String, String)` or
  `(bool, name, line1, line2, whisper)`.
* `WeatherSystem.draw(g, player, front)` and `update()` are unchanged. The
  player must provide `getDirection()` (an int angle from -180 to 180),
  `getLocation()` (an `[x, z]` array) and `isMoving()`.

## Threads

* `Button.countTo`, `ComboButton.activate` and `ComboButton.reset` run their
  animation threads as coroutines (`_countToAnimation`, `_activateAnimation`,
  `_resetAnimation`) using `await Scheduler.sleep`.
* The delayed "done" sound of `ComboButton.checkButtons` uses `Scheduler.after`.
* The thread in `TriggerDoor.arrive` that waits for the labyrinth fade uses
  `Scheduler.waitUntil`. It checks every frame instead of every 100 ms.

## Not ported faithfully

* `WeatherSystem` sorts with `sort_custom` on `SortingElement.yPos` instead of
  `Arrays.sort`. This sort is not stable, so particles with equal coordinates
  could end up in a different order. With random floats this has no visible
  effect.
* The debug `System.out.println` in `HiddenHinderDoor.activate` was removed.

## Performance

The weather systems have 10000 particles each. `drawParticle` uses typed locals
and allocates nothing per particle. `draw`, `loop` and `loopBackwards` read the
player's direction, location and moving flag once per frame instead of once per
particle. The result is the same.

## Cross-unit issues / TODO

* `Graph.gd` and `Labyrinth.gd` are still skeletons. Check the `InventorySave`
  draw call and the `drawDialog` dispatch described above when they are ported.

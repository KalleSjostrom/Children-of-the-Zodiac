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

## Own random numbers and hidden weather (the dungeon particles phase)

* Port deviation: `RainParticle.getInitialHeight` draws from `WeatherParticle.rand` (Java: `Math.random`), as
  `SnowParticle`'s does, so that a seeded run's other draws do not depend on the rain (10 000 draws per rain floor
  build). Normal play does not change.
* `--hide-particles` (`Main.hide_particles`, dev): `WeatherSystem.draw` runs `place_particles` (the same GL state,
  front list and cached view values) and draws nothing; `place_particles` returns no quads.

## Bridge to the GPU weather (the dungeon particles phase, docs/ARCHITECTURE.md section 10)

* `WeatherSystem.gpu_path()`: the weather and the save points run on the GPU (`WeatherParticles3D`,
  `SaveParticles3D`) unless `--legacy=dungeon_particles`, `--legacy=dungeons` or `--legacy=dungeon_drawing`. Then
  the system builds no particles (`gpu`; `gpu_seed` from `WeatherParticle.rand`), `update` counts the updates
  (`gpu_updates`), and `place_particles` returns the state of the passes (`place_gpu`: the same GL state changes,
  the colour and texture coordinate of the last quad; `gpu_running`, taken at the back pass, runs both passes in
  step). `draw` on the GPU path places without drawing (the scene draws).
* `Labyrinth.show_weather_over`: the front pass over a battle or riddle on the GPU path, in a batch slot of the 3D
  bridge's chunk (`Graphics.reserve_scene_slot`), not with `--hide-particles`.

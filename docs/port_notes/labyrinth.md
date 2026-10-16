# Port notes: labyrinth unit

Files ported: `info/LabyrinthInfo.gd`, `info/LabyrinthMap.gd`, `info/MenuMapLoader.gd`,
`labyrinth/{Graph, Labyrinth, LabyrinthRenderer, MapLoader, MapRenderer}.gd`,
`labyrinth/mission/{Mission, BombMission, FireMission, TimeMission, VillagerMission, MissionFactory}.gd`,
`shaders/Shader.gd` (class `GameShader`). Already-ported files in the unit
(Camera, Horizontal, LabyrinthDrawable, LabyrinthPlayer, LabyrinthTexture, Node,
PillarWalls, Position) were left unchanged; all compile.

## API notes for callers

* `Labyrinth.init(info)`: info Dictionary in the first parameter (`"map"`,
  `"start"`, `"name"`, `"music"`). Calls `initGameMode(info, Values.DETECT_AS_KEY)`.
* `Labyrinth.resume()` = Java public `resume()` (resumeWith(DETECT_ALL, false) +
  `GameEventListener.set3D()`). If called with a detection mode it forwards to
  `GameMode.resumeWith(...)`.
* `Labyrinth.exit(next: String, fadeBattleMusic: bool)` is the Java
  `exit(String, boolean)`; `exit(int)` (also `exitLabyrinth(int)`) goes to
  `GameMode.exit(mode)`.
* `Labyrinth.drawDialog(...)` dispatches on the first argument: `String` →
  `(first, second)`, `bool` → `(firstDialogImage, name, first, second, whisper)`,
  `Array` → `ArrayList<DialogSequence>`, otherwise a `DialogSequence`.
* `Labyrinth.enterRiddle(name, riddleClassName, hinders)`: `riddleClassName` is
  the Java name (`"miniGames.X"`) resolved via `ClassRegistry.newInstance`.
* `Labyrinth.addTopLayer/removeFromTopLayer` key by `ClassRegistry.getClassName(i)`.
* `LabyrinthMap.getInventories()` returns an `Array` of keys (Java returned an
  `Iterator<String>`). Only `Graph` used it.
* `LabyrinthMap` static image-name arrays (`arrows`, `doorClosed`, ...) are set in
  `_static_init` (they load the menu images permanently when the class loads,
  as the Java static initializers did).
* `MapLoader.parseFile(name)` / `MenuMapLoader.parseFile(name)`: single argument
  is the file name, resolved under `Values.LabyrinthMaps`.
* `MissionFactory.createMission(info)` uses `ClassRegistry.newInstance("labyrinth.mission." + info[0])`.

## Not ported faithfully / workarounds

* **Shaders** (`GameShader`): the original compiled GLSL (`vtest.glsl`,
  `ftest.glsl`) via JOGL. The GL emulation has no programmable pipeline, so
  `init` only reads the sources (if they exist) and compiles nothing;
  `getUniformLocation/getAttributeLocation` return -1; `useShader/useDefaultShader`
  are no-ops (fixed-function rendering is used). No caller in the reference
  code seems to depend on it for gameplay.
* `Graph.sortInventory`: Java `Arrays.sort` with the (inconsistent)
  `Inventory.compareTo` is replaced by a stable partition (non-material
  inventories first, then material ones), which is what Java's stable sort
  produces with that comparator.
* Java `HashMap` iteration order (nodes/inventories) is replaced by Dictionary
  insertion order. This only changes draw order / which inventory is found first
  when several match (e.g. `saveLocation` with more than one Save on a floor).
* `MapRenderer`: the static GLU/quadric are taken from the active Graphics at
  call time (`g.gluNewQuadric()`, `g.gluDisk`).
* `LabyrinthRenderer.addFog` keeps the original `glClearColor(c0, c1, c1, c2)` (sic).

## Cross-unit observations

* None blocking at the time of the final check (0 failed). `Labyrinth` relies on
  `BattleManager`, `RiddleGame`, `Dialog`, `DeckPage`, `EnemyFactory`,
  `Load`, inventory classes (other units); several were still skeletons when
  checked (e.g. `BattleManager`, `inventory/Boss`, `HinderDoor`, `Save`), so runtime
  behaviour depends on their ports.

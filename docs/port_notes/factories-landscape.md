# Port notes: factories-landscape

Files: `src/factories/{AbstractFactory, CardStoreFactory, EnemyFactory, EnemyLoader,
EquipmentFactory, LevelFactory, Load, Save, WeaponStoreFactory}.gd`, `src/info/Database.gd`,
`src/landscape/{LandPlayer, Landscape, LandscapeLoader, Node, Road, Visited}.gd`,
`src/landscape/airship/{AirLandNode, AirLandscape, AirLandscapeLoader, AirShip}.gd`.
`tools/check.sh src/factories src/info/Database.gd src/landscape`: 20 scripts, 0 failed.

## API notes for callers

- **Singletons are lazy.** The Java static initializers (`new XFactory()`) now run on first
  access: `EnemyFactory.getEnemyFactory()`, `EquipmentFactory.getEquipment()`,
  `WeaponStoreFactory.getStoreFactory()`, `LevelFactory.getLevelFactory()/getLevelFor()`,
  `CardStoreFactory.getCardsFor()`, `Visited.getVisited()`, `Save.getSave()`,
  `LandscapeLoader.checkPlace()` (the place map is built by `_getPlaceMap()`). Do not read the
  static fields (`enemyFactory`, `placeMap`, ...) directly.
- `Load.getLeftHandFor(character)` is **`Load.getLeftHandForStatic(character)`** (skeleton
  rename). `menu/EquipPage` (Java line 106) must call that name.
- `Landscape.music` is `Landscape.music_` (use `Landscape.setInfo()/isNight()`).
- `LevelFactory.NO_INCREASE` is a `static var` = -2147483648 (Java's overflowed
  `-Integer.MIN_VALUE`).
- `Database.getLevelFor(name, level, class)` builds the key with `str(int(...))`, so floats
  passed by callers still give "Kin=1:4".
- `Database.addStatus(name, value = null)`: a Dictionary as the first argument with no value
  is the `addStatus(HashMap)` overload.
- `Database.saveData(writer)` needs an object with `println(String)`; `Save.SaveWriter` is
  that object (`print_(s)`, `println(s = null)`, `writeTo(path)`).
- `Load.convertListToAbstractRemoveEquipped(cls)` / `getEquipmentFor(char, cls)` take the
  script class (`Armor`, `Weapon`, `Shield`); `is_instance_of` and `get_script() ==` replace
  `Class.isInstance` and `getClass() ==`.
- `Landscape/AirLandscape.resume()` with no arguments is the Java `resume()`; with arguments it
  forwards to `GameMode.resumeWith(...)`. `AirShip.standStill()` with no arguments is the
  airship slow-down; `standStill(dir, ...)` is the Sprite version.
- The landscape inner loaders take the outer object: `LandscapeLoaderMapLoader.new(self)`,
  `AirLandscapeLoaderMapLoader.new(self)`.

## Save games

- `Save.saveGame(slot, place)` writes `user://saves/<slot>.sav` (`Save.SAVE_DIR`), not
  `Values.lib`. The format is the same as the original: same commands, LF line endings, ints
  for attributes, `true/false` for booleans. Text is written as UTF-8; Java used the platform
  encoding, which only matters for non-ASCII names (none known).
- `Load.parseFile`: `Start.sav` is read from `Values.Banks`. Other slots are read from
  `user://saves/` if the file exists, otherwise from `Values.lib` and then `Values.Banks`
  through GameResourceLoader (the shipped `Slot 1-3.sav`, `E1.sav` etc. are in `maps/Banks/`,
  read only). The Values.Banks fallback is new; the original read only from `lib/`.
- The order of lines inside the `status`, `storedTrigger`, `counter` and labyrinth `node`
  blocks follows Dictionary insertion order instead of Java HashMap order. Load does not
  depend on the order.
- `Save.crypt` (never called in the original) is ported with an inline `swapChars`.

## Not exactly faithful / risks

- `Database.getStatusForDeckStore` iterates in Dictionary insertion order, not Java HashMap
  order (it has no callers in the Java code).
- The Database maps start as `{}` instead of null, so code that runs before
  `Organizer.reset()` does not crash. **Original behaviour kept:** `Database.reset()` (called
  by `Load.loadGame` through `Organizer.reset()`) clears `levelInformation`, and LevelFactory
  parses `levels.bank` only once. If the factory was created before a later `loadGame`,
  `getLevelFor` returns null from then on. The Java code has the same problem. If it shows up
  (level up after loading a second save), the integrator could reset
  `LevelFactory.levelFactory = null` in `Database.reset()`.
- `LandscapeLoader.init`: when the start node has no map, `push_error` replaces the swallowed
  Java exception. As in Java, `placeMap.get(startNode)` is not converted.
- `EquipmentFactory.getEquipment` with an unknown name: `push_error` + `GameCore.exitGame()`
  (Java: `System.exit`).
- Logger and debug `System.out` lines were removed.

## Cross-unit dependencies to verify

- `EnemyLoader` calls `parser.getDialogSequence(t)` on a `Parser` instance. That method is not
  in `Parser.gd` yet (villages/story unit).
- `EnemyLoader` calls `EnemyInfo.setAttack(attackInfo)` with one AttackInfo (the merged
  signature's first parameter), `BossDialog.set_`, `BossesDialog.add`, and
  `AttackInfo.Frame.new(15 args)`. These were skeletons at the time of writing.
- `Load` uses `Bestiary.getStats(name: String)`; `Save` uses `Bestiary.getStats()` → a Dictionary
  of Stats. It also uses `PartyItems.addItem(Item)` (one argument, an Item object, from
  collectLoot) and `LabyrinthMap.convert/convertForSave`.

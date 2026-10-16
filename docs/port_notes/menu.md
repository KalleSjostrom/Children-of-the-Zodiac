# Port notes: menu unit (menu, menu.tutorial, settings, title)

Ported: menu/{BestiaryPage, DeckPage, EquipPage, Help, HelpPage, MapPage, StatusPage, TutorialPage},
menu/tutorial/{Chapter, ColorTextLoader, HelpText, Icon, Row, Tutorial},
settings/{Settings, AnimSettings, EmitterSettings, ParticleSettings, ShapeSettings, SystemSettings},
title/{GameOver, TitleScreen}. Already-ported files (AbstractPage, MainMenu, MenuHand, MenuValues, Node,
ScrollBar, StartPage) were left unchanged.
`tools/check.sh src/menu src/settings src/title` -> `CHECKED 29 scripts, 0 failed`.

## API notes for callers

- **Settings**
  - `iterator()` returns an **Array of the keys in ascending order**, not a Java iterator. This is the order of
    Java's `HashMap<Integer,…>` keySet. `SystemLoader.settingKeys` accepts it.
  - `setVector(i, x, y, z)`: three numbers, a `Vector3f` (`setVector(i, vec)`), or an Array (`int[]` or
    `float[]`, `setVector(i, arr)`). The Vector3f is stored by reference; `getVector(i)` returns it shared.
  - `getVector(i, defaultVector)` returns the default when the key has no vector.
  - `getString(i)` returns `null` for unset keys. `getValue(i)`/`getBoolean(i)` create a default entry, as
    Java's `get(i)` does (value 0.0).
  - The private Java `get(int)` is `get_(i)`. `clone()` deep-copies the entries (Vector3f via `clone()`) and
    keeps the subclass (`get_script().new()`).
- **StatusPage** merged static overloads: `draw(g, c, s, attr, xi, yi)` dispatches on the arguments:
  6 args → (Character, String, attr, xi, yi); `s is int` → (String, xi, yi); `s == null` → (Character);
  otherwise → (Character, AbstractEquipment compare). `drawTop(g, c[, offset[, compare]])`.
  `drawSlots(g, slots, compareW, yPos)`: when `yPos == null` it is the Java `drawSlots(g, Character, compare)`
  (local helper `_drawCharacterSlots`).
- **MapPage**: the Java private `update()` and the per-frame `update(float)` share
  `update(elapsedTime = null)`. With no argument it refreshes the shown map; with an argument it does nothing,
  like the AbstractPage default. `crossPressed()`/`downPressed()` with no argument play the sound, as in Java.
- **Tutorial / HelpText / ColorTextLoader**: `ColorTextLoader.parseFile(filename)` with one argument
  parses `Values.Tutorials + filename`. The book is a Dictionary keyed by int.
- **GameOver**: the Java field `done` (it hides GameMode.done) is `done_`.

## Local workarounds

- `HelpPage` uses `AbstractPage._isGamePadManager()` because the framework has no
  `GameCore.inputManager.isGamePadManager()`.
- `GameOver`'s 22-second auto-exit thread is a coroutine (`await Scheduler.sleep(1000)` loop).
- `BestiaryPage` animation thread → coroutine `_runAnimation(id)`. `anim` holds the id of the running animation.
  `stopAnimating()` invalidates the id (this replaces interrupt/join) and resets `enemyImage` to 0, as in Java.
- `Tutorial` uses `GameResourceLoader.getResourceLoader().exists(...)` in place of `ResourceLoader.exists`.
- Skeleton constants with a lost minus sign were fixed from the Java source: `Chapter.LAST_PAGE = -10`,
  `DeckPage.NO_DECK = -1`. Initial values `Chapter.index = -1`, `soundPage = -2`, and `Tutorial.index = -1`
  also come from the Java source.

## Not exactly faithful

- `MapPage.setCurrent`: Java `floor.equals(...)` would throw an NPE when `floor` is null. The port treats a
  null floor as "not found".
- `Help.draw` and `EquipPage.drawInformation` are empty, because their bodies are commented out in the Java source.
- `HelpPage` menu entries do nothing ("Set Music Volume" etc. never match), as in the original.

## Cross-unit

- `character/Bestiary.gd` was still a skeleton when this was written. BestiaryPage uses `Bestiary.Stats.*`
  constants and `getStats/getEnemy/getInfo/shouldShowImage`.
- EquipPage calls `Load.getLeftHandForStatic` (renamed in factories).

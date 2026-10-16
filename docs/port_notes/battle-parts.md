# Port notes: battle-parts

Packages: `battle.bars`, `battle.bosses`, `battle.resultScreen`, `battleBacks`
(20 files). `tools/check.sh` on these folders: 0 failed.

## API that callers must know

- **BattleProgressBar** (`battle.bars.ProgressBar`): `_init(size, o)`
  dispatches on the type of the first argument. A **float** is the side
  (`ProgressBar(float side)`), an **int** is the texture count
  (`ProgressBar(int size, Object o)`, used only by `BattleScrollBar`). Pass the
  side as a float (`BattleProgressBar.LEFT` / `RIGHT`, or `0.0`, not `0`).
  `TimeBar.new(0)` is fine because TimeBar converts its argument to float.
  `RIGHT` is `-0.415` as in Java.
- `BattleProgressBar.draw(g)` does nothing; `draw(g, alpha, mode)` draws the bar.
  `BattleScrollBar.draw(g, offset)` draws the scroll bar (the 3-argument
  form still goes to ProgressBar). `TimeBar.draw(g)` rotates the matrix and
  draws with alpha 1 and mode -1.
- `createCoords()` on the bars takes no arguments. A single int argument goes
  to `Object2D.createCoords(int)`.
- `size` field of ProgressBar is `size_` (from the skeleton). TimeBar's `side`
  is `side_`.
- `LevelUpBar`: the static Java `draw(g, x, y, p1, p2, scale)` is
  `LevelUpBar.drawStatic(...)`. The image list `bar` is created lazily.
- `BossDialog`: `get_(i)` / `set_(i, d)` (Java `get` / `set`). The constants
  are `BEGINNING = 0`, `ENEMY_DEAD = -1`, `PARTY_DEAD = -2`.
- `BattleBoss.next(i = null)`: with no argument it uses `rounds`.
- `BossScript.parseFile(name)` (one argument) reads
  `Values.EnemyMaps + name + ".script"`. With two arguments it calls
  `AbstractMapLoader.parseFile(path, filename)`.
- `ResultScreenBase` (`resultScreen.Screen`): `_init()`, `_init(alpha)` or
  `_init(back, x, y, scale, alpha)`. The static `back` image is loaded lazily
  through `ResultScreenBase.getBack()`.

## Threads

- `SpoilsScreen` constructor thread (sleep 200, then until `done`: sleep 70 if
  paused, else sleep 700 and `next()`) is now a `Scheduler.every(_threadTick)`
  state machine with the same timing. The tick ends when `done` is true, or
  when the screen is freed (the method Callable becomes invalid).

## Not ported faithfully / small deviations

- `BossScript.MoveList.next()`: Java would throw (`% 0`) when the last
  "Single" move of a LIFE_PERCENT list is removed. The port sets `current = 0`
  in that case.
- `BattleSystem` sorts particles with `sort_custom` on `SortingElement.compareTo`.
  This sort is not stable like Java `Arrays.sort`, which only matters when
  z values are equal.
- Logger calls in `ResultScreen.calcResult` were removed.

## Cross-unit notes

- `BattleBoss` relies on `BattleEnemy._init(enemy)` (still a skeleton when
  this unit was ported) and on `EnemyLogic.makeMove(attackInfo)` dispatching
  on an `AttackInfo` argument (it is merged with `makeMove(enemy, characters)`).
- `BossScript` uses `AttackInfo.AttackInfos.new(onlyOnce)`, `.add`,
  `.getRandom`, `.shouldUseThisInfoOnlyOnce` and `AttackInfo.NOP` (skeletons
  in battle/enemy at the time of porting).

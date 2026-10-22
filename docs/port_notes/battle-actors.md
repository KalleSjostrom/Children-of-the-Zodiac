# battle-actors (battle.character, battle.enemy, battle.equipment)

Ported: Character3D, CharacterRow, Creature3D, CreatureRow, Enemy3D, EnemyRow,
Attack, AttackBackground, AttackInfo (+ AttackInfos, Frame), BattleEnemy,
CardInfo, EnemyAttackEffect, EnemyCard, EnemyInfo, EnemyLogic, GLDeck, GLWeapon.
AbstractDeck, FlatObj, GLCard, GLSlot and WeaponModeIcon were already ported;
they were not changed.

## API differences callers must know

* **CreatureRow / CharacterRow / EnemyRow**: Java's protected `float[] getPos()`
  is **`getRowPos()`**. `getPos(axis)` is Hideable's.
  Row access is `get_(i)`. `size()` and `init(boss)` keep their names.
* **CharacterRow** constants are `NO_TARGET = -1`, `ON_ALL = -2`, `RANDOM = -3`
  (the skeleton had lost the signs). `setTarget(t[, supportMode])`.
* **Creature3D.setHideTimer(ms, crit)** / **BattleEnemy.setHideTimer(ms, crit)**
  call `TimeHideable.hideFor(ms)`.
* **BattleEnemy**
  * The static `setColor(float[])` is `setColorStatic(c)`. The instance
    `setColor(Vector3f)` keeps its name.
  * Fields `attack_`, `slice_`, `shouldHit_` (methods `attack()`, `slice()`,
    `shouldHit()`).
  * `update(elapsedMs)` passes `elapsed / 1000` to the particle systems, as in Java.
  * `hit(info, target)` starts coroutines in place of threads. `attack(info, target)`
    is a coroutine: a caller that wants to wait on it must `await` it.
  * `wouldLikeToTalk()` uses `has_method("wantsToTalk")` (Boss) in place of
    `instanceof Boss`, to avoid a cyclic class reference.
  * `drawSlice` is merged: an int second argument selects (texIndex, coordIndex).
* **EnemyInfo**: `set_(i, v)` / `get_(i)`. `setAttack(attackInfo)` (one argument)
  or `setAttack(name, power, type, element, isAll, probability, frames, target)`.
  Attacks are iterated in emulated Java `HashMap<String>` order (`_javaKeyOrder`),
  so `getRandomAttack` and `getAttack` behave as in the original.
  `getRandomAttack` returns null (with push_error) when no attack of that
  type exists. Java threw an exception there.
* **EnemyLogic.makeMove(enemy, characters)** or **makeMove(attackInfo)** (one
  AttackInfo argument).
* **AttackInfo**: field `isAll_`, method `isAll()`. `NOP` is created in
  `_static_init`. The Frame fields with a trailing `_` are listed in
  skeleton_report.md. `soundEffect`/`startMusic` are `null` when absent.
* **GLDeck**
  * `update()` is the per-frame update. `update(character)` is the Java
    `update(Character)` resync.
  * `drawTopCard()` (no arguments) is the private pop of the top card.
    `drawTopCard(g, deck)` is AbstractDeck's.
  * `hasRoomFor(t[, undecided])`. `SAVED_CARD = -1`.

## Threads → Scheduler

* `BattleEnemy`: `hit`, `attack`, `shakeit`/`shake`, `rise` and the color
  recovery in `changeColor` are coroutines using `await Scheduler.sleep(ms)`.
  `slice()` uses `Scheduler.after(1500)`.
* `CharacterRow.testShowCharacters`: `Scheduler.waitUntil(not shouldTranslate_)`
  replaces the 100 ms polling thread.

## Local workarounds

* `Attack.setAttackName` measures the text with the framework helper
  `Graphics._stringWidth(name, 50)`. It replaces `TextManager.createRenderer(50).getBounds`.
* `Creature3D` info texture: `GraphicHelp.createImage` + `ImageGraphics`. It is
  uploaded with `GameTexture.fromImage("Creature3D_<id>", img)` and
  `tex.updateImage(g, img)`.
* `Character3D.imW` (full-screen white image) is created lazily.

## Not faithful / TODO

* `EnemyLogic.calcTarget` and `GLDeck.shuffleCards` use a fresh `JRandom` as
  Java did with `new Random()`. The sequences are not reproducible either way.
* Logging was removed. `System.exit(0)` in `GLDeck.update(Character)` became
  an `assert` (the game never quits from code).

## Cross-unit dependencies

* These files depend on skeletons that other units are still porting:
  `Bestiary.getStats(enemy).getInfo()`, `Enemy.getImages/getInfo/getStartFrame/
  getDieSound/getAttackType...`, `BattleAnimation.AnimationInfo.setTarget/
  setEnemy/setOnEnemy`, `Battle.changeMusic/testShowCharacters/
  testHideCharacters/exitToNext/setDialog/calcMiss`, `AttackText.addCenter`.
* All of these files compile, but their behavior at runtime depends on those ports.

# battle-core port notes

Files: `src/battle/{Animation(BattleAnimation), AttackText, Battle, BattleManager,
BattleQueue, BattleStarter, BossBattleArea, Clock, GLHand, HitElement, Legend}.gd`,
`src/battleTest/BattleTest.gd`. `check.sh` reports 0 failed.

## API notes for callers
- `BattleManager.switchMusic(name, fadeSpeed)` has no default (it overrides
  GameMode's). Java `switchMusic(music)` means `switchMusic(music, 500)`.
  `Battle.changeMusic(name[, time])` keeps both Java forms.
- `BattleManager.exit()` with no arguments is Java's private exit() (calls
  `starter.leaveBattle()`). `exit(int)` still goes to `GameMode.exit`. The same
  applies to `BossBattleArea.exit(String, bool)` and `exit(int)`.
- `BattleManager.init(info)`, `BossBattleArea.init(info)` and `BattleTest.init(info)`
  take the info Dictionary as their first parameter. `BossBattleArea.enterBattle(info)`
  works the same way.
- `AttackText.addCenter(info, centerx, y, support, size)` accepts every Java
  overload: info can be an int or a String, and `(info, bool support[, y])`
  works too. `add(info, x, y, support[, size])`. The size enum is
  `AttackText.textSize.LARGE/MEDIUM/SMALL/SMALLEST` (int consts).
  `AttackText.getAttackText()` creates the singleton lazily.
- `HitElement.new(card, attack, effect, text)` or `HitElement.new(attack, text)`.
- `BattleAnimation.init(cards, targetIndex, targets, enemy, attacker, glCharacters)`
  or `init("Shuffle", charIndex)`.
- `GLHand.setPos(playerParty: bool, index)`, `GLHand.hide()` (no time).
- BattleStarter is duck typed. Implementers need `exitDialog, drawDialog(ds),
  leaveBattle, gameOver, exit(next, fadeBattleMusic), notifySwitchMusic(music, ms),
  overwriteStarterMusic(music, oggPlayer)`.
- Boss check: `monster is BattleBoss` (the class_name of battle/bosses/Boss.gd).
  `Battle.getBoss` builds `battle.bosses.<DbName>` through `ClassRegistry.JAVA_TO_PATH`
  and falls back to `BattleBoss.new(enemy)`.

## Workarounds and differences
- **3D text** (JOGL TextRenderer.draw3D): `AttackText.draw3DText()` projects the
  point with `g.getModelView()` and the game's perspective (fov 45, 1024x768).
  It then draws the text in screen space through `g.backend.ci_2d` with a font
  size scaled to the depth. This uses Graphics internals (`_fonts`, `_blend_dst`,
  `_effAlphaFunc`, `_alpha_ref`). A "renderer" is `[fontSize, bold]`.
  `AttackText.calcAlignCenterTest` is local because it measures with the
  renderer's font, not the current font.
- Threads: the `Clock.reset` timebar thread is `Scheduler.every`. The
  `Animation.nextSystem` sleep of 400 ms for offense cards is `Scheduler.after`.
  The open-wound thread is a coroutine (`_openWoundThread`). The delayed
  talking and game over use `Scheduler.after`. The finishRound Semaphore and the
  loggers are removed.
- `Animation._addSystem`: if the card list was cleared during the 400 ms delay
  (in Java the thread threw an exception), it sets `animationDone = true` instead
  of crashing.
- `Clock.DEFAULT_X_POS` is the const 1024 (Java `ORIGINAL_RESOLUTION[X]`). This
  fixes the static-init order error.
- `compareToIgnoreCase` is a case-insensitive `==` on `str(...)`.

## Cross-unit issues
- `src/battle/character/CharacterRow.gd` is still a skeleton with
  `NO_TARGET = 1, ON_ALL = 2`. In Java they are **-1 / -2**. Battle uses these
  constants, so the battle/character unit must fix them.

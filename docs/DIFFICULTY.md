# Difficulty

Three levels: **Easy**, **Medium** and **Original** (COTZ-004).

* A new game asks for one: Title → Start → Easy / Medium / Original (the
  cursor starts on Medium; the highlighted level's description is shown
  under the list).
* In the game, Menu → Options → Difficulty lists the levels. Only easier
  ones than the current can be chosen; the level can be lowered but never
  raised again. The Options page shows the current level and its
  multipliers.
* The level is the Database status `difficulty` (0 Easy, 1 Medium,
  2 Original), so it is written to and read from saves like any other
  status. A save without it (made before this) plays as Original.

## Saving

How the game can be saved depends on the level (COTZ-005):

| | Easy | Medium | Original |
|---|---|---|---|
| Menu → Save in a labyrinth | anywhere | on a save point | on a save point |
| Menu → Save elsewhere (villages, world map, airship) | yes | yes | yes |
| Autosave | yes | yes | no |

* Off a save point the menu's Save is greyed out (it was always enabled in
  the original code, `if (true) // isOnSave`).
* A save made in a labyrinth also stores the player's node and direction
  (`labpos <floor> <address> <direction>` after the `start` line), so it
  starts exactly there. An older save of a floor without a save point (the
  COTZ-005 crash) starts at the floor's first door.
* Autosaves go to the hidden slot `Autosave` (`user://saves/Autosave.sav`):
  after every labyrinth battle (with the position), and when a village, a
  labyrinth floor, the world map or the airship is entered from another
  place (it then starts at that place's entrance). Loading a game does not
  autosave, so an older slot never overwrites a newer autosave. The title's
  Continue lists Autosave when it exists; the manual slot lists do not.
* Every slot list (title, menu, church) shows when each slot was saved, in
  local time, or "Empty". (Seeded test runs, `--seed`, date a slot saved in
  the run by their game clock from 1 Jan 2000 instead: `SaveSlots.note_saved`,
  dev only.)
* The emergency keys 6/7/8 (slots E1–E3) now write the same place and
  position as the menu.

The code: `Save.place_for`, `save_game_in`, `autosave` (after a battle,
`Labyrinth.leaveBattle`), `autosave_at` (`Organizer._initNext`), the
position in `Labyrinth.save_position` / `Load.take_labyrinth_position`, the
slots in `SaveSlots` (`scenes/common/SaveSlots.gd`).

## Tuning

Each level is a `DifficultyLevel` resource in `resources/difficulty/`
(`easy.tres`, `medium.tres`, `original.tres`); open one in the inspector or
edit the file. Original stays at 1.0 everywhere.

| Multiplier | Easy | Medium | Applied in |
|---|---|---|---|
| `experience_multiplier` | 1.5 | 1.2 | `SpoilsScreen.getSpoils`: the experience of a battle, before it is shared out |
| `enemy_damage_multiplier` | 0.6 | 0.8 | `EnemyLogic.attackTarget`: damage of enemy attacks and offensive magic on a party member, after critical hits (not their healing or support) |
| `ally_damage_multiplier` | 1.3 | 1.1 | `Card.actuallAttack`: damage of the party's offense and magic cards on an enemy, after critical hits (Drain heals from the scaled damage; cure and support cards are not touched) |

The code reads them through `Difficulty` (`scenes/common/Difficulty.gd`):
`Difficulty.scale_experience`, `scale_enemy_damage`, `scale_ally_damage`.
A new multiplier is an `@export` in `DifficultyLevel`, a value in the three
`.tres` files and a `scale_*` function used at the place in the table below.

Not scaled on purpose: instant kills (Death, enemies' "Death"), effects that
set HP to a fixed value ("DownTo"), and bleeding (open wound / negative HP
boost), which are fractions of HP already.

## Suggestions for more multipliers

Where each would go (legacy code, `src/`):

| Knob | Where |
|---|---|
| Gold from battles | `battle/resultScreen/SpoilsScreen.gd` `getSpoils`, next to the experience (the party has too much gold already, see TODO.md) |
| Gold from chests and loot | `labyrinth/inventory/Chest.gd` (gold content), `factories/Load.gd` `collectLoot` |
| Store prices (buy and sell) | `store/CardStore.gd` (price), `store/WeaponStore.gd` (`/ div`, selling gives half), `equipment/AbstractEquipment.gd`, `cards/AbstractCard.gd` |
| Inn and church prices | `store/Inn.gd` (rest 50 gp), `store/Church.gd` (resurrect 200 gp, bless cost) |
| Encounter rate | `labyrinth/Labyrinth.gd` `resetSteps` (steps to the next battle; default 13–20 in `MapLoader.gd`, `steps` lines per map) |
| Enemy HP / stats | `battle/Battle.gd` after `fillIdling` (normal enemies are copied per battle; `EnemyFactory.getBoss()` loads a boss anew for each battle, COTZ-015) |
| A separate boss multiplier | the same places as the damage multipliers, checking whether the battle is a boss battle (TODO.md has several notes on bosses being too hard or too easy) |
| Number of enemies per battle | `battle/Battle.gd` `fillIdling` |
| Healing | `factories/Load.gd` `cureParty` (0.5 % per labyrinth step), `cards/SupportCard.gd` `cure`, `labyrinth/inventory/Save.gd` (full cure at save points) |
| Critical hits | `cards/AbstractCard.gd` (`CRITICAL_PRECENT`, `CRITICAL_INCREASE`), `battle/enemy/EnemyLogic.gd` (enemy chance) |
| Hit / miss chance | `battle/Battle.gd` `calcMiss` |
| Item drop rate | `battle/resultScreen/SpoilsScreen.gd` `getSpoils` (rates from `EnemyFactory`) |
| Flee chance | `battle/Battle.gd` (`J.random() < 0.002` per tick while L2+R2 are held) |
| Turn speed (enemy agility) | `battle/Battle.gd` (the idling / turn order code) |
| Church bless experience | `character/Character.gd` `setExpPercentOfNext` (from `store/Church.gd`) |

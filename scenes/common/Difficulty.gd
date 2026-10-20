class_name Difficulty
extends RefCounted
## The difficulty of the current game (COTZ-004): Easy, Medium or Original.
##
## The player chooses it when starting a new game and may lower it later
## (the menu's Options page) but never raise it again. It is stored as the
## Database status "difficulty", so saves keep it without a format change;
## a save without it (made before difficulties existed) plays as Original.
##
## The balancing of each level is data: resources/difficulty/<level>.tres
## (DifficultyLevel). Legacy code reads the multipliers through the static
## functions below; they are the only entry points it uses.

enum Level { EASY, MEDIUM, ORIGINAL }

## Database status that holds the current Level.
const STATUS := "difficulty"
## The levels, indexed by Level.
const LEVELS: Array[DifficultyLevel] = [
	preload("res://resources/difficulty/easy.tres"),
	preload("res://resources/difficulty/medium.tres"),
	preload("res://resources/difficulty/original.tres"),
]


## The current level (Original when the game has none stored).
static func current() -> Level:
	var value: int = Database.getStatusFor(STATUS)
	if value < Level.EASY or value > Level.ORIGINAL:
		return Level.ORIGINAL
	return value as Level


## The settings of the current level.
static func settings() -> DifficultyLevel:
	return LEVELS[current()]


## Sets the level of a new game.
static func start_with(level: Level) -> void:
	Database.addStatus(STATUS, level)


## True when the current game may switch to the level: only to an easier one.
static func can_lower_to(level: Level) -> bool:
	return level < current()


## Switches to an easier level. Returns false (and changes nothing) for the
## current level or a harder one.
static func lower_to(level: Level) -> bool:
	if not can_lower_to(level):
		return false
	Database.addStatus(STATUS, level)
	return true


## The name of a level.
static func name_of(level: Level) -> String:
	return LEVELS[level].display_name


## Scales the experience of a battle.
static func scale_experience(value: float) -> int:
	return roundi(value * settings().experience_multiplier)


## Scales damage dealt by an enemy to a party member.
static func scale_enemy_damage(value: float) -> int:
	return roundi(value * settings().enemy_damage_multiplier)


## Scales damage dealt by a party member to an enemy.
static func scale_ally_damage(value: float) -> int:
	return roundi(value * settings().ally_damage_multiplier)

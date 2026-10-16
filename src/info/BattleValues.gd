class_name BattleValues
extends RefCounted
## Port of info.BattleValues: positions, scales and speeds used in battles.
## 3D positions are in the battle's eye space (see Graphics' projection);
## speeds are per millisecond.

# General
const STANDARD_Z_DEPTH := -2.0

# BattleEnemy
const ENEMY_DEPTH := -6.0
const ENEMY_HEIGHT := -2.0

# GLCard
const CARD_FLIP_SPEED := 0.6
const CARD_MOVE_SPEED := 0.0018
const CARD_MOVE_SPEED_2 := 0.0024
const CARD_SELECTED_OFFSET := 0.025
const CARD_SCALE := 0.002
const CARD_DISTANCE_BETWEEN := 0.212

# GLDeck
const DECK_HEIGHT_SLOTS := -0.65
const DECK_HEIGHT_CARDS := -0.3
const DECK_POSITION := -0.95

# Creature row
const CREATURE_SCALE := 0.0017

# Character row
static var DISTANCE_BETWEEN_CHARACTERS_X := 0.0
static var CHARACTER_POSITION := [0.0, 0.0, 0.0]
const CHARACTER_POS_Y := 0.5
static var NR_CHARACTERS := 0
static var CHARACTER_OFFSETS := [0.0, 0.0]

# Enemy row
const DISTANCE_BETWEEN_ENEMIES := -0.25
static var ENEMY_ROW_POSITION := [0.9, 0.19]

static var ENEMY_POS_FOR_TEXT := _createEnemyPosForText()
static var CHAR_POS_FOR_HAND: Array = []
static var CHAR_POS_FOR_TEXT: Array = []

# GLWeapon
const SLOT_SCALE := 0.002
const WEAPON_SLOTHEIGHT := -0.325
const WEAPON_SLOT_X := DECK_POSITION
const WEAPON_MODE_ICON_SCALE := 0.002

# GLHand
const HAND_SCALE := 0.0025

# Result screen
const RESULT_SCALE := 0.0015

# Clock
static var CLOCK_POSITION := [-1.0, -0.3]
static var ENEMY_POSITION := [-1.1, -0.2]

const HASTE := 0
const SLOW := 1

static var CARD_BACK := ImageHandler.addPermanentlyLoadNow(Values.Cards + "back.png")


static func setCharacterPosition(size: int) -> Array:
	var ret: Array
	if size == 4:
		DISTANCE_BETWEEN_CHARACTERS_X = 0.53
		CHARACTER_OFFSETS = [-0.16, 1.25]
		ret = [-1.03, CHARACTER_POS_Y]
	elif size == 3:
		DISTANCE_BETWEEN_CHARACTERS_X = 0.75
		CHARACTER_OFFSETS = [-0.17, 1.25]
		ret = [-0.95, CHARACTER_POS_Y]
	elif size == 2:
		DISTANCE_BETWEEN_CHARACTERS_X = 1.0
		CHARACTER_OFFSETS = [-0.225, 1.25]
		ret = [-0.7, CHARACTER_POS_Y]
	else:
		DISTANCE_BETWEEN_CHARACTERS_X = 1.2
		CHARACTER_OFFSETS = [0.0, 1.25]
		ret = [-0.2, CHARACTER_POS_Y]
	NR_CHARACTERS = size
	CHARACTER_POSITION = ret
	CHAR_POS_FOR_HAND = _createCharPosForHandAll()
	CHAR_POS_FOR_TEXT = _createCharPosForTextAll()
	return CHARACTER_POSITION


static func _createCharPosForHandAll() -> Array:
	var pos: Array = []
	for i in NR_CHARACTERS:
		pos.append(_createCharPosForHand(i))
	return pos


static func _createCharPosForTextAll() -> Array:
	var pos: Array = []
	for i in NR_CHARACTERS:
		pos.append(_createCharPosForText(i))
	return pos


static func _createEnemyPosForText() -> Array:
	var pos: Array = []
	for i in 3:
		pos.append([ENEMY_ROW_POSITION[0] + 0.1,
			ENEMY_ROW_POSITION[1] + 0.05 + DISTANCE_BETWEEN_ENEMIES * i])
	return pos


static func _createCharPosForHand(index: int) -> Array:
	index = mini(NR_CHARACTERS - 1, index)
	var pos := _createCharPosForText(index)
	pos[1] += 0.16
	return pos


static func _createCharPosForText(index: int) -> Array:
	var pos := [0.0, 0.0]
	pos[0] = (CHARACTER_POSITION[0] - CHARACTER_OFFSETS[0] - 0.15) \
		+ (index * DISTANCE_BETWEEN_CHARACTERS_X * CHARACTER_OFFSETS[1])
	pos[1] = CHARACTER_POSITION[1] + 0.18
	return pos


static func getCharPosForHand(index: int) -> Array:
	index = mini(CHAR_POS_FOR_HAND.size() - 1, index)
	return CHAR_POS_FOR_HAND[index]


static func getCharPosForText(index: int) -> Array:
	index = mini(CHAR_POS_FOR_TEXT.size() - 1, index)
	return CHAR_POS_FOR_TEXT[index]


static func getEnemyPosForText(index: int) -> Array:
	return ENEMY_POS_FOR_TEXT[index]


static func getCharPosXForSupport(index: int) -> float:
	index = mini(CHAR_POS_FOR_TEXT.size() - 1, index)
	if CHARACTER_POSITION == null:
		return 0.0
	return CHARACTER_POSITION[0] + index * DISTANCE_BETWEEN_CHARACTERS_X

class_name StoreDoor
extends RefCounted
## Port of store.Door: a door in a building. This door can be connected to any
## building via the type argument. When the player presses the cross button in
## front of a door, the doors attributes are gotten and the player enters the
## building.

const LOCKED = -1
const DONT_FADE = 0
const FADE_UP = 1
const FADE_TO_HALF = 2
const FADE_DOWN = 3
var name = null
var dbName = ""
var sign = null
var pos = null
var mode = null
var width: int = 0
var fade: int = 0
var toPos = null
var directions = null
var activateStatus: int = -1
var active: bool = true

## Creates a new door (Java: private constructor; VillageScene.load_into builds them).
func _init(type = null, name = null, x = null, y = null, w = null, directionList = null, f = null, villageName = null) -> void:
	if type == null:
		return
	mode = J.array(type.size(), 0)
	for i in range(type.size()):
		var t: String = type[i]
		if t == "church":
			mode[i] = Values.CHURCH
		elif t == "weapon":
			mode[i] = Values.WEAPONSTORE
		elif t == "house":
			mode[i] = Values.HOUSE
		elif t == "inn":
			mode[i] = Values.INN
		elif t == "card":
			mode[i] = Values.CARDSTORE
		elif t == "library":
			mode[i] = Values.LIBRARY
		elif t == "labyrinth":
			mode[i] = Values.LABYRINTH
		elif t == "village":
			mode[i] = Values.VILLAGE
		elif t == "switch":
			mode[i] = Values.SWITCH_BACK
		elif t == "story":
			mode[i] = Values.STORY_SEQUENSE
		name[i] = name[i].replace("_", " ")
	self.name = name
	directions = directionList
	fade = int(f)
	dbName = (villageName + name[0])
	pos = Values.createNormalPoint(x, y)
	width = int(w)

## Sets the sign of the door.
func setSign(s):
	sign = s

## Gets the sign of the door. This sign can tell the player that the door is
## locked for example.
func getSign():
	return sign

## Checks if the door is in range of the given position.
func isInRange(p):
	var dist: int = J.round(Vector2(p[Values.X], p[Values.Y]).distance_to(
			Vector2(pos[Values.X], pos[Values.Y])))
	return dist < width

## Gets the name of the building (null if locked).
func getBuildingName():
	var status: int = Database.getStatusFor(dbName)
	if dbName.contains("CardShop") and status != -1:
		status = 0
	if status != -1:
		return name[status]
	return null

## Gets the mode of the building that this door leads to (e.g. Values.INN).
func getMode():
	var status: int = Database.getStatusFor(dbName)
	if dbName.contains("CardShop") and status != -1:
		status = 0
	if status != -1:
		return mode[status]
	return -1

## Checks if the door is locked.
func isLocked():
	var status: int = Database.getStatusFor(dbName)
	return status == StoreDoor.LOCKED

func setActivateStatus(i):
	if i != -1:
		activateStatus = i
		active = false
		checkStatus()

func checkStatus():
	if activateStatus != -1:
		if Database.getStatusFor(dbName + "activation") == activateStatus:
			active = true

func setToPos(pos):
	toPos = pos

func canBeOpened(dir):
	if not active:
		checkStatus()
	if active:
		var found: bool = false
		var i: int = 0
		while i < directions.size() and not found:
			found = directions[i] == dir
			i += 1
		return found
	else:
		return false

func getFadeMode():
	return fade

func getToPos():
	return toPos

func getName():
	return name[0]

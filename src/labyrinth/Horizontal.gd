class_name Horizontal
extends RefCounted
## Port of labyrinth.Horizontal: stores the location of a node in the
## labyrinth. A node is one step, and the location is used to draw either the
## floor or the ceiling (carpet floors with straight, hook, T-cross, cross and
## end textures).
##
## Its drawing (draw) and the .map parse's setters (setStraight, setHook,
## setTCross, setCross, setEnd) are removed (plan 7.9): the floor scenes hold
## each carpet's slot and rotation (DungeonCell; DungeonScene.load_into sets
## direction and rotation, DungeonFloor draws the carpet).

const STRAIGHT = 0
const HOOK = 1
const TCROSS = 2
const CROSS = 3
const END = 4

var coord = null
var direction: int = 0
var rotation: int = 0


## Creates a new storage object and set the location to the given values.
func _init(x = null, z = null) -> void:
	coord = [float(x), float(z)]


## Gets the direction of the horizontal texture.
func getDirection() -> int:
	return direction


## Gets the rotation of the horizontal texture (Values.UP, RIGHT, DOWN, LEFT).
func getRotation() -> int:
	return rotation

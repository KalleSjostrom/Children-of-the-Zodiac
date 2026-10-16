class_name InstructionFollower
extends Sprite
## Port of sprite.InstructionFollower: a sprite which follows instructions.
##
## Overload notes:
##  - update(f): Java has Sprite.update(float) and the overload
##    InstructionFollower.update(int elapsedTime) (time modified by the
##    instruction speed). Dispatch is on the runtime type: an int calls the
##    InstructionFollower version, a float the plain Sprite version.
##  - move(dir, anim, ia): Java move(boolean reset, float elapsedTime) when
##    dir is a bool; the private move(float distance, int direction) when dir
##    is a float and anim an int; otherwise the inherited Sprite overloads.

var instructions = null
var instruction = null
var storyDialog: bool = false
var currentInstructions = null
var destination: int = 0
var start: bool = true

func _init() -> void:
	instructions = Instructions.new()
	currentInstructions = instructions

func update(f, player = null, reset = null):
	if f is int:
		super.update(instruction.modifyTime(f))
	else:
		super.update(f)

func setInstructions(index):
	instruction = currentInstructions.getInstruction(index)
	setAttributes(false)

func checkInstructions(reset):
	if currentInstructions.isDone():
		if start:
			currentInstructions = instructions
			start = false
		return
	var ans: int = currentInstructions.checkInstruction(reset)
	match ans:
		1:
			setAttributes(true)
		2:
			if reset:
				setAttributes(true)

func reset():
	instructions.reset()
	currentInstructions = instructions
	setAttributes(true)

func setAttributes(setInstructions):
	if setInstructions:
		instruction = currentInstructions.getInstruction()
	speed = instruction.getSpeed()
	moving = instruction.isMoving()
	direction = instruction.getDirection()
	destination = J.round(pos[direction % 2]
		+ (instruction.getDistance() * Values.DIRECTIONS[direction]))
	setImages()

func move(dir = null, anim = null, ia = null):
	if dir is bool:
		_moveReset(dir, float(anim))
	elif dir is float and anim is int and ia == null:
		_moveDistance(dir, anim)
	else:
		super.move(dir, anim, ia)

## Java: protected void move(boolean reset, float elapsedTime).
func _moveReset(reset: bool, elapsedTime: float) -> void:
	checkInstructions(reset)
	_moveDistance(speed * elapsedTime, direction)
	var extra: int = instruction.getExtraDirection()
	if extra != -1:
		_moveDistance(speed * elapsedTime, extra)

## Java: private void move(float distance, int direction).
func _moveDistance(distance: float, p_direction: int) -> void:
	if isMoving():
		var i: int = p_direction % 2
		if absf(distance) >= absf(pos[i] - destination):
			pos[i] = float(destination)
			currentInstructions.getInstruction().resetDistance()
		else:
			pos[i] += distance * Values.DIRECTIONS[p_direction]

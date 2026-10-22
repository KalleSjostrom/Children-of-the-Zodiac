class_name Instructions
extends RefCounted
## Port of sprite.Instructions: a list of instructions for an animated object.
## getInstruction() / getInstruction(index) are merged (index = null means the
## current index).

var instructions = []
var index: int = 0

func _init() -> void:
	pass

func parseFile(filename):
	pass

func add(instruction):
	instructions.append(instruction)

func getInstruction(index = null):
	if index == null:
		return getInstruction(self.index)
	return instructions[index]

func advanceInstruction(reset):
	instructions[index].reset()
	index += 1
	if index >= instructions.size():
		if reset:
			index = 0
		return true
	return false

func reset():
	getInstruction(index).reset()
	index = 0

func checkInstruction(reset):
	var i = instructions[index]
	if i.getDistanceLeft() <= 0:
		return 2 if advanceInstruction(reset) else 1
	i.decrementDistance()
	return 0

func executeCommand(command, tok):
	if command == "in":
		var angle: String = tok.nextToken()
		var firstCommand: String = tok.nextToken()
		if firstCommand != "dialog":
			var distance: int = J.parseInt(firstCommand)
			var stopped: bool = J.parseBoolean(tok.nextToken())
			var speed: int = J.parseInt(tok.nextToken()) if tok.hasMoreTokens() else 1
			instructions.append(Instruction.new(angle, stopped, distance, speed))
		else:
			instructions.append(Instruction.new(J.parseInt(angle)))

func isDone():
	return index >= instructions.size()

## True when the moves end where they start. Port fix (COTZ-023): Java
## exited the game otherwise, and summed up - down + right - left, which let
## a walk off by as much on both axes through (Omer in Berca); the villager
## asserts it instead (Villager.executeDialogCommand).
func check() -> bool:
	var test := J.array(4, 0)
	for i in instructions:
		test[i.getDirection()] += i.getDistance() if i.isMoving() else 0
	return test[0] == test[2] and test[1] == test[3]

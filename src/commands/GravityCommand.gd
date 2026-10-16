class_name GravityCommand
extends Command
## Port of commands.GravityCommand.

const DEFAULT_GRAVITY = 9.82
var gravity = null


## Java: GravityCommand() and GravityCommand(float grav).
func _init(grav = null) -> void:
	if grav == null:
		gravity = Vector3f.new(0, -DEFAULT_GRAVITY, 0)
	else:
		gravity = Vector3f.new(0, -float(grav), 0)


func executeSingle(b, elapsedTime):
	if b.isAlive():
		b.addForce(gravity.mult(b.getMass()))


func execute(bodies, elapsedTime):
	executeAll(bodies, elapsedTime)

class_name UpdateCommand
extends Command
## Port of commands.UpdateCommand: updates all living bodies.


func _init() -> void:
	pass


func executeSingle(b, elapsedTime):
	if b.isAlive():
		b.update(elapsedTime)


func execute(bodies, elapsedTime):
	executeAll(bodies, elapsedTime)

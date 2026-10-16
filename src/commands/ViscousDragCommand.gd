class_name ViscousDragCommand
extends Command
## Port of commands.ViscousDragCommand.

var drag: float = 0.0


func _init(f = null) -> void:
	if f != null:
		drag = f


func execute(bodies, elapsedTime):
	executeAll(bodies, elapsedTime)


func executeSingle(b, elapsedTime):
	b.addViscousDrag(drag)

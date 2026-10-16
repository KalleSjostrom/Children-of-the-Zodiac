class_name Command
extends RefCounted
## Port of commands.Command: an operation executed on all bodies of a system.


## Abstract in Java.
func execute(bodies, elapsedTime):
	pass


func executeAll(bodies, elapsedTime):
	var it = bodies.iterator()
	while it.hasNext():
		var b = it.next()
		executeSingle(b, elapsedTime)


func executeSingle(b, elapsedTime):
	pass

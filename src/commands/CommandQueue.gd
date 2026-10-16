class_name CommandQueue
extends RefCounted
## Port of commands.CommandQueue: a stack of commands run (LIFO) once.

var pq = null


func _init() -> void:
	pq = []


func enqueue(command):
	pq.append(command)


func run(bodies, elapsedTime):
	var c
	while not pq.is_empty():
		c = pq.pop_back()
		c.execute(bodies, elapsedTime)

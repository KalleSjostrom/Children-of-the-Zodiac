class_name GameModeQueue
extends RefCounted
## Port of organizer.GameModeQueue: a stack of suspended game modes.

var queue: Array = []


func push(gm: GameMode) -> void:
	queue.insert(0, gm)


func pop() -> GameMode:
	return J.removeAt(queue, 0)


func size() -> int:
	return queue.size()


func peek() -> GameMode:
	if queue.size() > 0:
		return queue[0]
	return null


func _to_string() -> String:
	return str(queue)


func delete() -> void:
	while size() > 0:
		pop().exit(Values.EXIT)

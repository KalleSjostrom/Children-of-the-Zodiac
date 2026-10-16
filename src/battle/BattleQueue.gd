class_name BattleQueue
extends RefCounted
## Port of battle.BattleQueue: a queue of creatures that are ready to fight.

var queue = []


## Gets the first creature in the queue, returns it and deletes it.
func dequeue():
	var c = null
	if not isEmpty():
		c = queue[0]
		J.removeAt(queue, 0)
	return c


## Enqueues a creature to the queue.
func enqueue(c):
	queue.append(c)


## Checks if the queue is empty.
func isEmpty():
	return queue.size() == 0


## Sets all the creatures in the queue to active or not active.
func setActive(active):
	for i in range(queue.size()):
		queue[i].setActive(active)

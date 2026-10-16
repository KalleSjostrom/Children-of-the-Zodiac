class_name PillarWalls
extends RefCounted
## Port of labyrinth.PillarWalls: sets the wall textures of a node when the
## labyrinth uses "pillar walls" (four wall textures that depend on how the
## neighboring nodes are connected).

static var node = null


static func addPillarWalls(n, offset, nrOfNeightbours) -> void:
	node = n
	if nrOfNeightbours == 1:
		oneNeighbour(offset)
	elif nrOfNeightbours == 2:
		twoNeighbours(offset)
	elif nrOfNeightbours == 3:
		threeNeighbours(offset)


static func oneNeighbour(offset) -> void:
	for i in 4:
		if node.getNeighbor(i) != null:
			node.setWall(Values.getCounterAngle(i), 3 + offset)
			var test: int = 2 if Values.getCounterAngle(i) / 2 == 0 else 1
			var leftIndex: int = (i + 3) % 4
			var rightIndex: int = (i + 5) % 4
			var n = node.getNeighbor(i)
			node.setWall(leftIndex, (3 if n.neighbors[leftIndex] != null else test) + offset)
			node.setWall(rightIndex, (3 if n.neighbors[rightIndex] != null else test) + offset)


static func twoNeighbours(offset) -> void:
	var sum: int = 0
	for i in 4:
		if node.getNeighbor(i) != null:
			sum += i
	if sum == 2 or sum == 4:
		setStraight(sum, offset)
	else:
		setHook(sum, offset)


static func setStraight(sum, offset) -> void:
	var s: int = sum
	var low: int = absi(s / 2 - 2) # 2 -> 1, 4 -> 0
	var high: int = low + 2 # 2 -> 3, 4 -> 2
	var n = node.getNeighbor(s / 2 - 1) # 2 -> 0, 4 -> 1
	node.setWall(low, 2 if n.neighbors[low] != null else 0)
	node.setWall(high, 2 if n.neighbors[high] != null else 0)

	n = node.getNeighbor(s / 2 + 1) # 2 -> 2, 4 -> 3
	if n.getNeighbor(low) != null:
		node.setWall(low, 1, 3)

	if n.neighbors[high] != null:
		node.setWall(high, 1, 3)
	node.addToWall(low, offset)
	node.addToWall(high, offset)


static func setHook(sum, offset) -> void:
	var s: int = sum
	if s == 1 or s == 5:
		var high: int = absi(s - 4)
		var low: int = high - 1
		var n = node.getNeighbor(s / 2) # sum / 2
		node.setWall(high, (3 if n.neighbors[high] != null else s % 3) + offset)

		n = node.getNeighbor(s / 2 + 1)
		node.setWall(low, (3 if n.neighbors[low] != null else s % 3) + offset)
	else:
		var n = node.getNeighbor(0)
		if n != null:
			node.setWall(1, (3 if n.neighbors[1] != null else 1) + offset)

			n = node.getNeighbor(3)
			node.setWall(2, (3 if n.neighbors[2] != null else 2) + offset)
		else:
			n = node.getNeighbor(1)
			node.setWall(0, (3 if n.neighbors[0] != null else 1) + offset)
			n = node.getNeighbor(2)
			node.setWall(3, (3 if n.neighbors[3] != null else 2) + offset)


static func threeNeighbours(offset) -> void:
	for i in 4:
		if node.getNeighbor(i) == null:
			var n = node.getNeighbor((i + 5) % 4)
			if n.neighbors[i] != null:
				node.setWall(i, 2 if (i + 5) % 4 < 2 else 1)
			else:
				node.setWall(i, 0)

			n = node.getNeighbor((i + 3) % 4)
			if n.neighbors[i] != null:
				node.setWall(i, 2 if (i + 3) % 4 < 2 else 1, 3)
			node.addToWall(i, offset)
			return

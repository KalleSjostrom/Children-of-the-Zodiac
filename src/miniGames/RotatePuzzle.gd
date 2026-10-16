class_name RotatePuzzle
extends Puzzle
## Port of miniGames.RotatePuzzle: a puzzle where the cross button rotates
## the ring of tiles around the cursor.


func crossPressed():
	var last = null

	var xi: int
	var yi: int
	for x in range(1, -2, -1):
		xi = cursorx + x

		if x == -1:
			for y in range(1, -2, -1):
				yi = cursory + y
				last = test(last, xi, yi)
		else:
			for y in range(1 - x * 2, 2):
				yi = cursory + y
				last = test(last, xi, yi)

	xi = cursorx
	yi = cursory - 1
	last = test(last, xi, yi)

	xi = cursorx + 1
	test(last, xi, yi)

	isRiddleDone()


## Puts last at (xi, yi) and returns the tile that was there. Outside the
## grid (Java: IndexOutOfBoundsException) nothing changes and last is
## returned.
func test(last, xi, yi):
	var current
	if xi < 0 or xi >= tiles.size() or yi < 0 or yi >= tiles[xi].size():
		current = last
	else:
		current = tiles[xi][yi]
		tiles[xi][yi] = last
		if last != null:
			last.setCurrent(xi, yi)
	return current

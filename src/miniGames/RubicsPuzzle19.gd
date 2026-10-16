class_name RubicsPuzzle19
extends RubicsPuzzle
## Port of miniGames.RubicsPuzzle19: the magic square puzzle (tiles 1..N*N,
## every row, column and both diagonals must have the same sum). It is not
## scrambled; the tile numbers are read from the image names.


func scramblePuzzle():
	pass


func isRiddleDone():
	var row: Array = J.array(N, 0)
	var col: Array = J.array(N, 0)
	var dia: Array = J.array(N, 0)
	var diaIndex: int = 0
	var dia2: Array = J.array(N, 0)
	var diaIndex2: int = 0
	var A: int = N - 1
	for x in N:
		for y in N:
			var s: String = tiles[x][y].getImage()
			s = s.replace(str(N) + "x" + str(N), "")
			s = s.replace(".png", "")
			var sa: Array = J.split(s, "/")
			var nr: int = J.parseInt(sa[sa.size() - 1])
			col[x] += nr
			row[y] += nr
			if x == y:
				dia[diaIndex] += nr
				diaIndex += 1
			if y == A:
				dia2[diaIndex2] += nr
				diaIndex2 += 1
				A -= 1
	var found := false
	match N:
		3:
			found = isFound(15, row, col, dia, dia2)
		5:
			found = isFound(65, row, col, dia, dia2)
	if not found:
		SoundPlayer.playSound(SoundMap.LABYRINTH_SECRET)
		InventoryButton.updateDoorStatus(hinders, 1)
		fadingDown = true
	return not found


## Returns true if any row, column or diagonal does not sum to magicSum.
## (The Java debug prints are removed.)
func isFound(magicSum, row, col, dia, dia2):
	var found := false
	var i: int = 0
	while i < row.size() and not found:
		found = row[i] != magicSum
		i += 1
	if found:
		return true

	i = 0
	while i < col.size() and not found:
		found = col[i] != magicSum
		i += 1
	if found:
		return true

	var sum: int = 0
	for k in dia.size():
		sum += dia[k]
	found = sum != magicSum
	if found:
		return true

	sum = 0
	for k in col.size():
		sum += dia2[k]
	found = sum != magicSum
	return found

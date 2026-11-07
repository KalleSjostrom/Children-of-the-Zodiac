class_name Tile
extends RefCounted
## Port of miniGames.Tile: one tile of a tile puzzle (Puzzle, RotatePuzzle,
## RubicsPuzzle). Knows its correct and its current position in the grid and
## the image (texture name) to draw.

var correctX: int = 0
var correctY: int = 0
var currentY: int = 0
var currentX: int = 0

var image = ""


func _init(x = null, y = null, p_image = null) -> void:
	correctX = x
	correctY = y
	currentX = x
	currentY = y
	image = p_image


## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): draw
## (drawImage(image, xs[currentX], ys[currentY])) without the drawing
## (Graphics.place_image: the bind; [texture, rect, tint], [] for
## the free slot of a Puzzle, which has no image).
func place(g, xs, ys) -> Array:
	return g.place_image(image, xs[currentX], ys[currentY])


func setImage(im):
	image = im


func getImage():
	return image


func setCurrent(bx, by):
	currentX = bx
	currentY = by


func isCorrect():
	return currentX == correctX and currentY == correctY

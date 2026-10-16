class_name ParticleValues
extends RefCounted
## Port of particleSystem.ParticleValues.

const DESTROY_ONCE = 0
const DESTROY_MULTIPLE_TIMES = 1
const PLAIN_DESTROY = 2
static var PLAIN_GRAY = [0.2, 0.2, 0.2]
static var FIRE_RED = [1.0, 0.2, 0.0]
static var DARK_RED = [0.5, 0.02, 0.0]
static var ICE_BLUE = [0.3, 0.3, 0.9]
static var WIND_GREEN = [0.1, 0.3, 0.1]
static var EARTH_BROWN = [0.3, 0.18, 0.1]
static var WHITE = [1.0, 1.0, 1.0, 1.0]
static var BLACK = [0.3, 0.0, 0.3, 0.0]
static var PURPLE = [0.15, 0.0, 0.15, 0.0]
static var YELLOW = [1.0, 1.0, 0.0]
static var COLORS = [
	PLAIN_GRAY, FIRE_RED, ICE_BLUE, WIND_GREEN, EARTH_BROWN, WHITE, BLACK, DARK_RED, PURPLE, YELLOW]
const COLOR_GRAY = 0
const COLOR_RED = 1
const COLOR_BLUE = 2
const COLOR_GREEN = 3
const COLOR_BROWN = 4
const COLOR_WHITE = 5
const COLOR_BLACK = 6
const COLOR_DARK_RED = 7
const COLOR_PURPLE = 8
const COLOR_YELLOW = 9
const COLOR_RANDOM = 10

## Returns a copy of the color with the given index (a random color for
## COLOR_RANDOM).
static func getColor(color):
	var copy: Array
	if color == COLOR_RANDOM:
		copy = [J.random(), J.random(), J.random()]
	else:
		var original: Array = COLORS[color]
		copy = original.duplicate()
	return copy

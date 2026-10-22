class_name MenuStarter
extends GameMode
## Port of organizer.MenuStarter: a game mode from which the menu can be
## entered (with a thumbnail screen shot of the mode).

var enterMenuQueued := false
var thumbNailScreenShot: Image
## Port addition (COTZ-012): the menu entered opens on its map page
## (MainMenu.init reads and clears it).
var menuOnMap := false


func getThumbnailScreenShot() -> Image:
	return thumbNailScreenShot


func queueEnterMenu() -> void:
	enterMenuQueued = true
	menuOnMap = false


## Port addition (COTZ-012): Square opens the menu on the map page, once a
## labyrinth has been visited (as the menu's Map entry).
func queueEnterMap() -> void:
	if Database.getVisitedLabyrinths().size() > 0:
		enterMenuQueued = true
		menuOnMap = true


static func isMenuButtonPressed(p_gameActions: Array) -> bool:
	return p_gameActions[GameMode.TRIANGLE].isPressed()


## Square, the map shortcut (COTZ-012); not on the world map, where it
## boards the airship.
static func isMapButtonPressed(p_gameActions: Array) -> bool:
	return p_gameActions[GameMode.SQUARE].isPressed()


func checkMenu() -> void:
	if enterMenuQueued:
		thumbNailScreenShot = enterMenu()
		enterMenuQueued = false

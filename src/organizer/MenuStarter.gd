class_name MenuStarter
extends GameMode
## Port of organizer.MenuStarter: a game mode from which the menu can be
## entered (with a thumbnail screen shot of the mode).

var enterMenuQueued := false
var thumbNailScreenShot: Image


func getThumbnailScreenShot() -> Image:
	return thumbNailScreenShot


func queueEnterMenu() -> void:
	enterMenuQueued = true


static func isMenuButtonPressed(p_gameActions: Array) -> bool:
	return p_gameActions[GameMode.TRIANGLE].isPressed()


func checkMenu() -> void:
	if enterMenuQueued:
		thumbNailScreenShot = enterMenu()
		enterMenuQueued = false

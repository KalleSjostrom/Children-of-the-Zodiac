class_name HelpPage
extends AbstractPage
## Port of menu.HelpPage: the options page (game pad, volumes).


func _init() -> void:
	activeNode = MenuNode.new(null, "Options")
	fillRoot(true)
	activeNode.setMenuCursor(0)
	setPage(BESTIARY_PAGE)


func fillRoot(resetCursor = null):
	var n = activeNode
	n.removeChildren(resetCursor)
	if AbstractPage._isGamePadManager():
		n.insertChild("Game Pad in use").setEnabled(false)
	else:
		n.insertChild("Connect Game Pad")
	n.insertChild("Set Music Vol")
	n.insertChild("Set SFX Vol")
	n.insertChild("Back")
	n.setDistance(MenuValues.DISTANCE)
	n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
	n.updateHandPos()


func upPressed():
	activeNode.previousChild()


func downPressed(playSound = null):
	activeNode.nextChild()


func circlePressed(pressAnyWay = null):
	MainMenu.getMainMenu().initStartPage(4)


func crossPressed(playSound = null):
	var command = activeNode.getCurrentChild().getName()
	if command == "Connect Game Pad":
		pass
	elif command == "Set Music Volume":
		pass
	elif command == "Set SFX Volume":
		pass
	elif command == "Back":
		circlePressed()


func selectPressed():
	# HELP
	pass


func draw3D(g):
	drawStandard(g)
	var x: int = MenuValues.MENU_TEXT_X
	g.drawString(activeNode.getName(), x, 54)
	activeNode.drawChildren(g)
	StartPage.drawInfo(g)
	drawHelp(g)


func drawHelp(g, drawAll = null):
	var helpx: int = 90
	var step: int = 125
	var helpy: int = 720
	var helpxicons: int = helpx - 28
	var helpyicons: int = helpy - 23

	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons)
	g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + step, helpyicons)

	g.drawString("Exit", helpx, helpy)
	g.drawString("Back", helpx + step, helpy)

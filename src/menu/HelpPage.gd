class_name HelpPage
extends AbstractPage
## Port of menu.HelpPage: the options page (game pad, volumes).
##
## Port addition (COTZ-004): "Difficulty" lists the levels; an easier one
## than the current can be chosen (Difficulty.lower_to), never a harder one.
## The left panel shows the current level and its multipliers.


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
	n.insertChild("Difficulty")
	n.insertChild("Back")
	n.setDistance(MenuValues.DISTANCE)
	n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
	n.updateHandPos()


func upPressed():
	activeNode.previousChild()


func downPressed(playSound = null):
	activeNode.nextChild()


func circlePressed(pressAnyWay = null):
	if activeNode.getParent() != null:
		SoundPlayer.playSound(SoundMap.MENU_BACK)
		activeNode = activeNode.getParent()
		return
	MainMenu.getMainMenu().initStartPage(4)


## The levels to choose from: the easier ones are enabled.
func fillDifficulty():
	var n = activeNode.getChild("Difficulty")
	n.removeChildren(true)
	for level in Difficulty.Level.values():
		n.insertChild(Difficulty.name_of(level)).setEnabled(Difficulty.can_lower_to(level))
	n.setDistance(MenuValues.DISTANCE)
	n.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
	n.setMenuCursor(Difficulty.current())
	n.updateHandPos()
	activeNode = n


func crossPressed(playSound = null):
	if activeNode.getName() == "Difficulty":
		var level: int = activeNode.getMenuCursor()
		if Difficulty.lower_to(level):
			SoundPlayer.playSound(SoundMap.MENU_ACCEPT)
			activeNode = activeNode.getParent()
		else:
			SoundPlayer.playSound(SoundMap.MENU_ERROR)
		return
	var command = activeNode.getCurrentChild().getName()
	if command == "Difficulty":
		SoundPlayer.playSound(SoundMap.MENU_ACCEPT)
		fillDifficulty()
	elif command == "Connect Game Pad":
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


## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): each part is
## shown by its node where it was drawn, or drawn with its --legacy flag
## (AbstractPage.draw_title, draw_list, _show_difficulty, StartPage.draw_info,
## AbstractPage.draw_help).
func draw3D(g):
	drawStandard(g)
	AbstractPage.draw_title(g, activeNode.getName())
	AbstractPage.draw_list(g, activeNode, false, false, false, false, false)
	if Main.is_legacy("menu_text"):
		drawDifficulty(g)
	else:
		_show_difficulty(g)
	StartPage.draw_info(g)
	AbstractPage.draw_help(g, drawHelp)


## The current difficulty and its multipliers, in the left panel.
func drawDifficulty(g):
	var settings: DifficultyLevel = Difficulty.settings()
	var x: int = 60
	var y: int = 100
	var lines: PackedStringArray = ["Difficulty: " + settings.display_name, ""]
	lines.append_array(wrapText(settings.description, 620))
	lines.append_array(["",
		"Experience: %d %%" % roundi(settings.experience_multiplier * 100),
		"Damage taken: %d %%" % roundi(settings.enemy_damage_multiplier * 100),
		"Damage dealt: %d %%" % roundi(settings.ally_damage_multiplier * 100),
		""])
	lines.append_array(wrapText("The difficulty can be lowered, but never raised again.", 620))
	for line in lines:
		g.drawString(line, x, y)
		y += 40


## Bridge (phase 4.2 step B): drawDifficulty without the drawing (the same
## lines, measured as it measures them; drawString's setColor(color) after
## each), and the frame's next MenuText node shows them (AbstractPage.show_lines).
func _show_difficulty(g) -> void:
	var settings: DifficultyLevel = Difficulty.settings()
	var x: int = 60
	var y: int = 100
	var lines: PackedStringArray = ["Difficulty: " + settings.display_name, ""]
	lines.append_array(wrapText(settings.description, 620))
	lines.append_array(["",
		"Experience: %d %%" % roundi(settings.experience_multiplier * 100),
		"Damage taken: %d %%" % roundi(settings.enemy_damage_multiplier * 100),
		"Damage dealt: %d %%" % roundi(settings.ally_damage_multiplier * 100),
		""])
	lines.append_array(wrapText("The difficulty can be lowered, but never raised again.", 620))
	var shown := []
	for line in lines:
		if line != "":
			shown.append([line, Vector2i(x, y), g.getFontSize(), Graphics.text_color(1.0),
					Graphics.font_bold(), HORIZONTAL_ALIGNMENT_LEFT])
		g.setColor(g.color)
		y += 40
	AbstractPage.show_lines(g, shown)


## The text in lines no wider than width (at the current font size).
static func wrapText(text: String, width: float) -> PackedStringArray:
	var lines: PackedStringArray = []
	var line := ""
	for word in text.split(" ", false):
		var tried: String = word if line == "" else line + " " + word
		if line != "" and Graphics._stringWidth(tried) > width:
			lines.append(line)
			line = word
		else:
			line = tried
	if line != "":
		lines.append(line)
	return lines


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

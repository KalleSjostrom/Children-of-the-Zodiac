class_name StartPage
extends AbstractPage
## Port of menu.StartPage: the first page that will show when the player
## enters the menu. In this menu, the player can choose to check the decks and
## equipment of the characters, check the items, read the tutorials, check the
## labyrinth map and save the game. A screenshot of the screen before the menu
## was entered is shown in thumbnail size.
##
## Port additions (COTZ-005): in a labyrinth, Save is enabled only on a save
## point (as the original intended), or anywhere on Easy; elsewhere always.
## A save in a labyrinth keeps the player's node (Save.save_game_in). The
## slot list shows when each slot was saved (SaveSlots).

static var frame = ""
static var miniScreenShot = null
const EQUIP_PAGE_ = 0
const DECK_PAGE_ = 1
## Bridge (phase 4.2 step B): the nodes of draw_screen_shot, draw_info and
## the saving box.
const THUMBNAIL_VIEW := "res://scenes/ui/MenuThumbnail.tscn"
const INFO_VIEW := "res://scenes/ui/MenuInfo.tscn"
const MENU_BOX_VIEW := "res://scenes/ui/MenuBox.tscn"

var parentNode = null
var displayParent: bool = false
var saving: bool = false
var selectedMode: int = -1
var savingString = ""


## Creates the start page. im is the thumbnail sized screenshot (an Image or
## null) and menuIndex the index where the menu hand should start.
func _init(im = null, menuIndex = null) -> void:
	miniScreenShot = im
	activeNode = MenuNode.new(null, "Main")
	activeNode.setDistance(MenuValues.DISTANCE)
	activeNode.setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
	activeNode.setMenuCursor(menuIndex)
	loadImages()
	fillRoot()
	setPage(START_PAGE)


## Loads the images used on this page.
func loadImages():
	frame = ImageHandler.addPermanentlyLoadNow(Values.MenuImages + "frame.png")


## Moves the menu hand one step upwards in the active menu.
func upPressed():
	if not saving:
		activeNode.previousChild()


## Moves the menu hand one step downwards in the active menu.
func downPressed(playSound = null):
	if not saving:
		activeNode.nextChild()


## Activates the current node in the menu tree and executes it.
func crossPressed(playSound = null):
	if not saving and activeNode.hasChildren():
		var n = activeNode.getCurrentChild()
		if n.isEnabled():
			activeNode = n
			activeNode.setActive(true)
			parentNode = activeNode.getParent()
			parentNode.setActive(false)
			displayParent = false
			var name: String = activeNode.getName()
			if not name.contains("Slot"):
				SoundPlayer.playSound(SoundMap.ACCEPT)
			executeNode(name)
		else:
			SoundPlayer.playSound(SoundMap.ERROR)


## Backs one step in the menu tree. If the active node is the root, the menu
## is exited and the previous mode is resumed.
func circlePressed(pressAnyWay = null):
	if pressAnyWay == null:
		pressAnyWay = false
	if pressAnyWay or not saving:
		var n = activeNode.getParent()
		if n != null:
			activeNode = MenuNode.switchNode(activeNode, n)
			parentNode = activeNode
		else:
			MainMenu.getMainMenu().exit()


## Executes different methods depending on which node that should be
## executed. Called right after the player has chosen a node.
func executeNode(name):
	if name == "Deck":
		fillCharacter()
		displayParent = true
		selectedMode = DECK_PAGE_
	elif name == "Equip":
		fillCharacter()
		displayParent = true
		selectedMode = EQUIP_PAGE_
	elif name == "Key Items":
		fillItems()
	elif name == "Tutorial":
		MainMenu.getMainMenu().initTutorialPage()
	elif name == "Options":
		MainMenu.getMainMenu().initHelpPage()
	elif name == "Load":
		fillLoad()
	elif name.contains("Save"):
		fillLoad()
	elif name.contains("Slot"):
		var save: bool = activeNode.getParent().getName() == "Save"
		if save:
			var prev = Organizer.getOrganizer().getPreviousMode()
			var finalName: String = name
			savingString = "Saving.  "
			saving = true
			var t = MainMenu.getMainMenu()
			SoundPlayer.playSound(SoundMap.MENU_SAVE)
			# Java: a thread that sleeps 3 x 500 ms and then saves.
			circlePressed(true)
			Scheduler.after(500, func():
				savingString = "Saving.. "
				Scheduler.after(500, func():
					savingString = "Saving..."
					Scheduler.after(500, func():
						Save.save_game_in(finalName, prev)
						saving = false
						t.unLockInput())))
		else:
			Load.loadGame(name)
			MainMenu.getMainMenu().exitTo(Load.getStartLocation())
	elif name == "":
		if selectedMode == DECK_PAGE_:
			MainMenu.getMainMenu().initDeckPage(
					activeNode.getParent().getMenuCursor(), -1, null)
		elif selectedMode == EQUIP_PAGE_:
			MainMenu.getMainMenu().initEquipPage(
					activeNode.getParent().getMenuCursor(), 0, false)
	elif name.contains("Map"):
		MainMenu.getMainMenu().initMapPage()


## Fills the root menu.
func fillRoot(resetCursor = null):
	activeNode.insertChild("Deck")
	activeNode.insertChild("Equip")
	activeNode.insertChild("Key Items")
	activeNode.insertChild("Tutorial")
	activeNode.insertChild("Options")
	activeNode.insertChild("Map").setEnabled(
			Database.getVisitedLabyrinths().size() > 0)
	var gm = Organizer.getOrganizer().getPreviousMode()
	var isOnSave := false
	if gm is Labyrinth:
		var lab = gm
		var inv = lab.getCurrentNode().getInventory()
		if inv != null:
			isOnSave = inv is InventorySave
	else:
		isOnSave = true
	# Java: if (true) { // isOnSave: Save was always there.
	activeNode.insertChild("Save").setEnabled(
			isOnSave or Difficulty.current() == Difficulty.Level.EASY)


## Fills the character menu.
func fillCharacter():
	var list: Array = []
	for i in range(Load.getCharacters().size()):
		list.append("")
	fillMenu(list, MenuValues.CHARACTER_DISTANCE, 50, 105)


func fillItems():
	var n = activeNode
	n.removeChildren(true)
	for i in range(Load.getPartyItems().itemSize()):
		var item = Load.getPartyItems().getItem(i)
		var child = n.insertChild(item.getName())
		child.addNumber(item.getNr())
		child.setEnabled(false)
	n.setDisableColor(JColor.black)
	n.setStandardWithBB()


## Fills the load menu.
func fillLoad():
	fillMenu(Array(SaveSlots.MANUAL), SaveSlots.MENU_DISTANCE,
			MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)


## Inserts the elements in the list as children to the activeNode, using the
## given distance between the children and x, y as position of the menu
## (default: the standard menu position).
func fillMenu(list, dist = null, x = null, y = null):
	if dist == null:
		fillMenu(list, MenuValues.DISTANCE, MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
		return
	var n = activeNode
	n.removeChildren(true)
	for i in range(list.size()):
		n.insertChild(list[i])
	n.setDistance(dist)
	n.setPositions(x, y)


## Draws the start page on the given graphics.
## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): each part is
## shown by its node where it was drawn (MenuNode.show_children_freely,
## AbstractPage.draw_title, SaveSlots.show_dates_under, StatusPage.show_top,
## draw_screen_shot, draw_info, _show_saving_box).
func draw3D(g):
	drawStandard(g)
	if displayParent:
		parentNode.show_all_children(g, Graphics.UI_LAYER)
	else:
		activeNode.show_children_freely(g, false, true, true, false, false, Graphics.UI_LAYER)
	var title = activeNode.getName()
	AbstractPage.draw_title(g, title)
	if not displayParent and activeNode.getName() == "Save":
		SaveSlots.show_dates_under(g, activeNode, MenuValues.MENU_FONT_SIZE)

	for i in range(Load.getCharacters().size()):
		var d: int = MenuValues.CHARACTER_DISTANCE * i
		var c = Load.getCharacters()[i]
		StatusPage.show_top(g, c, d)
	draw_screen_shot(g)
	draw_info(g)
	if saving:
		_show_saving_box(g)


## Bridge (phase 4.2 step B): drawConfirmBuyDialog (the saving box) without
## the drawing (the piece's bind, drawString's setColor(color)), and the
## frame's next MenuBox node on the UI layer shows the saving box
## (Graphics.show_ui).
func _show_saving_box(g) -> void:
	var mat = g.canvas_material()
	var piece: Array = g.place_centered_image(Values.MenuImages + "Pieces/1.png",
			Values.ORIGINAL_RESOLUTION[Values.X] / 2, 300)
	var lines := []
	if savingString != "":
		lines.append([savingString, Vector2i(470, 347), g.getFontSize(), Graphics.text_color(1.0),
				Graphics.font_bold()])
	g.setColor(g.color)
	var view = g.show_ui(MENU_BOX_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_box(piece, lines, mat)


## Bridge (phase 4.2 step B): drawScreenShot (the screen shot miniature and
## its frame) without the drawing: the binds, and the frame's next
## MenuThumbnail node on the UI layer shows the thumbnail and its frame
## (Graphics.show_ui). The menu's pages call this.
static func draw_screen_shot(g) -> void:
	var mat = g.canvas_material()
	var shot: Array = g.place_image(miniScreenShot, MenuValues.MENU_TEXT_X, 428)
	var framed: Array = g.place_image(frame, MenuValues.MENU_TEXT_X, 428)
	var view = g.show_ui(THUMBNAIL_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_thumbnail(shot, framed, mat)


## Bridge (phase 4.2 step B): drawInfo (the amount of gold, the number of
## steps taken and the time that the player has played the game) without the
## drawing: drawString's setColor(color) after each line, and the frame's next
## MenuInfo node on the UI layer shows the three lines (show_info). The menu's
## pages, the Inn and the Church (its copy of drawInfo) call this.
static func draw_info(g) -> void:
	show_info(g, PackedStringArray([
		"Gold: " + str(Load.getPartyItems().getGold()) + " gp",
		"Steps: " + str(Load.getPartyItems().getSteps()),
		"Time: " + str(Load.getTime().getHours()) + ":" + str(Load.getTime().getMin())]))


## Bridge (phase 4.2 step B): three lines drawn at drawInfo's places
## without the drawing (drawString's setColor(color) after each), shown by
## the frame's next MenuInfo node on the UI layer (Graphics.show_ui):
## drawInfo's, and the stores' own (WeaponStore.drawInfo, CardStore.drawInfo).
static func show_info(g, lines: PackedStringArray) -> void:
	var colors: Array[Color] = []
	for i in lines.size():
		colors.append(Graphics.text_color(1.0))
		g.setColor(g.color)
	var view = g.show_ui(INFO_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_info(lines, colors, g.getFontSize(), Graphics.font_bold(), g.canvas_material())

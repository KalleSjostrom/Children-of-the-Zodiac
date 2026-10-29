class_name MenuNode
extends RefCounted
## Port of menu.Node: a node in the menu tree. A node is a choice in the
## menu, like equip. The children of a node are drawn as a vertical list with
## a menu hand pointing at the current child. Used by the menu, the stores,
## the title screen, dialogs, battles etc.

var parent = null
var children: Array = []
var hand = null
var active: bool = false
var enabled: bool = true
var name = ""
var equipment = null
var distance: int = 0
var Xpos: int = 0
var Ypos: int = 0
var price: int = 0
var number: int = 0
var menuCursor: int = 0
var Y_DISTANCE_OFFSET: int = 20
var enableColor = JColor.BLACK
var disableColor = JColor.DARK_GRAY
var scrollBar = null

var bboffset: int = 0
var bbMaxY: int = -1
var bbMinY: int = -1


## Constructs a new node with parent p and name n.
func _init(p = null, n = null) -> void:
	parent = p
	name = n
	hand = MenuHand.new(Values.RIGHT)


## Inserts a child with the given name. Returns the inserted child.
func insertChild(p_name):
	var child := MenuNode.new(self, p_name)
	children.append(child)
	return child


## Sets the color of the text in the menu.
func setEnableColor(c):
	enableColor = c


func setDisableColor(c):
	disableColor = c


## Removes all the children of this node. resetCursor: true if this method
## should also reset the menu cursor.
func removeChildren(resetCursor):
	if resetCursor:
		menuCursor = 0
		bboffset = 0
	children.clear()


## Draws just the children of this node with default configuration, not this
## nodes grand children.
func drawChildren(g):
	draw(g, false, false, false, false, false)


## Draws all children (including grand children) of this node.
func drawAllChildren(g):
	draw(g, false, true, false, false, false)


## Draws the children of this node with the given configuration.
## withPrice: the children are drawn with their price next to the text.
## allChildren: grand children of active children are drawn as well.
## withNumber: the children are drawn with their number next to the text.
## down: the extra information (price, equipment) is drawn 25 pixels down.
## withEquipment: the children are drawn with the name of their equipment.
func drawChildrenFreely(g, withPrice, allChildren, withNumber, down, withEquipment):
	draw(g, withPrice, allChildren, withNumber, down, withEquipment)


func draw(g, withPrice, allChildren, withNumber, down, withEquipment):
	if menuCursor >= children.size():
		previousChild()
	var child = null
	for i in range(children.size()):
		child = children[i]
		if allChildren and child.isActive():
			child.drawAllChildren(g)
		Graphics.setTextColor(enableColor if child.enabled else disableColor)
		if not str(child.getName()).contains("character"):
			var y: int = (Ypos + i * distance) + bboffset
			if bbMinY == -1 or (y >= bbMinY and y <= bbMaxY):
				if withPrice:
					drawWithPrice(child, g, y, down)
				if withNumber:
					drawWithNumber(child, g, y, withNumber)
				if not withPrice and not withNumber:
					g.drawString(child.getName(), Xpos, y)
				if withEquipment:
					drawWithEquipment(child, g, y, down)
		if not child.enabled:
			Graphics.setTextColor(enableColor)
	if child != null:
		hand.drawHand(g)
		if bbMinY != -1:
			var h: int = bbMaxY - bbMinY
			if (children.size() - 1) * distance > h:
				scrollBar.draw(g, menuCursor, children.size())


## Bridge (phase 3 step B, docs/ARCHITECTURE.md section 12): drawAllChildren
## without the drawing, for a UI node that shows the menu (the game pad lost
## overlay's, GameCore): the same state changes (the text colours, drawString's
## setColor(color), the hand's). Returns {"items": [[name, x, y (the
## baseline), colour] …], "hand": MenuHand.place_hand's}. Only for a menu
## whose children are drawn as plain lines: no active child (its children
## would be drawn too) and no scroll bar (bbMinY); menus with these are phase
## 4.2's.
func place_all_children(g) -> Dictionary:
	if menuCursor >= children.size():
		previousChild()
	var items := []
	var child = null
	for i in range(children.size()):
		child = children[i]
		assert(not child.isActive(), "MenuNode.place_all_children: an active child's children")
		Graphics.setTextColor(enableColor if child.enabled else disableColor)
		if not str(child.getName()).contains("character"):
			var y: int = (Ypos + i * distance) + bboffset
			if bbMinY == -1 or (y >= bbMinY and y <= bbMaxY):
				if child.getName() != null:
					items.append([str(child.getName()), Xpos, y, Graphics.text_color(1.0)])
					g.setColor(g.color)
		if not child.enabled:
			Graphics.setTextColor(enableColor)
	var placed := {"items": items, "hand": []}
	if child != null:
		placed.hand = hand.place_hand(g)
		assert(bbMinY == -1, "MenuNode.place_all_children: a menu with a scroll bar")
	return placed


## Draws the given child at the given y position with the price stored in
## the child (right aligned, a bit further down if down is true).
func drawWithPrice(child, g, y, down):
	g.drawString(child.getName(), Xpos, y)
	if child.getPrice() > 0:
		g.setFontSize(20)
		var p: String = str(child.getPrice()) + " gp"
		g.drawStringRightWithReg(p, y + (25 if down else 0))
		g.setFontSize(MenuValues.MENU_FONT_SIZE)


## Draws the name of the equipment stored in the given child, right aligned,
## with a smaller font (a bit further down if down is true).
func drawWithEquipment(child, g, y, down):
	var ae = child.getEquipment()
	if ae != null:
		var n: String = ae.getName()
		g.setFontSize(20)
		g.drawStringRightWithReg(n, y + (25 if down else 0))
		g.setFontSize(MenuValues.MENU_FONT_SIZE)


## Draws the given child at the given y position with the number stored in
## the child.
func drawWithNumber(child, g, y, withNumber):
	g.drawString(child.getName(), Xpos, y)
	if child.number > 0:
		var nr: String = ""
		if child.number > 1:
			nr = "(" + str(child.number) + ")"
		g.setFontSize(20)
		var x: int = Graphics.calcAlignRight(nr, 980)
		g.drawString(nr, x, y)
		g.setFontSize(MenuValues.MENU_FONT_SIZE)


## Switches the active node from the given node activeNode to the node n.
## Returns the new active node (n).
static func switchNode(activeNode, n):
	activeNode.setActive(false)
	activeNode = n
	activeNode.setActive(true)
	return activeNode


###################
# GETTERS & SETTERS
###################

func isActive():
	return active


## Java overloads getChild(String name) and getChild(int i).
func getChild(p_name):
	if p_name is int:
		return children[p_name]
	for i in range(children.size()):
		if children[i].name == p_name:
			return children[i]
	return null


## Gets the child at the current index.
func getCurrentChild():
	return children[menuCursor]


## Moves the cursor to the next child (wrapping to the top).
func nextChild(play = null):
	if play == null:
		play = true
	if play:
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	menuCursor += 1
	if menuCursor == children.size():
		menuCursor = 0
		if bbMinY != -1:
			bboffset = 0
	updateHandPos()


## Moves the cursor to the previous child (wrapping to the bottom).
func previousChild(play = null):
	if play == null:
		play = true
	if play:
		SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE)
	menuCursor -= 1
	if menuCursor == -1:
		menuCursor = children.size() - 1
		if bbMinY != -1:
			var h: int = bbMaxY - bbMinY
			var nr: int = int(ceil(h / float(distance)))
			bboffset = (nr - menuCursor) * distance
	updateHandPos()


## Updates the hand position.
func updateHandPos():
	var yPos: int = menuCursor * distance + Ypos + bboffset
	if bbMinY != -1:
		if yPos <= bbMinY:
			bboffset += ((bbMinY - yPos) / distance) * distance
		elif yPos >= bbMaxY:
			bboffset -= ((yPos - bbMaxY) / distance) * distance
		yPos = menuCursor * distance + Ypos + bboffset
	hand.setYpos(yPos - Y_DISTANCE_OFFSET)


func hasChildren():
	return children.size() != 0


## Activates or deactivates this node.
func setActive(p_active):
	active = p_active
	hand.setVisible(p_active)


func setName(p_name):
	name = p_name


## Sets the price of this node (used in stores).
func setPrice(p):
	price = p


func getPrice():
	return price


func getParent():
	return parent


func getDistance():
	return distance


func getName():
	return name


func getYpos():
	return Ypos


## Gets the size of the menu (the number of children).
func getSize():
	return children.size()


## Gets the index of the node that the hand is pointing at.
func getMenuCursor():
	return menuCursor


func getMenuHandYpos():
	return hand.getYpos()


## Gets the position of the menu hand ([x, y]).
func getHandPos():
	return hand.getPos()


func getEquipment():
	return equipment


## Java overloads setPositions(int[] is) (a Values.createNormalPoint array)
## and setPositions(int x, int y).
func setPositions(x, y = null):
	if y == null:
		setPositions(x[Values.X], x[Values.Y])
		return
	Xpos = x
	Ypos = y
	for i in range(children.size()):
		children[i].setYpos(Ypos + (i * distance))
		children[i].setXpos(Xpos)
	hand.setXpos(Xpos - 35)
	hand.setYpos(Ypos - Y_DISTANCE_OFFSET)


func setXpos(xpos):
	Xpos = xpos


func setYpos(ypos):
	Ypos = ypos


func setDistance(d):
	distance = d


## Sets the current menu index to the given number.
func setMenuCursor(currentChild):
	menuCursor = currentChild
	updateHandPos()


## Stores the given equipment in this node.
func setEquipment(equip):
	equipment = equip
	if equip != null:
		number = equip.getNumber()


func setNoNumber():
	number = -1


## Enables or disables this node. An enabled node uses the enable color.
func setEnabled(p_enabled):
	enabled = p_enabled


## Adds the given number to the number that is stored in this node.
func addNumber(nr):
	number = maxi(number + nr, 0)


func getNumber():
	return number


## Gets the total price of all the children of this node.
func getTotalPrice():
	var total: int = 0
	for i in range(children.size()):
		var n = children[i]
		total += n.getPrice()
	return total


func isEnabled():
	return enabled


## Moves the cursor to the child with the given name (case insensitive).
func setCurrentChild(p_name):
	if p_name == null:
		return # Java would throw a NullPointerException here.
	var lower: String = str(p_name).to_lower()
	for i in range(children.size()):
		if lower == str(children[i].name).to_lower():
			setMenuCursor(i)
			return


func setBoundingBox(minY, maxY, barX):
	bbMinY = minY
	bbMaxY = maxY
	scrollBar = MenuScrollBar.new(barX, minY, (maxY - minY))


func setDimmedHand(p_dimmed):
	hand.setDimmed(p_dimmed)


func setStandardWeaponWithBB():
	setDistance(MenuValues.DISTANCE)
	var maxY: int = MenuValues.MAIN_MENU_TEXT_Y_FOR_WEAPON + 5 * MenuValues.DISTANCE
	setBoundingBox(MenuValues.MAIN_MENU_TEXT_Y_FOR_WEAPON, maxY, 978)
	setPositions(MenuValues.MENU_TEXT_X, MenuValues.MAIN_MENU_TEXT_Y_FOR_WEAPON)


func setStandardWithBB():
	setDistance(MenuValues.DISTANCE)
	setPositions(MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y)
	var maxY: int = MenuValues.MENU_TEXT_Y + 6 * MenuValues.DISTANCE
	setBoundingBox(MenuValues.MENU_TEXT_Y, maxY, 978)

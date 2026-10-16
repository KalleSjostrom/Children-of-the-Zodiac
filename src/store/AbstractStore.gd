class_name AbstractStore
extends Building
## Port of store.AbstractStore: a building where the player can buy things
## (with a confirm dialog).

var confirmNode = null # MenuNode
var confirm: int = 0
const POSITIVE = 0
const NOT_AFFORD = 1
const CANT_EQUIP = 2
const CANT_MERGE = 3
const POSITIVE_MERGE = 4


func initStore():
	confirmNode = MenuNode.new(null, "")


## Abstract: fills the positive confirm menu.
func fillPositiveConfirm(n):
	pass


## Abstract: called when a directional button has been pressed.
func dirPressed(dir):
	pass


## Java overloads: checkBuy(Node node, AbstractEquipment ae) and
## checkBuy(int price).
func checkBuy(node, ae = null):
	if node is int:
		var price: int = node
		if price > Load.getPartyItems().getGold():
			negativeConfirm(NOT_AFFORD)
		else:
			positiveConfirm()
		return
	if ae != null and not Load.isCharacterActive(ae.getForWhom()):
		negativeConfirm(CANT_EQUIP)
	else:
		checkBuy(node.getPrice())


## Moves the menu hand upwards in the current menu.
func upPressed():
	dirPressed(Values.UP)


## Moves the menu hand downwards in the current menu.
func downPressed():
	dirPressed(Values.DOWN)


## Moves the menu hand to the right (when editing a deck).
func rightPressed():
	dirPressed(Values.RIGHT)


## Moves the menu hand to the left (when editing a deck).
func leftPressed():
	dirPressed(Values.LEFT)


## Java overloads: positiveConfirm() fills the confirm purchase menu, and
## positiveConfirm(String name, int type).
func positiveConfirm(name = null, type = null):
	confirmNode.removeChildren(true)
	var n = confirmNode
	if name == null:
		fillPositiveConfirm(n)
		n.insertChild("Cancel")
		n.setDistance(MenuValues.DISTANCE - 5)
		n.setPositions(440, 420)
		confirm = POSITIVE
	else:
		n.insertChild(name)
		n.insertChild("Cancel")
		n.setDistance(MenuValues.DISTANCE - 10)
		n.setPositions(450, 405)
		confirm = type


## Fills the confirm node with the response to a negative statement from the
## store keeper (the only response is "OK").
func negativeConfirm(type):
	confirmNode.removeChildren(true)
	confirmNode.insertChild("OK")
	confirmNode.setDistance(MenuValues.DISTANCE)
	confirmNode.setPositions(480, 415)
	confirm = type


## Java overloads: drawConfirmDialog(g) (uses the current child of the
## active node) and drawConfirmDialog(g, String name, int price).
func drawConfirmDialog(g, name = null, price = null):
	if name == null:
		var n = activeNode.getCurrentChild()
		drawConfirmDialog(g, n.getName(), n.getPrice())
		return
	match confirm:
		POSITIVE:
			g.fadeOldSchool(0.5)
			g.setColor(1)
			g.drawImage(AbstractPage.images[14], 400, 300)
			g.drawString(name, 430, 360)
			var s: String = str(price) + " gp"
			var x: int = Graphics.calcAlignRight(s, 630)
			g.drawString(s, x, 390)
		NOT_AFFORD:
			g.fadeOldSchool(0.5)
			g.setColor(1)
			g.drawImage(AbstractPage.images[3], 400, 315)
			g.drawString("You can't afford that!", 430, 360)
		CANT_EQUIP:
			g.fadeOldSchool(0.5)
			g.setColor(1)
			g.drawImage(AbstractPage.images[3], 400, 315)
			g.drawString("No one can equip that.", 430, 360)
		CANT_MERGE:
			g.fadeOldSchool(0.5)
			g.setColor(1)
			g.drawImage(AbstractPage.images[3], 400, 315)
			g.drawString("Can't merge that card.", 430, 360)
		POSITIVE_MERGE:
			g.fadeOldSchool(0.5)
			g.setColor(1)
			g.drawImage(AbstractPage.images[3], 400, 315)
			g.drawString("Are you sure?", 430, 360)
		_:
			pass
	confirmNode.drawAllChildren(g)

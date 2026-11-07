class_name AbstractStore
extends Building
## Port of store.AbstractStore: a building where the player can buy things
## (with a confirm dialog).

## Bridge (phase 4.2 step B): the node of a confirm box (show_box).
const MENU_BOX_VIEW := "res://scenes/ui/MenuBox.tscn"

var confirmNode = null # MenuNode
var confirm: int = 0
const POSITIVE = 0
const NOT_AFFORD = 1
const CANT_EQUIP = 2
const CANT_MERGE = 3
const POSITIVE_MERGE = 4


func initStore():
	confirmNode = MenuNode.new(null, "")


## The confirm menu too (Building).
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		MenuNode.releaseTree(confirmNode)


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
##
## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): the dim, the
## box and its list are nodes where they were drawn (draw_dim,
## _show_confirm_box, AbstractPage.draw_list), or drawn with their --legacy
## flags (dim, menu_text, menu_list).
func drawConfirmDialog(g, name = null, price = null):
	if name == null:
		var n = activeNode.getCurrentChild()
		drawConfirmDialog(g, n.getName(), n.getPrice())
		return
	if not Main.is_legacy("menu_text"):
		_show_confirm_box(g, name, price)
	else:
		match confirm:
			POSITIVE:
				draw_dim(g)
				g.setColor(1)
				g.drawImage(AbstractPage.images[14], 400, 300)
				g.drawString(name, 430, 360)
				var s: String = str(price) + " gp"
				var x: int = Graphics.calcAlignRight(s, 630)
				g.drawString(s, x, 390)
			NOT_AFFORD:
				draw_dim(g)
				g.setColor(1)
				g.drawImage(AbstractPage.images[3], 400, 315)
				g.drawString("You can't afford that!", 430, 360)
			CANT_EQUIP:
				draw_dim(g)
				g.setColor(1)
				g.drawImage(AbstractPage.images[3], 400, 315)
				g.drawString("No one can equip that.", 430, 360)
			CANT_MERGE:
				draw_dim(g)
				g.setColor(1)
				g.drawImage(AbstractPage.images[3], 400, 315)
				g.drawString("Can't merge that card.", 430, 360)
			POSITIVE_MERGE:
				draw_dim(g)
				g.setColor(1)
				g.drawImage(AbstractPage.images[3], 400, 315)
				g.drawString("Are you sure?", 430, 360)
			_:
				pass
	AbstractPage.draw_list(g, confirmNode, false, true, false, false, false)


## Bridge (phase 4.2 step B): drawConfirmDialog's dim and box without the
## drawing: the dim (draw_dim), setColor(1), and the box of the current kind
## (show_box: piece 14 with the name and the price right-aligned to 630, or
## piece 3 with the store's answer).
func _show_confirm_box(g, name, price) -> void:
	var image = AbstractPage.images[3]
	var at := Vector2i(400, 315)
	var text: String
	match confirm:
		POSITIVE:
			draw_dim(g)
			g.setColor(1)
			show_box(g, AbstractPage.images[14], Vector2i(400, 300), [
					[name, Vector2i(430, 360), HORIZONTAL_ALIGNMENT_LEFT],
					[str(price) + " gp", Vector2i(630, 390), HORIZONTAL_ALIGNMENT_RIGHT]])
			return
		NOT_AFFORD:
			text = "You can't afford that!"
		CANT_EQUIP:
			text = "No one can equip that."
		CANT_MERGE:
			text = "Can't merge that card."
		POSITIVE_MERGE:
			text = "Are you sure?"
		_:
			return
	draw_dim(g)
	g.setColor(1)
	show_box(g, image, at, [[text, Vector2i(430, 360), HORIZONTAL_ALIGNMENT_LEFT]])


## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): the dim behind
## a confirm box, g.fadeOldSchool(0.5) (the current fade mode's image at
## alpha .5), or with --legacy=dim off its twin: a Fade node on the UI layer,
## before the box and its list (Graphics.show_fade).
static func draw_dim(g) -> void:
	if Main.is_legacy("dim"):
		g.fadeOldSchool(0.5)
	else:
		g.show_fade(0.5, Graphics.UI_LAYER)


## Bridge (phase 4.2 step B): a box's piece (drawImage at at) and its texts
## (drawString each) without the drawing: the piece's bind, drawString's
## setColor(color) after each text (none for null, as drawString), and the
## frame's next MenuBox node on the UI layer shows them (Graphics.show_ui).
## lines: [text, position (the baseline's start, or its end when
## right-aligned: Graphics.calcAlignRight's place), alignment] each.
static func show_box(g, image, at: Vector2i, lines: Array) -> void:
	var mat = g.canvas_material()
	var piece: Array = g.place_image(image, at.x, at.y)
	var shown := []
	for line: Array in lines:
		if line[0] == null:
			continue
		shown.append([str(line[0]), line[1], g.getFontSize(), Graphics.text_color(1.0),
				Graphics.font_bold(), line[2]])
		g.setColor(g.color)
	var view = g.show_ui(MENU_BOX_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_box(piece, shown, mat)

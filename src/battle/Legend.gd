class_name Legend
extends Hideable
## Port of battle.Legend: the button legend shown during the player turn.

const STEP = 40
const IMAGE_HEIGHT = 220
const IMAGE_TEXT_STEP = 24
const TEXT_HEIGHT = IMAGE_HEIGHT + IMAGE_TEXT_STEP
const IMAGE_X = 210.0
const TEXT_X = 680.0
static var INFO = ["Execute", "Choose", "Store", "Discard", "Support", "Offense", "Target"]
static var BATTLE_LEGEND_ACTIVE: bool = true
var support: bool = false


func _init() -> void:
	super(4)
	setLimit(false)
	setMovementSpeed(false)
	instantHide()


func initDraw(g: Graphics):
	setPos(BattleValues.CLOCK_POSITION)


func setSupport(p_support):
	self.support = p_support


## Draws the gradient and the lines (every frame: off the screen while the
## legend is hidden). Bridge (phase 4.4's rollout, part 3): the gradient is a
## PanelQuad in its batch's slot (Graphics.place_gradient). Part 4: the lines
## are a MenuText node on the UI layer in the frame's 2D order (_show_lines).
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	g.loadIdentity()
	g.setFontSize(40)

	translate(g)

	var xl: float = -0.079 + getXtrans()
	var xr: float = 0.26 + getXtrans()
	var ybottom: float = -0.19 # -.145f
	var ytop: float = 0.4
	Utils3D.show_quad(g, [get_instance_id(), &"back"], g.place_gradient(
			Vector3f.ZERO, CreatureRow.BACK_ALPHA_TOP, CreatureRow.BACK_ALPHA_BOTTOM,
			xr, xl, ybottom, ytop, true, true))

	_show_lines(g, int(TEXT_X + super.getXtrans() * 600))


## Bridge (phase 4.4's rollout, part 4, step B, docs/ARCHITECTURE.md section
## 15): the six lines (the Java's drawMultiString calls) without the drawing
## (black at the text alpha, then white
## at alpha 1 two pixels up and to the left, at 24: startText's size, which
## replaces draw's 40): the same text state changes in the same order
## (startText, setTextColorAndApply, finishText), the lines shown by the
## frame's next MenuText on the UI layer in the order they were drawn, in the
## material of the 2D state here (AbstractPage.show_lines).
func _show_lines(g: Graphics, x: int) -> void:
	var lines: Array = []
	g.startText(-1, 0, 24)
	for i in 6:
		g.place_multi_string(lines, INFO[_info_index(i)], x, TEXT_HEIGHT + i * STEP)
	g.setTextColorAndApply(1, 1)
	for i in 6:
		g.place_multi_string(lines, INFO[_info_index(i)], x - 2, TEXT_HEIGHT - 2 + i * STEP)
	g.finishText()
	if not lines.is_empty():
		AbstractPage.show_lines(g, lines)


## The INFO entry of line i: "Support" in offense mode, "Offense" in support mode.
func _info_index(i: int) -> int:
	if i < 4:
		return i
	if i == 4:
		return 5 if support else 4
	return 6


func drawTopLayer(g: Graphics):
	g.setColor(1)
	_show_icons(g, int(IMAGE_X + super.getXtrans() * 200) + AbstractPage.xoffset)


## Bridge (phase 4.4 step B, docs/ARCHITECTURE.md section 15): drawTopLayer's
## six button icons (the Java's drawImage calls) without the drawing (their binds, Graphics.place_image at
## 1:1), shown by the frame's next MenuBackground node on the UI layer
## (AbstractPage.show_pieces) at the x that slides with the legend (off the
## screen at -190 while it is hidden: it is drawn every frame).
func _show_icons(g: Graphics, x: int) -> void:
	AbstractPage.show_pieces(g, [
		g.place_image(AbstractPage.getExecuteButtonIcon(), x, IMAGE_HEIGHT),
		g.place_image(AbstractPage.BUTTON_ICONS[GameMode.CROSS], x, IMAGE_HEIGHT + STEP),
		g.place_image(AbstractPage.BUTTON_ICONS[GameMode.SQUARE], x, IMAGE_HEIGHT + 2 * STEP),
		g.place_image(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], x, IMAGE_HEIGHT + 3 * STEP),
		g.place_image(AbstractPage.BUTTON_ICONS[GameMode.L2R2], x, IMAGE_HEIGHT + 4 * STEP),
		g.place_image(AbstractPage.BUTTON_ICONS[GameMode.L1R1], x, IMAGE_HEIGHT + 5 * STEP)])


static func toggleActive():
	BATTLE_LEGEND_ACTIVE = not BATTLE_LEGEND_ACTIVE


func toggleLegend():
	BATTLE_LEGEND_ACTIVE = not BATTLE_LEGEND_ACTIVE
	if BATTLE_LEGEND_ACTIVE and not visible:
		show()
	elif not BATTLE_LEGEND_ACTIVE and visible:
		hide()

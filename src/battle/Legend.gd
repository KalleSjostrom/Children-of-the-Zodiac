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


func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	g.loadIdentity()
	g.setFontSize(40)

	translate(g)

	var xl: float = -0.079 + getXtrans()
	var xr: float = 0.26 + getXtrans()
	var ybottom: float = -0.19 # -.145f
	var ytop: float = 0.4
	g.drawGradient(
			Vector3f.ZERO, CreatureRow.BACK_ALPHA_TOP, CreatureRow.BACK_ALPHA_BOTTOM,
			xr, xl, ybottom, ytop, true, true)

	var x: int = int(TEXT_X + super.getXtrans() * 600)

	g.startText(-1, 0, 24)
	g.drawMultiString(INFO[0], x, TEXT_HEIGHT)
	g.drawMultiString(INFO[1], x, TEXT_HEIGHT + STEP)
	g.drawMultiString(INFO[2], x, TEXT_HEIGHT + 2 * STEP)
	g.drawMultiString(INFO[3], x, TEXT_HEIGHT + 3 * STEP)
	g.drawMultiString(INFO[5 if support else 4], x, TEXT_HEIGHT + 4 * STEP)
	g.drawMultiString(INFO[6], x, TEXT_HEIGHT + 5 * STEP)
	g.setTextColorAndApply(1, 1)
	x -= 2
	var y: int = TEXT_HEIGHT - 2
	g.drawMultiString(INFO[0], x, y)
	g.drawMultiString(INFO[1], x, y + STEP)
	g.drawMultiString(INFO[2], x, y + 2 * STEP)
	g.drawMultiString(INFO[3], x, y + 3 * STEP)
	g.drawMultiString(INFO[5 if support else 4], x, y + 4 * STEP)
	g.drawMultiString(INFO[6], x, y + 5 * STEP)
	g.finishText()


func drawTopLayer(g: Graphics):
	g.setColor(1)
	var x: int = int(IMAGE_X + super.getXtrans() * 200) + AbstractPage.xoffset
	g.drawImage(AbstractPage.getExecuteButtonIcon(), x, IMAGE_HEIGHT)
	g.drawImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], x, IMAGE_HEIGHT + STEP)
	g.drawImage(AbstractPage.BUTTON_ICONS[GameMode.SQUARE], x, IMAGE_HEIGHT + 2 * STEP)
	g.drawImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], x, IMAGE_HEIGHT + 3 * STEP)
	g.drawImage(AbstractPage.BUTTON_ICONS[GameMode.L2R2], x, IMAGE_HEIGHT + 4 * STEP)
	g.drawImage(AbstractPage.BUTTON_ICONS[GameMode.L1R1], x, IMAGE_HEIGHT + 5 * STEP)


static func toggleActive():
	BATTLE_LEGEND_ACTIVE = not BATTLE_LEGEND_ACTIVE


func toggleLegend():
	BATTLE_LEGEND_ACTIVE = not BATTLE_LEGEND_ACTIVE
	if BATTLE_LEGEND_ACTIVE and not visible:
		show()
	elif not BATTLE_LEGEND_ACTIVE and visible:
		hide()

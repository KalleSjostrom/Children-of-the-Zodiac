class_name AttackText
extends RefCounted
## Port of battle.AttackText: the texts shown when a creature has attacked
## ("Miss!", "Critical Hit!", "31", ...). The texts move upwards while fading.
##
## Port notes: JOGL's TextRenderer (3D text rendering) does not exist in the
## framework. A "renderer" here is [fontSize, bold]; draw3DText() projects the
## 3D text position with the current modelview and the game's perspective
## (gluPerspective(45, 4/3, 1, 75)) and draws the text in screen space with
## the scaled font size.

var textToDraw = []
var text = null
var smallText = null
var smallerText = null
var smallestText = null
static var attackText = null
## Bridge (phase 4.4's rollout, part 4): the node of the texts.
const ATTACK_TEXTS_VIEW := "res://scenes/ui/AttackTexts.tscn"
const HALF_DISTANCE = 1.39
const HEIGHT_DISTANCE_BETWEEN_TEXT = 0.1


## Creates a new AttackText (renderers of size 40, 30, bold 20 and bold 16).
func _init() -> void:
	text = [40, false]
	smallText = [30, false]
	smallerText = [20, true]
	smallestText = [16, true]


static func getAttackText():
	if attackText == null:
		attackText = AttackText.new()
	return attackText


func update(elapsedTime):
	var i: int = 0
	while i < textToDraw.size():
		if not textToDraw[i].update():
			J.removeAt(textToDraw, i)
			i -= 1
		i += 1


## Draws the stored texts. Loads identity and translates 2 units into the screen.
## Bridge (phase 4.4's rollout, part 4, step B, docs/ARCHITECTURE.md section
## 15): the texts are an AttackTexts node on the UI layer in the frame's 2D
## order (_show_texts: the same state changes); --legacy=battle_attack_text
## keeps the legacy text.
func draw(g):
	g.loadIdentity()
	g.translate(0, 0, BattleValues.STANDARD_Z_DEPTH)
	g.scale(0.8)
	if not Main.is_legacy("battle_attack_text"):
		_show_texts(g)
	else:
		for i in range(textToDraw.size()):
			var t = textToDraw[i]
			t.draw(g)
	g.loadIdentity()


## Bridge (phase 4.4's rollout, part 4): the texts' drawing without the
## drawing (each text's colour at its life and blend function, then its
## place: AttackTextText.place_text), shown by the frame's next AttackTexts
## node on the UI layer in the material of the 2D state where they were
## drawn; texts drawn in another material (a canvas item of their own in the
## legacy drawing) go to a node of their own, in order. Nothing is shown when
## no text is drawn.
func _show_texts(g) -> void:
	var texts: Array = []
	var mat: Material = null
	for i in range(textToDraw.size()):
		var t: Array = textToDraw[i].place_text(g)
		if t.is_empty():
			continue
		var m: Material = g.canvas_material()
		if not texts.is_empty() and m != mat:
			_show_view(g, texts, mat)
			texts = []
		mat = m
		texts.append(t)
	if not texts.is_empty():
		_show_view(g, texts, mat)


static func _show_view(g, texts: Array, mat: Material) -> void:
	var view = g.show_ui(ATTACK_TEXTS_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_texts(texts, mat)


## Checks if there are no more texts in this AttackText.
func isDone():
	return textToDraw.size() == 0


func reset():
	textToDraw.clear()


## Java overloads:
##   addCenter(String|int info, float centerx, float y, boolean support, textSize size)
##   addCenter(String|int info, float centerx, float y, boolean support)  [SMALLEST]
##   addCenter(String info, boolean support)                              [0, 0]
##   addCenter(String info, boolean support, float y)                     [x = 0]
##   addCenter(int damage, boolean support)                               [0, 0]
func addCenter(info, centerx, y = null, support = null, size = null):
	var s: String = str(info)
	var cxf: float
	var yy: float
	var sup: bool
	if centerx is bool:
		sup = centerx
		cxf = 0.0
		yy = 0.0 if y == null else float(y)
	else:
		cxf = float(centerx)
		yy = float(y)
		sup = bool(support)
	if size == null:
		size = textSize.SMALLEST
	cxf += HALF_DISTANCE
	cxf /= 2 * HALF_DISTANCE
	var cx: int = J.round(cxf * Values.ORIGINAL_RESOLUTION[Values.X])
	var x: float = calcAlignCenterTest(s, cx, getRenderer(size), 1.8)
	cxf = x / Values.ORIGINAL_RESOLUTION[Values.X]
	cxf *= (2 * HALF_DISTANCE)
	cxf -= HALF_DISTANCE
	# centerx -= .1f
	add(s, cxf, yy, sup, size)


## Java overloads add(info, x, y, support) [SMALL] and add(info, x, y, support, size).
func add(info, x, y, support, size = null):
	if size == null:
		size = textSize.SMALL
	var t := AttackTextText.new(str(info))
	t.setXY(x, y)
	t.setRenderer(getRenderer(size))
	t.setColor(AttackTextText.GREEN if support else AttackTextText.RED)
	textToDraw.append(t)


func getRenderer(size):
	var t = null
	match size:
		textSize.LARGE:
			t = text
		textSize.MEDIUM:
			t = smallText
		textSize.SMALL:
			t = smallerText
		textSize.SMALLEST:
			t = smallestText
	return t


static func getSize(large):
	return textSize.MEDIUM if large else textSize.SMALLEST


## Local replacement of Graphics.calcAlignCenterTest(string, center, renderer, scale):
## measures the string with the renderer font (not the current font).
static func calcAlignCenterTest(string: String, center: int, rend, p_scale: float) -> int:
	var font: Font = _getFont(rend)
	var w: float = font.get_string_size(string, HORIZONTAL_ALIGNMENT_LEFT, -1, rend[0]).x
	var halfWidth: int = J.round((w * p_scale) / 2.0)
	return center - halfWidth


static func _getFont(rend) -> Font:
	Graphics.getFont() # makes sure the fonts are loaded
	return Graphics._fonts[Values.BOLD if rend[1] else Values.PLAIN]


## Local replacement of TextRenderer.draw3D(text, x, y, z, scaleFactor):
## the text baseline starts at (x, y, z) in the current modelview space and
## one font pixel is scaleFactor units wide.
static func draw3DText(g, s: String, x: float, y: float, z: float, scaleFactor: float,
		rend, col: Color) -> void:
	if g.backend == null:
		return
	var t: Array = place_3d_text(g, s, x, y, z, scaleFactor, rend, col)
	if t.is_empty():
		return
	var ci: RID = g.backend.ci_2d(g._blend_dst == Graphics.GL_ONE, g._effAlphaFunc(), g._alpha_ref)
	g.backend.set_ci_transform(ci, Transform2D.IDENTITY)
	_getFont(rend).draw_string(ci, t[1], s, HORIZONTAL_ALIGNMENT_LEFT, -1, t[2], col)


## Bridge (phase 4.4's rollout, part 4, step B, docs/ARCHITECTURE.md section
## 15): where draw3DText draws the text, without the drawing: [text, the
## baseline's start on the screen (the projection of (x, y, z) through the
## modelview: not whole pixels), the font size in pixels (the renderer's size
## times scaleFactor, the modelview's scale and the projection's scale there),
## bold, colour], or [] when nothing is drawn (an empty text, a point at or
## behind the eye).
static func place_3d_text(g, s: String, x: float, y: float, z: float, scaleFactor: float,
		rend, col: Color) -> Array:
	if s == "":
		return []
	var mv: Transform3D = g.getModelView()
	var p: Vector3 = mv * Vector3(x, y, z)
	if p.z > -0.0001:
		return []
	var half_h: float = GLBackend.VIRTUAL_SIZE.y / 2.0
	var half_w: float = GLBackend.VIRTUAL_SIZE.x / 2.0
	var f: float = half_h / tan(deg_to_rad(22.5)) / -p.z
	var mvScale: float = mv.basis.x.length()
	var px: int = maxi(1, int(round(rend[0] * scaleFactor * mvScale * f)))
	var sx: float = half_w + p.x * f
	var sy: float = half_h - p.y * f
	return [s, Vector2(sx, sy), px, bool(rend[1]), col]


## Java enum AttackText.textSize.
class textSize extends RefCounted:
	const LARGE = 0
	const MEDIUM = 1
	const SMALL = 2
	const SMALLEST = 3


## Java inner class AttackText.Text: one text drawn in 3D space that moves
## upwards while fading.
class AttackTextText extends RefCounted:
	static var GREEN = [0.0, 1.0, 0.0]
	static var RED = [1.0, 0.0, 0.0]
	var textRenderer = null
	var text: String = ""
	var life: float = 1.0
	var x: float = (J.random() - 0.5) / 2
	var y: float = 0.0
	static var FADE: float = 0.00048
	var color = RED

	func _init(info = null) -> void:
		text = str(info)

	func setColor(newColor):
		color = newColor

	func setXY(p_x, p_y):
		self.x = p_x
		self.y = p_y # - .15f + Values.rand.nextFloat() * .3f

	func setRenderer(renderer):
		textRenderer = renderer

	## Draws the string with the renderer (TextRenderer.draw3D in Java).
	func draw(g):
		g.setColor(color[0], color[1], color[2], life)
		g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
		AttackText.draw3DText(g, text, x, y + (1 - life) / 5, 0, 0.005, textRenderer,
				Color(color[0], color[1], color[2], life))

	## Bridge (phase 4.4's rollout, part 4): draw without the drawing: the same
	## colour and blend function, and the text where it would be drawn
	## (AttackText.place_3d_text; [] when it would draw nothing).
	func place_text(g) -> Array:
		g.setColor(color[0], color[1], color[2], life)
		g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
		return AttackText.place_3d_text(g, text, x, y + (1 - life) / 5, 0, 0.005, textRenderer,
				Color(color[0], color[1], color[2], life))

	## Reduces the life by FADE; returns true if life is above zero.
	func update():
		life -= FADE * Values.LOGIC_INTERVAL
		return life > 0

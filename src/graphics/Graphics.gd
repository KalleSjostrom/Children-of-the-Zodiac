class_name Graphics
extends RefCounted
## Port of graphics.Graphics plus an emulation of the OpenGL 2 / GLU calls the
## original game made through JOGL.
##
## The original wrapped JOGL in a Graphics2D-like API. Everything (including
## images) was drawn as textured quads in immediate mode, either with a 2D
## orthographic projection (1024x768, y down) or a 3D perspective projection
## (gluPerspective(45, 4/3, 1, 75)). This class keeps the same GL state
## machine semantics (current color, matrix stack, blend/alpha/depth state,
## lights, fog, display lists) and hands finished primitives to GLBackend.
##
## Java code that used the GL object directly (`GL2 gl = g.getGL();
## gl.glVertex3f(...)`) keeps working: getGL() returns this object, which
## implements the gl* / glu* methods used by the game. Graphics.gl and
## Graphics.glu also point to the active instance.

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const FADE_TO_BLACK := 0
const FADE_TO_WHITE := 1
const FADE_TO_IMAGE := 2

# OpenGL constants (same values as in GL2).
const GL_NO_ERROR := 0
const GL_POINTS := 0x0000
const GL_LINES := 0x0001
const GL_LINE_LOOP := 0x0002
const GL_LINE_STRIP := 0x0003
const GL_TRIANGLES := 0x0004
const GL_TRIANGLE_STRIP := 0x0005
const GL_TRIANGLE_FAN := 0x0006
const GL_QUADS := 0x0007
const GL_QUAD_STRIP := 0x0008
const GL_POLYGON := 0x0009
const GL_NEVER := 0x0200
const GL_LESS := 0x0201
const GL_EQUAL := 0x0202
const GL_LEQUAL := 0x0203
const GL_GREATER := 0x0204
const GL_NOTEQUAL := 0x0205
const GL_GEQUAL := 0x0206
const GL_ALWAYS := 0x0207
const GL_ZERO := 0
const GL_ONE := 1
const GL_SRC_COLOR := 0x0300
const GL_ONE_MINUS_SRC_COLOR := 0x0301
const GL_SRC_ALPHA := 0x0302
const GL_ONE_MINUS_SRC_ALPHA := 0x0303
const GL_DST_ALPHA := 0x0304
const GL_ONE_MINUS_DST_ALPHA := 0x0305
const GL_FRONT := 0x0404
const GL_BACK := 0x0405
const GL_FRONT_AND_BACK := 0x0408
const GL_CULL_FACE := 0x0B44
const GL_LIGHTING := 0x0B50
const GL_COLOR_MATERIAL := 0x0B57
const GL_FOG := 0x0B60
const GL_DEPTH_TEST := 0x0B71
const GL_ALPHA_TEST := 0x0BC0
const GL_BLEND := 0x0BE2
const GL_TEXTURE_2D := 0x0DE1
const GL_NORMALIZE := 0x0BA1
const GL_LIGHT0 := 0x4000
const GL_LIGHT1 := 0x4001
const GL_LIGHT2 := 0x4002
const GL_LIGHT3 := 0x4003
const GL_LIGHT4 := 0x4004
const GL_LIGHT5 := 0x4005
const GL_LIGHT6 := 0x4006
const GL_LIGHT7 := 0x4007
const GL_AMBIENT := 0x1200
const GL_DIFFUSE := 0x1201
const GL_SPECULAR := 0x1202
const GL_POSITION := 0x1203
const GL_SPOT_DIRECTION := 0x1204
const GL_CONSTANT_ATTENUATION := 0x1207
const GL_LINEAR_ATTENUATION := 0x1208
const GL_QUADRATIC_ATTENUATION := 0x1209
const GL_EMISSION := 0x1600
const GL_SHININESS := 0x1601
const GL_AMBIENT_AND_DIFFUSE := 0x1602
const GL_LIGHT_MODEL_AMBIENT := 0x0B53
const GL_FOG_DENSITY := 0x0B62
const GL_FOG_START := 0x0B63
const GL_FOG_END := 0x0B64
const GL_FOG_MODE := 0x0B65
const GL_FOG_COLOR := 0x0B66
const GL_FOG_HINT := 0x0C54
const GL_PERSPECTIVE_CORRECTION_HINT := 0x0C50
const GL_NICEST := 0x1102
const GL_FASTEST := 0x1101
const GL_DONT_CARE := 0x1100
const GL_EXP := 0x0800
const GL_EXP2 := 0x0801
const GL_LINEAR := 0x2601
const GL_SMOOTH := 0x1D01
const GL_FLAT := 0x1D00
const GL_MODELVIEW := 0x1700
const GL_PROJECTION := 0x1701
const GL_COLOR_BUFFER_BIT := 0x4000
const GL_DEPTH_BUFFER_BIT := 0x0100
const GL_LIGHTING_BIT := 0x0040
const GL_ENABLE_BIT := 0x2000
const GL_CURRENT_BIT := 0x0001
const GL_COMPILE := 0x1300
const GL_COMPILE_AND_EXECUTE := 0x1301
const GL_TRUE := 1
const GL_FALSE := 0

# ---------------------------------------------------------------------------
# Static state (as in the Java class)
# ---------------------------------------------------------------------------

## The active Graphics (JOGL's GL / GLU objects map to it).
static var gl: Graphics
static var glu: Graphics
static var fadeMode := FADE_TO_BLACK
static var fadeImageName := ""
## Java's Graphics.fadeImage etc. were BufferedImages; here they are Images.
static var fadeImage: Image
static var whiteFadeImage: Image
static var textBack: Image
## Current text color (r, g, b).
static var textColor := [0.0, 0.0, 0.0]

# TextManager: fonts exist in even sizes 20..50, plain and bold.
static var _fontSize := 24
static var _fontType := 0
static var _fonts: Array = []
# Caches for getStringWidth: ink extents Vector2(min x, max x) by
# "font size glyph", and widths by "type size string".
static var _glyphInks := {}
static var _boundsWidths := {}

# ---------------------------------------------------------------------------
# Instance state
# ---------------------------------------------------------------------------

var backend: GLBackend
var color := 0.0 # last value given to setColor(float)
var _fadeColor := [1.0, 1.0, 1.0, 1.0]
var textStarted := false
var _textAlpha := 1.0

# GL state machine
var _cur_color := Color(1, 1, 1, 1)
var _cur_uv := Vector2.ZERO
var _cur_normal := Vector3(0, 0, 1)
var _mv := Transform3D.IDENTITY
var _mv_stack: Array[Transform3D] = []
var _matrix_mode := GL_MODELVIEW
var _proj3d := false
var _caps := {}
var _blend_dst := GL_ONE_MINUS_SRC_ALPHA
var _alpha_func := GL_LEQUAL
var _alpha_ref := 1.0
var _depth_mask := true
var _cull_mode := GL_BACK
var _bound: GameTexture = null
var _attrib_stack: Array = []
## Bridge (COTZ-011): while true, 3D drawing ignores the depth test and is
## drawn over everything drawn before it, in submission order (every 3D batch
## is in the transparent pass, sorted by submission). The battle interface
## uses it: it is 3D geometry at z = -2, the plane of the walls of the
## player's labyrinth node.
var ignore_depth_test := false

var _fog := {"mode": GL_EXP, "density": 1.0, "start": 0.0, "end": 1.0, "color": Color(0, 0, 0, 0)}
var _lights: Array = []
var _mat := {"ambient": Color(0.2, 0.2, 0.2, 1), "diffuse": Color(0.8, 0.8, 0.8, 1),
	"specular": Color(0, 0, 0, 1), "emission": Color(0, 0, 0, 1), "shininess": 0.0}

# Immediate mode buffers
var _im_mode := -1
var _im_v := PackedVector3Array()
var _im_uv := PackedVector2Array()
var _im_c := PackedColorArray()
var _im_n := PackedVector3Array()

# Display lists
var _next_list := 1
var _lists := {}
var _compiling: DisplayList = null


func _init(p_backend: GLBackend = null) -> void:
	backend = p_backend
	gl = self
	glu = self
	for i in 8:
		_lights.append({"pos": Vector4(0, 0, 1, 0), "ambient": Color(0, 0, 0, 1),
			"diffuse": Color(1, 1, 1, 1) if i == 0 else Color(0, 0, 0, 1),
			"specular": Color(1, 1, 1, 1) if i == 0 else Color(0, 0, 0, 1),
			"att": Vector3(1, 0, 0)})
	_loadFonts()
	if fadeImage == null:
		fadeImage = GraphicHelp.getImage(0.125, 0.125, Color.BLACK)
		whiteFadeImage = GraphicHelp.getImage(0.125, 0.125, Color.WHITE)
		textBack = GraphicHelp.getImage(1, 0.25, Color.BLACK)
	# GameEventListener.init()
	_caps[GL_CULL_FACE] = true
	_cull_mode = GL_BACK
	_caps[GL_BLEND] = true
	_caps[GL_ALPHA_TEST] = true
	_blend_dst = GL_ONE_MINUS_SRC_ALPHA
	_alpha_func = GL_LEQUAL
	_alpha_ref = 1.0


static func _loadFonts() -> void:
	if _fonts.size() > 0:
		return
	_fonts = [load("res://res/Main/font.ttf"), load("res://res/Main/boldfont.ttf")]


## Called by the main loop at the start of each frame (GameEventListener.display).
func beginFrame(proj3d: bool) -> void:
	_matrix_mode = GL_MODELVIEW
	_mv = Transform3D.IDENTITY
	_mv_stack.clear()
	_im_mode = -1
	_setProjection(proj3d)
	_caps[GL_TEXTURE_2D] = true


func _setProjection(to3d: bool) -> void:
	_proj3d = to3d
	if to3d:
		_depth_mask = true
		_caps[GL_DEPTH_TEST] = true
	else:
		_depth_mask = false
		_caps[GL_DEPTH_TEST] = false
		_caps[GL_LIGHTING] = false


## GameEventListener.setRenderModeNow: switches projection and loads identity.
func setRenderModeNow(to2d: bool) -> void:
	_setProjection(not to2d)
	_matrix_mode = GL_MODELVIEW
	_mv = Transform3D.IDENTITY
	if not to2d and backend:
		backend.break_3d()


func is3D() -> bool:
	return _proj3d


func getGL() -> Graphics:
	return self


func setGL(p_gl) -> void:
	pass


# ===========================================================================
# Image drawing (2D quads, affected by the modelview matrix and glColor)
# ===========================================================================

func drawi(tc, x: int, yh: int, xw: int, y: int, begin: bool = true) -> void:
	if begin:
		beginQuads()
	glTexCoord2f(tc.left(), tc.bottom())
	glVertex2i(x, yh)
	glTexCoord2f(tc.right(), tc.bottom())
	glVertex2i(xw, yh)
	glTexCoord2f(tc.right(), tc.top())
	glVertex2i(xw, y)
	glTexCoord2f(tc.left(), tc.top())
	glVertex2i(x, y)
	if begin:
		end()


func drawip(tc, x: int, yh: int, xw: int, y: int, a, b = null) -> void:
	# Java overloads: drawip(tc, x, yh, xw, y, percent)
	#                 drawip(tc, x, yh, xw, y, begin, percent)
	var begin := true
	var percent: float
	if b == null:
		percent = a
	else:
		begin = a
		percent = b
	if begin:
		beginQuads()
	glTexCoord2f(tc.left(), tc.bottom())
	glVertex2i(x, yh)
	glTexCoord2f(tc.right() * percent, tc.bottom())
	glVertex2i(xw, yh)
	glTexCoord2f(tc.right() * percent, tc.top())
	glVertex2i(xw, y)
	glTexCoord2f(tc.left(), tc.top())
	glVertex2i(x, y)
	if begin:
		end()


func drawipp(tc, x: int, yh: int, xw: int, y: int, a, b, c = null) -> void:
	# Java overloads: drawipp(tc, x, yh, xw, y, percentLow, percentHigh)
	#                 drawipp(tc, x, yh, xw, y, begin, percentLow, percentHigh)
	var begin := true
	var lo: float
	var hi: float
	if c == null:
		lo = a
		hi = b
	else:
		begin = a
		lo = b
		hi = c
	if begin:
		beginQuads()
	glTexCoord2f(tc.left() + lo, tc.bottom())
	glVertex2i(x, yh)
	glTexCoord2f(tc.right() * hi, tc.bottom())
	glVertex2i(xw, yh)
	glTexCoord2f(tc.right() * hi, tc.top())
	glVertex2i(xw, y)
	glTexCoord2f(tc.left() + lo, tc.top())
	glVertex2i(x, y)
	if begin:
		end()


func drawf(tc, x: float, yh: float, xw: float, y: float, begin: bool = true) -> void:
	if begin:
		beginQuads()
	glTexCoord2f(tc.left(), tc.bottom())
	glVertex2f(x, yh)
	glTexCoord2f(tc.right(), tc.bottom())
	glVertex2f(xw, yh)
	glTexCoord2f(tc.right(), tc.top())
	glVertex2f(xw, y)
	glTexCoord2f(tc.left(), tc.top())
	glVertex2f(x, y)
	if begin:
		end()


func draw3f(tc, flip: bool, x: float, y: float, z: float, x2: float, y2: float,
		z2: float, begin: bool = true) -> void:
	if begin:
		beginQuads()
	glTexCoord2f(tc.left() if flip else tc.right(), tc.top() if flip else tc.bottom())
	glVertex3f(x, y, z)
	glTexCoord2f(tc.left() if flip else tc.right(), tc.bottom() if flip else tc.top())
	glVertex3f(x, y2, z)
	glTexCoord2f(tc.right() if flip else tc.left(), tc.bottom() if flip else tc.top())
	glVertex3f(x2, y2, z)
	glTexCoord2f(tc.right() if flip else tc.left(), tc.top() if flip else tc.bottom())
	glVertex3f(x2, y, z)
	if begin:
		end()


## Java overloads:
##   drawImage(BufferedImage|String image, x, y)
##   drawImage(BufferedImage|String image, x, y, float scale)
##   drawImage(String name, x, y, int w, int h, float scale, float percent)
##   drawImage(String name, x, y, int w, int h, float scale, float lo, float hi)
## The image may be a path (String), an Image (BufferedImage) or a GameTexture.
func drawImage(image, x, y, a = null, b = null, c = null, d = null, e = null) -> void:
	if image == null:
		return
	var t := _toTexture(image)
	if t == null:
		return
	if c == null:
		var scale: float = 1.0 if a == null else float(a)
		t.draw(self, roundi(x), roundi(y), scale)
	elif e == null:
		t.drawPart(self, int(x), int(y), a, b, c, d)
	else:
		t.drawPartRange(self, int(x), int(y), a, b, c, d, e)


func _toTexture(image) -> GameTexture:
	if image is GameTexture:
		return image
	if image is String or image is StringName:
		return ImageHandler.getTexture(image)
	if image is Image:
		return ImageHandler.getGameTexture(image)
	if image is Texture2D:
		return GameTexture.new("", image)
	push_error("Graphics.drawImage: unsupported image " + str(image))
	return null


## Java: drawTexture(GameTexture t, x, y[, size]) and
## drawTexture(t, x, y, w, h, size, percent[, percentHigh]).
func drawTexture(t: GameTexture, x: int, y: int, a = null, b = null, c = null, d = null, e = null) -> void:
	if t == null:
		return
	if c == null:
		t.draw(self, x, y, 1.0 if a == null else float(a))
	elif e == null:
		t.drawPart(self, x, y, a, b, c, d)
	else:
		t.drawPartRange(self, x, y, a, b, c, d, e)


## Java: drawCenteredImage(String name, int y) and (String name, int x, int y).
func drawCenteredImage(name: String, a: int, b = null) -> void:
	var t := ImageHandler.getTexture(name)
	if t == null:
		return
	var width := J.round(t.getWidth() / 2.0)
	if b == null:
		var hx: int = Values.ORIGINAL_RESOLUTION[Values.X] / 2
		drawImage(name, hx - width, a)
	else:
		drawImage(name, a - width, b)


## Java: GameTexture[][] get(String[][] names) (renamed: 'get' is reserved).
func get_(names: Array) -> Array:
	var gts: Array = []
	for i in names.size():
		var row: Array = []
		for j in names[0].size():
			row.append(ImageHandler.getTexture(names[i][j]))
		gts.append(row)
	return gts


func getWidth(name: String) -> float:
	var t := ImageHandler.getTexture(name)
	return t.getWidth() if t else 0.0


func getHeight(name: String) -> float:
	var t := ImageHandler.getTexture(name)
	return t.getHeight() if t else 0.0


# ===========================================================================
# Text drawing (JOGL TextRenderer: always screen space, not affected by the
# modelview matrix or glColor; y is the baseline)
# ===========================================================================

static func getFont() -> Font:
	_loadFonts()
	return _fonts[_fontType]


func _drawText(s: String, x: float, y: float, col: Color) -> void:
	if s == null or s == "":
		return
	if backend == null:
		return
	var ci := backend.ci_2d(_blend_dst == GL_ONE, _effAlphaFunc(), _alpha_ref)
	backend.set_ci_transform(ci, Transform2D.IDENTITY)
	getFont().draw_string(ci, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, _fontSize, col)


func _effAlphaFunc() -> int:
	return _alpha_func if _caps.get(GL_ALPHA_TEST, false) else GL_ALWAYS


## Java overloads: drawString(s, x, y) and drawString(s, x, y, alpha).
func drawString(string, x, y, alpha: float = 1.0) -> void:
	if string == null:
		return
	_drawText(str(string), x, y, Color(textColor[0], textColor[1], textColor[2], alpha))
	setColor(color)


func drawStringSetSize(string: String, x: int, y: int, size: int) -> void:
	setFontSize(size)
	drawString(string, x, y, 1)


func drawMultiString(string, x: int, y: int) -> void:
	if string == null:
		return
	_drawText(str(string), x, y, Color(textColor[0], textColor[1], textColor[2], _textAlpha))


## Java overloads: startText(), startText(alpha, color), startText(alpha, color, fontSize).
func startText(alpha = null, c = null, fontSize: int = -1) -> void:
	if alpha == null:
		alpha = -1.0
		c = -1.0
	if not textStarted:
		setFontSize(fontSize)
		setTextColor(float(c))
		textStarted = true
		if alpha <= -1:
			alpha = Organizer.getOrganizer().getCurrentMode().fadeValue
		_textAlpha = alpha


func finishText() -> void:
	textStarted = false
	setColor(color)


## Java overloads:
##   drawSingleCenteredText(s, y)
##   drawSingleCenteredText(s, y, int x)
##   drawSingleCenteredText(s, y, float alpha, float c)
##   drawSingleCenteredText(s, y, alpha, c, int center)
##   drawSingleCenteredText(s, y, alpha, c, int fontSize, int center)
func drawSingleCenteredText(string: String, y: int, a = null, b = null, c = null, d = null) -> void:
	var hx: int = Values.ORIGINAL_RESOLUTION[Values.X] / 2
	var alpha := 1.0
	var col := 1.0
	var fontSize := -1
	var center := hx
	if a != null and b == null:
		center = a
	elif a != null:
		alpha = a
		col = b
		if d != null:
			fontSize = c
			center = d
		elif c != null:
			center = c
	setFontSize(fontSize)
	startText(alpha, col)
	drawMultiCenteredText(string, y, center)
	finishText()


func drawMultiCenteredText(string: String, y: int, x = null) -> void:
	if x == null:
		x = Values.ORIGINAL_RESOLUTION[Values.X] / 2
	var nx := calcAlignCenter(string, x)
	drawMultiString(string, nx, y)


static func _stringWidth(string: String, size: int = -1) -> float:
	if string == null:
		return 0.0
	return getFont().get_string_size(string, HORIZONTAL_ALIGNMENT_LEFT, -1,
		_fontSize if size < 0 else size).x


static func calcAlignRight(string: String, rightMostLimit: int) -> int:
	return rightMostLimit - J.round(_stringWidth(string))


static func calcAlignCenter(string: String, center: int, rend = null) -> int:
	var halfWidth := J.round(_stringWidth(string) / 2.0)
	return center - halfWidth


static func calcAlignCenterTest(string: String, center: int, rend, scale: float) -> int:
	var halfWidth := J.round((_stringWidth(string) * scale) / 2.0)
	return center - halfWidth


## JOGL TextRenderer.getBounds(string).getWidth(): the width of the glyphs'
## ink (GlyphVector.getVisualBounds, so spaces do not count) plus a border of
## max(1, 0.015 * size) pixels on each side. Not the advance width: Row adds
## a space to every word, and the advance width spread the words too far.
static func getStringWidth(string: String) -> int:
	var key := "%d %d %s" % [_fontType, _fontSize, string]
	var w = _boundsWidths.get(key)
	if w != null:
		return w
	var ts := TextServerManager.get_primary_interface()
	var shaped := ts.create_shaped_text()
	ts.shaped_text_add_string(shaped, string, getFont().get_rids(), _fontSize)
	var pen := 0.0
	var minx := INF
	var maxx := -INF
	for gl in ts.shaped_text_get_glyphs(shaped):
		var ink := _glyphInk(ts, gl.font_rid, gl.font_size, gl.index)
		if ink.x <= ink.y:
			minx = minf(minx, pen + gl.offset.x + ink.x)
			maxx = maxf(maxx, pen + gl.offset.x + ink.y)
		pen += gl.advance
	ts.free_rid(shaped)
	var inkWidth := maxx - minx if minx <= maxx else 0.0
	w = ceili(inkWidth + 2 * maxi(1, int(0.015 * _fontSize)))
	_boundsWidths[key] = w
	return w


static func _glyphInk(ts: TextServer, font: RID, size: int, index: int) -> Vector2:
	var key := "%d %d %d" % [font.get_id(), size, index]
	var ink = _glyphInks.get(key)
	if ink == null:
		ink = Vector2(INF, -INF)
		var points: PackedVector3Array = ts.font_get_glyph_contours(font, size, index).get(
				"points", PackedVector3Array())
		for p in points:
			ink.x = minf(ink.x, p.x)
			ink.y = maxf(ink.y, p.x)
		_glyphInks[key] = ink
	return ink


func drawStringRightWithReg(text: String, y: int) -> void:
	drawString(text, calcAlignRight(text, 985), y)


func drawStringRightAligned(text: String, y: int, rightLimit: int) -> void:
	drawString(text, calcAlignRight(text, rightLimit), y)


func drawValueWithShadow(value: int, x: int, y: int, c: Color) -> void:
	setTextColor(JColor.black)
	drawString(str(value), x + 1, y + 1)
	if value > 0:
		setTextColor(c)
	else:
		setTextColor(JColor.white)
	drawString(str(value), x, y)


## Java overloads: drawWithShadow(String|int, x, y[, Color]).
func drawWithShadow(string, x: int, y: int, c = null) -> void:
	if c == null:
		c = JColor.white
	var s := str(string)
	setTextColor(JColor.black)
	drawString(s, x + 1, y + 1)
	setTextColor(c)
	drawString(s, x, y)


## Java overloads: setTextColor(Color), (float r, g, b), (Vector3f), (float i).
static func setTextColor(a, g = null, b = null) -> void:
	if a is Color:
		textColor[0] = a.r
		textColor[1] = a.g
		textColor[2] = a.b
	elif g != null:
		textColor[0] = float(a)
		textColor[1] = float(g)
		textColor[2] = float(b)
	elif a is Object and a.has_method("getX"):
		textColor[0] = a.x
		textColor[1] = a.y
		textColor[2] = a.z
	elif a is Vector3:
		textColor[0] = a.x
		textColor[1] = a.y
		textColor[2] = a.z
	else:
		var i := float(a)
		if i >= 0 and i <= 1:
			textColor[0] = i
			textColor[1] = i
			textColor[2] = i


## Java overloads: setTextColorAndApply(Vector3f) and (float i, float alpha).
func setTextColorAndApply(a, alpha: float = 1.0) -> void:
	setTextColor(a)
	_textAlpha = alpha


func setFontSize(size: int, bold = null) -> void:
	if size > 0:
		if size >= 20 and size <= 50 and size % 2 == 0:
			_fontSize = size
			if bold != null:
				_fontType = Values.BOLD if bold else Values.PLAIN
		else:
			push_warning("Font size must be an even integer between 20 and 50, not " + str(size))


func getFontSize() -> int:
	return _fontSize


static func getCurrentFontSize() -> int:
	return _fontSize


# ===========================================================================
# Color / fading
# ===========================================================================

func fade(fv: float) -> void:
	if fadeMode == FADE_TO_WHITE:
		fv = 1 - fv
	if fv < 1:
		glColor3f(fv, fv, fv)


func dim(alpha: float) -> void:
	glColor4f(1, 1, 1, alpha)


func fadeOldSchool(fadeindex: float) -> void:
	fadeindex = 0.0 if fadeindex <= 0 else fadeindex
	if fadeindex < 1:
		glColor4f(_fadeColor[0], _fadeColor[1], _fadeColor[2], 1 - fadeindex)
		match fadeMode:
			FADE_TO_WHITE:
				drawImage(whiteFadeImage, 0, 0, 8)
			FADE_TO_BLACK:
				drawImage(fadeImage, 0, 0, 8)
			FADE_TO_IMAGE:
				drawImage(fadeImageName, 0, 0, 1)


func fadeOldSchoolColor(r: float, g: float, b: float, a: float) -> void:
	glColor4f(r, g, b, a)
	drawImage(fadeImage, 0, 0, 8)
	glColor4f(1, 1, 1, 1)


func fadeOldSchoolColorWhite(r: float, g: float, b: float, a: float) -> void:
	glColor4f(r, g, b, a)
	drawImage(whiteFadeImage, 0, 0, 8)
	glColor4f(1, 1, 1, 1)


## Java overloads: setFadeImage(int mode) and setFadeImage(String image).
static func setFadeImage(image) -> void:
	if image is String:
		fadeMode = FADE_TO_IMAGE
		fadeImageName = image
	else:
		fadeMode = int(image)


func setImageColor(r: float, g: float, b: float, a: float) -> void:
	glColor4f(r, g, b, a)


func setFadeColor(r: float, g: float, b: float, a: float) -> void:
	glColor4f(r, g, b, a)
	_fadeColor = [r, g, b, a]


## Java overloads: setColor(float i) [all four components = i],
## setColor(r, g, b), setColor(r, g, b, a), setColor(Vector3f[, a]).
func setColor(a, g = null, b = null, alpha = null) -> void:
	if a is Object and a != null:
		glColor4f(a.x, a.y, a.z, 1.0 if g == null else float(g))
	elif a is Vector3:
		glColor4f(a.x, a.y, a.z, 1.0 if g == null else float(g))
	elif g == null:
		var i := float(a)
		glColor4f(i, i, i, i)
		color = i
	elif alpha == null:
		glColor3f(a, g, b)
	else:
		glColor4f(a, g, b, alpha)


func setColor3(c: Array) -> void:
	glColor3f(c[0], c[1], c[2])


func setColor4(c: Array, alpha: float) -> void:
	glColor4f(c[0], c[1], c[2], alpha)


func setColorv(colors: Array, index: int) -> void:
	glColor4f(colors[index], colors[index + 1], colors[index + 2], colors[index + 3])


func clearColor(c: int) -> void:
	glClearColor(c, c, c, 1)


# ===========================================================================
# Matrix helpers / state helpers of the Java class
# ===========================================================================

func scale(zoom: float) -> void:
	glScalef(zoom, zoom, 1)


## Java overloads: translate(x, y, z) and translate(Vector3f).
func translate(x, y = null, z = null) -> void:
	if y == null:
		glTranslatef(x.x, x.y, x.z)
	else:
		glTranslatef(x, y, z)


func translateBack(pos) -> void:
	glTranslatef(-pos.x, -pos.y, -pos.z)


func drawList(list: int) -> void:
	if list != -1:
		glCallList(list)


func loadIdentity() -> void:
	glLoadIdentity()


func setBlendFunc(glMode: int) -> void:
	glBlendFunc(GL_SRC_ALPHA, glMode)


func beginBlend(disableDepth: bool) -> void:
	glEnable(GL_BLEND)
	glAlphaFunc(GL_LEQUAL, 1)
	if disableDepth:
		glDisable(GL_DEPTH_TEST)
		glDepthMask(false)


func endBlend() -> void:
	glEnable(GL_DEPTH_TEST)
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	glAlphaFunc(GL_GEQUAL, 0.01)


func beginQuads() -> void:
	glBegin(GL_QUADS)


func end() -> void:
	glEnd()


func push() -> void:
	glPushMatrix()


func pop() -> void:
	glPopMatrix()


## Java overloads: drawCenteredCurrent2D(Vector3f pos, size) and (pos, w, h).
func drawCenteredCurrent2D(pos, width: float, height = null) -> void:
	var hw: float
	var hh: float
	if height == null:
		hw = width
		hh = width
	else:
		hw = width * 0.5
		hh = float(height) * 0.5
	glTexCoord2f(0, 1)
	glVertex3f(pos.x - hw, pos.y - hh, pos.z)
	glTexCoord2f(1, 1)
	glVertex3f(pos.x + hw, pos.y - hh, pos.z)
	glTexCoord2f(1, 0)
	glVertex3f(pos.x + hw, pos.y + hh, pos.z)
	glTexCoord2f(0, 0)
	glVertex3f(pos.x - hw, pos.y + hh, pos.z)


func rotate(angle: float, x: float, y: float, z: float) -> void:
	glRotatef(angle, x, y, z)


func setTextureEnabled(enable: bool) -> void:
	_setCap(GL_TEXTURE_2D, enable)


func setAlphaTestEnabled(enable: bool) -> void:
	_setCap(GL_ALPHA_TEST, enable)


func setLightEnabled(enable: bool) -> void:
	_setCap(GL_LIGHTING, enable)


func setDepthTestEnabled(enable: bool) -> void:
	_setCap(GL_DEPTH_TEST, enable)


func setCullFaceEnabled(enable: bool) -> void:
	_setCap(GL_CULL_FACE, enable)


func setAlphaFunc(f: float) -> void:
	glAlphaFunc(GL_GREATER, f)


## Bridge (phase 1 step B, docs/ARCHITECTURE.md): the alpha test 2D drawing
## uses now, as a threshold for scene nodes that stand in for legacy drawing
## (VillageScene): fragments whose alpha is not above it are dropped; -1 when
## every fragment passes.
func alpha_threshold() -> float:
	var fn := _effAlphaFunc()
	if GLBackend._alpha_passes_all(fn, _alpha_ref):
		return -1.0
	match fn:
		GL_GREATER:
			return _alpha_ref
		GL_GEQUAL:
			return _alpha_ref - 0.5 / 255.0
	push_warning("Graphics.alpha_threshold: alpha function 0x%x has no threshold" % fn)
	return -1.0


func drawGradient(c, topAlpha: float, bottomAlpha: float, xRight: float,
		xLeft: float, yBottom: float, yTop: float, popPush: bool, beginQuadsFlag: bool) -> void:
	if popPush:
		push()
		loadIdentity()
		translate(0, 0, BattleValues.STANDARD_Z_DEPTH)
	if beginQuadsFlag:
		setTextureEnabled(false)
		beginQuads()
	setColor(c, topAlpha)
	glVertex3f(xRight, yTop, 0)
	glVertex3f(xLeft, yTop, 0)
	setColor(c, bottomAlpha)
	glVertex3f(xLeft, yBottom, 0)
	glVertex3f(xRight, yBottom, 0)
	if beginQuadsFlag:
		end()
		setTextureEnabled(true)
	if popPush:
		setColor(1, 1, 1)
		pop()


func setNormal(x: float, y: float, z: float) -> void:
	glNormal3f(x, y, z)


func pushTranslateRotatez(x: float, y: float, z: float, angle: float) -> void:
	push()
	translate(x, y, z)
	rotate(-angle, 0, 0, 1)


func generateList() -> int:
	return glGenLists(1)


func compileDrawList(drawList: int) -> void:
	glNewList(drawList, GL_COMPILE)


func endList() -> void:
	glEndList()


func callList(drawList: int) -> void:
	glCallList(drawList)


func deleteList(list: int) -> void:
	glDeleteLists(list, 1)


func checkError() -> void:
	pass


## Java: copyFrame(GL) took a screenshot of the front buffer.
func copyFrame(p_gl = null) -> Image:
	if backend == null:
		return null
	var tex := backend.host.get_viewport().get_texture()
	if tex == null:
		return null
	return tex.get_image()


# ===========================================================================
# OpenGL emulation
# ===========================================================================

func glEnable(cap: int) -> void:
	_setCap(cap, true)


func glDisable(cap: int) -> void:
	_setCap(cap, false)


func glIsEnabled(cap: int) -> bool:
	return _caps.get(cap, false)


func _setCap(cap: int, on: bool) -> void:
	_caps[cap] = on
	if cap >= GL_LIGHT0 and cap <= GL_LIGHT7 or cap == GL_FOG:
		_pushLightGlobals()


func glBlendFunc(src: int, dst: int) -> void:
	_blend_dst = dst


func glAlphaFunc(fn: int, ref: float) -> void:
	_alpha_func = fn
	_alpha_ref = ref


func glDepthMask(flag: bool) -> void:
	_depth_mask = flag


func glDepthFunc(fn: int) -> void:
	pass


func glCullFace(mode: int) -> void:
	_cull_mode = mode


func glShadeModel(mode: int) -> void:
	pass


func glHint(target: int, mode: int) -> void:
	pass


func glClearDepth(d: float) -> void:
	pass


func glViewport(x: int, y: int, w: int, h: int) -> void:
	pass


func glLineWidth(w: float) -> void:
	pass


func glClearColor(r: float, g: float, b: float, a: float) -> void:
	RenderingServer.set_default_clear_color(Color(r, g, b, 1.0))


func glClear(mask: int) -> void:
	if backend == null:
		return
	if mask & GL_COLOR_BUFFER_BIT:
		backend.clear_frame()
	elif mask & GL_DEPTH_BUFFER_BIT:
		backend.break_3d()


func glGetError() -> int:
	return GL_NO_ERROR


func glPushAttrib(mask: int) -> void:
	_attrib_stack.append({"caps": _caps.duplicate(), "color": _cur_color,
		"blend": _blend_dst, "afunc": _alpha_func, "aref": _alpha_ref, "dmask": _depth_mask})


func glPopAttrib() -> void:
	if _attrib_stack.is_empty():
		return
	var st: Dictionary = _attrib_stack.pop_back()
	_caps = st.caps
	_cur_color = st.color
	_blend_dst = st.blend
	_alpha_func = st.afunc
	_alpha_ref = st.aref
	_depth_mask = st.dmask
	_pushLightGlobals()


# --- Colors, texture coordinates, normals ---

func glColor3f(r: float, g: float, b: float) -> void:
	_cur_color = Color(r, g, b, 1.0)


func glColor4f(r: float, g: float, b: float, a: float) -> void:
	_cur_color = Color(r, g, b, a)


func glColor4fv(v: Array, offset: int = 0) -> void:
	_cur_color = Color(v[offset], v[offset + 1], v[offset + 2], v[offset + 3])


func glColor3fv(v: Array, offset: int = 0) -> void:
	_cur_color = Color(v[offset], v[offset + 1], v[offset + 2], 1.0)


func getCurrentColor() -> Color:
	return _cur_color


func glTexCoord2f(u: float, v: float) -> void:
	_cur_uv = Vector2(u, v)


func glTexCoord2i(u: int, v: int) -> void:
	_cur_uv = Vector2(u, v)


func glNormal3f(x: float, y: float, z: float) -> void:
	_cur_normal = Vector3(x, y, z)


# --- Matrices ---

func glMatrixMode(mode: int) -> void:
	_matrix_mode = mode


func glLoadIdentity() -> void:
	if _matrix_mode == GL_MODELVIEW:
		_mv = Transform3D.IDENTITY


func glPushMatrix() -> void:
	if _matrix_mode == GL_MODELVIEW:
		_mv_stack.append(_mv)


func glPopMatrix() -> void:
	if _matrix_mode == GL_MODELVIEW:
		if _mv_stack.is_empty():
			push_warning("glPopMatrix: stack underflow")
		else:
			_mv = _mv_stack.pop_back()


func glTranslatef(x: float, y: float, z: float) -> void:
	if _matrix_mode == GL_MODELVIEW:
		_mv = _mv * Transform3D(Basis.IDENTITY, Vector3(x, y, z))


func glRotatef(angle: float, x: float, y: float, z: float) -> void:
	if _matrix_mode != GL_MODELVIEW:
		return
	var axis := Vector3(x, y, z)
	if axis.length_squared() == 0.0:
		return
	_mv = _mv * Transform3D(Basis(axis.normalized(), deg_to_rad(angle)), Vector3.ZERO)


func glScalef(x: float, y: float, z: float) -> void:
	if _matrix_mode == GL_MODELVIEW:
		_mv = _mv * Transform3D(Basis.from_scale(Vector3(x, y, z)), Vector3.ZERO)


func getModelView() -> Transform3D:
	return _mv


func setModelView(t: Transform3D) -> void:
	_mv = t


func gluPerspective(fovy: float, aspect: float, zNear: float, zFar: float) -> void:
	pass # The 3D camera always uses the game's single perspective.


func gluOrtho2D(l: float, r: float, b: float, t: float) -> void:
	pass


# --- Lights, materials, fog ---

func glLightfv(light: int, pname: int, params: Array, offset: int = 0) -> void:
	var i := light - GL_LIGHT0
	if i < 0 or i >= 8:
		return
	var L: Dictionary = _lights[i]
	match pname:
		GL_POSITION:
			var p := Vector4(params[offset], params[offset + 1], params[offset + 2], params[offset + 3])
			if p.w != 0.0:
				var e := _mv * Vector3(p.x, p.y, p.z)
				L.pos = Vector4(e.x * p.w, e.y * p.w, e.z * p.w, p.w)
			else:
				var d := _mv.basis * Vector3(p.x, p.y, p.z)
				L.pos = Vector4(d.x, d.y, d.z, 0)
		GL_AMBIENT:
			L.ambient = _col(params, offset)
		GL_DIFFUSE:
			L.diffuse = _col(params, offset)
		GL_SPECULAR:
			L.specular = _col(params, offset)
		GL_CONSTANT_ATTENUATION:
			L.att.x = params[offset]
		GL_LINEAR_ATTENUATION:
			L.att.y = params[offset]
		GL_QUADRATIC_ATTENUATION:
			L.att.z = params[offset]
	_pushLightGlobals()


func glLightf(light: int, pname: int, value: float) -> void:
	glLightfv(light, pname, [value], 0)


func glMaterialfv(face: int, pname: int, params: Array, offset: int = 0) -> void:
	match pname:
		GL_AMBIENT:
			_mat.ambient = _col(params, offset)
		GL_DIFFUSE:
			_mat.diffuse = _col(params, offset)
		GL_AMBIENT_AND_DIFFUSE:
			_mat.ambient = _col(params, offset)
			_mat.diffuse = _col(params, offset)
		GL_SPECULAR:
			_mat.specular = _col(params, offset)
		GL_EMISSION:
			_mat.emission = _col(params, offset)
		GL_SHININESS:
			_mat.shininess = params[offset]
	_pushLightGlobals()


func glMaterialf(face: int, pname: int, value: float) -> void:
	glMaterialfv(face, pname, [value], 0)


func glLightModelfv(pname: int, params: Array, offset: int = 0) -> void:
	if pname == GL_LIGHT_MODEL_AMBIENT:
		_light_model_ambient = _col(params, offset)
		_pushLightGlobals()


var _light_model_ambient := Color(0.2, 0.2, 0.2, 1)


func glFogf(pname: int, value: float) -> void:
	match pname:
		GL_FOG_MODE:
			_fog.mode = int(value)
		GL_FOG_DENSITY:
			_fog.density = value
		GL_FOG_START:
			_fog.start = value
		GL_FOG_END:
			_fog.end = value
	_pushLightGlobals()


func glFogi(pname: int, value: int) -> void:
	glFogf(pname, value)


func glFogfv(pname: int, params: Array, offset: int = 0) -> void:
	if pname == GL_FOG_COLOR:
		_fog.color = _col(params, offset)
		_pushLightGlobals()
	else:
		glFogf(pname, params[offset])


static func _col(p: Array, o: int) -> Color:
	var a: float = p[o + 3] if p.size() > o + 3 else 1.0
	return Color(p[o], p[o + 1], p[o + 2], a)


static func _v4(c: Color) -> Vector4:
	return Vector4(c.r, c.g, c.b, c.a)


func _pushLightGlobals() -> void:
	GLBackend.set_global("gl_fog_color", _v4(_fog.color))
	var mode := 0
	if _fog.mode == GL_EXP2:
		mode = 1
	elif _fog.mode == GL_LINEAR:
		mode = 2
	GLBackend.set_global("gl_fog_params", Vector4(mode, _fog.density, _fog.start, _fog.end))
	GLBackend.set_global("gl_light_model_ambient", _v4(_light_model_ambient))
	GLBackend.set_global("gl_mat_ambient", _v4(_mat.ambient))
	GLBackend.set_global("gl_mat_diffuse", _v4(_mat.diffuse))
	GLBackend.set_global("gl_mat_emission", _v4(_mat.emission))
	# The shader supports two lights: the first two enabled ones.
	var slot := 0
	for i in 8:
		if slot >= 2:
			break
		if _caps.get(GL_LIGHT0 + i, false):
			var L: Dictionary = _lights[i]
			GLBackend.set_global("gl_light%d_pos" % slot, L.pos)
			GLBackend.set_global("gl_light%d_amb" % slot, _v4(L.ambient))
			GLBackend.set_global("gl_light%d_dif" % slot, _v4(L.diffuse))
			GLBackend.set_global("gl_light%d_att" % slot, Vector4(L.att.x, L.att.y, L.att.z, 1))
			slot += 1
	while slot < 2:
		GLBackend.set_global("gl_light%d_att" % slot, Vector4(1, 0, 0, 0))
		slot += 1


# --- Immediate mode ---

func glBegin(mode: int) -> void:
	_im_mode = mode
	_im_v.clear()
	_im_uv.clear()
	_im_c.clear()
	_im_n.clear()


func glVertex3f(x: float, y: float, z: float) -> void:
	_im_v.append(Vector3(x, y, z))
	_im_uv.append(_cur_uv)
	_im_c.append(_cur_color)
	_im_n.append(_cur_normal)


func glVertex2f(x: float, y: float) -> void:
	glVertex3f(x, y, 0.0)


func glVertex2i(x: int, y: int) -> void:
	glVertex3f(x, y, 0.0)


func glEnd() -> void:
	var mode := _im_mode
	_im_mode = -1
	if _im_v.is_empty():
		return
	var idx := _triangulate(mode, _im_v.size())
	if idx.is_empty():
		return
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var c := PackedColorArray()
	var n := PackedVector3Array()
	v.resize(idx.size())
	uv.resize(idx.size())
	c.resize(idx.size())
	n.resize(idx.size())
	for k in idx.size():
		var i: int = idx[k]
		v[k] = _im_v[i]
		uv[k] = _im_uv[i]
		c[k] = _im_c[i]
		n[k] = _im_n[i]
	_emitTriangles(v, uv, c, n)


static func _triangulate(mode: int, count: int) -> PackedInt32Array:
	var idx := PackedInt32Array()
	match mode:
		GL_QUADS:
			var q := 0
			while q + 3 < count:
				idx.append_array([q, q + 1, q + 2, q, q + 2, q + 3])
				q += 4
		GL_TRIANGLES:
			for i in count - count % 3:
				idx.append(i)
		GL_TRIANGLE_STRIP, GL_QUAD_STRIP:
			for i in range(2, count):
				if i % 2 == 0:
					idx.append_array([i - 2, i - 1, i])
				else:
					idx.append_array([i - 1, i - 2, i])
		GL_TRIANGLE_FAN, GL_POLYGON:
			for i in range(2, count):
				idx.append_array([0, i - 1, i])
	return idx


## Current texture used by glBegin/glEnd primitives.
func bindTexture(t: GameTexture) -> void:
	_bound = t


func _texForDraw() -> Texture2D:
	if not _caps.get(GL_TEXTURE_2D, true) or _bound == null:
		return null
	return _bound.getGodotTexture()


func _emitTriangles(v: PackedVector3Array, uv: PackedVector2Array, c: PackedColorArray,
		n: PackedVector3Array) -> void:
	if _compiling != null:
		_compiling.add(self, v, uv, c, n)
		return
	if backend == null:
		return
	if _proj3d:
		var m := _material3D()
		var ev := PackedVector3Array()
		ev.resize(v.size())
		var en := PackedVector3Array()
		en.resize(n.size())
		for i in v.size():
			ev[i] = _mv * v[i]
			en[i] = _mv.basis * n[i]
		backend.vp_3d().add_triangles(m, ev, uv, c, en)
	else:
		_emit2D(v, uv, c)


func _emit2D(v: PackedVector3Array, uv: PackedVector2Array, c: PackedColorArray) -> void:
	var cull: bool = _caps.get(GL_CULL_FACE, false)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	var count := v.size() - v.size() % 3
	for t in range(0, count, 3):
		var a := _mv * v[t]
		var b := _mv * v[t + 1]
		var d := _mv * v[t + 2]
		if cull and _cull_mode != GL_FRONT_AND_BACK:
			# Screen space is y down, so GL's counter clockwise front faces
			# have a negative cross product here.
			var cross := (b.x - a.x) * (d.y - a.y) - (b.y - a.y) * (d.x - a.x)
			var front := cross < 0.0
			if (_cull_mode == GL_BACK and not front) or (_cull_mode == GL_FRONT and front):
				continue
		elif cull:
			continue
		pts.append(Vector2(a.x, a.y))
		pts.append(Vector2(b.x, b.y))
		pts.append(Vector2(d.x, d.y))
		cols.append(c[t])
		cols.append(c[t + 1])
		cols.append(c[t + 2])
		uvs.append(uv[t])
		uvs.append(uv[t + 1])
		uvs.append(uv[t + 2])
	if pts.is_empty():
		return
	var ci := backend.ci_2d(_blend_dst == GL_ONE, _effAlphaFunc(), _alpha_ref)
	backend.set_ci_transform(ci, Transform2D.IDENTITY)
	var tex := _texForDraw()
	var indices := PackedInt32Array()
	indices.resize(pts.size())
	for i in pts.size():
		indices[i] = i
	RenderingServer.canvas_item_add_triangle_array(ci, indices, pts, cols, uvs,
		PackedInt32Array(), PackedFloat32Array(), tex.get_rid() if tex else RID())


func _material3D() -> ShaderMaterial:
	var tex := _texForDraw()
	var cull := 0
	if _caps.get(GL_CULL_FACE, false):
		cull = 2 if _cull_mode == GL_FRONT else 1
	var st := {
		"tex_id": tex.get_instance_id() if tex else 0,
		"texture": tex,
		"use_tex": tex != null,
		"additive": _blend_dst == GL_ONE,
		"opaque": not _caps.get(GL_BLEND, true),
		"depth_test": _caps.get(GL_DEPTH_TEST, false) and not ignore_depth_test,
		"depth_write": _depth_mask,
		"cull": cull,
		"lit": _caps.get(GL_LIGHTING, false),
		"fog": _caps.get(GL_FOG, false),
		"alpha_func": _effAlphaFunc(),
		"alpha_ref": _alpha_ref,
	}
	return backend.material_3d(st)


# --- Display lists ---

func glGenLists(range_count: int) -> int:
	var id := _next_list
	_next_list += range_count
	return id


func glNewList(list: int, mode: int) -> void:
	_compiling = DisplayList.new()
	_compiling.base_inv = _mv.affine_inverse()
	_lists[list] = _compiling


func glEndList() -> void:
	if _compiling != null:
		_compiling.finish()
	_compiling = null


func glCallList(list: int) -> void:
	var dl: DisplayList = _lists.get(list)
	if dl == null or dl.mesh == null or backend == null:
		return
	if not _proj3d:
		push_warning("glCallList in 2D projection is not supported")
		return
	backend.vp_3d().add_mesh(dl.mesh, _mv)


func glDeleteLists(list: int, range_count: int) -> void:
	for i in range_count:
		_lists.erase(list + i)


# --- GLU ---

func gluNewQuadric():
	return null


func gluDisk(quad, inner: float, outer: float, slices: int, loops: int) -> void:
	var tex_was: bool = _caps.get(GL_TEXTURE_2D, true)
	glBegin(GL_TRIANGLES)
	for i in slices:
		var a0 := TAU * i / slices
		var a1 := TAU * (i + 1) / slices
		var p0o := Vector2(cos(a0), sin(a0)) * outer
		var p1o := Vector2(cos(a1), sin(a1)) * outer
		var p0i := Vector2(cos(a0), sin(a0)) * inner
		var p1i := Vector2(cos(a1), sin(a1)) * inner
		glNormal3f(0, 0, 1)
		glVertex3f(p0i.x, p0i.y, 0)
		glVertex3f(p0o.x, p0o.y, 0)
		glVertex3f(p1o.x, p1o.y, 0)
		if inner > 0:
			glVertex3f(p0i.x, p0i.y, 0)
			glVertex3f(p1o.x, p1o.y, 0)
			glVertex3f(p1i.x, p1i.y, 0)
	glEnd()


func gluSphere(quad, radius: float, slices: int, stacks: int) -> void:
	glBegin(GL_TRIANGLES)
	for s in stacks:
		var t0 := PI * s / stacks
		var t1 := PI * (s + 1) / stacks
		for i in slices:
			var p0 := TAU * i / slices
			var p1 := TAU * (i + 1) / slices
			var a := _sph(t0, p0)
			var b := _sph(t1, p0)
			var c := _sph(t1, p1)
			var d := _sph(t0, p1)
			for q in [a, b, c, a, c, d]:
				glNormal3f(q.x, q.y, q.z)
				glVertex3f(q.x * radius, q.y * radius, q.z * radius)
	glEnd()


static func _sph(theta: float, phi: float) -> Vector3:
	return Vector3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta))


## Shader program calls of the original labyrinth bump mapping experiment are
## no-ops in this port.
func glUseProgram(program: int) -> void:
	pass


## A compiled display list (glNewList/glEndList): an ArrayMesh with one surface
## per material, relative to the matrix active when the list was started.
class DisplayList extends RefCounted:
	var base_inv := Transform3D.IDENTITY
	var groups := {} # material -> [v, uv, c, n]
	var order: Array = []
	var mesh: ArrayMesh

	func add(g: Graphics, v: PackedVector3Array, uv: PackedVector2Array,
			c: PackedColorArray, n: PackedVector3Array) -> void:
		if g.backend == null:
			return
		var mat := g._material3D()
		var rel := base_inv * g.getModelView()
		if not groups.has(mat):
			groups[mat] = [PackedVector3Array(), PackedVector2Array(), PackedColorArray(), PackedVector3Array()]
			order.append(mat)
		var grp: Array = groups[mat]
		var gv: PackedVector3Array = grp[0]
		var gn: PackedVector3Array = grp[3]
		for i in v.size():
			gv.append(rel * v[i])
			gn.append(rel.basis * n[i])
		grp[0] = gv
		grp[3] = gn
		var guv: PackedVector2Array = grp[1]
		guv.append_array(uv)
		grp[1] = guv
		var gc: PackedColorArray = grp[2]
		gc.append_array(c)
		grp[2] = gc

	func finish() -> void:
		mesh = ArrayMesh.new()
		var s := 0
		for mat in order:
			var grp: Array = groups[mat]
			if grp[0].is_empty():
				continue
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = grp[0]
			arrays[Mesh.ARRAY_TEX_UV] = grp[1]
			arrays[Mesh.ARRAY_COLOR] = grp[2]
			arrays[Mesh.ARRAY_NORMAL] = grp[3]
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			mesh.surface_set_material(s, mat)
			s += 1
		groups.clear()

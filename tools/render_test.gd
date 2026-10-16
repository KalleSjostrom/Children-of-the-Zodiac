extends Node2D
## Visual test of the OpenGL emulation (Graphics/GLBackend). Run with
##   godot --path . res://tools/RenderTest.tscn -- --out=<png>
## It draws a few frames and saves a screenshot.

var backend: GLBackend
var g: Graphics
var frame := 0
var out := "user://render_test.png"
var label_img: Image


func _exit_tree() -> void:
	backend.free_all()


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--out="):
			out = String(a).substr(6)
	backend = GLBackend.new(self)
	g = Graphics.new(backend)
	GameEventListener.g = g
	label_img = GraphicHelp.createImage(256, 64)
	var ig := ImageGraphics.new(label_img)
	ig.setColor(Color(0.2, 0.2, 0.6, 0.8))
	ig.fillRect(0, 0, 256, 64)
	ig.setColor(JColor.YELLOW)
	ig.setFont(Values.getFont(Values.BOLD, 30))
	ig.drawString("HP 123/456", 10, 42)


func _process(delta: float) -> void:
	frame += 1
	backend.begin_frame()
	g.beginFrame(false)
	# 2D background
	g.setColor(1)
	g.drawImage(Values.TitleImages + "GameOverKin.jpg", 0, 0)
	g.drawImage(Values.TitleImages + "loggatext.png", 300, 20, 0.5)
	# Additive image
	g.setBlendFunc(Graphics.GL_ONE)
	g.drawImage(Values.Cards + "back.png", 40, 300)
	g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
	# Half transparent tinted image with translation/scale
	g.push()
	g.translate(800, 300, 0)
	g.scale(0.5)
	g.setImageColor(1, 0.3, 0.3, 0.6)
	g.drawImage(Values.Cards + "back.png", 0, 0)
	g.pop()
	g.setColor(1)
	# Text
	g.setFontSize(40)
	Graphics.setTextColor(JColor.white)
	g.drawWithShadow("Children of the Zodiac", 280, 200)
	g.setFontSize(24)
	g.drawSingleCenteredText("Centered text 24", 240, 1, 1)
	# Image painted with ImageGraphics
	g.drawImage(label_img, 700, 650)

	# 3D: a lit, fogged corridor and a rotating card in front of it.
	GameEventListener.set3DNow(g)
	var gl := g.getGL()
	gl.glEnable(Graphics.GL_FOG)
	gl.glFogf(Graphics.GL_FOG_MODE, Graphics.GL_EXP)
	gl.glFogf(Graphics.GL_FOG_DENSITY, 0.08)
	gl.glFogfv(Graphics.GL_FOG_COLOR, [0.1, 0.1, 0.2, 1], 0)
	gl.glEnable(Graphics.GL_LIGHTING)
	gl.glEnable(Graphics.GL_LIGHT0)
	gl.glLightfv(Graphics.GL_LIGHT0, Graphics.GL_POSITION, [0, 0, 0, 1], 0)
	gl.glLightfv(Graphics.GL_LIGHT0, Graphics.GL_AMBIENT, [0.8, 0.8, 0.8, 1], 0)
	gl.glLightfv(Graphics.GL_LIGHT0, Graphics.GL_DIFFUSE, [0.8, 0.8, 0.8, 1], 0)
	gl.glLightf(Graphics.GL_LIGHT0, Graphics.GL_CONSTANT_ATTENUATION, 1)
	gl.glLightf(Graphics.GL_LIGHT0, Graphics.GL_LINEAR_ATTENUATION, 0.01)
	gl.glLightf(Graphics.GL_LIGHT0, Graphics.GL_QUADRATIC_ATTENUATION, 0.015)
	g.push()
	g.translate(0, 0, -2)
	var floor_t := ImageHandler.getTexture(Values.LabyrinthTextures + "Floors/aegisbasementfloor0.jpg")
	var wall_t := ImageHandler.getTexture(Values.LabyrinthTextures + "Walls/aegisbasementwall.png")
	for i in 5:
		var z0 := -4.0 * i
		floor_t.bind(g)
		gl.glBegin(Graphics.GL_QUADS)
		gl.glNormal3f(0, 1, 0)
		gl.glTexCoord2f(0, 1); gl.glVertex3f(-2, -2, z0)
		gl.glTexCoord2f(1, 1); gl.glVertex3f(2, -2, z0)
		gl.glTexCoord2f(1, 0); gl.glVertex3f(2, -2, z0 - 4)
		gl.glTexCoord2f(0, 0); gl.glVertex3f(-2, -2, z0 - 4)
		gl.glEnd()
		wall_t.bind(g)
		gl.glBegin(Graphics.GL_QUADS)
		gl.glNormal3f(1, 0, 0) # left wall
		gl.glTexCoord2f(0, 0); gl.glVertex3f(-2, 2, z0)
		gl.glTexCoord2f(0, 1); gl.glVertex3f(-2, -2, z0)
		gl.glTexCoord2f(1, 1); gl.glVertex3f(-2, -2, z0 - 4)
		gl.glTexCoord2f(1, 0); gl.glVertex3f(-2, 2, z0 - 4)
		gl.glNormal3f(-1, 0, 0) # right wall
		gl.glTexCoord2f(0, 0); gl.glVertex3f(2, 2, z0 - 4)
		gl.glTexCoord2f(0, 1); gl.glVertex3f(2, -2, z0 - 4)
		gl.glTexCoord2f(1, 1); gl.glVertex3f(2, -2, z0)
		gl.glTexCoord2f(1, 0); gl.glVertex3f(2, 2, z0)
		gl.glEnd()
	g.pop()
	gl.glDisable(Graphics.GL_LIGHTING)
	gl.glDisable(Graphics.GL_FOG)
	# A card at the battle depth, rotating around Y.
	g.loadIdentity()
	g.translate(0.5, 0, BattleValues.STANDARD_Z_DEPTH)
	g.rotate(frame * 3.0, 0, 1, 0)
	var card := ImageHandler.getTexture(Values.Cards + "back.png")
	var w := card.getWidth() * BattleValues.CARD_SCALE / 2
	var h := card.getHeight() * BattleValues.CARD_SCALE / 2
	g.setCullFaceEnabled(false)
	Utils3D.draw3D(g, card, [[-w, w], [-h, h], [0, 0]])
	g.setCullFaceEnabled(true)
	# 2D overlay on top of the 3D.
	GameEventListener.set2DNow(g)
	g.setFontSize(30)
	Graphics.setTextColor(JColor.orange)
	g.drawString("2D overlay after 3D (chunks: %d)" % backend.stats_chunks, 20, 740)
	g.drawImage(label_img, 700, 650)
	g.setBlendFunc(Graphics.GL_ONE)
	g.drawImage(Values.Cards + "back.png", 40, 450)
	g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
	g.push()
	g.translate(850, 450, 0)
	g.scale(0.5)
	g.setImageColor(1, 0.3, 0.3, 0.6)
	g.drawImage(Values.Cards + "back.png", 0, 0)
	g.pop()
	g.setColor(1)
	g.fadeOldSchool(0.8)
	backend.end_frame()

	if frame == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png(out)
		print("saved ", out)
		get_tree().quit()

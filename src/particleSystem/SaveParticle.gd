class_name SaveParticle
extends RefCounted
## Port of particleSystem.SaveParticle: a particle of the save point effect.

var pos = [0.0, 0.0, 0.0]
var rgb = [0.0, 0.0, 0.0]
var speed: float = 0.0
var life: float = 0.0
var fade: float = 0.0
const size = 0.3
static var rand = JRandom.new()
static var poses = null

static func _static_init() -> void:
	poses = J.array2d(361, 2, 0.0)
	for i in range(361):
		var theta: float = deg_to_rad(i - 180)
		poses[i][0] = 0.9 * cos(theta)
		poses[i][1] = 0.9 * sin(theta)

func _init() -> void:
	resurrect()
	var theta: int = int(rand.nextFloat() * 360)
	pos[0] = poses[theta][0] + SaveSystem.pos[0]
	pos[2] = poses[theta][1] + SaveSystem.pos[1]
	for i in range(400):
		update()

func update():
	pos[1] += speed
	if pos[1] > 1 or life <= 0:
		resurrect()
	else:
		life -= fade
	for i in range(3):
		rgb[i] += 0.01 * i + 0.01
		if rgb[i] > 1:
			rgb[i] = 0.0

func resurrect():
	speed = ((rand.nextFloat() * 4) + 8) * 0.001
	pos[1] = -2.0
	life = 1.0
	fade = (rand.nextFloat() / 100.0) + 0.0025
	rgb[0] = rand.nextFloat()
	rgb[1] = rand.nextFloat()
	rgb[2] = rand.nextFloat()

func drawParticle(g, dir):
	g.setColor4(rgb, life)
	var x1: float = pos[0] - size / 2
	var y1: float = pos[1] - size / 2
	var y2: float = y1 + size / 2
	var z1: float = pos[2] - size / 2
	var gl = g.getGL()
	gl.glTexCoord2i(0, 0)
	gl.glVertex3f(x1, y1, z1)
	match dir:
		0:
			s3(gl, x1, y1, y2, z1)
		3:
			s2(gl, x1, y1, y2, z1)
		2:
			s1(gl, x1, y1, y2, z1)
		1:
			s4(gl, x1, y1, y2, z1)

func s4(gl, x1, y1, y2, z1):
	var z2: float = z1 + size / 2
	gl.glTexCoord2i(1, 0)
	gl.glVertex3f(x1, y1, z2)
	gl.glTexCoord2i(1, 1)
	gl.glVertex3f(x1, y2, z2)
	gl.glTexCoord2i(0, 1)
	gl.glVertex3f(x1, y2, z1)

func s2(gl, x1, y1, y2, z1):
	var z2: float = z1 + size / 2
	gl.glTexCoord2i(0, 1)
	gl.glVertex3f(x1, y2, z1)
	gl.glTexCoord2i(1, 1)
	gl.glVertex3f(x1, y2, z2)
	gl.glTexCoord2i(1, 0)
	gl.glVertex3f(x1, y1, z2)

func s1(gl, x1, y1, y2, z1):
	var x2: float = x1 + size / 2
	gl.glTexCoord2i(0, 1)
	gl.glVertex3f(x1, y2, z1)
	gl.glTexCoord2i(1, 1)
	gl.glVertex3f(x2, y2, z1)
	gl.glTexCoord2i(1, 0)
	gl.glVertex3f(x2, y1, z1)

func s3(gl, x1, y1, y2, z1):
	var x2: float = x1 + size / 2
	gl.glTexCoord2i(1, 0)
	gl.glVertex3f(x2, y1, z1)
	gl.glTexCoord2i(1, 1)
	gl.glVertex3f(x2, y2, z1)
	gl.glTexCoord2i(0, 1)
	gl.glVertex3f(x1, y2, z1)

func getPos(i):
	return pos[i]

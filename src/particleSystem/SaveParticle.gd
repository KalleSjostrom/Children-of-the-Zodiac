class_name SaveParticle
extends RefCounted
## Port of particleSystem.SaveParticle: a particle of the save point effect.
##
## drawParticle and its quads (place_quad, s1 to s4) are removed with the
## legacy save point drawing (plan 7.9): the GPU particles (SaveParticles3D)
## run these laws and draw.

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

func getPos(i):
	return pos[i]

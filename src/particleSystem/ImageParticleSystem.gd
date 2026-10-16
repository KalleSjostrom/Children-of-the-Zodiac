class_name ImageParticleSystem
extends ParticleSystem
## Port of particleSystem.ImageParticleSystem.

var currentImage: int = 0
var hasStarted: bool = false

## Java overloads: (AnimSettings, BattleEnemy) and (AnimSettings).
func _init(p_settings = null, p_enemy = null) -> void:
	super(p_settings, p_enemy)

func update(elapsedTime, body = null):
	super.update(elapsedTime)

func start(g):
	pass

func end(g):
	pass

func draw(g, t = null, pPos = null):
	if not hasInited:
		loadGLTextures()
		hasInited = true
	if not hasStarted:
		hasStarted = true
		for p in particles:
			p.setLife(0.0001)
		_animate()

	bindTexture(g, currentImage)
	g.beginQuads()
	particles[0].drawParticle(g, additiveColoring)
	g.end()

## Java: the anonymous Thread of draw (runs as a coroutine, not awaited).
func _animate() -> void:
	var fadeSpeed: float = 0.05
	var fadeingUp: bool = true
	while fadeingUp:
		for p in particles:
			p.addLife(fadeSpeed)
			fadeingUp = p.getLife() < 0.5
		await Scheduler.sleep(30)
	var open: int = 180
	var close: int = 100
	await Scheduler.sleep(500)
	for i in range(4):
		currentImage = 1
		await Scheduler.sleep(open)
		currentImage = 2
		await Scheduler.sleep(close)
	currentImage = 1
	await Scheduler.sleep(open)
	plainDestroy()
	var fadeingDown: bool = true
	fadeSpeed = 0.025
	while fadeingDown:
		for p in particles:
			p.addLife(-fadeSpeed)
			fadeingDown = p.getLife() > 0
		await Scheduler.sleep(30)

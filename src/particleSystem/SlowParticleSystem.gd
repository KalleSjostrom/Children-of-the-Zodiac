class_name SlowParticleSystem
extends ParticleSystem
## Port of particleSystem.SlowParticleSystem (the clock effect).

var hasStarted: bool = false
var hourTheta: float = 0.0
var minuteTheta: float = 0.0
var fadeSpeed: float = 0.05

## Java overloads: (AnimSettings, BattleEnemy) and (AnimSettings).
func _init(p_settings = null, p_enemy = null) -> void:
	super(p_settings, p_enemy)

func update(elapsedTime, body = null):
	super.update(elapsedTime)
	hourTheta += 60.0 * elapsedTime
	minuteTheta += 720.0 * elapsedTime

func start(g):
	pass

func end(g):
	pass

## Bridge (phase 4.4's rollout, part 5, step B, docs/ARCHITECTURE.md section
## 15): the clock's quad and each hand's are a PanelQuad in the slot of their
## batch (_drawQuad); the coroutine still starts in the first draw, and the
## particle's position and life are set as before; --legacy=battle_effect_draw
## keeps the legacy quads.
func draw(g, t = null, pPos = null):
	if not hasInited:
		loadGLTextures()
		hasInited = true
	if not hasStarted:
		hasStarted = true
		for p in particles:
			p.setLife(0.0001)
		_animate()
	g.push()
	g.translate(settings.getVector(AnimSettings.SOURCE))
	var p = particles[0]
	p.setPosition(Vector3f.new())
	bindTexture(g, 0)
	var l: float = p.getLife()
	_drawQuad(g, p, &"clock")
	p.setLife(l + 0.5)
	g.pop()

	g.push()
	g.translate(settings.getVector(AnimSettings.SOURCE))

	g.rotate(hourTheta, 0, 0, 1) # For FPS = 60, angle+=2 for FPS = 30
	bindTexture(g, 1)
	_drawQuad(g, p, &"hour")
	g.pop()

	g.push()
	g.translate(settings.getVector(AnimSettings.SOURCE))
	g.rotate(minuteTheta, 0, 0, 1)
	bindTexture(g, 2)
	_drawQuad(g, p, &"minute")
	g.pop()

	p.setLife(l)

## The particle's quad in a beginQuads/end block of its own (Java: inlined in
## draw); bridge: the PanelQuad of [this system, part] in the slot of its batch
## (Particle.show_particle) unless --legacy=battle_effect_draw.
func _drawQuad(g, p, part: StringName) -> void:
	if Main.is_legacy("battle_effect_draw"):
		g.beginQuads()
		p.drawParticle(g, additiveColoring)
		g.end()
	else:
		p.show_particle(g, [get_instance_id(), part])

## Java: the anonymous Thread of draw (runs as a coroutine, not awaited).
func _animate() -> void:
	var fadeingUp: bool = true
	while fadeingUp:
		for p in particles:
			p.addLife(fadeSpeed)
			fadeingUp = p.getLife() < 0.5
		await Scheduler.sleep(30)
	await Scheduler.sleep(750)
	plainDestroy()
	var fadeingDown: bool = true
	fadeSpeed = 0.025
	while fadeingDown:
		for p in particles:
			p.addLife(-fadeSpeed)
			fadeingDown = p.getLife() > 0
		await Scheduler.sleep(30)

class_name ShatterParticleSystem
extends ParticleSystem
## Port of particleSystem.ShatterParticleSystem.

## Java overloads: (AnimSettings, BattleEnemy) and (AnimSettings).
func _init(p_settings = null, p_enemy = null) -> void:
	super(p_settings, p_enemy)

## Java adds createParticle(float[] c, AnimSettings settings); the no-argument
## createParticle() is the inherited one.
func createParticle(c = null, p_settings = null):
	if c == null:
		return super.createParticle()
	return Particle.new(c, p_settings, self)

func start(g):
	pass

func end(g):
	pass

func draw(g, t = null, pPos = null):
	if not hasInited:
		loadGLTextures()
		hasInited = true

	bindTexture(g, 0)
	if gpu:
		show_gpu(g)
	g.beginQuads()
	for p in particles:
		# Main.hide_particles (dev) and the GPU path: no quads, the same GL
		# state (as far as the GPU path's smaller pool gives it).
		if Main.hide_particles or gpu:
			p.place_particle(g)
		else:
			p.drawParticle(g, additiveColoring)
	g.end()

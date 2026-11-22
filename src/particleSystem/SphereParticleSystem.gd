class_name SphereParticleSystem
extends ParticleSystem
## Port of particleSystem.SphereParticleSystem.

## Java overloads: (AnimSettings, BattleEnemy) and (AnimSettings).
func _init(p_settings = null, p_enemy = null) -> void:
	super(p_settings, p_enemy)

func createParticle(c = null, p_settings = null):
	return SphereParticle.new(super.getColor(), settings, self)

func update(elapsedTime, body = null):
	super.update(elapsedTime)
	if destroyed:
		for p in particles:
			p.kill()

func start(g):
	var gl = g.getGL()
	gl.glPushMatrix()
	gl.glPushAttrib(Graphics.GL_LIGHTING_BIT)
	gl.glLightfv(Graphics.GL_LIGHT2, Graphics.GL_POSITION, [0.0, 2.0, 0.0, 1.0], 0)

	gl.glDisable(Graphics.GL_TEXTURE_2D)
	gl.glEnable(Graphics.GL_LIGHTING)
	gl.glDisable(Graphics.GL_LIGHT0)
	gl.glDisable(Graphics.GL_LIGHT1)

	gl.glEnable(Graphics.GL_LIGHT2)
	var zero: Array = [0.0, 0.0, 0.0, 0.0]
	var one: Array = [1.0, 1.0, 1.0, 1.0]
	gl.glLightfv(Graphics.GL_LIGHT2, Graphics.GL_AMBIENT, zero, 0)
	gl.glLightfv(Graphics.GL_LIGHT2, Graphics.GL_DIFFUSE, one, 0)
	gl.glLightfv(Graphics.GL_LIGHT2, Graphics.GL_SPECULAR, one, 0)

	var dif: Array = [0.2, 0.0, 0.2, 1.0]
	gl.glColor4f(0, 0, 0, 1)
	gl.glMaterialfv(Graphics.GL_FRONT, Graphics.GL_AMBIENT, zero, 0)
	gl.glMaterialfv(Graphics.GL_FRONT, Graphics.GL_DIFFUSE, dif, 0)
	gl.glMaterialfv(Graphics.GL_FRONT, Graphics.GL_SPECULAR, one, 0)
	gl.glMaterialfv(Graphics.GL_FRONT, Graphics.GL_EMISSION, zero, 0)
	gl.glMaterialf(Graphics.GL_FRONT, Graphics.GL_SHININESS, 100.0)

## Bridge (phase 4.4's rollout, part 5, step B, docs/ARCHITECTURE.md section
## 15): each sphere is kept and shown by a PanelQuad in the slot of its batch
## (SphereParticle.show_particle), lit as the batch was (GLBackend's material
## and the light state the frame ends with); --legacy=battle_effect_draw keeps
## the legacy triangles.
func draw(g, t = null, pPos = null):
	var legacy: bool = Main.is_legacy("battle_effect_draw")
	for p in particles:
		if legacy:
			p.drawParticle(g, false)
		else:
			p.show_particle(g, [p.get_instance_id(), &"sphere"])

func end(g):
	var gl = g.getGL()
	gl.glPopAttrib()
	gl.glPopMatrix()

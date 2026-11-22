class_name FlameParticleSystem
extends ParticleSystem
## Port of particleSystem.FlameParticleSystem.

## Java overloads: (AnimSettings, BattleEnemy) and (AnimSettings).
func _init(p_settings = null, p_enemy = null) -> void:
	super(p_settings, p_enemy)

func update(elapsedTime, body = null):
	super.update(elapsedTime)

func create(nrOfParticles, p_settings):
	super.create(nrOfParticles, p_settings)
	# Bridge (the battle effects phase): the GPU system warms up (400 of the
	# original's steps) instead of the Java's pre-run "for burning man" (200
	# legacy updates of the system: its legacy particles decide nothing, the
	# flame is never destroyed). That pre-run blocked the game for 11 s
	# (docs/MODERNIZATION_PLAN.md 6.11); --legacy=effect_waits kept it until
	# the closing of phase 4.4 (plan 9.4).
	gpu_preprocess = 400 * Values.ORIGINAL_FRAME_MS / 1000.0

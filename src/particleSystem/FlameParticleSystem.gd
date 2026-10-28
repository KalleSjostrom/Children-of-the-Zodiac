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
	# Bridge (the battle effects phase): on the GPU path the GPU system warms
	# up instead (its legacy particles decide nothing: the flame is never
	# destroyed). This pre-run blocked the game for 11 s (docs/MODERNIZATION_PLAN.md
	# 6.11). --legacy=effect_waits keeps it, for the same random numbers.
	if gpu and not Main.is_legacy("effect_waits"):
		gpu_preprocess = 400 * Values.ORIGINAL_FRAME_MS / 1000.0
		return
	# For burning man: pre-run the system (in the port's steps, see
	# ParticleSystemPacket.update; Java: Values.LOGIC_INTERVAL).
	for i in range(200):
		var elapsedTime: float = Values.ORIGINAL_FRAME_MS / 1000.0
		super.update(elapsedTime)
		# Same as the particle loop of ParticleSystem.update (duplicated in Java).
		_updateParticles(elapsedTime)
		emitter.update(self, elapsedTime)

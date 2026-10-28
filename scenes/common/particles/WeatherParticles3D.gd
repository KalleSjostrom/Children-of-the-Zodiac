@tool
class_name WeatherParticles3D
extends QuadParticles3D
## The rain or snow of a dungeon floor on the GPU (WeatherSystem, src/weather;
## Rain.tscn, Snow.tscn): 10 000 particles that fall in columns of their own
## (weather_particle.gdshader, the legacy laws at 60 steps a second) and are
## drawn as the legacy quads. The legacy drawing has two passes, which
## DungeonWeather draws with two instances of the scene: the back pass (7.5
## to 20 units ahead of the player) after the floor's objects, and the front
## pass (3 to 7 units ahead) after them, or over a battle or riddle. Both
## instances have the same seed and run in step, so they draw the same
## particles.

const PROCESS_SHADER := preload("res://scenes/common/particles/weather_particle.gdshader")
## The band of distances ahead of the player that each pass draws
## (WeatherParticle.drawParticle; the front pass draws the back pass's front
## list, 3 < s < 7).
const BANDS := {&"back": Vector2(7.5, 20.0), &"front": Vector2(3.0, 7.0)}

## The system's force per legacy step (WeatherSystem.getForce: rain -0.2,
## snow -0.003; y up).
@export var force_y := -0.2:
	set(value):
		force_y = value
		_set_process(&"force_y", value)
## Below this height a particle starts again at the top of its column
## (shouldResurrect: rain -2, snow -2.2).
@export var respawn_below := -2.0:
	set(value):
		respawn_below = value
		_set_process(&"respawn_below", value)


func _init() -> void:
	super()
	var material := ShaderMaterial.new()
	material.shader = PROCESS_SHADER
	process_material = material


func _ready() -> void:
	_set_process(&"force_y", force_y)
	_set_process(&"respawn_below", respawn_below)
	super()
	if Engine.is_editor_hint():
		# The editor shows every particle around the floor's origin.
		_set_process(&"near_clip", -1000000.0)
		_set_process(&"far_clip", 1000000.0)
		emitting = true


## The pass this instance draws (&"back" or &"front").
func set_pass(pass_name: StringName) -> void:
	var band: Vector2 = BANDS[pass_name]
	_set_process(&"near_clip", band.x)
	_set_process(&"far_clip", band.y)


## QuadParticles3D.show_state, and "location": the player's location (x, z)
## for the view test.
func show_state(state: Dictionary, style: DungeonStyle) -> void:
	super(state, style)
	_set_process(&"player_location", state.get("location", Vector2.ZERO))
	_set_process(&"facing_angle", float(state.get("facing", 0)))


## WeatherParticle.drawParticle: in the x-y plane when the facing is in
## (-135, -45) or (45, 135), else in the z-y plane.
func along_x(facing: int) -> bool:
	return (facing > -135 and facing < -45) or (facing > 45 and facing < 135)

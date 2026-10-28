@tool
class_name SaveParticles3D
extends QuadParticles3D
## The particles of a save point on the GPU (SaveSystem, src/particleSystem;
## SaveParticles3D.tscn, the "Particles" child of DungeonSavePoint): 2,000
## particles rising on a ring around the cell, in cycling colours
## (save_particle.gdshader, the legacy laws at 60 steps a second), drawn as
## the legacy quads. The legacy particles run 400 steps when they are built:
## the warm-up. They move only in the frames the legacy save point is drawn
## (Save.place_view updates them), and stand still, hidden, otherwise.

const PROCESS_SHADER := preload("res://scenes/common/particles/save_particle.gdshader")
## The legacy warm-up: 400 steps in each particle's constructor.
const WARM_UP := 400.0 / 60.0


func _init() -> void:
	super()
	var material := ShaderMaterial.new()
	material.shader = PROCESS_SHADER
	process_material = material


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		emitting = true
		preprocess = WARM_UP


## Starts the particles around the save point's centre (x, z): the
## legacy warm-up as preprocess.
func start_at(center: Vector2, particle_seed: int) -> void:
	_set_process(&"center", center)
	start(particle_seed, WARM_UP)


## SaveSystem.draw: the quadrant of the facing; in the x-y plane for the
## first and the third ((-135, -45) and (45, 135)), else in the z-y plane.
func along_x(facing: int) -> bool:
	return (facing > -135 and facing < -45) or (facing > 45 and facing < 135)

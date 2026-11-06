extends OmniLight3D
## The player's light in the HD look (docs/LOOK_PROTOTYPES_PLAN.md 4.1, 10.9):
## on the camera, a little to the right of and below the eyes, so that its
## shadows show; warm, with shadows and a halo in the volumetric fog, and a
## flicker by noise: a slow swell of its strength, a faster, fainter flutter
## over it, and a small sway. HDLook sets them from its settings.

## The energy without the flicker.
var base_energy := 2.5
## The place on the camera without the sway.
var base_position := Vector3(0.35, -0.3, -0.1)
## The swell: at most this share of the energy up or down, and how fast it
## moves (about turns a second).
var flicker := 0.1
var flicker_speed := 1.2
## The flutter over the swell, as those.
var flutter := 0.025
var flutter_speed := 7.0
## The sway: at most this far (units), and how fast.
var sway := 0.01
var sway_speed := 0.6

var _noise := FastNoiseLite.new()
# Each motion's place along the noise, moved on by its speed (a change of
# speed does not jump to another place).
var _flicker_at := 0.0
var _flutter_at := 0.0
var _sway_at := 0.0


func _init() -> void:
	name = "Torch"
	light_color = Color(1.0, 0.82, 0.62)
	omni_range = 20.0
	omni_attenuation = 1.6
	shadow_enabled = true
	light_volumetric_fog_energy = 0.2
	# One octave, smooth: the flutter is the finer motion.
	_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_noise.frequency = 1.0
	position = base_position


func _process(delta: float) -> void:
	_flicker_at += delta * flicker_speed
	_flutter_at += delta * flutter_speed
	_sway_at += delta * sway_speed
	var n := flicker * _noise.get_noise_1d(_flicker_at) \
		+ flutter * _noise.get_noise_1d(_flutter_at + 1000.0)
	light_energy = base_energy * maxf(1.0 + n, 0.0)
	position = base_position + Vector3(_noise.get_noise_1d(_sway_at + 100.0),
		_noise.get_noise_1d(_sway_at + 200.0), 0.0) * sway

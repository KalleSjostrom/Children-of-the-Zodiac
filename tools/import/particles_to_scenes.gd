extends SceneTree
## Generates the GPU particle systems of the villages and cutscenes
## (docs/MODERNIZATION_PLAN.md 6.4, docs/ARCHITECTURE.md section 9) from
## maps/ParticleSystems/particleSystems.info, read by the legacy SystemLoader
## (and its settings, shapes and particle classes), so that every value is
## the one the game reads. How to run it and tune the results:
## docs/CONVERTING_PARTICLES.md. Run headless from the project root;
## tools/import/particles_to_scenes.sh runs the two stages with Godot's import
## between them:
##
##   godot --headless --path . --script res://tools/import/particles_to_scenes.gd -- [options] [<system>...]
##
## For every system (or the named ones) it writes
##   scenes/common/particles/systems/<system>.tscn         a VillageParticles2D
##       (GPUParticles2D): the particle class's shader as process material,
##       with the system's settings as uniforms; texture, blending, amount,
##       lifetime, warm-up; a Background (Sprite2D) for a background image; the
##       slave system of a master/slave emitter as a child
##   scenes/common/particles/systems/<system>_points.png   for an image shape:
##       the pixels it emits from (alpha >= 100 after scaling), one per texel
##
## Options:
##   --stage=points   only the emission point images (with .import files)
##   --stage=scenes   only the scenes; the point images must be imported first
##   --reset-tuning   intensity, size_scale and amount from the data, not kept
##                    from the existing scenes
##
## Rates. A legacy system emits one body per emitter time step while its pool
## has one, so both the time step and nrParticles limit the rate; a GPU
## system emits amount / lifetime per second. The generator steps single
## legacy particles (the real classes and commands, at 30 steps a second)
## over a grid of their random inputs to get their mean and longest lives,
## and takes the lower of the two limits; lifetime (the slot's cycle) is the
## longest life. Systems whose emitter never emits (a time step of 0) and
## that have a warm-up shape (the stars) emit all their particles at once
## from it. The tuning exports (intensity, size_scale, amount) of an existing
## scene are kept (amount by its ratio to the generated value), unless
## --reset-tuning. Generating twice writes the same files.
##
## A launcher: the code is particles_to_scenes_job.gd, loaded in _initialize, after the
## autoloads are registered. A script that --script runs is compiled before
## them, and the game's classes name the Game autoload (docs/ARCHITECTURE.md
## section 17, "Tools").

var _job: RefCounted


func _initialize() -> void:
	_job = load("res://tools/import/particles_to_scenes_job.gd").new()
	_job.run(self)

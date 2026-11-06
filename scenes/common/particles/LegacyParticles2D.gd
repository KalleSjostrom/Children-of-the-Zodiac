@tool
class_name LegacyParticles2D
extends Node2D
## A particle system of a village scene: an entry of a "particlesystem" line
## of a (deleted) .vil file (the systems are defined in
## maps/ParticleSystems/particleSystems.info). The layer node it is in is
## where it draws: Ground (bottom layer, under the background), Actors
## (villager layer, sorted with the sprites) or Effects (upper and weather
## layers). The node's position is the emitter's, for the editor.
##
## The legacy system (bodies.system.ParticleSystem) stays in charge. Every
## frame the village hands the node, per legacy system, the system's state
## where the legacy draw would draw (show_systems); the node instances the
## system's generated scene (VillageParticles2D,
## scenes/common/particles/systems/<system>.tscn) as a child and hands the
## state on (the particles phase, plan 6.10). The legacy simulation's quads
## (--legacy=particles) are removed (closing the particles phase).

## The system's name in particleSystems.info.
@export var system_name := ""
## The legacy layer: -1 bottom, 0 villager, 1 upper, 2 weather.
@export var layer := 1
## Whether the system runs from the start.
@export var start_active := true
## An inactive system starts when the Database status of system_name has this
## value; -1: never.
@export var activation_status := -1
## The system's position among all the particle systems of the variant: the
## legacy loader builds (and warms up) them in this order, and they draw
## random numbers.
@export var build_order := 0
## The particlesystem line of the variant the system is on (0, 1, ...): the
## systems of one line are built by one SystemLoader and share its settings
## objects (Vector3f positions and forces), as in the legacy loader.
@export var line := 0

## Keys (get_instance_id()) of the legacy systems this node draws: one name
## may build several systems.
var system_keys: Array[int] = []
var _gpu := {} # definition name -> its VillageParticles2D (or null: no scene)


## Draws the given systems, one Dictionary per legacy system in draw order
## (BodiesParticleSystem.place_particles; empty: an inactive system, which
## draws nothing). A view is the state of its system ("gpu",
## BodiesParticleSystem.gpu_view): the generated scene named "definition" is
## placed so that its local coordinates are the legacy body coordinates
## ("position" and scroll: the legacy drawing's offset; screen pixels, for
## which the village's origin is at scroll) and takes the state
## (VillageParticles2D.show_state); a slave's view is drawn by its master's
## scene, and a system without a view this frame draws nothing. Nothing is
## drawn with --hide-particles (Main.hide_particles).
func show_systems(views: Array, scroll: Vector2i) -> void:
	if Main.hide_particles:
		views = []
	var shown := {}
	for view: Dictionary in views:
		if view.get("gpu", false) and not view["slave"]:
			var system := _gpu_system(view["definition"])
			if system != null:
				var p: Vector2 = view["position"]
				system.position = Vector2(p.x - scroll.x, -p.y - scroll.y) - position
				system.show_state(view)
				shown[system] = true
	for system: VillageParticles2D in _gpu.values():
		if system != null and not shown.has(system):
			system.show_state({})


## The generated system of the definition, instanced as a child on first use.
func _gpu_system(definition: String) -> VillageParticles2D:
	if not _gpu.has(definition):
		var scene := VillageParticles2D.scene_for(definition)
		var system: VillageParticles2D = scene.instantiate() if scene != null else null
		if system != null:
			add_child(system)
		_gpu[definition] = system
	return _gpu[definition]


## The marker, in the editor and with Debug > Visible Collision Shapes
## (--debug-collisions).
func _draw() -> void:
	if not (Engine.is_editor_hint() or get_tree().debug_collisions_hint):
		return
	var color := Color(1.0, 0.5, 0.0)
	draw_arc(Vector2.ZERO, 12, 0.0, TAU, 16, color, 2.0)
	draw_line(Vector2(0, -4), Vector2(0, -28), color, 2.0)

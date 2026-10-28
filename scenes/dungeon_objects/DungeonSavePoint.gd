@tool
class_name DungeonSavePoint
extends DungeonObject
## A save point ("save", legacy Save): arriving cures the party and shuffles
## the decks, and the menu can save; its particles (SaveSystem, 2000 of them)
## stand around the cell. A "-save" place starts here.


const PARTICLES_SCENE := preload("res://scenes/common/particles/SaveParticles3D.tscn")


func _new_inventory(node, map, status: int) -> Inventory:
	return InventorySave.new(node, facing)


## Step B on the GPU path (the dungeon particles phase): the particles the
## legacy save point draws this frame (SaveSystem.place_gpu), shown by the
## "Particles" child (SaveParticles3D, made at the first frame; its local
## coordinates are the floor's units, so it undoes this node's position).
## Returns it, for its place among the objects' batches.
func show_particles(state: Dictionary, style: DungeonStyle) -> QuadParticles3D:
	var p := get_node_or_null(^"Particles") as SaveParticles3D
	if p == null:
		p = PARTICLES_SCENE.instantiate() as SaveParticles3D
		p.name = "Particles"
		p.position = -position
		add_child(p)
		p.start_at(state.center, state.seed)
	p.show_state(state, style)
	return p


func _marker_text() -> String:
	return "save %d" % cell

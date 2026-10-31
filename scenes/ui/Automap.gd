extends Control
## The menu's map of a labyrinth (phase 4.2 step B, docs/ARCHITECTURE.md
## section 14), as the map page draws it with LabyrinthMap.draw: every floor
## at a third of its size (the page's modelview: translate(25, 80),
## scale(1/3) and each floor's own translate), or one floor at full size.
## Each floor is its name (centred; on the player's floor green over a black
## shadow) and then its cells' pieces, icons and the player's arrow under
## the floor's modelview (AutomapFloor), in the floors' order. The legacy
## LabyrinthMap and its nodes stay in charge of what is visited and seen;
## each frame the map page's twin hands this node what it would have drawn
## (Graphics.show_ui).

const FLOOR_VIEW := preload("res://scenes/ui/AutomapFloor.tscn")

@onready var _floors: Control = $Floors


## floors: LabyrinthMap.place_map's {"names", "images", "modelview"} each,
## in drawing order. mat is the material of the legacy drawing
## (Graphics.canvas_material).
func show_map(floors: Array, mat: Material) -> void:
	material = mat
	var views := _floors.get_children()
	for i in floors.size():
		var view: Control
		if i < views.size():
			view = views[i]
		else:
			view = FLOOR_VIEW.instantiate()
			view.use_parent_material = true
			_floors.add_child(view)
		view.visible = true
		view.show_floor(floors[i].names, floors[i].images, floors[i].modelview)
	for i in range(floors.size(), views.size()):
		views[i].visible = false

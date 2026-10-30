extends Control
## The name plate of the world map and the airship (phase 4.1 step B,
## docs/ARCHITECTURE.md section 13): the menu piece Pieces/1.png centred at
## the top of the screen and the name of the node the player stands on (or the
## airship flies over) centred at 512 on the baseline 60, as Landscape.draw
## and AirLandscape.draw draw them. The legacy mode stays in charge of which
## name shows (none while walking, on a crossroad or away from a node); each
## frame its drawing hands this node the plate and the name where it would
## have drawn them (Graphics.show_ui).

@onready var _plate: Panel = $Plate
@onready var _name: BaselineLabel = $Name


## The plate with its top-left corner at plate_at in tint (hidden when not
## plate_shown: its image is missing), and the name in color ("" draws
## none); mat is the material of the legacy drawing
## (Graphics.canvas_material), bold the font.
func show_plate(plate_shown: bool, plate_at: Vector2i, tint: Color, text: String, color: Color,
		mat: Material, bold: bool) -> void:
	material = mat
	_plate.visible = plate_shown
	_plate.position = Vector2(plate_at)
	_plate.self_modulate = tint
	_name.text = text
	_name.color = color
	_name.bold = bold

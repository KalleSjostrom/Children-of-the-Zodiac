extends Control
## A character's row of the Church's bless page (phase 4.2 step B,
## docs/ARCHITECTURE.md section 14), as Church.draw3D draws it: the cost of
## its markers (at 560, size 26), its LevelUpBar range (a LevelBar), and on
## the current row the markers (the blue and the green MenuHand: a dimmed one
## once at .3, the other twice, white and then its colour at .3; while the
## blessing runs, the one hand that swings). A BlessPage has one per
## character.

@onready var _cost: BaselineLabel = $Cost
@onready var _bar: Control = $Bar
@onready var _hands: Control = $Hands


## cost: [text, position (the baseline's start), font size, colour, bold];
## bar: the LevelBar's parts (LevelUpBar.place_static); hands: [texture,
## rect, tint] each (Graphics.place_image), in drawing order ([] for none).
func show_row(cost: Array, bar: Array, hands: Array) -> void:
	_cost.text = cost[0]
	_cost.position = Vector2(cost[1])
	_cost.theme_type_variation = MenuText.role(cost[2])
	_cost.color = cost[3]
	_cost.bold = cost[4]
	_bar.show_parts(bar)
	_hands.show_images(hands)

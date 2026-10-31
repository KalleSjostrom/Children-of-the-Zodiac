extends Control
## A menu list (phase 4.2 step B, docs/ARCHITECTURE.md section 14): the
## lines of a legacy MenuNode list and its hand, as MenuNode.draw draws them:
## each choice a line of text at its baseline in the colour of its state
## (enabled or disabled), with its price, number or equipment right-aligned
## at a smaller size where the list's variant draws one, then the hand
## pointing at the current choice and, for a list that overflows its
## bounding box, the scroll bar. The legacy MenuNode stays in charge of the
## choices, the cursor, the scroll and the key repeat; each frame its twin
## (MenuNode.show_children_freely) hands this node what it would have drawn
## (Graphics.show_ui), on the title, the game pad lost overlay and the menu
## pages; the stores later. A list with an active child whose own list is
## drawn too (the start page's character select) is shown by several of
## these nodes, in the legacy order.
##
## Each line takes the theme role of its font size (MenuChoice<size>;
## Text<size> for a size without one): the legacy list is drawn at whatever
## size its mode set, its prices, numbers and equipment at 20.

@onready var _choices: Control = $Choices
@onready var _hand: TextureRect = $Hand
@onready var _bar: Control = $ScrollBar


## lines: [text, position (the baseline's start, or its end for a
## right-aligned line), font size, colour, bold, alignment] each, in drawing
## order; hand: [texture, position, tint] ([]: none; a dimmed hand's tint has
## alpha .3); bar: the scroll bar's images (PageScrollBar.show_bar; []:
## none). mat is the material of the legacy drawing
## (Graphics.canvas_material).
func show_list(lines: Array, hand: Array, bar: Array, mat: Material) -> void:
	material = mat
	var entries := []
	for line: Array in lines:
		entries.append([line[0], line[1], _role(line[2]), line[3], line[4], line[5]])
	_choices.show_labels(entries)
	_hand.visible = not hand.is_empty() and hand[0] != null
	if _hand.visible:
		_hand.texture = hand[0]
		_hand.position = Vector2(hand[1])
		_hand.self_modulate = hand[2]
	_bar.visible = not bar.is_empty()
	if _bar.visible:
		_bar.show_bar(bar, mat)


func _role(font_size: int) -> StringName:
	return MenuText.role(font_size, "MenuChoice")

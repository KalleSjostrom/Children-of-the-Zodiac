@tool
class_name VillageLoot
extends Node2D
## Something the player can find in a village (a "loot" line of a .vil file
## and its "lootLine" lines): gold, an item, a card, an equipment or life.
## The node's position is the loot's position in village pixels.

## Content types (Loot.GOLD ... Loot.LIFE).
enum ContentType { GOLD, ITEM, CARD, EQUIPMENT, LIFE }

## The loot's Database name without the village name ("<village><name>";
## status 1 means taken).
@export var loot_name := ""
## The directions the player may face to take it.
@export var directions: PackedInt32Array = []
## Database statuses set when the loot is taken.
@export var triggers: Dictionary = {}
## The content as written in the .vil file ("_" for spaces): the amount of
## gold, or the name of the item, card class or equipment.
@export var content_name := ""
@export var content_type: ContentType = ContentType.GOLD
## GOLD: the amount; ITEM: how many (default 1).
@export var amount := 0
## CARD: the card's level.
@export var card_level := 0
## CARD: whether the card is given to all characters.
@export var all_cards := false
## LIFE: the amount of life.
@export var life := 0.0
## The message lines shown when the loot is found (the "lootLine" texts).
## VillageLoader adds them to the last loot that is not taken yet, so the
## lines of a taken loot go to the previous one.
@export var lines: PackedStringArray = []


## The marker, in the editor and with Debug > Visible Collision Shapes
## (--debug-collisions).
func _draw() -> void:
	if not (Engine.is_editor_hint() or get_tree().debug_collisions_hint):
		return
	var color := Color(1.0, 0.8, 0.0)
	draw_arc(Vector2.ZERO, 35, 0.0, TAU, 32, color, 2.0)
	draw_circle(Vector2.ZERO, 4, color)

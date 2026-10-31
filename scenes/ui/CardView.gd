extends Control
## A card as a deck or a page draws it (phase 4.2 step B,
## docs/ARCHITECTURE.md section 14), AbstractCard.drawCard: its picture (in
## colour or grey) and its level's balls at the card's size, and in the card
## store its number right-aligned over a shadow. A DeckView has one per card;
## the deck page shows one per flying card (DeckPage.Animator).

@onready var _images: Control = $Images
@onready var _index: Control = $Index


## images: the picture and the balls (AbstractCard.place_at: [texture, rect,
## tint] each); index: the card store's number and its shadow ([text, end of
## the line, font size, colour, bold] each; [] for none). mat is the material
## of the legacy drawing (Graphics.canvas_material), null to use the
## parent's (in a DeckView).
func show_card(images: Array, index: Array, mat: Material) -> void:
	if mat != null:
		material = mat
	_images.show_images(images)
	var entries := []
	for line: Array in index:
		entries.append([line[0], line[1], _role(line[2]), line[3], line[4], HORIZONTAL_ALIGNMENT_RIGHT])
	_index.show_labels(entries)


func _role(font_size: int) -> StringName:
	if font_size == 26:
		return &"CardIndex"
	if font_size == 28:
		return &"CardIndexCurrent"
	return StringName("Text%d" % font_size)

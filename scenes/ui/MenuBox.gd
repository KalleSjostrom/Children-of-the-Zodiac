extends Control
## A box of the menu (phase 4.2 step B, docs/ARCHITECTURE.md section 14): a
## menu piece with lines of text on it, as the start page draws its saving
## box (StartPage.drawConfirmBuyDialog: Pieces/1.png centred at y 300,
## "Saving." to "Saving..."; no dim). The stores' confirm boxes are the same
## kind of box (a piece and texts, after a dim, before their Yes/No list).

@onready var _piece: TextureRect = $Piece
@onready var _lines: Control = $Lines


## piece: the box's image ([texture, rect, tint], Graphics.place_image's;
## [] for none); lines: [text, position (the baseline's start, or its end
## with alignment), font size, colour, bold[, alignment]] each (left-aligned
## when alignment is left out; a store's confirm box right-aligns its price).
## mat is the material of the legacy drawing (Graphics.canvas_material).
func show_box(piece: Array, lines: Array, mat: Material) -> void:
	material = mat
	_piece.visible = not piece.is_empty()
	if _piece.visible:
		var r: Rect2i = piece[1]
		_piece.texture = piece[0]
		_piece.position = Vector2(r.position)
		_piece.size = Vector2(r.size)
		_piece.self_modulate = piece[2]
	var entries := []
	for line: Array in lines:
		entries.append([line[0], line[1], MenuText.role(line[2]), line[3], line[4],
				line[5] if line.size() > 5 else HORIZONTAL_ALIGNMENT_LEFT])
	_lines.show_labels(entries)

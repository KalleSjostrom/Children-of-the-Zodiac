extends Control
## A tutorial page over the frame (phase 3 step B, docs/ARCHITECTURE.md
## section 12), as the legacy menu.tutorial.Tutorial draws its top layer: the
## dimmed screen, the paper, the title and the page's rows of words (black,
## or coloured with a black shadow) with their button icons. Trigger doors,
## battles, the stores and the menu's tutorial page show it. The legacy
## Tutorial and its .tut book stay in charge of the pages; each frame its
## drawing hands this node what it would have drawn (Graphics.show_ui).

@onready var _dim: ColorRect = $Dim
@onready var _paper: TextureRect = $Paper
@onready var _title: BaselineLabel = $Title
@onready var _words: Control = $Words
@onready var _icons: Control = $Icons


## The page. dim_tint: the colour the dim (the black fade image) is drawn in;
## the paper's texture, position and tint; the title in title_color; words:
## [text, position (the baseline's start), colour] each, in drawing order
## (a coloured word's shadow first); icons: [texture, rect (the scaled image,
## its far corner truncated to whole pixels), tint] each. mat is the
## material of the legacy drawing (Graphics.canvas_material), bold the font.
func show_page(dim_tint: Color, paper: Texture2D, paper_at: Vector2i, paper_tint: Color,
		title: String, title_color: Color, words: Array, icons: Array, mat: Material,
		bold: bool) -> void:
	material = mat
	_dim.color = Color(0, 0, 0, dim_tint.a)
	_paper.texture = paper
	_paper.position = Vector2(paper_at)
	_paper.self_modulate = paper_tint
	_paper.visible = paper != null
	_title.text = title
	_title.color = title_color
	_title.bold = bold
	var entries := []
	for w: Array in words:
		entries.append([w[0], w[1], &"TutorialWord", w[2], bold, HORIZONTAL_ALIGNMENT_LEFT])
	_words.show_labels(entries)
	_show_icons(icons)


func _show_icons(icons: Array) -> void:
	var rects := _icons.get_children()
	for i in icons.size():
		var rect: TextureRect
		if i < rects.size():
			rect = rects[i]
		else:
			rect = TextureRect.new()
			rect.use_parent_material = true
			rect.mouse_filter = MOUSE_FILTER_IGNORE
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_SCALE
			_icons.add_child(rect)
		var icon: Array = icons[i]
		var r: Rect2i = icon[1]
		rect.texture = icon[0]
		rect.position = Vector2(r.position)
		rect.size = Vector2(r.size)
		rect.self_modulate = icon[2]
		rect.visible = true
	for i in range(icons.size(), rects.size()):
		rects[i].visible = false

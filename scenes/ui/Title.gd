extends Control
## The title screen's picture (phase 4.2 step B, docs/ARCHITECTURE.md section
## 14): the background (res/Title/loggasten.png) and, over it, the logo
## (loggatext.png), both at (78, 59), as the legacy TitleScreen draws them.
## The logo fades in through its colour's alpha (TitleScreen.index). The
## legacy TitleScreen stays in charge of the fade-in, the menus and the
## input; each frame its drawing hands this node what it would have drawn
## (Graphics.show_ui). The menu, the difficulty's description and the slots'
## dates are nodes of their own after it (MenuList, ShadowText, SlotDates).

@onready var _background: TextureRect = $Background
@onready var _logo: TextureRect = $Logo


## The background (hidden when not shown: its image is missing) in tint;
## the logo is hidden until show_logo. mat is the material of the legacy
## drawing (Graphics.canvas_material).
func show_background(shown: bool, tint: Color, mat: Material) -> void:
	_background.visible = shown
	_background.self_modulate = tint
	_background.material = mat
	_logo.visible = false


## The logo (hidden when not shown) in tint, with the material mat.
func show_logo(shown: bool, tint: Color, mat: Material) -> void:
	_logo.visible = shown
	_logo.self_modulate = tint
	_logo.material = mat

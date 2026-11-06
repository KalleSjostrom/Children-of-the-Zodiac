extends CanvasLayer
## The pixel look's filter over the whole frame (PixelLook): a ColorRect over
## the game's 1024×768 screen whose shader (pixel_filter.gdshader) reads the
## frame drawn under it and draws it again at a virtual low resolution, with
## few colours. On layer 40: over the game's layers (LegacyLayer 1, UI 2,
## Transition 3), under the developer console (DebugConsole.LAYER 50).

const SHADER := preload("res://proto/pixel/pixel_filter.gdshader")

var _material := ShaderMaterial.new()


func _init() -> void:
	layer = 40
	_material.shader = SHADER
	var rect := ColorRect.new()
	rect.name = "Filter"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = _material
	add_child(rect)


## PixelLook.settings: res, levels, dither, average, sharp.
func set_settings(s: Dictionary) -> void:
	var width: int = s.get("res", 512)
	@warning_ignore("integer_division")
	_material.set_shader_parameter("virtual_size", Vector2(width, width * 3 / 4))
	_material.set_shader_parameter("levels", float(s.get("levels", 16)))
	_material.set_shader_parameter("dither", float(s.get("dither", 1.0)))
	_material.set_shader_parameter("average", bool(s.get("average", true)))
	_material.set_shader_parameter("sharp", bool(s.get("sharp", true)))

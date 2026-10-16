class_name LabyrinthTexture
extends RefCounted
## Port of labyrinth.LabyrinthTexture: stores information about a texture in
## the labyrinth (and its optional normal map, used by the original bump
## mapping experiment).

var fileName: String = ""
var texture = null
var textureNormal = null


## Constructs a new LabyrinthTexture and stores the given file name.
func _init(filename = null) -> void:
	fileName = "" if filename == null else str(filename)


## Loads the textures with the stored filename.
func loadTexture() -> void:
	var n: String = ImageHandler.addToCurrentLoadNow(Values.LabyrinthTextures + fileName)
	texture = ImageHandler.getTexture(n)
	var normal: String = Values.LabyrinthTextures + fileName.replace(".png", "normal.png")
	if GameResourceLoader.getResourceLoader().exists(normal):
		n = ImageHandler.addToCurrentLoadNow(normal)
		textureNormal = ImageHandler.getTexture(n)
	else:
		normal = Values.LabyrinthTextures + fileName.replace(".jpg", "normal.jpg")
		if GameResourceLoader.getResourceLoader().exists(normal):
			n = ImageHandler.addToCurrentLoadNow(normal)
			textureNormal = ImageHandler.getTexture(n)


## Gets the texture (GameTexture).
func getTexture():
	return texture


func getNormalTexture():
	return textureNormal

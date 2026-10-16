class_name ImageHandler
extends RefCounted
## Port of graphics.ImageHandler.
##
## Manages (almost) all images and textures. Textures are kept in lists per
## game mode (see Values), the current and the previous game mode's textures
## stay in memory; textures added "permanently" are never discarded.
## In this port loading is synchronous, so the load queue is always empty.

static var texList := {} # game mode -> Dictionary(name -> GameTexture)
static var permanentList := {} # name -> GameTexture
static var images := {} # name -> Image
static var imageTextures := {} # Image -> GameTexture (for drawing Images)
static var secondaryGameMode := 0
static var currentGameMode := 0


static func setGameMode(gameMode: int) -> void:
	if secondaryGameMode != gameMode:
		if secondaryGameMode != currentGameMode:
			if gameMode != Values.MENU:
				clearList(secondaryGameMode)
		secondaryGameMode = currentGameMode
		currentGameMode = gameMode


static func swapGameMode() -> void:
	var temp := secondaryGameMode
	secondaryGameMode = currentGameMode
	currentGameMode = temp


static func _getList(gameMode: int) -> Dictionary:
	if not texList.has(gameMode):
		texList[gameMode] = {}
	return texList[gameMode]


static func _add(list: Dictionary, name: String) -> String:
	if not permanentList.has(name) and not list.has(name):
		var t := _loadTexture(name)
		if t != null:
			list[name] = t
	return name


static func addToCurrentLoadOnUse(name: String) -> String:
	return name


static func addToCurrentLoadNow(name: String) -> String:
	return _add(_getList(currentGameMode), name)


static func addToCurrentConvertNow(name: String, image: Image) -> String:
	var list := _getList(currentGameMode)
	if not permanentList.has(name) and not list.has(name) and image != null:
		list[name] = GameTexture.fromImage(name, image)
	return name


static func addPermanentlyLoadOnUse(name: String) -> String:
	return addPermanentlyLoadNow(name)


static func addPermanentlyLoadNow(name: String) -> String:
	if not permanentList.has(name):
		var t := _loadTexture(name)
		if t != null:
			permanentList[name] = t
	return name


static func addPermanentlyConvertNow(name: String, image: Image) -> String:
	if image != null:
		permanentList[name] = GameTexture.fromImage(name, image)
	return name


static func clearDrawList() -> void:
	pass


static func generateDrawList(g: Graphics) -> int:
	return g.generateList()


static func load(g = null) -> void:
	pass


static func getLoadQueueSize() -> int:
	return 0


static func _loadTexture(name: String) -> GameTexture:
	var path := GameResourceLoader.resolve(name)
	if path == "":
		push_error("ImageHandler: image not found: " + name)
		return null
	var tex = ResourceLoader.load(path)
	if tex == null or not (tex is Texture2D):
		push_error("ImageHandler: could not load texture: " + path)
		return null
	return GameTexture.new(name, tex)


## Gets the image (java BufferedImage) with the given path [+ name].
static func getImage(path: String, name: String = "") -> Image:
	var full := path + name
	var im: Image = images.get(full)
	if im == null:
		var t := getTexture(full)
		if t == null:
			return null
		im = t.getData()
		images[full] = im
	return im


## Gets the texture with the given name, loading it if needed.
static func getTexture(name: String) -> GameTexture:
	var list := _getList(currentGameMode)
	var t: GameTexture = list.get(name)
	if t == null:
		t = permanentList.get(name)
		if t == null:
			t = _getList(secondaryGameMode).get(name)
			if t == null:
				t = _loadTexture(name)
				if t != null:
					list[name] = t
	return t


## Gets (creating if needed) the texture used to draw the given Image.
static func getGameTexture(image: Image) -> GameTexture:
	var t: GameTexture = imageTextures.get(image)
	if t == null:
		t = GameTexture.fromImage("image" + str(image.get_instance_id()), image)
		imageTextures[image] = t
	return t


## Call after modifying an Image that has been drawn, to refresh its texture.
static func updateImage(image: Image) -> void:
	var t: GameTexture = imageTextures.get(image)
	if t != null:
		t.updateImage(null, image)


static func clearList(gameMode: int) -> void:
	if texList.has(gameMode):
		texList[gameMode].clear()
	imageTextures.clear()


static func isCurrentGameModeCleared() -> bool:
	return _getList(currentGameMode).size() == 0

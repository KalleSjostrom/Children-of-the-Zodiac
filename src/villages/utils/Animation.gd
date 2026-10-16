class_name VillageAnimation
extends RefCounted
## Port of villages.utils.Animation: a simple frame animation of image names
## (used by the sprites).

var currFrameIndex: int = 0
var frames = []
var animTime: float = 0.0
var totalDuration: float = 0.0
var name = null


func _init() -> void:
	frames = []


## Adds a frame with the given image name shown for duration ms.
func addFrame(p_name, duration):
	totalDuration += duration
	frames.append(AnimFrame.new(p_name, totalDuration))


func changePic(i, image):
	frames[i].changeImage(image)


func update(elapsedTime):
	if frames.size() > 1:
		animTime += elapsedTime
		if animTime >= totalDuration:
			animTime = 0.0
			currFrameIndex = 0
		if animTime > frames[currFrameIndex].endTime:
			currFrameIndex += 1


func getImage():
	if frames.size() == 0:
		return null
	return frames[currFrameIndex].image


func draw(g, x, y):
	var tex: GameTexture = ImageHandler.getTexture(name)
	tex.bind(g)

	var ny := int(y)
	var nyh := int(y + 55)
	var xw := int(x + 36)

	var tx: float = ((currFrameIndex % 4) * 36) / float(tex.getWidth())
	var ty: float = ((currFrameIndex / 4) * 36) / float(tex.getHeight())

	var txw: float = tx + 36.0 / tex.getWidth()
	var tyh: float = ty + 55.0 / tex.getHeight()

	var gl = g.getGL()
	g.beginQuads()
	gl.glTexCoord2f(tx, tyh)
	gl.glVertex2i(int(x), nyh)

	gl.glTexCoord2f(txw, tyh)
	gl.glVertex2i(xw, nyh)

	gl.glTexCoord2f(txw, ty)
	gl.glVertex2i(xw, ny)

	gl.glTexCoord2f(tx, ty)
	gl.glVertex2i(int(x), ny)

	g.end()


class AnimFrame extends RefCounted:
	var image = ""
	var endTime = 0.0

	func _init(p_image = null, p_totalDuration = null) -> void:
		image = p_image
		endTime = 0.0 if p_totalDuration == null else float(p_totalDuration)

	func changeImage(p_image):
		image = p_image

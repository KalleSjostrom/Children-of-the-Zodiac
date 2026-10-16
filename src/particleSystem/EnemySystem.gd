class_name EnemySystem
extends ParticleSystem
## Port of particleSystem.EnemySystem: a "system" that pulses the color of
## the enemy depending on the element.

var color_ = Vector3f.new()
var time: float = 0.0
var colorType: int = 0

func _init(p_settings = null, p_enemy = null) -> void:
	super(p_settings, p_enemy)
	colorType = int(p_settings.getValue(AnimSettings.COLOR))
	color_ = Vector3f.new(1.0, 1.0, 1.0)
	p_enemy.cancelColorChange()

func update(elapsedTime, body = null):
	super.update(elapsedTime)
	if not isDestroyed():
		time += elapsedTime
		var theta: float = (20.0 * time)
		var t: float = theta
		var c: float = cos(t)

		if colorType == Card.FIRE_ELEMENT:
			color_.y = c / 3 + 0.6
			color_.z = c / 3 + 0.6
		elif colorType == Card.ICE_ELEMENT:
			color_.x = c / 3 + 0.6
			color_.y = c / 3 + 0.6
		elif colorType == Card.EARTH_ELEMENT:
			color_.x = ((c + 1) / 2) * 0.3 + 0.4
			color_.y = ((c + 1) / 2) * 0.18 + 0.34
			color_.z = ((c + 1) / 2) * 0.1 + 0.2
		elif colorType == Card.WIND_ELEMENT:
			color_.x = c / 3 + 0.6
			color_.z = c / 3 + 0.6

func start(g):
	pass

func end(g):
	pass

func draw(g, t = null, pPos = null):
	if not destroyed:
		if getEnemy() != null:
			var e = getEnemy()
			e.setColor(color_)

func getColor():
	if color_ == null:
		color_ = Vector3f.new(1.0, 1.0, 1.0)
	return getEnemy().getSourceColor()

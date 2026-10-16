class_name Fadeable
extends RefCounted
## Port of story.Fadeable: something that fades in and out, one step per
## draw call (the game runs at Values.FPS = 60 frames per second).

var fadein := false
var fadeout := false
var fadeValue := 0.0
var fadeOutSpeed := 0.03
var fadeInSpeed := 0.03


func setFadeOutSpeed(speed: float) -> void:
	fadeOutSpeed = speed


func setFadeInSpeed(speed: float) -> void:
	fadeInSpeed = speed


func setFadeSpeed(speed: float) -> void:
	fadeOutSpeed = speed
	fadeInSpeed = speed


func updateFadeValue() -> void:
	if fadein:
		fadeIn()
	elif fadeout:
		fadeOut()


func fadeIn() -> void:
	if fadeValue < 1:
		fadeValue += fadeInSpeed
	else:
		fadeValue = 1
		fadein = false


func fadeOut() -> void:
	if fadeValue > 0:
		fadeValue -= fadeOutSpeed
	else:
		fadeValue = 0
		fadeout = false


func checkFade(info) -> void:
	if info.isFade():
		var fadeInTime: float = info.getInfo(TimeLineEvent.FADE_TIME)
		setFadeSpeed((1 / fadeInTime) * Values.INTERVAL)
		fadein = info.getType() == TimeLineEvent.TYPE_FADE_IN
		fadeValue = 0.0 if fadein else 1.0
		fadeout = not fadein
	elif info.getType() == TimeLineEvent.TYPE_NO_FADE:
		fadein = false
		fadeout = false
		fadeValue = 1

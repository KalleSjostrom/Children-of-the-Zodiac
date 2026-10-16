class_name TheElementOfFire
extends Elements
## Port of cards.neutral.TheElementOfFire: changes the target's element to fire.


func setElement():
	element = FIRE_ELEMENT


func createTextInfo():
	return [
			"Fire is one of natures own elements that will either aid or hinder",
			"the one who uses it. Fire is not to be tampered with, but for those",
			"who know how to use it, the wind of battle can quickly change."]


func getSimpleName():
	return "FireElement"

class_name TheElementOfIce
extends Elements
## Port of cards.neutral.TheElementOfIce: changes the target's element to ice.


func setElement():
	element = ICE_ELEMENT


func createTextInfo():
	return [
			"Chilly essence of ice can aid the wielder greatly by wrapping its",
			"frozen energy around the weapon and armor. But beware for warm",
			"entities that could devastate this frosty defense."]


func getSimpleName():
	return "IceElement"

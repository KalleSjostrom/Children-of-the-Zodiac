class_name TheElementOfEarth
extends Elements
## Port of cards.neutral.TheElementOfEarth: changes the target's element to earth.


func setElement():
	element = EARTH_ELEMENT


func createTextInfo():
	return [
			"Earth can be one's greatest asset or one's greates liability. It",
			"can feed an entire population and yet kill thousands of people in a",
			"tremor. A shelter of earth can keep habitants safe but from Libra?"]


func getSimpleName():
	return "EarthElement"

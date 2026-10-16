class_name TheElementOfWind
extends Elements
## Port of cards.neutral.TheElementOfWind: changes the target's element to wind.


func setElement():
	element = WIND_ELEMENT


func createTextInfo():
	return [
			"Libra and Gemini sought to conseal their powers in this card. To",
			"use it, one must comprehend the dangers of throwing caution into",
			"the wind and trusting it blindly when earth itself starts to tremble."]


func getSimpleName():
	return "WindElement"

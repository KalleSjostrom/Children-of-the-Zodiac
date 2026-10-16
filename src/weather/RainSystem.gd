class_name RainSystem
extends WeatherSystem
## Port of weather.RainSystem: the rain in the labyrinths.


func getNumberOfParticles():
	return 10000


func getParticle():
	return RainParticle.new()


func getTextureName():
	return "rain.png"


func getForce():
	return [0.0, -0.2, 0.0]

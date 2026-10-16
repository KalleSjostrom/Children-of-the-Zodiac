class_name WeatherSnowSystem
extends WeatherSystem
## Port of weather.SnowSystem: the snow in the labyrinths.


func getParticle():
	return WeatherSnowParticle.new()


func getTextureName():
	return "snowparticle.png"


func getNumberOfParticles():
	return 10000


func setup(g):
	g.setAlphaTestEnabled(true)
	g.setAlphaFunc(0)


func getForce():
	return [0.0, -0.003, 0.0]

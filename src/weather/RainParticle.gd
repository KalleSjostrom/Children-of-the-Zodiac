class_name RainParticle
extends WeatherParticle
## Port of weather.RainParticle: a rain drop.
##
## Port note: the static Java fields color/size are color_/size_.

static var color_ = [1.0, 1.0, 1.0, 1.0]
static var size_ = [0.01, 0.045]


func getSize():
	return size_


func getColor():
	return color_


func shouldResurrect():
	return pos[1] < -2.0


func getInitialHeight():
	return J.random() * 6 - 2.0

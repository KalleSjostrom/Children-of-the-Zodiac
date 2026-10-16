class_name WeatherSnowParticle
extends WeatherParticle
## Port of weather.SnowParticle: a snow flake.
##
## Port note: the static Java fields color/size are color_/size_.

static var color_ = [1.0, 1.0, 1.0, 1.0]
static var size_ = [0.075, 0.075]


func getSize():
	return size_


func getColor():
	return color_


# func getWorldSize():
# 	return [11 * 4, 8, 13 * 4, 0]


func shouldResurrect():
	return pos[1] < -2.2


func getInitialHeight():
	return rand.nextFloat() * 6 - 2.0

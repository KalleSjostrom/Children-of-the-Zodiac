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


## Port deviation (docs/port_notes/inventory-weather.md): Java draws the
## initial height from Math.random; the port from the weather's own
## generator, as SnowParticle does, so that a seeded run's other draws do not
## depend on the rain.
func getInitialHeight():
	return rand.nextDouble() * 6 - 2.0

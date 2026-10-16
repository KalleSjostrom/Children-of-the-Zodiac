class_name LabyrinthRenderer
extends RefCounted
## Port of labyrinth.LabyrinthRenderer: renders the walls, floors and
## ceilings of the labyrinth (not the inventory), plus fog, light and sky.

var textures = null
var settings = null
var settingValues = null
var map = null
var tangent: int = -1

func _init(textures = null) -> void:
	self.textures = textures

func setSettings(settings, settingValues):
	self.settings = settings
	self.settingValues = settingValues

func setMap(map):
	self.map = map

func getSetting(index):
	return settings[index]

func getSettingValue(index):
	return settingValues[index]

func init(g):
	for i in range(textures.size()):
		textures[i].loadTexture()

func draw(g):
	var nodes = map.getNodes()
	for j in range(5):
		var temp: int = j
		if j == MapLoader.WALL:
			temp = j + 1
		elif j == MapLoader.ROOF:
			temp = j - 1
		for i in range(MapLoader.textureNorm[temp][0], MapLoader.textureNorm[temp][1]):
			textures[i].getTexture().bind(g)
			g.beginQuads()
			for addr in nodes:
				var n = nodes[addr]
				match temp:
					MapLoader.FLOOR:
						n.drawFloors(g, i)
					MapLoader.WALL:
						n.drawWall(g, i, false, tangent)
					MapLoader.ROOF:
						if not settings[MapLoader.SKY]:
							n.drawRoof(g, i)
					MapLoader.CARPET_FLOOR:
						n.drawFloors(g, i)
					MapLoader.PILLAR_WALLS:
						n.drawWall(g, i, true, tangent)
			g.end()

func addFog(g):
	var gl = g.getGL()
	if settings[MapLoader.FOG]:
		gl.glEnable(Graphics.GL_FOG)
		gl.glFogf(Graphics.GL_FOG_MODE, Graphics.GL_EXP)
		var fog: Array = settingValues[MapLoader.FOG]
		var color: Array = J.array(4, 0.0)
		for i in range(color.size()):
			color[i] = fog[i]
		gl.glFogf(Graphics.GL_FOG_DENSITY, fog[MapLoader.FOG_DENSITY])
		gl.glFogfv(Graphics.GL_FOG_COLOR, color, 0)
		gl.glHint(Graphics.GL_FOG_HINT, Graphics.GL_NICEST)
		# (sic) the original passes color[1] twice.
		gl.glClearColor(color[0], color[1], color[1], color[2])
	else:
		gl.glDisable(Graphics.GL_FOG)

## Java overloads addLight(Graphics g) and addLight(GL2 gl, int index, int glLight).
func addLight(gl, index = null, glLight = null):
	if index == null:
		var g = gl
		var gl2 = g.getGL()
		if settings[MapLoader.LIGHT_0]:
			addLight(gl2, MapLoader.LIGHT_0, Graphics.GL_LIGHT0)
		else:
			gl2.glDisable(Graphics.GL_LIGHT0)
		if settings[MapLoader.LIGHT_1]:
			addLight(gl2, MapLoader.LIGHT_1, Graphics.GL_LIGHT1)
		else:
			gl2.glDisable(Graphics.GL_LIGHT1)
		return
	var light: Array = settingValues[index]
	gl.glLightfv(glLight, Graphics.GL_POSITION, light, MapLoader.LIGHT_POSITION)
	gl.glLightfv(glLight, Graphics.GL_AMBIENT, light, MapLoader.LIGHT_AMBIENT)
	gl.glLightfv(glLight, Graphics.GL_DIFFUSE, light, MapLoader.LIGHT_DIFFUSE)
	gl.glLightfv(glLight, Graphics.GL_SPECULAR, light, MapLoader.LIGHT_SPECULAR)
	gl.glLightf(glLight, Graphics.GL_CONSTANT_ATTENUATION, light[MapLoader.LIGHT_ATTENUATION])
	gl.glLightf(glLight, Graphics.GL_LINEAR_ATTENUATION, light[MapLoader.LIGHT_ATTENUATION + 1])
	gl.glLightf(glLight, Graphics.GL_QUADRATIC_ATTENUATION, light[MapLoader.LIGHT_ATTENUATION + 2])
	gl.glEnable(glLight)

func setLight(g):
	var gl = g.getGL()
	gl.glLightfv(Graphics.GL_LIGHT3, Graphics.GL_POSITION, [0.0, 0.0, 0.0, 1.0], 0)
	gl.glLightfv(Graphics.GL_LIGHT3, Graphics.GL_AMBIENT, [1.0, 1.0, 1.0, 1.0], 0)
	gl.glLightfv(Graphics.GL_LIGHT3, Graphics.GL_DIFFUSE, [1.0, 1.0, 1.0, 1.0], 0)
	gl.glLightfv(Graphics.GL_LIGHT3, Graphics.GL_SPECULAR, [1.0, 1.0, 1.0, 1.0], 0)
	gl.glLightf(Graphics.GL_LIGHT3, Graphics.GL_CONSTANT_ATTENUATION, 1)
	gl.glLightf(Graphics.GL_LIGHT3, Graphics.GL_LINEAR_ATTENUATION, 0.01)
	gl.glLightf(Graphics.GL_LIGHT3, Graphics.GL_QUADRATIC_ATTENUATION, 0.015)

func getWeatherSystem():
	var system = null
	if settings[MapLoader.USE_SNOW]:
		system = WeatherSnowSystem.new()
	elif settings[MapLoader.USE_RAIN]:
		system = RainSystem.new()
	return system

func renderSky(g):
	if settings[MapLoader.SKY]:
		g.push()
		g.loadIdentity()
		g.setLightEnabled(false)
		g.setDepthTestEnabled(false)
		g.setTextureEnabled(false)
		var gl = g.getGL()
		gl.glDisable(Graphics.GL_CULL_FACE)
		var colors: Array = settingValues[MapLoader.SKY]
		g.beginQuads()
		g.setColorv(colors, MapLoader.SKY_TOP_COLOR)
		gl.glVertex3f(-2, 0.827, -2)
		gl.glVertex3f(2, 0.827, -2)
		g.setColorv(colors, MapLoader.SKY_BOTTOM_COLOR)
		gl.glVertex3f(2, 0, -2)
		gl.glVertex3f(-2, 0, -2)
		g.end()
		gl.glEnable(Graphics.GL_CULL_FACE)
		g.setDepthTestEnabled(true)
		g.setTextureEnabled(true)
		g.pop()

func setMaterial(g):
	var material: Array = settingValues[MapLoader.MATERIAL]
	var gl = g.getGL()
	gl.glMaterialfv(Graphics.GL_FRONT, Graphics.GL_AMBIENT, material, MapLoader.MATERIAL_AMBIENT)
	gl.glMaterialfv(Graphics.GL_FRONT, Graphics.GL_DIFFUSE, material, MapLoader.MATERIAL_DIFFUSE)
	gl.glMaterialfv(Graphics.GL_FRONT, Graphics.GL_SPECULAR, material, MapLoader.MATERIAL_SPECULAR)
	gl.glMaterialfv(Graphics.GL_FRONT, Graphics.GL_EMISSION, material, MapLoader.MATERIAL_EMISSION)
	gl.glMaterialfv(Graphics.GL_FRONT, Graphics.GL_SHININESS, material, MapLoader.MATERIAL_SHININESS)

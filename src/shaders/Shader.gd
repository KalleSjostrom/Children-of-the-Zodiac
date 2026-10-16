class_name GameShader
extends RefCounted
## Port of shaders.Shader.
##
## The original compiled GLSL programs (vtest.glsl / ftest.glsl) through JOGL.
## The GL emulation has no programmable shader pipeline, so this port keeps
## the API and falls back to fixed-function rendering: init() reads the shader
## sources (if present) but compiles nothing, uniform/attribute locations are
## -1 (as GL returns for unknown names) and useShader/useDefaultShader are no-ops.

var shaderprogram = 0

func init(gl):
	var v: int = 1
	var f: int = 2
	readFile("vtest.glsl", v, gl)
	readFile("ftest.glsl", f, gl)
	shaderprogram = 0
	useShader(gl)

func readFile(string, kind, gl):
	var path: String = Values.Shaders + string
	if not GameResourceLoader.fileExists(path):
		return
	var text: String = GameResourceLoader.readText(path)
	var a: Array = []
	for line in text.split("\n"):
		a.append(line + "\n")
	# No GLSL compilation available: compile status is always "true".
	checkError(kind, 1, gl)

func checkError(kind, status, gl):
	if status != 1:
		push_error("Shader: compile error for shader " + str(kind))

func getUniformLocation(gl, string):
	return -1

func getAttributeLocation(gl, string):
	return -1

func useShader(gl):
	pass

func useDefaultShader(gl):
	pass

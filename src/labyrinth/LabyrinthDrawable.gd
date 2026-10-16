class_name LabyrinthDrawable
extends RefCounted
## Port of the Java interface labyrinth.LabyrinthDrawable: something that is
## drawn inside the labyrinth's 3D scene (battles, riddles).
## Implementing classes (BattleManager, RiddleGame) do not extend this class;
## the labyrinth uses duck typing (has_method("drawTopLayer")).


func initDraw(g):
	pass


func draw(g):
	pass


func update(elapsedTime):
	pass


func drawTopLayer(g):
	pass

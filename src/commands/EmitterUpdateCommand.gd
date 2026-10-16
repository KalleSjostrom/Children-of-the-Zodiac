class_name EmitterUpdateCommand
extends Command
## Port of commands.EmitterUpdateCommand: updates the emitter of a system.

var emitter = null


func setEmitter(emitter):
	self.emitter = emitter


func execute(bodies, elapsedTime):
	emitter.update(elapsedTime)

package commands;

import bodies.Bodies;
import bodies.emitter.AbstractEmitter;

public class EmitterUpdateCommand extends Command {
	
	private AbstractEmitter emitter;

	public void setEmitter(AbstractEmitter emitter) {
		this.emitter = emitter;
	}

	@Override
	public void execute(Bodies bodies, float elapsedTime) {
		emitter.update(elapsedTime);
	}
}

package commands;

import bodies.Bodies;
import bodies.Body;

public class UpdateCommand extends Command {

	public UpdateCommand(){}

	protected void executeSingle(Body b, float elapsedTime) {
		if (b.isAlive()) {
			b.update(elapsedTime);
		}
	}
	@Override
	public void execute(Bodies bodies, float elapsedTime) {
		executeAll(bodies, elapsedTime);
	}
}

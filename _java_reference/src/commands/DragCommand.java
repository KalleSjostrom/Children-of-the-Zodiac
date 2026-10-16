package commands;

import bodies.Bodies;
import bodies.Body;

public class DragCommand extends Command {

	private float drag;
	
	public DragCommand(float f) {
		drag = f;
	}

	@Override
	public void execute(Bodies bodies, float elapsedTime) {
		executeAll(bodies, elapsedTime);
	}
	
	@Override
	protected void executeSingle(Body b, float elapsedTime) {
		b.addDrag(drag);
	}
}

package commands;

import bodies.Bodies;
import bodies.Body;

public class ViscousDragCommand extends Command {

	private float drag;
	
	public ViscousDragCommand(float f) {
		drag = f;
	}

	@Override
	public void execute(Bodies bodies, float elapsedTime) {
		executeAll(bodies, elapsedTime);
	}
	
	@Override
	protected void executeSingle(Body b, float elapsedTime) {
		b.addViscousDrag(drag);
	}
}

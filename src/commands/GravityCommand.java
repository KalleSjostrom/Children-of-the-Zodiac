package commands;

import bodies.Bodies;
import bodies.Body;
import bodies.Vector3f;

public class GravityCommand extends Command {

	public static final float DEFAULT_GRAVITY = 9.82f;

	private Vector3f gravity;

	public GravityCommand() {
		gravity = new Vector3f(0, -DEFAULT_GRAVITY, 0);
	}

	public GravityCommand(float grav) {
		gravity = new Vector3f(0, -grav, 0);
	}

	protected void executeSingle(Body b, float elapsedTime) {
		if (b.isAlive()) {
			b.addForce(gravity.mult(b.getMass()));
		}
	}

	public void execute(Bodies bodies, float elapsedTime) {
		executeAll(bodies, elapsedTime);
	}
}

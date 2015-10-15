package commands;

import java.util.Iterator;

import bodies.Bodies;
import bodies.Body;
import bodies.Vector3f;

public class WindCommand extends Command {

	public static final float DEFAULT_TURBULENCE = .1f;
	
	private Vector3f wind = new Vector3f();
	private float turbulence = DEFAULT_TURBULENCE;
	private float windMagnitude;

	public void setForce(Vector3f force) {
		wind = force;
		windMagnitude = wind.length();
	}
		
	public void setTurbulence(float value) {
		turbulence = value;
	}

	@Override
	public void execute(Bodies bodies, float elapsedTime) {
		Iterator<Body> it = bodies.iterator();
		wind.addLocal(
				(float) ((Math.random()-.5f) * turbulence), 
				(float) ((Math.random()-.5f) * turbulence), 
				(float) ((Math.random()-.5f) * turbulence));
		wind.normalizeLocal().multLocal(windMagnitude);
		while (it.hasNext()) {
			Body b = it.next();
			if (b.isAlive()) {
				b.addForce(wind.mult(b.getMass()));
			}
		}
	}
}

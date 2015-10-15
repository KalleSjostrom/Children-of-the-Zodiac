package commands;

import java.util.Iterator;

import bodies.Bodies;
import bodies.Body;

public abstract class Command {

	public abstract void execute(Bodies bodies, float elapsedTime);
	
	protected void executeAll(Bodies bodies, float elapsedTime) {
		Iterator<Body> it = bodies.iterator();
		while (it.hasNext()) {
			Body b = it.next();
			executeSingle(b, elapsedTime);
		}
	}
	
	protected void executeSingle(Body b, float elapsedTime) {}
}

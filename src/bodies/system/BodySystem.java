package bodies.system;

import graphics.Graphics;
import sprite.Sprite;
import bodies.Bodies;
import bodies.Body;

public abstract class BodySystem extends Sprite {
	
	private Bodies bodies = new Bodies();
	
	public BodySystem() {
		animImage = "";
	}

	protected Bodies getBodies() {
		return bodies;
	}
	
	public Body addBody(Body b) {
		return bodies.add(b);
	}
	
	@Override
	public void draw(float dt, Graphics g, int x, int y) {}
}

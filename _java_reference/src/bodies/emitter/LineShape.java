package bodies.emitter;

import settings.ShapeSettings;
import bodies.Vector3f;

public class LineShape extends EmitterShape {
	
	private Vector3f point;
	private float minAngleTan;
	private float maxAngleTan;
	private float interval;
	
	public LineShape(ShapeSettings settings) {
		super(settings);
		point = settings.getVector(ShapeSettings.POINTS);
		float angle = settings.getValue(ShapeSettings.ANGLE);
		minAngleTan = (float) Math.tan(Math.toRadians(-angle));
		maxAngleTan = (float) Math.tan(Math.toRadians(angle));
		interval = maxAngleTan - minAngleTan;
	}

	protected Vector3f modifyDirection(Vector3f direction) {
		float temp = (float) (Math.random() * interval + minAngleTan);
		direction.x += temp;
		return direction;
	}

	@Override
	public Vector3f getEmittancePos() {
		float deltaX, deltaY;
		Vector3f pos = getPosition();
		deltaX = point.x;
		deltaY = point.y;
		Vector3f emitPosition = new Vector3f(
				(float) (Math.random() * deltaX) + pos.x, 
				(float) (Math.random() * deltaY) + pos.y, 0);
		return emitPosition;
	}
}

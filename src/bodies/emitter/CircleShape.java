package bodies.emitter;

import settings.ShapeSettings;
import bodies.Vector3f;

public class CircleShape extends EmitterShape {

	private float radiusa;
	private float radiusb;

	protected CircleShape(ShapeSettings settings) {
		super(settings);
		radiusa = settings.getVector(ShapeSettings.POINTS).x;
		radiusb = settings.getVector(ShapeSettings.POINTS).y;
	}

	@Override
	protected Vector3f modifyDirection(Vector3f direction) {
		return direction;
	}

	@Override
	public Vector3f getEmittancePos() {
		Vector3f emitPosition = new Vector3f();
		double theta = Math.random() * 2 * Math.PI;// - (1.0 / 4.0) * Math.PI;
		emitPosition.x = (float) (radiusa * Math.cos(theta));
		emitPosition.y = (float) (radiusb * Math.sin(theta));
		emitPosition.addLocal(getPosition());
		return emitPosition;
	}
}

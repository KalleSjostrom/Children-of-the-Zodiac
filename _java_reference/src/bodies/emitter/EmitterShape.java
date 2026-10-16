package bodies.emitter;

import settings.ShapeSettings;
import bodies.Body;
import bodies.Vector3f;

public abstract class EmitterShape extends Body {

	protected EmitterShape(ShapeSettings settings) {
		setPosition(settings.getVector(ShapeSettings.POSITION));
	}
	
	public abstract Vector3f getEmittancePos();
	protected abstract Vector3f modifyDirection(Vector3f direction);
}

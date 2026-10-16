package bodies.emitter;

import settings.ShapeSettings;
import bodies.Vector3f;

public class BoxShape extends EmitterShape {

	private Vector3f[] vectors = new Vector3f[2];

	protected BoxShape(ShapeSettings settings) {
		super(settings);
		vectors[0] = settings.getVector(ShapeSettings.POINTS);
		vectors[1] = settings.getVector(ShapeSettings.POINTS + 1);
	}

	@Override
	protected Vector3f modifyDirection(Vector3f direction) {
		return direction;
	}
	
	int zeroHundred = 0;
	int hundred200 = 0;

	@Override
	public Vector3f getEmittancePos() {
		int index = Math.random() < .5f ? 0 : 1;
		Vector3f temp = interpolate(vectors[index]);
		index = Math.abs(index - 1);
		Vector3f emitPosition = interpolate(vectors[index]).add(temp).add(getPosition());
		if (emitPosition.x < 300) {
			zeroHundred++;
		} else {
			hundred200++;
		}
		return emitPosition;
	}
	
	private Vector3f interpolate(Vector3f v) {
		float l = v.length();
		float newL = (float) (Math.random() * l);
		return v.normalize().multLocal(newL);
	}
}

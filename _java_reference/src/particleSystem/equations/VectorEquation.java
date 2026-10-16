package particleSystem.equations;

import bodies.Vector3f;

public interface VectorEquation {

	public Vector3f modifyVector(Vector3f v, float elapsedTime);
	public Vector3f getVectorAfterTime(Vector3f v, float elapsedTime);
}

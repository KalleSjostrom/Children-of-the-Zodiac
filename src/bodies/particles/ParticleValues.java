package bodies.particles;

import bodies.Vector3f;

public class ParticleValues {
	
	public static final float DEFAULT_INTERACTION_RADIUS = 1;
	public static final float DEFAULT_INTERACTION_DIAMETER = 2 * DEFAULT_INTERACTION_RADIUS;
	public static final float DEFAULT_INTERACTION_DIAMETER_SQUARE = 
		DEFAULT_INTERACTION_DIAMETER * DEFAULT_INTERACTION_DIAMETER;
	public static final float DEFAULT_COLLISION_RADIUS = .3f;
	public static final float DEFAULT_COLLISION_RADIUS_SQUARE = 
		DEFAULT_COLLISION_RADIUS * DEFAULT_COLLISION_RADIUS;
	public static final float DEFAULT_SIZE = .5f;
	public static final float DEFAULT_LIFE = 0;
	public static final float DEFAULT_MASS = 1;
	public static final Vector3f DEFAULT_POSITION = new Vector3f();
}

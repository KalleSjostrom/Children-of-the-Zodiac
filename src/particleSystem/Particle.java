/*
 * Classname: AbstractParticle.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package particleSystem;

import graphics.Graphics;
import settings.AnimSettings;
import bodies.PointBody;
import bodies.Vector3f;

/**
 * This class contains some common methods for a particle.
 * 
 * @author		Kalle Sjöström
 * @version 	0.7.0 - 01 Oct 2008
 */
public class Particle extends PointBody {

	private float life;
	private float fade;
	private float[] rgb;
	private float fadeDistMult;
	private float fadeDistPower;
	private float fadeRandomAdd;
	private float fadeRandomMult;
	private float destroyForceVectorAmplifier;
	private float destroyFadeRandomAdd;
	private float destroyFadeRandomMult;
	private float velocityRandMult;
	private float velocityRandAdd;
	private float lifeMultiplier;
	private boolean systemDead;
	private boolean setVelocityOnParticles;
	private Vector3f source;
	private Vector3f positionNoise;
	private int counter;

	protected float size;
	private float targetPointGravityMult;
	private Vector3f color;
	private Vector3f collisionVector;
	private Vector3f targetPoint;
	private boolean targetPointGravityKillOnArrive;

	/**
	 * Creates a new particle with the given color and gravity.
	 * 
	 * @param color the color of the particle.
	 * @param body 
	 */
	public Particle(float[] color, AnimSettings settings, PointBody body) {
		setSettings(settings);
		rgb = color;
		life = 1;
		fade = getFade();
	}

	private void setSettings(AnimSettings settings) {
	 	setMass((float) (settings.getValue(AnimSettings.PARTICLE_MASS) + 
	 			Math.random() * settings.getValue(AnimSettings.MASS_RANDOM_MULT)));
	 	size = (float) (settings.getValue(AnimSettings.SIZE) + 
	 			Math.random() * settings.getValue(AnimSettings.SIZE_RANDOM_MULT));
	 	
		lifeMultiplier = settings.getValue(AnimSettings.LIFE_MULTIPLIER);
		positionNoise = settings.getVector(AnimSettings.POSITION_NOISE);
		velocityRandAdd = settings.getValue(AnimSettings.VELOCITY_RANDOM_ADD);
		velocityRandMult = settings.getValue(AnimSettings.VELOCITY_RANDOM_MULT);
		setVelocityOnParticles = settings.getBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES);
		fadeDistPower = settings.getValue(AnimSettings.FADE_INCREASE_DISTANCE_POWER);
		fadeDistMult = settings.getValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER);
		source = settings.getVector(AnimSettings.SOURCE);
		
		fadeRandomMult = settings.getValue(AnimSettings.FADE_RANDOM_MULT);
		fadeRandomAdd = settings.getValue(AnimSettings.FADE_RANDOM_ADD);

//		destroyForceVectorBias = settings.getVector(AnimSettings.DESTROY_FORCE_VECTOR_BIAS);
		destroyForceVectorAmplifier = settings.getValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER);
		destroyFadeRandomMult = settings.getValue(AnimSettings.DESTROY_FADE_RANDOM_MULT);
		destroyFadeRandomAdd = settings.getValue(AnimSettings.DESTROY_FADE_RANDOM_ADD);
		targetPoint = settings.getVector(AnimSettings.DESTROY_GRAVITY_TARGET_POINT);
		targetPointGravityMult = settings.getValue(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_MULT);
		targetPointGravityKillOnArrive = settings.getBoolean(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_KILL_ON_ARRIVE);
		
		collisionVector = settings.getVector(AnimSettings.COLLISION_VECTOR);
	}

	private Vector3f applyRand(Vector3f pos, Vector3f rand) {
		pos.x += (Math.random()-.5) * rand.x;
		pos.y += (Math.random()-.5) * rand.y;
		pos.z += (Math.random()-.5f) * rand.z;
		return pos;
	}

	protected float getFade() {
		return (float) Math.random() * fadeRandomMult + fadeRandomAdd;
	}

	/**
	 * This method draws the particle on the given GL.
	 * 
	 * @param g the GL to draw on.
	 * @param additiveColoring 
	 */
	protected void drawParticle(Graphics g, boolean additiveColoring) {
		Vector3f position = getPosition();
		if (color != null) {
			g.setColor(color.x, color.y, color.z, life * lifeMultiplier);
		} else {
			g.setColor(rgb[0], rgb[1], rgb[2], life * lifeMultiplier);
		}
		g.drawCenteredCurrent2D(position, size);
	}
	
	public void setLifeMultiplier(float lm) {
		lifeMultiplier = lm;
	}

	/**
	 * Moves the particle in the particles direction and pulls it towards
	 * the gravity vector. It also decreases the life (alpha value) of the
	 * particle and resurrects it if needed. The given system position is
	 * needed when resurrecting the particle and creating a new position
	 * for the particle.
	 * 
	 * @param sysPos the position of the system.
	 */
	public void update(float elapsedTime, PointBody body) { // in seconds
		Vector3f p = getPosition();
		Vector3f temp = null;
		if (targetPoint != null) {
			temp = new Vector3f(
					targetPoint.x - p.x,
					targetPoint.y - p.y, targetPoint.z - p.z);
			
			Vector3f grav = temp.multLocal(targetPointGravityMult);
			setForce(grav);
		}
		super.update(elapsedTime);
		life -= increaseFade(getPosition().distanceSquared(body.getPosition()));
		p = getPosition();
		if (targetPoint != null) {
			Vector3f temp2 = new Vector3f(
					targetPoint.x,
					targetPoint.y, 0);
			temp = new Vector3f(
					p.x,
					p.y, 0);
			if (targetPointGravityKillOnArrive) {
				float ls = temp2.lengthSquared();
				float pls = temp.lengthSquared();
				if (pls > ls) {
					life = 0;
				}
			} else if (p.y < 0) {
				p = ParticleSystem.getRandomSphereVector(.05f);
				p.z -= 2;
				setPosition(p);
				targetPoint = null;
				setForce(new Vector3f());
				setVelocity(new Vector3f());
				life = 1f;
			}
		}
		
		if (collisionVector != null) {
			Vector3f v = getVelocity();
			if (p.x <= collisionVector.x && v.x < 0) {
				v.x *= -.8f;
			} else if (p.x >= collisionVector.y && v.x > 0) {
				v.x *= -.8f;
			}
			if (p.y <= collisionVector.z && v.y < 0) {
				v.y *= -.8f;
			}
		}
	}

	protected float increaseFade(float dist) {
		if (!systemDead) {
			fade += Math.pow(dist, fadeDistPower) * fadeDistMult;
		}
		return fade;
	}
	
	public void resurrect(PointBody body, Vector3f pos) {
		resurrect(body, pos, 1);
	}

	public void resurrect(PointBody body, Vector3f pos, int startLife) {
		life = startLife;
		fade = getFade();
		Vector3f p;
		if (pos == null) {
			p = body.getPosition().clone();
			setPosition(applyRand(p, positionNoise));
		} else {
			setPosition(pos);
		}
		if (body != null) {
			setForce(body.getForce().clone());
		}
		setVelocity(new Vector3f(0, 0, 0));
		if (setVelocityOnParticles) {
			float velRand = ((float) Math.random()) * velocityRandMult + velocityRandAdd;
			setVelocity(body.getVelocity().clone().multLocal(velRand));
		}
	}

	/**
	 * Checks if the particle is alive.
	 * 
	 * @return true if the particle is alive.
	 */
	public boolean isAlive() {
		return life > 0;
	}

	/**
	 * This method kills the particle forever. It tells the particle that
	 * the system is dead and that the resurrection should stop. 
	 */
	public void kill() {
		systemDead = true;
	}

	/**
	 * This method is called when the particle system is destroyed. It can
	 * be used to make the last particles fly like sparks all over the place
	 * to illustrate an explosion.
	 * 
	 * @param particleSystem the position of the system.
	 */
	public void destroy(PointBody body) {
		Vector3f f = ParticleSystem.getRandomSphereVector(1);
		f.multLocal((float) ((Math.random()+.1f)*destroyForceVectorAmplifier));
		setForce(f);
		fade = (float) Math.random() * destroyFadeRandomMult + destroyFadeRandomAdd;
		systemDead = true;
	}

	public void plainDestroy(ParticleSystem particleSystem) {
		fade = (float) Math.random() * destroyFadeRandomMult + destroyFadeRandomAdd;
	}

	public boolean isDestroyed() {
		float dist = getPosition().distanceSquared(source);
		boolean destroyed = dist < .01f && !systemDead;
		if (destroyed) {
			counter++;
			setForce(new Vector3f(0, 0, 0));
			setVelocity(new Vector3f(0, 0, 0));
		}
		// TODO: Counter only for flare.
		return counter > 8 && !systemDead;
	}

	public void addLife(float f) {
		life += f;
	}

	public float getLife() {
		return life;
	}

	public void setLife(float f) {
		life = f;
	}

	public void setColor(Vector3f c, float a) {
		color = c;
		life = a;
	}
}

/*
 * Classname: AbstractParticleSystem.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package particleSystem;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.Stack;

import com.jogamp.opengl.GL2;

import labyrinth.Camera;
import particleSystem.drawable.SystemDrawable;
import particleSystem.emitter.DemolishEmitter;
import particleSystem.emitter.Emitter;
import particleSystem.emitter.Flame2Emitter;
import particleSystem.emitter.FlareEmitter;
import particleSystem.emitter.InterpolatingEmitter;
import particleSystem.emitter.LineEmitter;
import particleSystem.emitter.ShatterEmitter;
import particleSystem.equations.VectorEquation;
import settings.AnimSettings;
import battle.enemy.BattleEnemy;
import bodies.PointBody;
import bodies.Vector3f;

import com.jogamp.opengl.util.texture.Texture;

/**
 * This class contains some common methods for a particle system.
 * A particle system is used to illustrate fire or smoke or
 * something like that.
 * 
 * @author		Kalle Sjöström
 * @version 	0.7.0 - 01 Oct 2008
 */
public class ParticleSystem extends PointBody {

	protected static boolean hasInited = false;
	public static final String[] particleTexture = new String[]{
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "particle.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "yellowjitter.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "stars2.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "stars3.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "stars4.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "stars5.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "stars245.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "stars345.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "stars445.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "round.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "smallRound.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "sten.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "smoke_particle.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "death0.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "death1.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "death2.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "pixel.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "roundWhite.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "roundWhiteSharp.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "roundInverted.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "clock.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "clockHour.png"),
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "clockMinute.png"),
	};

	public static void load() {}
	public static final int ROUND = 0;
	public static final int SHARP = 1;
	public static final int JITTER_1 = 2;
	public static final int JITTER_2 = 3;
	public static final int JITTER_3 = 4;
	public static final int JITTER_4 = 5;
	public static final int JITTER_2_45 = 6;
	public static final int JITTER_3_45 = 7;
	public static final int JITTER_4_45 = 8;
	public static final int JONAS_ROUND = 9;
	public static final int JONAS_ROUND_2 = 10;
	public static final int STONE = 11;
	public static final int SMOKE = 12;
	public static final int DEATH_0 = 13;
	public static final int DEATH_1 = 14;
	public static final int DEATH_2 = 15;
	public static final int PIXEL = 16;
	public static final int ROUND_WHITE = 17;
	public static final int ROUND_WHITE_SHARP = 18;
	public static final int ROUND_INVERTED = 19;
	public static final int CLOCK = 20;
	public static final int CLOCK_HOUR = 21;
	public static final int CLOCK_MINUTE = 22;
	
	public static final int POS_X_GREATER_TARGET_X = 0;
	public static final int CHECK_DISTANCE = 1;
	public static final int POS_Z_LESS_TARGET_Z = 2;
	public static final int PARTICLES_DESTROYED = 3;
	public static final int POS_Y_GREATER_TARGET_Y = 4;
	public static final int POS_Z_GREATER_TARGET_Z = 5;
	public static final int POS_Y_LESS_TARGET_Y = 6;
	
	public static final int DEMOLISH_EMITTER_TYPE = 0;
	public static final int INTERPOLATING_EMITTER_TYPE = 1;
	public static final int DEFAULT_EMITTER_TYPE = 2;
	public static final int FLARE_EMITTER_TYPE = 3;
	public static final int SHATTER_EMITTER_TYPE = 4;
	public static final int TEST_EMITTER_TYPE = 5;
	public static final int LINE_EMITTER_TYPE = 6;
	public static final int FLAME_EMITTER_TYPE = 7;
	
	public static final int IS_DESTROYED = 0;
	public static final int IS_DEAD = 1;
	public static final int IS_DELAYED = 2;
	public static final int WAITING = 3;
	
	public static final int BLEND_MODE_NO_BLEND = -1;

	protected static Texture[] tex;

	protected Stack<Particle> particlePool = new Stack<Particle>();
	protected ArrayList<Particle> particles;
	protected float speed;
	protected int particlesLeft;
	protected int color;
	protected int targetIndex;
	private int nrParticles;
	private int[] textures;
	protected boolean destroyed = false;
	private Vector3f source;
	private Vector3f target;
	private Vector3f gravity;
	private Vector3f targetPoint;
	private int isDeadLimit;
	private SystemDrawable drawable;

	private float emitPeriod;
	private Vector3f destroyFadeGravity;
	protected boolean additiveColoring;
	private int destroyMode;
	private InterpolationInfo info;
	private BattleEnemy enemy;
	protected Emitter emitter;
	protected int particlesDestroyed;
	private int checkDestroyMode;
	private boolean destroyCameraShake;
	private boolean destroyEnemyShake;
	private boolean destroyEnemySlice;
	protected AnimSettings settings;
	private int readyMode;
	private boolean readyModeDone;
	private int readModeDelayTime;
	protected int blendMode;

	/**
	 * Creates a new system that contains of nrOfParticles amount of
	 * particles with the given color. This will set up the movement
	 * vector of the system, the vector that the origin of the system
	 * will follow.
	 * 
	 * @param nrOfParticles the number of particles of the system
	 * @param color the color of the particles.
	 */
	public ParticleSystem(AnimSettings settings, BattleEnemy enemy) {
		setSettings(settings);
		this.enemy = enemy;
		create(nrParticles, settings);
	}

	public ParticleSystem(AnimSettings settings) {
		setSettings(settings);
		create(nrParticles, settings);
	}

	private void setSettings(AnimSettings settings) {
		this.settings = (AnimSettings) settings.clone();
		setMass(settings.getValue(AnimSettings.SYSTEM_MASS));
		gravity = settings.getVector(AnimSettings.GRAVITY);
		emitPeriod = settings.getValue(AnimSettings.EMITTANCE_PERIOD);
		speed = settings.getValue(AnimSettings.SPEED);
		color = (int) settings.getValue(AnimSettings.COLOR);
		nrParticles = (int) settings.getValue(AnimSettings.NR_PARTICLES);
		isDeadLimit = (int) settings.getValue(AnimSettings.IS_DEAD_LIMIT);
		destroyMode = (int) settings.getValue(AnimSettings.DESTROY_MODE);
		additiveColoring = settings.getBoolean(AnimSettings.ADDITIVE_COLORING);
		blendMode = (int) settings.getValue(AnimSettings.BLEND_MODE);
		checkDestroyMode = (int) settings.getValue(AnimSettings.CHECK_DESTROY_MODE);
		readyMode = (int) settings.getValue(AnimSettings.READY_MODE);
		readModeDelayTime = (int) settings.getValue(AnimSettings.READY_MODE_DELAY_TIME);
		
		destroyCameraShake = settings.getBoolean(AnimSettings.DESTROY_CAMERA_SHAKE);
		destroyEnemyShake = settings.getBoolean(AnimSettings.DESTROY_ENEMY_SHAKE);
		destroyEnemySlice = settings.getBoolean(AnimSettings.DESTROY_ENEMY_SLICE);

		source = settings.getVector(AnimSettings.SOURCE);
		target = settings.getVector(AnimSettings.TARGET).clone();
		destroyFadeGravity = settings.getVector(AnimSettings.DESTROY_FADE_GRAVITY);
		targetPoint = settings.getVector(AnimSettings.DESTROY_GRAVITY_TARGET_POINT);

		int nrTexs = (int) settings.getValue(AnimSettings.NR_TEXTURES);
		textures = new int[nrTexs];
		for (int i = 0; i < nrTexs; i++) {
			textures[i] = (int) settings.getValue(AnimSettings.NR_TEXTURES + (i + 1));
		}
	}

	/**
	 * This method creates the system that contains of nrOfParticles 
	 * amount of particles with the given color. This will set up the 
	 * movement vector of the system, the vector that the origin of the 
	 * system will follow. This method is used by the constructors.
	 * 
	 * @param nrOfParticles the number of particles of the system
	 * @param color the color of the particles.
	 */
	protected void create(int nrOfParticles, AnimSettings settings) {		
		setPosition(source.clone());

		info = calcInterpolationInfo(settings);
		Vector3f sourceToTarget = target.subtract(source);
		Vector3f direction = sourceToTarget.normalize();
		direction.multLocal(speed);
		setVelocity(direction);

		particles = new ArrayList<Particle>();
		if (emitPeriod == 0) {
			for (int i = 0; i < nrOfParticles; i++) {
				Particle p = createParticle();
				p.resurrect(this, null);
				particles.add(p);
			}
		}
		int emitterType = (int) settings.getValue(AnimSettings.EMITTER_TYPE);
		switch (emitterType) {
		case DEMOLISH_EMITTER_TYPE:
			emitter = new DemolishEmitter(particlePool, particles, info, emitPeriod, nrOfParticles);
			break;
		case INTERPOLATING_EMITTER_TYPE:
			emitter = new InterpolatingEmitter(particlePool, particles, info, emitPeriod, nrOfParticles);
			break;
		case DEFAULT_EMITTER_TYPE:
			emitter = new Emitter(particlePool, particles, info, emitPeriod, nrOfParticles);
			break;
		case FLARE_EMITTER_TYPE:
			emitter = new FlareEmitter(particlePool, particles, info, emitPeriod, nrOfParticles);
			break;
		case SHATTER_EMITTER_TYPE:
			emitter = new ShatterEmitter(particlePool, particles, info, emitPeriod, nrOfParticles);
			break;
		case TEST_EMITTER_TYPE:
			emitter = new Emitter(particlePool, particles, info, emitPeriod, nrOfParticles);
			break;
		case LINE_EMITTER_TYPE:
			emitter = new LineEmitter(particlePool, particles, info, emitPeriod, nrOfParticles);
			break;
		case FLAME_EMITTER_TYPE:
			emitter = new Flame2Emitter(particlePool, particles, info, emitPeriod, nrOfParticles);
			break;
		default:
			break;
		}
		
		
	}
	
	@Override
	public void update(float elapsedTime) {
		super.update(elapsedTime);
		particlesLeft = particlesDestroyed = 0;
		emitter.update(this, elapsedTime);
		Iterator<Particle> it = particles.iterator();
		while (it.hasNext()) {
			Particle p = it.next();
			if (gravity != null) {
				Vector3f f = new Vector3f(gravity);
				f.x = (float) (f.x * (Math.random() - .5f));
				p.addForce(f);
			} else {
				p.addForce(gravity);
			}
			p.update(elapsedTime, this);
			if (!p.isAlive()) {
				it.remove();
				particlePool.push(p);
			}
			particlesLeft += p.isAlive() ? 1 : 0;
			if (!destroyed) {
				particlesDestroyed += p.isDestroyed() ? 1 : 0;
			}
		}
		
		if (checkShouldDestroy(getPosition(), target, particlesDestroyed)) {
			if (!destroyed) {
				if (enemy != null) {
					if (destroyCameraShake) {
						Camera.shakeit(1000);
					}
					if (destroyEnemyShake) {
						enemy.shake(1000);
					}
					if (destroyEnemySlice) {
						enemy.slice();
					}
				}
			}
			switch (destroyMode) {
			case ParticleValues.DESTROY_ONCE :
				if (!destroyed) {
					emitter.destroy(enemy);
					it = particles.iterator();
					while (it.hasNext()) {
						Particle p = it.next();
						p.setVelocity(new Vector3f(0, 0, 0));
						p.setForce(new Vector3f(0, 0, 0));
					}
					destroy();
				}
				break;
			case ParticleValues.DESTROY_MULTIPLE_TIMES:
				emitter.destroy(enemy);
				destroy();
				break;
			case ParticleValues.PLAIN_DESTROY:
				plainDestroy();
				break;
			}
		}
	}

	public void plainDestroy() {
		emitter.destroy(enemy);
		destroyed = true;
		gravity = destroyFadeGravity;
		for (Particle p : particles) {
			p.plainDestroy(this);
		}
	}

	private boolean checkShouldDestroy(Vector3f pos, Vector3f target,
			int particlesDestroyed) {
		boolean shouldDestroy = false;
		switch (checkDestroyMode) {
		case POS_Z_LESS_TARGET_Z:
			shouldDestroy = pos.z < target.z;
			break;
		case POS_Z_GREATER_TARGET_Z:
			shouldDestroy = pos.z > target.z;
			break;
		case POS_X_GREATER_TARGET_X:
			shouldDestroy = pos.x > target.x;
			break;
		case POS_Y_GREATER_TARGET_Y:
			shouldDestroy = pos.y > target.y;
			break;
		case POS_Y_LESS_TARGET_Y:
			shouldDestroy = pos.y < target.y;
			break;
		case PARTICLES_DESTROYED:
			shouldDestroy = particlesDestroyed == 400;
			break;
		case CHECK_DISTANCE:
			float dist = getPosition().distanceSquared(target);
			shouldDestroy = dist < .2f;
			break;
		default:
			break;
		}
		return shouldDestroy;
	}

	protected void createPos(
			boolean onAll, 
			boolean onEnemy) {
		// Unimplemented. Override to implement effect.
	}

	public Particle createParticle() {
		return new Particle(getColor(), settings, this);
	}

	/**
	 * This method loads the texture if needed.
	 */
	protected void loadGLTextures() {
		tex = new Texture[particleTexture.length];
		for (int i = 0; i < particleTexture.length; i++) {
			tex[i] = ImageHandler.getTexture(particleTexture[i]).getTexture();
		}
	}
	
	public boolean isDestroyed() {
		return destroyed;
	}
	
	protected Vector3f getGravity() {
		return gravity;
	}

	public boolean isDead() {
		if (readyModeDone) {
			return destroyed ? particlesLeft <= isDeadLimit : false;
		}
		if (readyMode != WAITING) {
			return destroyed ? particlesLeft <= isDeadLimit : false;
		}
		return false;
	}
	
	public boolean isReady() {
		boolean ret = false;
		switch (readyMode) {
		case IS_DESTROYED:
			ret = isDestroyed();
			break;
		case IS_DEAD:
			ret = isDead();
			break;
		case IS_DELAYED:
			readyMode = WAITING;
			readyModeDone = false;
			new Thread() {
				public void run() {
					Values.sleep(readModeDelayTime);
					readyModeDone = true;
				}
			}.start();
			break;
		case WAITING:
			ret = readyModeDone;
			break;
		}
		return ret;
	}

	/**
	 * This method destroys the particle system and can result
	 * in an explosion depending on which system it is.
	 */
	public void destroy() {
		if (targetPoint != null) {
			gravity = targetPoint;
		} else {
			gravity = destroyFadeGravity;
		}
		destroyed = true;
		for (Particle p : particles) {
			p.destroy(this);
		}
	}

	/**
	 * This method abruptly kills the system which should not result 
	 * in an explosion or something like that. It should just disappear.
	 */
	protected void kill() {
		destroyed = true;
		for (Particle p : particles) {
			p.kill();
		}
	}

	/**
	 * This method draws the system on the given GL.
	 * 
	 * @param gl the GL to draw on.
	 */
	public void draw(float dt, Graphics g) {
		if (!hasInited) {
			loadGLTextures();
			hasInited  = true;
		}
		
		if (blendMode != BLEND_MODE_NO_BLEND) {
			g.beginBlend(true);
			g.setBlendFunc(additiveColoring ? GL2.GL_ONE : GL2.GL_ONE_MINUS_SRC_ALPHA);
		}
		
		GL2 gl = Graphics.gl2;
		tex[textures[0]].bind(gl);
		if (drawable != null) {
			drawable.drawGround(
					g, destroyed, getPosition(), particles, particlesLeft);
		}

		int piece = particles.size() / textures.length;
		for (int i = 0; i < textures.length; i++) {
			tex[textures[i]].bind(gl);
			g.beginQuads();
			for (int j = i * piece; j < (i+1)*piece; j++) {
				particles.get(j).drawParticle(g, additiveColoring);
			}
			g.end();
		}
		if (blendMode != BLEND_MODE_NO_BLEND) {
			g.endBlend();
		}
	}
	
	public void start(Graphics g) {
	}
	
	public void end(Graphics g) {
	}

	/**
	 * This method gets the color of the system.
	 * 
	 * @return the color of the system.
	 */
	public float[] getColor() {
		return ParticleValues.getColor(color);
	}

	public void bindTexture(Graphics g, int i) {
		tex[textures[i]].bind(Graphics.gl);
	}

	public static Vector3f getRandomVector(float scalar) {
		return new Vector3f(
				(float) Math.random()-.5f, 
				(float) Math.random()-.5f,
				(float) Math.random()-.5f).multLocal(scalar);
	}

	public static Vector3f getRandomCircleVector(float scalar) {
		double theta = Math.random() * 2 * Math.PI;
		Vector3f v = new Vector3f(
				(float) Math.cos(theta),
				(float) Math.sin(theta),
				0);
		v.multLocal((float) (scalar*Math.random()));
		return v;
	}
	
	public static Vector3f getRandomSphereVector(float scalar) {
		double theta = Math.random() * 2 * Math.PI;
		Vector3f v = new Vector3f(
				(float) Math.cos(theta),
				(float) Math.sin(theta),
				(float) Math.sin(theta));
		v.multLocal((float) (scalar*Math.random()));
		return v;
	}

	public static Vector3f calcSourceToTarget(AnimSettings settings) {
		Vector3f source = settings.getVector(AnimSettings.SOURCE);
		Vector3f sourceToTarget = settings.getVector(AnimSettings.TARGET).subtract(source);
		return sourceToTarget;
	}

	public static float calcTotalTime(AnimSettings settings) {
		Vector3f sourceToTarget = calcSourceToTarget(settings);
		float l = sourceToTarget.length();
		float totalTime = l / settings.getValue(AnimSettings.SPEED);
		return totalTime;
	}

	public static InterpolationInfo calcInterpolationInfo(AnimSettings settings) {
		Vector3f source = settings.getVector(AnimSettings.SOURCE);
		Vector3f sourceToTarget = calcSourceToTarget(settings);
		float totalTime = calcTotalTime(settings);
		VectorEquation ve = settings.getVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION);
		return new InterpolationInfo(ve, source, sourceToTarget, totalTime);
	}

	public static class InterpolationInfo {

		private Vector3f source;
		private Vector3f sourceToTarget;
		private float totalTime;
		private VectorEquation vectorEquation;

		public InterpolationInfo(VectorEquation e, Vector3f source, Vector3f sourceToTarget,
				float totalTime) {
			vectorEquation = e;
			this.source = source;
			this.sourceToTarget = sourceToTarget;
			this.totalTime = totalTime;
		}

		public Vector3f interpolate(Vector3f pos, float time) {
			if (vectorEquation != null) { // Non linerar
				return vectorEquation.getVectorAfterTime(source.add(sourceToTarget.mult(time / totalTime)), time);
				//				pos, time);
			} else { // Use straight line
				return source.add(sourceToTarget.mult(time / totalTime));
			}
		}
		
		public Vector3f useVectorEquationFromSource() {
			return vectorEquation.getVectorAfterTime(null, 0);
		}

		public Vector3f getSource() {
			return source;
		}
	}

	public String getTextureName(int currentImage) {
		return particleTexture[textures[currentImage]];
	}

	public BattleEnemy getEnemy() {
		return enemy;
	}
}

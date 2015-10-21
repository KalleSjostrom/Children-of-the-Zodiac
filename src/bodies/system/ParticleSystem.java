package bodies.system;

import graphics.GameTexture;
import graphics.Graphics;
import graphics.ImageHandler;
import info.Database;
import info.Values;

import java.util.Iterator;

import com.jogamp.opengl.GL2;

import settings.ParticleSettings;
import settings.SystemSettings;
import bodies.Bodies;
import bodies.Body;
import bodies.Vector3f;
import bodies.emitter.AbstractEmitter;
import bodies.emitter.EmitterShape;
import bodies.particles.ParticleFactory;
import bodies.particles.SmokeParticle;

import commands.CommandQueue;
import commands.EmitterUpdateCommand;
import commands.GravityCommand;
import commands.UpdateCommand;
import commands.WindCommand;

public class ParticleSystem extends BodySystem {
	
	private final UpdateCommand UPDATE_COMMAND = new UpdateCommand();
	private final GravityCommand GRAVITY_COMMAND = new GravityCommand();
	private final EmitterUpdateCommand EMITTER_COMMAND = new EmitterUpdateCommand();

	protected AbstractEmitter emitter;
	
	private boolean additiveBlending;
	private boolean inited;
	private boolean active = true;
	private CommandQueue cq = new CommandQueue();
	private GameTexture tex;
	private Vector3f position = new Vector3f();
	private String background;
	private String texture;
	private int warmUp;
	private int backx, backy;
	private int activateStatus = -1;

	private static WindCommand windCommand = new WindCommand();

	protected void setTexture(String tex) {
		texture = 
			ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + tex);
	}
	
	public void setPos(float[] p) {
		pos = p;
		Vector3f emitterPos = emitter.getPosition();
		emitterPos.x = p[Values.X];
		emitterPos.y = -p[Values.Y];
	}
	
	public float[] getPos() {
		return pos;
	}
	
	public Vector3f getPosition() {
		return position;
	}
	
	public float getY() {
		return -(emitter.getPosition().y+56);
	}
	
	long zeroTime;

	public void update(float dt) {
		if (active) {
			enqueue(cq, dt);
			cq.run(getBodies(), dt);

			Bodies b = getBodies();
			Body tempBody;
			Iterator<Body> it = b.iterator();
			while (it.hasNext()) {
				tempBody = it.next();
				if (tempBody.isDead()) {
					emitter.postEmit(tempBody);
				}
			}
		} else if (activateStatus != -1) {
			if (Database.getStatusFor(name) == activateStatus) {
				active = true;
			}
		}
	}

	protected void drawSprite(Graphics g, int x, int y) {
		drawIt(g, x, y);
	}
	
	public void draw(Graphics g, int x, int y) {
		Vector3f pos = getPosition();
		pos.x = x;
		pos.y = -y;
		drawIt(g, x, y);
	}
	
	private void drawIt(Graphics g, int x, int y) {
		/*if (active) {
			if (!inited) {
				init(g);
				inited = true;
			}
			if (background != null) {
				g.drawImage(background, x + backx, y + backy);
			}
			g.beginBlend(false);
			g.setBlendFunc(additiveBlending ? GL2.GL_ONE : GL2.GL_ONE_MINUS_SRC_ALPHA);
			tex.bind(g);
			g.beginQuads();
			Bodies b = getBodies();
			Iterator<Body> it = b.iterator();
			while (it.hasNext()) {
				Body body = it.next();
				if (body.isAlive()) {
					body.draw(g, tex, position);
				}
			}
			g.end();
			g.setBlendFunc(GL2.GL_ONE_MINUS_SRC_ALPHA);
			g.setAlphaFunc(.1f);
			g.setColor(1);
		}*/
	}

	private void init(Graphics g) {
		tex = ImageHandler.getTexture(texture);
	}
	
	protected void enqueue(CommandQueue cq, float elapsedTime) {
		cq.enqueue(UPDATE_COMMAND);
		if (getBodies().iterator().next() instanceof SmokeParticle) {
			cq.enqueue(windCommand);
		}
		// cq.enqueue(DRAG_COMMAND);
		cq.enqueue(GRAVITY_COMMAND);
		cq.enqueue(EMITTER_COMMAND);
	}

	// -- Getters -- //
	protected CommandQueue getCommandQueue() {
		return cq;
	}
	
	// -- Setters -- //
	public void setEmitter(AbstractEmitter emitter) {
		this.emitter = emitter;
	}

	public void setAdditiveBlending(boolean add) {
		additiveBlending = add;
	}
	
	public static void setWind(Vector3f windForce, float turbulence) {
		windCommand.setForce(windForce);
		windCommand.setTurbulence(turbulence);
	}
	
	public ParticleSystem(
			SystemSettings settings, ParticleSettings pSettings, 
			AbstractEmitter emitter, EmitterShape warmer) {
		int particleType = (int) pSettings.getValue(ParticleSettings.KIND);
		int nrParticles = 0;
		if (settings != null) {
			Iterator<Integer> it = settings.iterator();
			while (it.hasNext()) {
				int type = it.next();
				String s;
				switch (type) {
				case SystemSettings.TEXTURE:
					setTexture(settings.getString(type));
					break;
				case SystemSettings.ADDITIVE:
					setAdditiveBlending(settings.getBoolean(type));
					break;
				case SystemSettings.NR_PARTICLES:
					nrParticles = (int) settings.getValue(type);
					break;
				case SystemSettings.WARM_UP_LENGTH:
					warmUp = (int) settings.getValue(type);
					break;
				case SystemSettings.BACKGROUND:
					s = settings.getString(type);
					String[] args = s.split(";");
					background = Values.ParticleSystemsImages + args[0];
					backx = Integer.parseInt(args[1]);
					backy = Integer.parseInt(args[2]);
					break;
				default:
					break;
				}
			}
		}
		this.emitter = emitter;
		
		for (int i = 0; i < nrParticles; i++) {
			Body b = addBody(ParticleFactory.createParticle(particleType, pSettings));
			b.setParent(this);
			if (warmer != null) {
				emitter.emitFrom(b, warmer);
			} else {
				emitter.fillPool(b);
			}
		}
		EMITTER_COMMAND.setEmitter(emitter);
	}

	public int getWarmUp() {
		return warmUp;
	}
	public void setWarmUp(int warm) {
		warmUp = warm;
	}

	public void setActive(boolean activate) {
		active = activate;
	}

	public void setActivateStatus(int status) {
		activateStatus = status;
	}
	
	public AbstractEmitter getEmitter() {
		return emitter;
	}
}

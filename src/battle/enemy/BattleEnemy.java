/*
 * Classname: BattleEnemy.java
 * 
 * Version information: 0.7.0
 *
 * Date: 09/06/2008
 */
package battle.enemy;

import equipment.Slot;
import graphics.Graphics;
import graphics.Object2D;
import graphics.Utils3D;
import info.Values;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.concurrent.ConcurrentLinkedQueue;

import com.jogamp.opengl.GL2;

import labyrinth.Camera;
import particleSystem.ParticleSystemPacket;
import sound.SoundPlayer;
import villages.utils.DialogSequence;
import battle.Battle;
import battle.bosses.Boss;
import battle.bosses.BossDialog;
import battle.character.CharacterRow;
import battle.enemy.AttackInfo.Frame;
import bodies.Vector3f;
import character.Creature;
import character.Enemy;

import com.jogamp.opengl.util.texture.Texture;

/**
 * This class wraps a normal enemy (objects from the Enemy class) into a 3D
 * BattleEnemy. This makes it possible to draw the enemy in 3D space,
 * to animate it and to battle against it.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 09 June 2008
 */
public class BattleEnemy extends Object2D {

	private static float[] color;
	private static float[] source;
	private static float[] usedColor;
	private float test1;
	private float test2;
	private float xs;
	
	protected boolean hitting;
	private String[] images;
	private float[] vector;
	private float totalTime;
	
	private EnemyInfo info;
	
	private boolean killed = false;
	protected int rounds = 0;

	private Attack attack;
	private EnemyCard card;
	private float risey = 0;
	private float shakeoffy = 0;
	private float shakeoffx = 0;
	private int mode;
	private float origHeight;
	private float origWidth;
	private ConcurrentLinkedQueue<ParticleSystemPacket> particleSystem = 
		new ConcurrentLinkedQueue<ParticleSystemPacket>();
//	private ArrayList<ParticleSystemPacket> particleSystem = new ArrayList<ParticleSystemPacket>();
	private Vector3f tempSource;
	private Enemy enemy;
	private boolean slice;
	private boolean useCritImage;
	private static final float XS_ACC = .00003f;
	private float xsSpeed;
	private float life;
	private float sliceFade;
	private Battle battle;
	private boolean shouldHit;
	private ParticleSystemPacket preloadedSystem;

	public static void setColor(float[] c) {
		color = c;
		source = Values.copyArray(color);
		usedColor = Values.copyArray(color);
	}
	
	/**
	 * Wraps the given enemy into a 3D BattleEnemy which can be 
	 * rendered in JOGL.
	 *
	 * @param enemy the enemy to wrap.
	 */
	public BattleEnemy(Enemy enemy) {
		super(enemy.getImages().length + 1);
		if (color == null) {
			setColor(new float[]{1, 1, 1, 1});
		}
		currentList = enemy.getStartFrame();
		System.out.println("Start " + currentList + " " + enemy.getName());
		images = enemy.getImages();
		info = enemy.getInfo();
		this.enemy = enemy;
		
		attack = new Attack();
		card = new EnemyCard();
	}

	/**
	 * Initializes the drawing by compiling GL lists for each animation frame
	 * of the enemy. When this method is called the only method needed to draw
	 * the enemies is the draw() method.
	 * 
	 * @param gl the GL context to initiated the textures on.
	 */
	public void initDraw(Graphics g) {
		for (int i = 0; i < images.length; i++) {
			loadTexture(images[i], i);
		}
		setSize(0, info.get(EnemyInfo.SCALE));
		origWidth = width;
		origHeight = height;
		createCoords();
		attack.initDraw(g);
		card.initDraw(g);
	}
	
	public void update(float elapsedTime) {
		attack.update();
		card.update();
		Iterator<ParticleSystemPacket> it = particleSystem.iterator();
		while (it.hasNext()) {
			ParticleSystemPacket psp = it.next();
			psp.update(elapsedTime / 1000f);
			if (psp.isDead()) {
				it.remove();
			}
		}
	}

	/**
	 * Creates the texture coordinates for the enemy texture.
	 */
	public void createCoords() {
		createCoordList(1);

		float x = info.get(EnemyInfo.X_OFFSET);
		createCoordFor((-width / 2) + x, (width / 2) + x, 0, X);
		float y = info.get(EnemyInfo.HEIGHT);
		createCoordFor(y, y + height, 0, Y);
		createCoordFor(0, 0, 0, Z);
	}
	
	public void slice() {
		xs = 0;
		xsSpeed = 0;
		slice = true;
		life = 2.5f;
		float nrFadeSteps = 1500f / Values.LOGIC_INTERVAL;
		sliceFade = 3 / nrFadeSteps;
		new Thread() {
			public void run() {
				Values.sleep(1500);
				slice = false;
			}
		}.start();
	}
	
	public void drawTopLayer(Graphics g) {
		if (useCritImage && !isVisible()) {
			g.fadeOldSchoolColorWhite(.8f, 0, 0, .5f);
		}
	}

	/**
	 * Draws the enemy on the given GL. This method translates the current
	 * matrix to (0, 0, BattleValues.ENEMY_DEPTH).
	 * 
	 * @param g the Graphics object to draw on.
	 */
	public void draw(Graphics g) {
		if (!killed) {
			g.loadIdentity();
			g.translate(shakeoffx, shakeoffy + risey, info.get(EnemyInfo.DEPTH));
			// -0.14884003
			g.setColor3(usedColor);
			if (isVisible()) {
				if (slice) {
					life -= sliceFade;
					drawSlice(g, currentList, 0);
				} else {
					draw(g, currentList, 0);
				}
			}
			
			g.loadIdentity();
			Iterator<ParticleSystemPacket> it = particleSystem.iterator();
			while (it.hasNext()) {
				ParticleSystemPacket psp = it.next();
				psp.draw(g);
			}
			g.setColor(1);
			g.setAlphaTestEnabled(true);
			g.setAlphaFunc(.1f);
			attack.draw(g);
			g.setAlphaFunc(0);
			card.draw(g);
		}
		g.setColor(1);
	}
	
	private void drawSlice(Graphics g, int texIndex, int coordIndex) {
		if (texture[texIndex] != null) {
			float[][] cl = coordList[coordIndex];
			drawSlice(g, texture[texIndex].getTexture(), cl[0], cl[1], cl[2]);
		}
	}
	
	private void drawSlice(
			Graphics g, Texture texture, float[] x, float[] y, float[] z) {
		GL2 gl = g.getGL();
		xsSpeed += XS_ACC * Values.INTERVAL;
		xs -= xsSpeed;
		float ys = xs*.3f;
		
		float y1 = info.get(EnemyInfo.HEIGHT);
		float y0 = y1 + height;
		float ym = info.get(EnemyInfo.MIDDLE_POINT);
		float p = (y0 - ym) / (y0 - y1);
		
		test1 = p + .1f;
		test2 = p - .1f;
		// .9 o .7
		float test1c = 1 - test1;
		float test2c = 1 - test2;
		
		float testy1 = y[0] + (y[1] - y[0]) * test1c;
		float testy2 = y[0] + (y[1] - y[0]) * test2c;
		g.setColor4(usedColor, life);
		g.push();
		texture.bind(gl);
		g.beginQuads();
		gl.glTexCoord2f(0, test1); gl.glVertex3f(x[0]+xs, testy1 + ys, z[0]);
		gl.glTexCoord2f(1, test2); gl.glVertex3f(x[1]+xs, testy2 + ys, z[0]);
		gl.glTexCoord2f(1, 0); gl.glVertex3f(x[1]+xs, y[1] + ys, z[1]);
		gl.glTexCoord2f(0, 0); gl.glVertex3f(x[0]+xs, y[1] + ys, z[1]);
		g.end();
		g.pop();
		
		testy1 = y[0] + (y[1] - y[0]) * test1c;
		testy2 = y[0] + (y[1] - y[0]) * test2c;
		
		texture.bind(gl);
		g.beginQuads();
		gl.glTexCoord2f(0, 1); gl.glVertex3f(x[0], y[0], z[0]);
		gl.glTexCoord2f(1, 1); gl.glVertex3f(x[1], y[0], z[0]);
		gl.glTexCoord2f(1, test2); gl.glVertex3f(x[1], testy2, z[1]);
		gl.glTexCoord2f(0, test1); gl.glVertex3f(x[0], testy1, z[1]); 
		g.end();
	}

	public void setScale() {
		width *= .95f;
		height *= .95f;
		createCoords();
	}

	/**
	 * Checks if this enemy is being animated, if it attacks.
	 * 
	 * @return true if the enemy is attacking.
	 */
	public boolean isHitting() {
		return hitting;
	}

	/**
	 * This method causes the enemy to starts it animation.
	 * It starts a separate thread that updates the current draw list.
	 * Thread safe?
	 * @param attackName2 
	 */
	public void hit(final AttackInfo i, final int target) {
		if (i == AttackInfo.NOP) {
			return;
		}
		if (i.getType() == Slot.NO_TYPE) {
			new Thread() {
				public void run() {
					attack(i, target);
				}
			}.start();
		} else {
			attack.setAttackName(i.getName());
			card.setImage(i.getType(), i.getElement());
		}
		if (!hitting) {
			hitting = true;
			new Thread() {
				public void run() {
					card.show();
					attack.show();
					switch(i.getType()) {
					case Slot.SUPPORT :
						attack(i, target);
						break;
					case Slot.MAGIC :
						attack(i, target);
						break;
					case Slot.ATTACK :
						attack(i, target);
						break;
					}
					card.hide();
					attack.hide();
				}
			}.start();
		}
	}
	
	private void attack(AttackInfo info, int target) {
		ArrayList<Frame> frames = info.getFrames();
		int def = 0;
		boolean hasHit = false;
		for (int i = 0; i < frames.size(); i++) {
			Frame frame = frames.get(i);
			currentList = frame.getFrame();
			float sleepTime = frame.getAnimTime();
			long t1 = System.currentTimeMillis();
			if (frame.isDefault()) {
				def = frame.getFrame();
			}
			if (frame.playSoundEffect()) {
				String s = frame.getSoundEffect();
				SoundPlayer.playSound(Values.BattleSoundEffects + s + ".wav");
			}
			if (frame.shouldSwitchMusic()) {
				String s = frame.getMusic();
				battle.changeMusic(s, frame.getAnimTime());
			}
			System.out.println(frame.characterMode());
			if (frame.characterMode() > 0) {
				switch (frame.characterMode()) {
				case 1:
					battle.testShowCharacters();
					break;
				case 2:
					battle.testHideCharacters();
					break;
				}
			}
			if (frame.shouldClearSystems()) {
				particleSystem.clear();
			}
			if (frame.hasCard() && frame.shouldPreload()) {
				preloadedSystem = frame.getCardSystem(this, target);
			} else if (frame.hasCard()) {
				if (preloadedSystem == null) {
					particleSystem.add(frame.getCardSystem(this, target));
				} else {
					particleSystem.add(preloadedSystem);
					preloadedSystem = null;
				}
				frame.getCard().playSound();
			}
			if (frame.shouldRise()) {
				rise(frame.getAnimTime(), frame.getRiseSpeed());
			}
			if (!hasHit && frame.shouldHit()) {
				shouldHit = true;
				hasHit = true;
			}
			if (frame.shouldExit()) {
				exit();
			}
			boolean f = frame.shouldShake() || frame.shouldCameraShake();
			if (f) {
				if (frame.shouldShake()) {
					shake(frame.getAnimTime());
				}
				if (frame.shouldCameraShake()) {
					Camera.shakeit(frame.getAnimTime());
				}
			}
			long t2 = System.currentTimeMillis();
			sleepTime -= (t2 - t1);
			System.out.println("Sleeptime " + sleepTime);
			if (sleepTime > 0) {
				Values.sleep((int) sleepTime);
			}
		}
		if (!hasHit) {
			shouldHit = true;
		}
		currentList = def;
		hitting = false;
	}

	private void exit() {
		battle.exitToNext();
	}

	public void setTempSource(Vector3f source) {
		tempSource = source;
	}
	public Vector3f getTempSource() {
		return tempSource;
	}

	// milliseconds
	private void shakeit(int time) {
		int max = time / 50;
		for (int j = 0; j < max; j++) {
			Values.sleep(50);
			float m = .05f; // .1f
//			int mode = Values.rand.nextInt(6);
			mode++;
			mode %= 3;
			switch (mode) {
			case 0 : shakeoffx = m; break;
			case 1 : shakeoffx = 0; break;
			case 2 : shakeoffx = -m; break;
			case 3 : shakeoffy = m; break;
			case 4 : shakeoffy = 0; break;
			case 5 : shakeoffy = -m; break;
			}
		}
		shakeoffx = 0;
		shakeoffy = 0;
	}
	
	public void shake(final int time) {
		new Thread() {
			public void run() {
				shakeit(time);
			}
		}.start();
	}
	
	private void rise(final int time, final float speed) {
		new Thread() {
			public void run() {
				float riseSpeed = 0;
				int totalTime = 0;
				while (totalTime < time / 2f) {
					riseSpeed += speed;
					risey += riseSpeed;
					totalTime += (int) Values.LOGIC_INTERVAL;
					Values.sleep((int) Values.LOGIC_INTERVAL);
				}
				while (totalTime < time) {
					riseSpeed -= speed;
					risey += riseSpeed;
					totalTime += (int) Values.LOGIC_INTERVAL;
					Values.sleep((int) Values.LOGIC_INTERVAL);
				}
			}
		}.start();
	}

	/**
	 * This method changes the color of the enemy to the new color.
	 * The enemy then tries to recover by restoring the old color.
	 * This recovery is actually a movement on a vector that is created
	 * between the old color and the new color. If these colors are viewed as
	 * points in 3D space, it is easy to create this vector between 
	 * "the points" and the movement also becomes very easy. 
	 * 
	 * @param newColor the color to change to.
	 */
	public void changeColor(float[] newColor) {
		if (newColor == null) {
			return;
		}
		totalTime = 0;
		source = newColor;
		usedColor = Values.copyArray(source);
		vector = Utils3D.createVector(newColor, color);
		width = origWidth;
		height = origHeight;
		createCoords();
		new Thread() {
			public void run() {
				while (Utils3D.calcDistance(usedColor, color, 1) > .01f) {
					totalTime += .02f;
					for (int i = 0; i < 3; i++) {
						usedColor[i] = source[i] + vector[i] * totalTime;
					}
					Values.sleep(30);
				}
				usedColor = Values.copyArray(color);
			}
		}.start();
	}
	
	public void cancelColorChange() {
		usedColor = Values.copyArray(color);
	}

	public void setColor(Vector3f color) {
		usedColor[0] = color.x;
		usedColor[1] = color.y;
		usedColor[2] = color.z;
	}

	/**
	 * This method determines if this enemy should hit. This method will
	 * always return true, but can be overridden to implement another 
	 * behavior.
	 * 
	 * @return true if the enemy should hit.
	 */
	public boolean shouldHit() {
		return shouldHit;
	}
	
	public void resetHit() {
		shouldHit = false;
	}

	/**
	 * Sets the amount of game updates to hide hits enemy.
	 * 
	 * @param time the amount of game updates to hide this enemy.
	 */
	public void setHideTimer(int time, boolean useCritImage) {
		hide(time);
		this.useCritImage = useCritImage;
	}

	/**
	 * Kills this enemy. This will simply cause the enemy to not be drawn.
	 */
	public void kill() {
		killed = true;
	}

	public EnemyInfo getInfo() {
		return info;
	}
	
	public DialogSequence next() {
		return null;
	}

	public boolean wouldLikeToTalk() {
		if (this instanceof Boss) {
			return ((Boss) this).wantsToTalk(rounds);
		}
		return false;
	}

	public void increment() {
		rounds++;
	}

	public boolean shouldHitAfterTalk() {
		return rounds > BossDialog.BEGINNING;
	}

	public void setDialog(int dialog) {
		rounds = dialog;
	}

	public int getDialogIndex() {
		return rounds;
	}

	public String getNextPlace() {
		return enemy.getNextPlace();
	}

	public void oneTurn() {}

	public int getTarget(ArrayList<Creature> characters, AttackInfo i) {
		int t = i.getTarget();
		if (t == CharacterRow.RANDOM) {
			t = EnemyLogic.calcTarget(characters);
		}
		return t;
	}

	public String getCurrentImageName() {
		return images[currentList];
	}

	public Enemy getEnemy() {
		return enemy;
	}

	public float[] getSourceColor() {
		return Values.copyArray(color);
	}

	public float getTempHeight() {
		return risey;
	}

	public void setBattle(Battle battle) {
		this.battle = battle;
	}
}

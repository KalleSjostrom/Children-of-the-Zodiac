/*
 * Classname: AbstractSprite.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package sprite;

import graphics.GameTexture;
import graphics.Graphics;
import graphics.ImageHandler;
import graphics.SpriteRenderer.SpriteInfo;
import info.Values;
import sun.reflect.generics.reflectiveObjects.NotImplementedException;

/**
 * This abstract class represents an animated object. This includes 
 * players, party members, villagers and so on.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 13 May 2008
 */
public abstract class Sprite {

	public static final int STANDARD_WIDTH = 36;
	public static final int STANDARD_HEIGHT = 56;
	private static final String[] EMOTIONS;
	static{
		EMOTIONS = new String[]{
		Values.Emotions + "exclamation.png", Values.Emotions + "question.png", Values.Emotions + "questionEx.png",
		Values.Emotions + "dot.png", Values.Emotions + "aye.png", Values.Emotions + "no.png",
		Values.Emotions + "zzz.png", Values.Emotions + "hihi.png", Values.Emotions + "ha1.png", 
		Values.Emotions + "ha2.png"};
		for (int i = 0; i < EMOTIONS.length; i++) {
			ImageHandler.addPermanentlyLoadNow(EMOTIONS[i]);
		}
	}

	public int direction;
	public int width = STANDARD_WIDTH;
	public int height = STANDARD_HEIGHT;
	public float[] pos = new float[2];
	public String name;
	public boolean moving;
	
	protected String animImage;
	protected int drawX;
	protected int drawY;
	protected float speed;
	private int currentX = 1;
	private int currentEmotion = -1;

	private boolean shakeEmotion;
	private float counter = 0;
	private float emotionSpeed = .8f;
	private int emotionX;
	private int emotionY;

	private boolean paused = true;
	private float animationTime = 0.0f;
	private int currentFrame = 0;
	private SpriteInfo spriteInfo;
	
	public void loadImage(String string, String name, int size) {
		throw new NotImplementedException();
	}
	public void loadImage(String path, String name) {
		animImage = ImageHandler.addToCurrentLoadNow(path + name + ".png");
		createSpriteInfo();
	}
	public void loadPermImages(String path, String name) {
		animImage = ImageHandler.addPermanentlyLoadNow(path + name + ".png");
		createSpriteInfo();
	}
	
	public void createSpriteInfo() {
		spriteInfo = new SpriteInfo();
		spriteInfo.height = height;
		spriteInfo.width = width;
		spriteInfo.horizontal_parts = 4;
		spriteInfo.vertical_parts = 4;
	}

	public void update(float dt) {
		if (paused)
			return;

		animationTime += dt;
		if (animationTime > 0.15f) {
			animationTime -= 0.15f;
			currentFrame = (currentFrame+1)%4;
		}
	}

	protected boolean inRange(float[] checkPos, int maxDistance) {
		float distSq = checkPos[Values.X] * pos[Values.X] + checkPos[Values.Y] * pos[Values.Y];
		return distSq < (maxDistance*maxDistance);
	}
	protected boolean checkCollision(float[] checkPos, int maxDistance, int direction) {
		boolean collided = false;
		if (inRange(checkPos, maxDistance)) {
			if (direction == Values.UP) {
				collided = checkPos[Values.Y] < pos[Values.Y];
			} else if (direction == Values.RIGHT) {
				collided = checkPos[Values.X] > pos[Values.X];
			} else if (direction == Values.DOWN) {
				collided = checkPos[Values.Y] > pos[Values.Y];
			} else if (direction == Values.LEFT) {
				collided = checkPos[Values.X] < pos[Values.X];
			}
		}
		return collided;
	}

	public boolean isVisible() {
		int compareX = drawX + width;
		int compareY = drawY + height;
		return 	compareX > 0 || drawX < Values.RESOLUTIONS[Values.X] || 
		compareY > 0 || drawY < Values.RESOLUTIONS[Values.Y];
	}
	
	public void stop() { stop(direction); }
	public void stop(int dir) {
		if (moving || direction != dir) {
			direction = dir;
			currentFrame = 0;
			moving = false;
			paused = true;
		}
	}

	public void move() { move(direction); }
	public void move(int dir) {
		if (!moving || direction != dir) {
			direction = dir;
			currentFrame = 0;
			moving = true;
			paused = false;
		}
	}
	public void setEmotion(boolean show, int emotion, boolean shake) {
		currentEmotion = show ? emotion : -1;
		currentX = 1;
		shakeEmotion = shake;
	}
	
	// DRAW SPRITE //
	public void draw(float dt, Graphics g) {
		drawSprite(g, drawX, drawY);
	}
	public void draw(float dt, Graphics g, int x, int y) {
		drawSprite(g, x, y);
	}

	private int[] DIRECTION_TO_FRAME = new int[]{ 12, 8, 0, 4 };
	protected void drawSprite(Graphics g, int x, int y) {
		GameTexture tex = ImageHandler.getTexture(animImage);
		tex.bind(g);
		int frame = DIRECTION_TO_FRAME[direction] + currentFrame;
		g.spriteRenderer.drawSprite(Graphics.gl, spriteInfo, frame, x, y);

		if (currentEmotion != -1) {
			emotionX = x;
			emotionY = y;
		}
	}

	private int[] EMOTION_OFFSETS = new int[]{15, 17, 19};
	public void drawEmotions(Graphics g) {
		if (currentEmotion != -1) {
			if (shakeEmotion) {
				if (((counter + emotionSpeed) > EMOTION_OFFSETS.length - 1) || ((counter + emotionSpeed) < 0)) {
					emotionSpeed *= -1;
				}
				counter += emotionSpeed;
				currentX = Math.round(counter);
			}
			g.drawImage(EMOTIONS[currentEmotion], emotionX + EMOTION_OFFSETS[currentX], emotionY - 13);
		}
	}
}

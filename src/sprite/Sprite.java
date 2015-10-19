/*
 * Classname: AbstractSprite.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package sprite;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

import java.awt.Rectangle;
import java.awt.geom.Point2D;

import villages.utils.Animation;

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
	
	protected String[] animImages;
	protected Animation anim = new Animation();
	protected String name;
	protected int drawX;
	protected int drawY;
	protected int direction;
	protected int width = STANDARD_WIDTH;
	protected int height = STANDARD_HEIGHT;
	protected boolean moving;
	protected float speed;
	protected float[] pos = new float[2];
	
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

	private int[] xs = new int[]{15, 17, 19};
	private int currentX = 1;
	private int currentEmotion = -1;

	private Rectangle boundingRect = 
		new Rectangle(0, 0, getHeight(), getWidth());
	private boolean shakeEmotion;
	private float counter = 0;
	private float emotionSpeed = .8f;
	private int emotionX;
	private int emotionY;
	private int size = 4;

	/**
	 * Loads the images for the animated sprite.
	 * 
	 * @param path the path to the images used.
	 * @param name the prefix name of the image to use.
	 * @param nr the number of images to try and load.
	 */
	public void loadImages(String path, String name, int nr) {
		loadImagesFromPath(path + name + "/" + name, nr);
	}
	
	public void loadImagesFromPath(String path, int nr) {
		animImages = new String[nr];
		for (int i = 0; i < animImages.length; i++) {
			animImages[i] = path + (i + 1) + ".png";
			ImageHandler.addToCurrentLoadNow(animImages[i]);
		}
		size = Math.min(nr, size);
		for (int i = 0; i < size; i++) {
			anim.addFrame(animImages[0], 150);
		}	
	}
	
	/**
	 * Loads the images for this sprite in the list of permanent images.
	 * 
	 * @param path the path to the images.
	 * @param name the prefix name of the images.
	 */
	public void loadPermImages(String path, String name) {
		animImages = new String[16];
		for (int i = 0; i < animImages.length; i++) {
			animImages[i] = path + name + "/" + name + (i + 1) + ".png";
			ImageHandler.addPermanentlyLoadNow(animImages[i]);
		}
		for (int i = 0; i < size; i++) {
			anim.addFrame(animImages[0], 150);
		}
	}

	/**
	 * This method returns a rectangle that will cover this sprite.
	 * This rectangle is bounding so t can be used to check for collisions.
	 * 
	 * @return the bounding rectangle of the sprite.
	 */
	public Rectangle getRectangle() {
		boundingRect.x = Math.round(pos[Values.X]);
		boundingRect.y = Math.round(pos[Values.Y]);
		return boundingRect;
	}

	/**
	 * This method wraps the given sprite. It takes the information from the
	 * given sprite and overwrites the information in this sprite.
	 * 
	 * @param sprite the sprite to take the information from.
	 */
	protected void merge(Sprite sprite) {
		animImages = sprite.animImages;
		anim = sprite.anim;
		pos = sprite.pos;
		name = sprite.name;
		drawX = sprite.drawX;
		drawY = sprite.drawY;
	}

	/**
	 * Loads the images for the animated sprite.
	 * 
	 * @param path the path to the images used.
	 * @param name the prefix name of the image to use.
	 */
	protected void loadImages(String path, String name) {
		loadImages(path, name, 16);
	}

	/**
	 * Gets the height of the images used for the animations.
	 * 
	 * @return the height of the images used.
	 */
	public int getHeight() {
		return height;
	}

	/**
	 * Gets the width of the images used for the animations.
	 * 
	 * @return the width of the images used.
	 */
	public int getWidth() {
		return width;
	}

	/**
	 * Checks if this sprite has collided with the object represented by
	 * the given position.
	 * 
	 * @param checkPos the position to check this sprite against.
	 * @param maxDistance the distance to use as range to trigger a collision.
	 * @return true if the given position is less than maxDistance from 
	 * this sprite.
	 */
	protected boolean checkCollision(float[] checkPos, int maxDistance) {
		return checkCollision(checkPos, maxDistance, direction);
	}

	/**
	 * Updates the sprite.
	 * 
	 * @param elapsedTime the time that has elapsed since the last 
	 * call to the update.
	 */
	public void update(float elapsedTime) {
		anim.update(elapsedTime);
	}

	/**
	 * Gets the current image in the animation of this sprite.
	 * 
	 * @return the current image of this sprite.
	 */
	public String getImage() {
		return anim.getImage();
	}

	/**
	 * Checks if this sprite has collided with the object represented by
	 * the given position.
	 * 
	 * @param checkPos the position to check this sprite against.
	 * @param maxDistance the distance to use as range to trigger a collision.
	 * @param direction of the sprite.
	 * @return true if the given position is less than maxDistance from 
	 * this sprite.
	 */
	protected boolean checkCollision(float[] checkPos, int maxDistance, int direction) {
		boolean collided = false;
		if (inRange(checkPos, maxDistance, false)) {
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

	/**
	 * Checks if the given position is within maxDistance from this sprite.
	 * 
	 * @param checkPos the position to check against.
	 * @param maxDistance the distance to use as radius when checking.
	 * @param b 
	 * @return true if the given position is within the distance maxDistance.
	 */
	protected boolean inRange(float[] checkPos, int maxDistance, boolean b) {
		int dist = (int) Point2D.distance(checkPos[Values.X], checkPos[Values.Y],
				pos[Values.X], pos[Values.Y]);
		return dist < maxDistance;
	}

	/**
	 * Checks if this sprite is visible on screen.
	 * 
	 * @return true if this sprite is visible.
	 */
	public boolean isVisible() {
		int compareX = drawX + getWidth();
		int compareY = drawY + getHeight();
		return 	compareX > 0 || drawX < Values.RESOLUTIONS[Values.X] || 
		compareY > 0 || drawY < Values.RESOLUTIONS[Values.Y];
	}

	/**
	 * Checks if this sprite is moving.
	 * 
	 * @return true if this sprite is moving.
	 */
	public boolean isMoving() {
		return moving;
	}

	/**
	 * Gets the name of this sprite.
	 * 
	 * @return name the name of this sprite.
	 */
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}

	/**
	 * Gets the position of the sprite.
	 * 
	 * @return the position of the sprite.
	 */
	public float[] getPos() {
		return pos;
	}

	/**
	 * Set the position of the sprite to the given pos.
	 * 
	 * @param p the new position.
	 */
	public void setPos(float[] p) {
		pos = p;
	}
	
	public void setPos(int[] p) {
		pos[0] = p[1];
		pos[1] = p[0];
		standStill(p[2]);
	}

	/**
	 * Draws the sprite on the given graphics at the given coordinates.
	 * 
	 * @param g the graphics to draw on.
	 * @param x the x coordinate to draw on.
	 * @param y the y coordinate to draw on.
	 */
	public void drawAtPosition(Graphics g, int x, int y) {
		drawSprite(g, x, y);
	}
	
	public abstract void draw(Graphics g, int x, int y);

	/**
	 * Draws the sprite on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void draw(Graphics g) {
		drawSprite(g, drawX, drawY);
	}
	
	protected void drawSprite(Graphics g, int x, int y) {
//		Graphics.gl.glPushMatrix();
//		Graphics.gl.glScalef(1.25f, 1.25f, 1);
//		int yoffset = STANDARD_HEIGHT - this.getHeight();
//		int xoffset = STANDARD_WIDTH - this.getWidth();
//		g.drawImage(anim.getImage(), x + xoffset, y + yoffset);
		g.drawImage(anim.getImage(), x, y);
//		Graphics.gl.glPopMatrix();
		if (currentEmotion != -1) {
			emotionX = x;
			emotionY = y;
		}
	}
	
	public void drawEmotions(Graphics g) {
		if (currentEmotion != -1) {
			if (shakeEmotion) {
				if (((counter + emotionSpeed) > xs.length - 1) || ((counter + emotionSpeed) < 0)) {
					emotionSpeed *= -1;
				}
				counter += emotionSpeed;
				currentX = Math.round(counter);
			}
			g.drawImage(EMOTIONS[currentEmotion], emotionX + xs[currentX], emotionY - 13);
		}
	}

	/**
	 * Sets the images.
	 * It just calls setImages(int) with the current direction.
	 */
	public void setImages() {
		setImages(direction);
	}

	/**
	 * Changes the image that depicts the sprite. This method will
	 * change the images based on whether or not the player is moving.
	 * 
	 * @param direction the direction that the sprite is moving.
	 */
	protected void setImages(int direction) {
		if (isMoving()) {
			move(direction, anim, animImages);
		} else {
			standStill(direction, anim, animImages);
		}
	}

	/**
	 * Changes the characters images so that the animation shows the 
	 * sprite moving in the current direction.
	 */
	public void move() {
		move(direction, anim, animImages);
	}    
	
	/**
	 * Changes the characters images so that the animation shows the 
	 * sprite moving in the current direction.
	 */
	public void moveActor() {
		moveActor(direction, anim, animImages);
	}    

	/**
	 * Changes the characters images so that the animation shows the 
	 * sprite standing still in the current direction.
	 */
	public void standStill() {
		standStill(direction, anim, animImages);
	}

	/**
	 * Changes the characters images so that the animation shows the 
	 * sprite moving in the given direction.
	 * 
	 * @param direction the direction of the sprite.
	 */
	public void move(int direction) {
		move(direction, anim, animImages);
	}
	
	/**
	 * Changes the characters images so that the animation shows the 
	 * sprite moving in the given direction.
	 * 
	 * @param direction the direction of the sprite.
	 */
	public void moveActor(int direction) {
		moveActor(direction, anim, animImages);
	}    

	/**
	 * Changes the characters images so that the animation shows the 
	 * sprite standing still in the current direction.
	 * 
	 * @param direction the direction of the sprite.
	 */
	public void standStill(int direction) {
		standStill(direction, anim, animImages);
	}
	
	/**
	 * Changes the characters images so that the animation shows the 
	 * sprite standing still in the current direction.
	 * 
	 * @param direction the direction of the sprite.
	 */
	public void standStillActor(int direction) {
		standStillActor(direction, anim, animImages);
	}

	/**
	 * Set the animation pictures for the moving character.
	 * Different pictures for different angles of course.
	 * 
	 * @param dir the direction that the player should have when moving.
	 * @param anim the animation object to change the images in.
	 * @param ia the image array containing the images used.
	 */
	protected void move(int dir, Animation anim, String[] ia) {
		for (int i = 0; i < size; i++) {
			if (dir * size < ia.length && i < ia.length) {
				anim.changePic(i, ia[i + dir * size]);
			}
		}
	}

	/**
	 * Set the animation pictures for the still character.
	 * 
	 * @param dir the direction that the player should have when 
	 * standing still. 
	 * @param anim the animation object to change the images in.
	 * @param ia the image array containing the images used.
	 */
	protected void standStill(int dir, Animation anim, String[] ia) {
		for (int i = 0; i < size; i++) {
			if (dir * size < ia.length) {
				anim.changePic(i, ia[dir * size]);
			}
		}
	}
	
	/**
	 * Set the animation pictures for the moving character.
	 * Different pictures for different angles of course.
	 * 
	 * @param dir the direction that the player should have when moving.
	 * @param anim the animation object to change the images in.
	 * @param ia the image array containing the images used.
	 */
	protected void moveActor(int dir, Animation anim, String[] ia) {
		if (!moving || direction != dir) {
			direction = dir;
			moving = true;
			for (int i = 0; i < size; i++) {
				if (dir * size < ia.length && i < ia.length) {
					anim.changePic(i, ia[i + dir * size]);
				}
			}
		}
	}
	
	/**
	 * Set the animation pictures for the still character.
	 * 
	 * @param dir the direction that the player should have when 
	 * standing still. 
	 * @param anim the animation object to change the images in.
	 * @param ia the image array containing the images used.
	 */
	protected void standStillActor(int dir, Animation anim, String[] ia) {
		if (moving || direction != dir) {
			direction = dir;
			moving = false;
			for (int i = 0; i < size; i++) {
				if (dir * size < ia.length) {
					anim.changePic(i, ia[dir * size]);
				}
			}
		}
	}
	
	/**
	 * Sets the animation to show the image in the array of animation images
	 * with the given pos as index.
	 * 
	 * @param pos the position (index) of the image to set as the 
	 * current animation.
	 */
	public void animate(int pos) {
		for (int i = 0; i < size; i++) {
			anim.changePic(i, animImages[pos]);
		}
	}
	
	/**
	 * Adds an image, with the given name, to the array of animation images.
	 * The given pos acts as the index in this array.
	 * 
	 * @param name the name of the image to add.
	 * @param pos the index in the array where to add the image.
	 */
	public void addAnimation(String name, int pos) {
		if (pos >= animImages.length) {
			String[] newAnim = new String[pos + 1];
			for (int i = 0; i < animImages.length; i++) {
				newAnim[i] = animImages[i];
			}
			animImages = newAnim;
		}
		animImages[pos] = name;
	}
	
	/**
	 * Gets the x position of the sprite.
	 * 
	 * @return the x position of this sprite.
	 */
	public float getX() {
		return pos[Values.X];
	}

	/**
	 * Gets the y position of the sprite.
	 * 
	 * @return the y position of this sprite.
	 */
	public float getY() {
		return pos[Values.Y];
	}

	public void setDirection(int dir) {
		direction = dir;
	}

	public void setEmotion(boolean show, int emotion, boolean shake) {
		currentEmotion = show ? emotion : -1;
		currentX = 1;
		shakeEmotion = shake;
	}

	public int getDirection() {
		return direction;
	}

	public void setMoving(boolean m) {
		moving = m;
	}
}

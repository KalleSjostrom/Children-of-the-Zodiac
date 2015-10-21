package villages.villageStory;

import graphics.Graphics;
import info.Values;

import java.awt.Rectangle;
import java.util.ArrayList;

import sprite.DefaultSprite;
import sprite.Sprite;
import villages.Villager;

public class Actor {
	
	private Sprite actor;
	private ArrayList<int[]> instructions = new ArrayList<int[]>();
	private int[] target = new int[3];
	private float speed = 1;
	private float[] velocity = new float[2];
	private boolean waiting;
	private boolean inControll = false;

	private Rectangle boundingRect;

	public Actor(Sprite sprite) {
		actor = sprite;
		boundingRect = new Rectangle(0, 0, sprite.width, sprite.height);
	}
	
	public Actor(String path, int size) {
		actor = new DefaultSprite(path);
		path = path.replace("Extras", "");
		actor.loadImage(Values.VillageImages, path);
		boundingRect = new Rectangle(0, 0, actor.width, actor.height);
	}
	
	public void setControll(boolean controll) {
		inControll = controll;
		if (actor instanceof Villager) {
			Villager v = (Villager) actor;
			v.setPause(controll);
		}
	}

	public void update(float dt) {
		if (!inControll && (actor instanceof villages.Villager)) {
			((villages.Villager) actor).updateVillager(Math.round(dt * speed));
		} else {
			float[] pos = actor.pos;
			float preDistance = calcDist(pos, target);
			for (int i = 0; i < 2; i++) {
				// velocity[i] += acc[i] * dt;
				pos[i] += velocity[i] * dt;
			}
			float postDistance = calcDist(pos, target);
			if (preDistance < postDistance) {
				pos[0] = target[0];
				pos[1] = target[1];
				velocity[0] = velocity[1] = 0;
				// acc[0] = acc[1] = 0;
				if (instructions.size() > 0) {
					int[] start = popInstruction();
					move(start[0], start[1], start[2]);
				} else if (actor.moving) {
					actor.stop(target[2]);
				}
			}
			actor.update(Math.round(dt * speed));
		}
	}
	
	private int[] popInstruction() {
		int[] ins = instructions.remove(0);
		waiting = instructions.size() == 0;
		return ins;
	}

	private float calcDist(float[] pos, int[] target2) {
		return (float) (Math.pow((pos[0] - target2[0]), 2) + Math.pow((pos[1] - target2[1]), 2));
	}

	public void stop(int direction) {
		actor.stop(direction);
		target[2] = direction;
	}
	
	public Sprite getSprite() {
		return actor;
	}
	
	public void moveToRel(int x, int y, float duration) {
		int[] direction = moveToRelative(x, y);
		setStepBasedOnDistance(direction, duration);
	}
	
	private int[] moveToRelative(int x, int y) {
		int[] direction = new int[2];
		
		direction[Values.X] = x < 0 ? Values.LEFT : Values.RIGHT;
		direction[Values.Y] = y < 0 ? Values.UP : Values.DOWN;
		int faceDirection = direction[Math.abs(x) > Math.abs(y) ? Values.X : Values.Y];
		actor.move(faceDirection);
		float[] pos = actor.pos;
		target[Values.X] = (int) pos[Values.X] + x;
		target[Values.Y] = (int) pos[Values.Y] + y;
		target[2] = faceDirection;
		return direction;
	}
	
	public void moveToWithSpeed(int x, int y, float speed) {
		float[] pos = actor.pos;
		int[] direction = moveToRelative(Math.round(x - pos[Values.X]), Math.round(y - pos[Values.Y]));
		setStepBasedOnSpeed(direction, speed);
	}
	
	public void moveTo(int x, int y, float duration) {
		float[] pos = actor.pos;
		moveToRel(Math.round(x - pos[Values.X]), Math.round(y - pos[Values.Y]), duration);
	}
	
	public void move(int distance, int direction, float duration) {
		move(distance, direction, direction, duration);
	}
	
	public void move(int distance, int direction, int faceDirection, float duration) {
		if (duration == 0) {
			target[2] = faceDirection;
			stop(faceDirection);
			return;
		}
		actor.move(faceDirection);
		target[2] = faceDirection;
		float[] pos = actor.pos;
		int index = direction % 2;
		target[index] = (int) pos[index] + (distance * Values.DIRECTIONS[direction]);
		index = Math.abs(index - 1);
		target[index] = (int) pos[index];
		setStepBasedOnDistance(new int[]{direction, direction}, duration);
	}
	
	public void queueMove(int distance, int direction, float duration) {
		instructions.add(new int[]{distance, direction, (int) duration});
	}
	
	private void setStepBasedOnDistance(int[] direction, float duration) {
		float[] pos = actor.pos;
		for (int i = 0; i < 2; i++) {
			velocity[i] = Math.abs(target[i] - pos[i]) / duration;
			velocity[i] *= Values.DIRECTIONS[direction[i]];
		}
	}

	private void setStepBasedOnSpeed(int[] direction, float speed) {
		float[] pos = actor.pos;
		double x = Math.abs(target[Values.X] - pos[Values.X]);
		double y = Math.abs(target[Values.Y] - pos[Values.Y]);
		double theta;
		if (x == 0) {
			theta = Math.PI / 2;
			theta *= (y < 0 ? 1 : -1);
		} else {
			theta = Math.atan(y / x);
		}
		double[] speedComp = new double[2];
		speedComp[Values.X] = speed * Math.cos(theta);
		speedComp[Values.Y] = speed * Math.sin(theta);
		for (int i = 0; i < 2; i++) {
			velocity[i] = (float) speedComp[i];
			velocity[i] *= Values.DIRECTIONS[direction[i]];
		}		
	}
	
	/*
	public void deaccelerateActor() {
		float pos[] = actor.getPos();
		for (int i = 0; i < 2; i++) {			
			double p = pos[i];
			double t = target[i];
			if (p != t) {
				double s = Math.abs(p - t);
				acc[i] = (step[i] * step[i]) / (2*s);
				acc[i] *= step[i] < 0 ? 1 : -1;
			}
		}
	}
	*/
	
	public void lookTo(int x, int y) {
		float[] pos = actor.pos;
		int xdir = x < pos[Values.X] ? Values.LEFT : Values.RIGHT;
		int ydir = y < pos[Values.Y] ? Values.UP : Values.DOWN;
		int direction = Math.abs(x - pos[Values.X]) > Math.abs(y - pos[Values.Y]) ? xdir : ydir;
		actor.stop(direction);
		target[0] = (int) pos[0];
		target[1] = (int) pos[1];
		target[2] = direction;
	}

	public void setPos(float[] p) {
		actor.pos = p;
	}
	public float[] getPos() {
		return actor.pos;
	}
	public void setPos(int[] p) {
		actor.pos[0] = p[1];
		actor.pos[1] = p[0];
		stop(p[2]);
	}

	public boolean isMoving() {
		return actor.moving;
	}

	public void add_Animation(String name, int pos) {
		// actor.addAnimation(name, pos);
	}
	// TODO(kalle): Implement a way of showing this image instead of the regular sprite
	public void overrideImage(String name) {
	}
	
	public boolean isWaiting() {
		return waiting;
	}

	public String getName() {
		return actor.name;
	}

	public void setEmotion(boolean show, int emotion, boolean shake) {
		actor.setEmotion(show, emotion, shake);
	}
	
	/**
	 * Draws the villager on the given graphics2D object.
	 * The background position is used to draw the villager in 
	 * relation to the village background. This means that if the background 
	 * has moved, so has the villager (in some sense).
	 * 
	 * @param g the graphics2D object to draw on.
	 * @param bx the x position of the background.
	 * @param by the y position of the background.
	 */
	public void draw(float dt, Graphics g, int bx, int by) {
		float[] pos = actor.pos;
		int x = Math.round(pos[Values.X] + bx);
		int y = Math.round(pos[Values.Y] + by);
		actor.draw(dt, g, x, y);
	}
	
	/**
	 * This method will initiate this instruction followers starting
	 * instruction. The starting instruction is a generated instruction
	 * that tells the sprite where to go before the written instructions
	 * should be carried out. An example of this is when a story mode is
	 * initiated by the player in a village. The player party can be
	 * positioned anywhere around the villager who will start the story mode,
	 * so the player party will have to go in front of the villager before the
	 * actual story mode begins. A list of nearby villagers are sent to this
	 * method because the generated instruction should not make the player 
	 * party move through any villagers.
	 * 
	 * @param pos the start position that this sprite will move to.
	 * @param members the villagers in the nearby area.
	 */
	public void initStartLocation(
			int[] pos, ArrayList<Actor> members) {
		if (pos == null) {
			waiting = true;
		} else {
			float[] startPos = new float[2];
			startPos[0] = pos[0];
			startPos[1] = pos[1];
			createStartInstructions(startPos, pos[2], members);
		}
	}
	
	/**
	 * Creates the stop instructions for the given villager.
	 * 
	 * @param pos the position to go to.
	 */
	public void createStopInstructions(float[] pos) {
		createStartInstructions(pos, 0, new ArrayList<Actor>());
	}
	
	private static final int X_AXIS = 3;
	private static final int Y_AXIS = 0;
	
	private Rectangle getRectangle() {
		boundingRect.x = Math.round(actor.pos[Values.X]);
		boundingRect.y = Math.round(actor.pos[Values.Y]);
		return boundingRect;
	}
	
	/**
	 * Creates the starting instructions. These instructions should lead 
	 * the villager to its starting location. The location is calculated
	 * by first moving along to x axis and then the y axis. This will, however,
	 * not work in the final version because the villager must also avoid 
	 * other villagers.
	 * 
	 * @param positions the position which the villager will travel to.
	 * @param startDir the starting direction of this instruction follower.
	 * @param villagers the list of villagers to avoid.
	 */
	private void createStartInstructions(
			float[] positions, int startDir, 
			ArrayList<Actor> villagers) {
		float[] pos = actor.pos;
		int xDif = Math.round(positions[Values.X] - pos[Values.X]);
		int yDif = Math.round(positions[Values.Y] - pos[Values.Y]);

		if (villagers.size() > 0) {
			Rectangle villager = villagers.get(0).getRectangle();

			if (pos[Values.Y] < villager.y) {
				Rectangle player = getRectangle();
				player.height = yDif;
				if (player.intersects(villager)) {
					int point1 = villager.x - villager.width;
					int point2 = villager.x + villager.width;
					int p1 = Math.abs(player.x - point1);
					int p2 = Math.abs(player.x - point2);
					int point = (p1 < p2 ? point1 : point2);
					createInstruction(X_AXIS, point - player.x);
					xDif = Math.round(positions[Values.X] - point);
				}
			}
		}

		
		createInstruction(Y_AXIS, yDif);
		createInstruction(X_AXIS, xDif);

		if (xDif == 0 && yDif == 0) {
			actor.stop(startDir);
		} else {
			instructions.add(new int[]{0, startDir, 0});
			actor.move(startDir);
		}
		if (instructions.size() > 0) {
			int[] start = popInstruction();
			move(start[0], start[1], start[2]);
		} else {
			waiting = true;
		}
	}
	
	/**
	 * Creates one instruction from the given arguments.
	 *  
	 * @param start 3 if x axis or 0 if the y axis.
	 * @param dif the distance to travel. Difference in positions.
	 */
	private void createInstruction(int start, int dif) {
		int dir;
		if (dif < 0) {
			dir = start;
		} else if (dif > 0) {
			dir = Math.abs(start - 2);
		} else {
			return;
		}
		dif = Math.abs(dif);
		instructions.add(new int[]{dif, dir, dif * 20});
	}
	
	public String toString() {
		return actor.name;
	}

	public void resetVillager() {
		Villager v = (Villager) actor;
		v.reset();
	}

	public void updateDialog(int value) {
		Villager v = (Villager) actor;
		v.updateDialog(value);		
	}

	public void drawEmotion(Graphics g) {
		actor.drawEmotions(g);
	}

	public void setDirection(int dir) {
		actor.direction = dir;
	}
}

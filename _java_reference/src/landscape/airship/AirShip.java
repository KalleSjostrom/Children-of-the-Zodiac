package landscape.airship;

import factories.Load;
import info.Values;
import landscape.LandPlayer;

public class AirShip extends LandPlayer {
	
	private float velocity = 0;
	private static final float MAX_VELOCITY = .2f;
	private static final float VELOCITY_INCREASE_STEP = .02f;
	private static final float VELOCITY_DECREASE_STEP = -.03f;
	private float distance;
	private float increase = 0;
	private boolean[] dirs = new boolean[4];
	
	public void init() {
		loadImages(Values.LandscapeImages, "Airship");
	}

	public void go(int dir) {
		increase = VELOCITY_INCREASE_STEP;
		dirs[dir] = true;
		if (!moving || direction != dir) {
			direction = dir;
			move(dir);
		}
	}
	
	private void goforward(int dir) {
		float dist = Values.DIRECTIONS[dir] * Values.LOGIC_INTERVAL* velocity;
		pos[dir % 2] += dist;
		distance += Math.abs(dist);
		if (distance >= 30) {
			Load.getPartyItems().takeStep();
			distance = 0;
		}
	}
	
	public void update(float elapsedTime) {
		if ((increase > 0 && velocity < MAX_VELOCITY) || (increase < 0 && velocity > 0)) {
			velocity += increase;
		}
		if (velocity >= MAX_VELOCITY) {
			velocity = MAX_VELOCITY;
			increase = 0;
		} else if (velocity <= 0) {
			velocity = 0;
			increase = 0;
		}
		for (int i = 0; i < 4; i++) {
			if (dirs[i]) {
				goforward(i);
			}
			dirs[i] = false;
		}
		super.update(elapsedTime);
		checkLeftUp();
		checkRightDown();
	}
	
	private void checkLeftUp() {
		for (int i = 0; i < 2; i++) {
			if (pos[i] < 0) {
				pos[i] += (Values.ORIGINAL_RESOLUTION[i] + 55);
			}
		}
	}
	
	private void checkRightDown() {
		for (int i = 0; i < 2; i++) {
			if (pos[i] > Values.ORIGINAL_RESOLUTION[i] + 55) {
				pos[i] -= (Values.ORIGINAL_RESOLUTION[i] + 55) ;
			}
		}
	}
	
	public int getDirection() {
		return direction;
	}
	
	public void standStill() {
		increase = VELOCITY_DECREASE_STEP;
		dirs[direction] = true;
//		standStill(direction);
	}
}

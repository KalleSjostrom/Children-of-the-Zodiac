package landscape.airship;

import factories.Load;
import info.Values;
import landscape.LandPlayer;

public class AirShip extends LandPlayer {
	
	private float velocity = 0;
	private static final float MAX_VELOCITY = 200.0f;
	private static final float ACCELERATION = 200.0f;
	private static final float DECCELERATION = -300.0f;
	private float distance;
	private float delta_velocity = 0;
	private boolean[] dirs = new boolean[4];
	
	public void init() {
		loadImage(Values.LandscapeImages, "Airship");
	}

	public void go(int dir) {
		delta_velocity = ACCELERATION;
		dirs[dir] = true;
		if (!moving || direction != dir) {
			direction = dir;
			move(dir);
		}
	}
	
	private void goforward(float dt, int dir) {
		float dist = Values.DIRECTIONS[dir] * dt * velocity;
		pos[dir % 2] += dist;
		distance += Math.abs(dist);
		if (distance >= 30) {
			Load.getPartyItems().takeStep();
			distance = 0;
		}
	}
	
	public void update(float dt) {
		if ((delta_velocity > 0 && velocity < MAX_VELOCITY) || (delta_velocity < 0 && velocity > 0)) {
			velocity += delta_velocity * dt;
		}
		if (velocity >= MAX_VELOCITY) {
			velocity = MAX_VELOCITY;
			delta_velocity = 0;
		} else if (velocity <= 0) {
			velocity = 0;
			delta_velocity = 0;
		}
		for (int i = 0; i < 4; i++) {
			if (dirs[i]) {
				goforward(dt, i);
			}
			dirs[i] = false;
		}
		super.update(dt);
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
		delta_velocity = DECCELERATION;
		dirs[direction] = true;
//		standStill(direction);
	}
}

/*
 * Classname: Camera.java
 * 
 * Version information: 0.7.0
 *
 * Date: 24/05/2008
 */
package labyrinth;

import graphics.Graphics;
import info.Values;

/**
 * This class manages the view in the labyrinth. It is the players "eyes"
 * or the camera.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 24 May 2088
 */
public class Camera {

	private float[] location;
	private float angle;
	private static int mode;
	private static float shakeoffx;
	private static float shakeoffy;
	

	/**
	 * Construct a new camera, with both the location and the target set to
	 * the origin.
	 */
	public Camera() {
		location = new float[]{0, 0};
	}

	/**
	 * Gets the location of the camera.
	 * 
	 * @return the location of the camera.
	 */
	public float[] getLocation() {
		return location;
	}

	/**
	 * Sets the location of the camera to the given location.
	 * 
	 * @param location the location to set.
	 */
	public void setLocation(float[] location) {
		this.location = location;
	}

	/**
	 * This method sets the values stored in the camera to the given GL
	 * object. It turns the view in open GL so that the view of the screen 
	 * matches that of the camera.
	 * 
	 * @param gl the GL object to show the camera on.
	 */
	public void lookAt(Graphics g) {
		g.rotate(angle + 90, 0, 1, 0);
		if (angle == 0 || angle == 180) {
			g.translate(-location[Position.X], shakeoffy, -location[Position.Z]+shakeoffx);
		} else {
			g.translate(-location[Position.X]+shakeoffx, shakeoffy, -location[Position.Z]);
		}
	}
	
	public static void shakeit(final int time) {
		new Thread() {
			public void run() {
				shakeit2(time);
			}
		}.start();
	}
	
	private static void shakeit2(int time) {
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

	/**
	 * Updates this cameras location and target based on the values
	 * stored in the given position  object.
	 * 
	 * @param position the position to update to.
	 */
	public void updatePosition(Position position) {
		location[Position.X] = position.getX();
		location[Position.Z] = position.getZ();
		angle = position.getAngle();
	}
}

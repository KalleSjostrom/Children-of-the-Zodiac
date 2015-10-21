package organizer;

import com.jogamp.opengl.GLAutoDrawable;

public class FPSAnimator implements Runnable {

	private GameEventListener game;
	private GLAutoDrawable drawable;
	private Thread thread;
	private boolean keeprunning;
	
	public FPSAnimator(GLAutoDrawable drawable, GameEventListener game) {
		this.drawable = drawable;
		this.game = game;
	}
	
	public void start() {
		if (thread == null || thread.isAlive()) {
			keeprunning = true;
			thread = new Thread(this, "FPSAnimator");
			thread.start();
		}
	}
	
	public void stop() {
		keeprunning = false;
	}

	public void run() {
		long previous_timestamp = System.nanoTime();
		while (keeprunning) {
			try {
				long now = System.nanoTime();
				long duration = now - previous_timestamp;
				previous_timestamp = now;
				
				game.update(duration);
				drawable.display();

//				int timetosleep = (int) (targetduration - duration);
//				if (timetosleep > 0) {
//					Thread.sleep(timetosleep);
//				}
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}
}

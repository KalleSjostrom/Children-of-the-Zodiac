package organizer;

import com.jogamp.opengl.GLAutoDrawable;

public class FPSAnimator implements Runnable {

	private GLAutoDrawable drawable;
	private Thread thread;
	private int targetduration;	
	private boolean keeprunning;
	
	public FPSAnimator(GLAutoDrawable drawable, int fps) {
		this.drawable = drawable;
		setTargetfps(fps);		
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
		while (keeprunning) {
			try {
				long t1 = System.currentTimeMillis();
				drawable.display();
				long t2 = System.currentTimeMillis();
				int duration = (int) (t2 - t1);
				int timetosleep = (int) (targetduration - duration);
				if (timetosleep > 0) {
					Thread.sleep(timetosleep);
				}
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}
	
	public void setTargetfps(float targetfps) {
		targetduration = (int) ((1f / targetfps) * 1000);
	}
}

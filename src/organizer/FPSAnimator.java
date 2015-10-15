package organizer;

import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

import com.jogamp.opengl.GLAutoDrawable;

public class FPSAnimator implements Runnable {

	private GLAutoDrawable drawable;
	private Thread thread;
	private int targetduration;	
	private boolean keeprunning;
	private long zeroTime;
	
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
		Semaphore sem = new Semaphore(1);
		try {
			sem.acquire();
		} catch (InterruptedException e1) {
			e1.printStackTrace();
		}
		zeroTime = System.currentTimeMillis();
		while (keeprunning) {
			try {
				long t1 = System.currentTimeMillis();
				drawable.display();
				long t2 = System.currentTimeMillis();
				int duration = (int) (t2 - t1);
				int timetosleep = (int) (targetduration - duration);
//				if (duration > 10) {
//					System.out.println("Duration " + duration + " " + timetosleep);
//				}
				if (timetosleep > 0) {
					sem.tryAcquire((long) (23/*timetosleep*/), TimeUnit.MILLISECONDS);
					
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

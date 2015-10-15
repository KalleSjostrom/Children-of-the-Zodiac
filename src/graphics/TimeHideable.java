package graphics;

import info.Values;

public class TimeHideable {
	
	private boolean visible = true;
	
	public boolean isVisible() {
		return visible;
	}

	public void hide(final int time) {
		Thread t = new Thread() {
			public void run() {
				visible = false;
				Values.sleep(time);
				visible = true;
			}
		};
		t.start();
	}
}

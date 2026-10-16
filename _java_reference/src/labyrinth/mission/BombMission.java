package labyrinth.mission;

import graphics.Graphics;

import java.util.ArrayList;

public class BombMission extends Mission {

	private String string = "Bombs Disarmed: ";
	private static final int DONE_CRITERION = 3;

	@Override
	public void init(ArrayList<String> info) {
		setDatabaseName(info.get(MissionFactory.DATABASE_NAME));
		if (getStatus() == -1) {
			setStatus(0);
		}
		addTriggers(info);
	}

	public void draw(Graphics g) {
		g.startText();
		super.update();
		g.setFontSize(40);
		Graphics.setTextColor(1);
		int status = getStatus();
		if (isFinished(status)) {
			g.drawMultiString("Mission done!", (int) (800 + getXtrans() * 300), 50);
		} else {
			g.drawMultiString(string + status + "/" + DONE_CRITERION, (int) (700 + getXtrans() * 350), 50);
		}
		g.finishText();
	}
	
	public void initDraw(Graphics g) {}

	@Override
	public boolean isFinished(int status) {
		return status == DONE_CRITERION;
	}
}

package labyrinth.mission;

import graphics.Graphics;
import info.Database;
import info.Values;

import java.util.ArrayList;

import labyrinth.Labyrinth;

import organizer.GameMode;
import organizer.Organizer;

public class TimeMission extends Mission {

	private String string = "Time: ";
	private float time;
	private int min = 0;
	private int sec = 0;
	private boolean gameOver = false;

	@Override
	public void init(ArrayList<String> info) {
		setDatabaseName(info.get(MissionFactory.DATABASE_NAME));
		if (getStatus() == -1) {
			setStatus(150);//150);
		}
		addTriggers(info);
	}

	public void draw(Graphics g) {
		super.update();
		g.setFontSize(40);
		g.setColor(1);
		int status = getStatus();
		time += Values.INTERVAL;
		if (time > 1000) {
			time = 0;
			status--;
			setStatus(status);
		}
		if (isFinished(status)) {
			g.drawString("Time's up!", (int) (800 + getXtrans() * 300), 50);
			if (!gameOver) {
				GameMode m = Organizer.getOrganizer().getCurrentMode();
				Labyrinth l = (Labyrinth) m;
				Database.addStatus("pensara prison--floor 1.mapchest25", 1);
				Database.addStatus("pensara prison--floor 3.mapchest185", 1);
				Database.addStatus("pensara prison--floor 6.mapchest110", 1);
				Database.addStatus("The Prison Cell", 0);
//				setStatus(150);
				l.exit("Pensara Prison--Floor 5-mark0", true);
				gameOver  = true;
			}
		} else {
			sec = status % 60;
			min = status / 60;
			g.drawString(string + min + ":" + (sec < 10 ? "0" : "") + sec, (int) (800 + getXtrans() * 300), 50);
		}
	}

	public void initDraw(Graphics g) {}

	@Override
	public boolean isFinished(int status) {
		return status <= 0;
	}
}

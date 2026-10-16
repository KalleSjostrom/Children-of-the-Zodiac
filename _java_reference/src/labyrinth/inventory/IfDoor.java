package labyrinth.inventory;

import info.Database;
import info.Values;

import java.util.StringTokenizer;

import organizer.Organizer;

import villages.VillageLoader;

import labyrinth.Labyrinth;
import labyrinth.Node;

public class IfDoor extends Door {
	
	private String condition;
	private int conditionStatus;
	private String trueCase;
	private String falseCase;
	private static int ALWAYS_FALSE = -2;

	public IfDoor(Node node, int dir, String openRoad, String next, int status,
			StringTokenizer tok) {
		super(node, dir, openRoad, next, status, tok);
		String[] temp = nextPlaces.get(0).split("==");
		condition = Organizer.convert(temp[0]);
		conditionStatus = Integer.parseInt(temp[1]);
		trueCase = nextPlaces.get(1);
		falseCase = nextPlaces.get(2);
	}
	
	public void activate(Labyrinth lab) {
		int playerDir = ((lab.getPlayerAngle() - 90) / 90 + 4) % 4;
		if (playerDir == dir) {
			for (int i = 0; i < openRoad.length; i++) {
				String road = openRoad[i];
				if (!road.equals("dontopen")) {
					Database.addStatus("road" + road, 1); // road
				}			
			}

			status = Database.getStatusFor(dataBaseName);
			status = status == -1 ? 0 : status;
			String next;
			if (status == ALWAYS_FALSE) {
				next = falseCase;
			} else {
				int s = Database.getStatusFor(condition);
				if (s == conditionStatus) {
					int trueStatus = Database.getStatusFor(Organizer.convert(trueCase));
					if (trueStatus == -1) {
						next = trueCase;
						status = ALWAYS_FALSE;
						Database.addStatus(dataBaseName, status);
						Database.addStatus(Organizer.convert(trueCase), 1);
						Organizer.getOrganizer().updateNextPlaceFor(trueCase, falseCase);
					} else {
						next = falseCase;
					}
				} else {
					next = falseCase;
				}
			}
			super.enter(lab, info);
			lab.exitLabyrinth(Values.EXIT);
			setHaveBeen();
			if (next.contains("-pos")) {
				String[] split = next.split("-pos");
				next = split[0];
				VillageLoader.staticStartPos = Integer.parseInt(split[1]);
			}
			lab.setNextPlace(next);
		}
	}
}

package labyrinth.mission;

import java.util.ArrayList;

public class MissionFactory {
	
	public static final int CLASS = 0;
	public static final int DATABASE_NAME = 1;
	public static final int TRIGGER_START = 2;

	public static Mission createMission(ArrayList<String> info) {
		Mission mission = null;
		if (info != null) {
			try {
				Class<?> missionClass = Class.forName("labyrinth.mission." + info.get(CLASS));
				mission = (Mission) missionClass.newInstance();
				mission.init(info);
			} catch (ClassNotFoundException e) {
				e.printStackTrace();
			} catch (InstantiationException e) {
				e.printStackTrace();
			} catch (IllegalAccessException e) {
				e.printStackTrace();
			}
		}
		return mission;
	}
}

package info;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

public class LabyrinthInfo {
	
	private static final int MAX_FLOORS = 6;
	private String labyrinthName;
	private HashMap<Integer, LabyrinthMap> floors = new HashMap<Integer, LabyrinthMap>();
	
	public LabyrinthInfo(String labyrinthName) {
		this.labyrinthName = labyrinthName;
	}
	
	public String getLabyrinthName() {
		return labyrinthName;
	}

	public LabyrinthMap getFloor(String name, boolean split) {
		if (split) {
			name = name.split("--")[1].replace(".map", "");
		}
		LabyrinthMap f = null;
		
		boolean found = false;
		Iterator<LabyrinthMap> it = floors.values().iterator();
		while (it.hasNext() && !found) {
			f = it.next();
			found = f.getName().equalsIgnoreCase(name);
		}
		return found ? f : null;
	}

	public void addFloor(String name, LabyrinthMap labyrinthMap) {
		Iterator<LabyrinthMap> it = floors.values().iterator();
		boolean found = false;
		while (it.hasNext() && !found) {
			found = it.next().getName().equalsIgnoreCase(name);
		}
		if (!found) {
			labyrinthMap.setName(name);
			int[] p = labyrinthMap.getMapPos();
			int preferredIndex = p[1] * 3 + p[0];
			floors.put(preferredIndex, labyrinthMap);
		}
	}

	public ArrayList<LabyrinthMap> getFloors() {
		ArrayList<LabyrinthMap> fl = new ArrayList<LabyrinthMap>();
		for (int i = 0; i < MAX_FLOORS; i++) {
			LabyrinthMap f = floors.get(i);
			if (f != null) {
				fl.add(f);
			}
		}
		return fl;
	}

	public LabyrinthMap getFirstFloor() {
		boolean found = false;
		LabyrinthMap floor = null;
		for (int i = 0; i < MAX_FLOORS && !found; i++) {
			floor = floors.get(i);
			found = floor != null;
		}
		return floor;
	}

	public boolean isFullyExplored() {
		Iterator<LabyrinthMap> it = floors.values().iterator();
		boolean isFullyExplored = true;
		while (it.hasNext() && isFullyExplored) {
			LabyrinthMap map = it.next();
			isFullyExplored = map.isFullyVisited();
		}
		return isFullyExplored;
	}
}

import info.Database;
import info.LabyrinthMap;
import info.Values;

import java.io.File;

import labyrinth.MapLoader;

public class s {

	public static void main(String[] args) {
		File f = new File(Values.LabyrinthMaps);
		Database.reset();
		int nr = 0;
		int nra = 0;
		for (String s : f.list()) {
			if (s.startsWith("Forest of Reil")) {
				System.out.println(s);
				LabyrinthMap currentMap = new MapLoader(s).getMap();
				nr += currentMap.getNodes().size();
				nra++;
			}
		}
		System.out.println(nr + " " + nra);
	}
}

package organizer;

import info.Values;

import java.util.ArrayList;

public class GameModeQueue {

	private ArrayList<GameMode> queue;
	
	public GameModeQueue() {
		queue = new ArrayList<GameMode>();
	}
	
	public void push(GameMode gm) {
		queue.add(0, gm);
	}

	public GameMode pop() {
		return queue.remove(0);
	}
	
	public int size() {
		return queue.size();
	}

	public GameMode peek() {
		GameMode mode = null;
		if (queue.size() > 0) {
			mode = queue.get(0);
		}
		return mode;
	}
	
	public String toString() {
		return queue.toString();
	}

	public void delete() {
		while (size() > 0) {
			pop().exit(Values.EXIT);
		}
	}
}

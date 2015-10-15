package bodies;

import java.util.ArrayList;
import java.util.Iterator;

public class Bodies {
	
	private ArrayList<Body> list;
	
	public Bodies() {
		list = new ArrayList<Body>();
	}
	
	public Body add(Body b) {
		list.add(b);
		return b;
	}
	
	public Iterator<Body> iterator() {
		return new BodyItr();
	}
	
	public int size() {
		return list.size();
	}
	
	private class BodyItr implements Iterator<Body> {
		
		private int current;
		
		public boolean hasNext() {
			return current < list.size();
		}
		
		public Body next() {
			return list.get(current++);
		}
		
		public void remove() {
			list.remove(current);
		}
	}
}

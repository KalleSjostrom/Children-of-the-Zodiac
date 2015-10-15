package labyrinth;

import info.Values;

public class PillarWalls {
	
	private static Node node;
	
	protected static void addPillarWalls(Node n, int offset, int nrOfNeightbours) {
		node = n;
		if (nrOfNeightbours == 1) {
			oneNeighbour(offset);
		} else if (nrOfNeightbours == 2) {
			twoNeighbours(offset);
		} else if (nrOfNeightbours == 3) {
			threeNeighbours(offset);
		}
	}

	private static void oneNeighbour(int offset) {
		for (int i = 0; i < 4; i++) {
			if (node.getNeighbor(i) != null) {
				node.setWall(Values.getCounterAngle(i), 3 + offset);
				int test = Values.getCounterAngle(i) / 2 == 0 ? 2 : 1;
				int leftIndex = (i + 3) % 4;
				int rightIndex = (i + 5) % 4;
				Node n = node.getNeighbor(i);
				node.setWall(leftIndex, (n.neighbors[leftIndex] != null ? 3 : test) + offset);
				node.setWall(rightIndex, (n.neighbors[rightIndex] != null ? 3 : test) + offset);
			}
		}		
	}

	private static void twoNeighbours(int offset) {
		int sum = 0;
		for (int i = 0; i < 4; i++) {
			if (node.getNeighbor(i) != null) {
				sum += i;
			}
		}
		if (sum == 2 || sum == 4) {
			setStraight(sum, offset);
		} else {
			setHook(sum, offset);
		}	
	}

	private static void setStraight(int sum, int offset) {
		int low = Math.abs(sum / 2 - 2); // 2 -> 1, 4 -> 0
		int high = low + 2; // 2 -> 3, 4 -> 2
		Node n = node.getNeighbor(sum / 2 - 1); //2 -> 0, 4 -> 1
		node.setWall(low, n.neighbors[low] != null ? 2 : 0);
		node.setWall(high, n.neighbors[high] != null ? 2 : 0);
		
		n = node.getNeighbor(sum / 2 + 1); //2 -> 2, 4 -> 3
		if (n.getNeighbor(low) != null) {
			node.setWall(low, 1, 3);
		}
		
		if (n.neighbors[high] != null) {
			node.setWall(high, 1, 3);
		}
		node.addToWall(low, offset);
		node.addToWall(high, offset);	
	}
	
	private static void setHook(int sum, int offset) {
		if (sum == 1 || sum == 5) {
			int high = Math.abs(sum - 4);
			int low = high - 1;
			Node n = node.getNeighbor(sum / 2); // sum / 2
			node.setWall(high, (n.neighbors[high] != null ? 3 : sum % 3) + offset);
			
			n = node.getNeighbor(sum / 2 + 1);
			node.setWall(low, (n.neighbors[low] != null ? 3 : sum % 3) + offset);
		} else {
			Node n;
			if ((n = node.getNeighbor(0)) != null) {
				node.setWall(1, (n.neighbors[1] != null ? 3 : 1) + offset);
				
				n = node.getNeighbor(3);
				node.setWall(2, (n.neighbors[2] != null ? 3 : 2) + offset);
			} else {
				n = node.getNeighbor(1);
				node.setWall(0, (n.neighbors[0] != null ? 3 : 1) + offset);
				n = node.getNeighbor(2);
				node.setWall(3, (n.neighbors[3] != null ? 3 : 2) + offset);
			}
		}
	}

	private static void threeNeighbours(int offset) {
		for (int i = 0; i < 4; i++) {
			if (node.getNeighbor(i) == null) {
				Node n = node.getNeighbor((i + 5) % 4);
				if (n.neighbors[i] != null) {
					node.setWall(i, ((i + 5) % 4 < 2) ? 2 : 1);
				} else {
					node.setWall(i, 0);
				}
				
				n = node.getNeighbor((i + 3) % 4);
				if (n.neighbors[i] != null) {
					node.setWall(i, ((i + 3) % 4 < 2) ? 2 : 1, 3);
				}
				node.addToWall(i, offset);
				return;
			}
		}		
	}
}

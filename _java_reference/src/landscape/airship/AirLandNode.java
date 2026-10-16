package landscape.airship;

public class AirLandNode {
	
	private String name;
	private String type;
	private int x;
	private int y;
	private int zone;

	public AirLandNode(int x, int y, String type, String name) {
		this.x = x;
		this.y = y;
		this.type = type;
		this.name = name;
	}

	public String getName() {
		return name;
	}

	public int getXpos() {
		return x;
	}

	public int getYpos() {
		return y;
	}

	public String getType() {
		return type;
	}
	
	public int getZone() {
		return zone;
	}

	public boolean isCross() {
		return type.equals("crossroad");
	}

	public void setZone(int zone) {
		this.zone = zone;
	}
}

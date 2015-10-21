package labyrinth.mission;

import graphics.Graphics;
import info.Database;

import java.util.ArrayList;
import java.util.HashMap;

import battle.Hideable;

public abstract class Mission extends Hideable {
	
	private int status;
	private String dbName;
	private HashMap<String, Integer> triggers = new HashMap<String, Integer>();
	private ArrayList<String[]> dialogs;
	protected HashMap<Integer, String> conditions = new HashMap<Integer, String>();

	public Mission() {
		super(0);
		setAxis(X);
		setLimit(true);
		setMovementSpeed(true);
	}
	
	public boolean checkIfFinished() {
		boolean done = false;
		status = Database.getStatusFor(dbName);
		if (done = isFinished(status)) {
			Database.addStatus(triggers);
		}
		return done;
	}
	
	public abstract void draw(float dt, Graphics g);
	public abstract void init(ArrayList<String> info);
	public abstract boolean isFinished(int status);
	
	protected void addTriggers(ArrayList<String> info) {
		for (int i = MissionFactory.TRIGGER_START; i < info.size(); i++) {
			String s = info.get(i);
			String[] args = s.split("&&");
			if (args[0].equals("trigger")) {
				triggers.put(args[1], Integer.parseInt(args[2]));
			} else if (args[0].equals("dialog")) {
				if (dialogs == null) {
					dialogs = new ArrayList<String[]>();
				}
				String[] dialog = new String[]{"", "", ""};
				for (int j = 1; j < args.length; j++) {
					dialog[j - 1] = args[j];
				}
				dialogs.add(dialog);
			} else if (args[0].equals("extranext")) {
				int key = Integer.parseInt(args[1]);
				String value = args[2];
				int ms = Database.getStatusFor("mission" + value);
				if (ms <= 0) {
					conditions.put(key, value);
				}
			}
		}
	}
	
	public int getStatus() {
		return status = Database.getStatusFor(dbName);
	}

	protected void setStatus(int status) {
		this.status = status;
		Database.addStatus(dbName, status);
	}

	protected String getDatabaseName() {
		return dbName;
	}

	protected void setDatabaseName(String name) {
		this.dbName = name;
	}

	protected HashMap<String, Integer> getTriggers() {
		return triggers;
	}

	protected void setTriggers(HashMap<String, Integer> triggers) {
		this.triggers = triggers;
	}

	public ArrayList<String[]> getFinishedDialogs() {
		return dialogs;
	}

	public void incrementStatus() {
		setStatus(getStatus() + 1);
	}

	public String getNext() {
		String c = conditions.get(status);
		int ms = Database.getStatusFor("mission" + c);
		if (ms == -1 || ms == 0) {
			return c;
		}
		return null;
	}

	public void resetNext() {
		String c = conditions.get(status);
		Database.addStatus("mission" + c, 1);
	}
}

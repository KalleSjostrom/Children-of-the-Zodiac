package battle.enemy;

import java.util.ArrayList;

import villages.villageStory.Parser;

public class EnemyAttackEffect {
	
	private String name;
	private int valuei;
	private float valuef;
	private String values;
	private String[] dialog;

	public static ArrayList<EnemyAttackEffect> createEffects(String instructions) {
		ArrayList<EnemyAttackEffect> effectList = new ArrayList<EnemyAttackEffect>();
		String[] effects = instructions.split("--");
		for (String s : effects) {
			s = s.replace("(", "");
			s = s.replace(")", "");
			String[] args = Parser.getArgument(s);
			String command = args[0];
			String val = args[1];
			EnemyAttackEffect eae = new EnemyAttackEffect();
			if (command.equals("ChangeElement")) {
				eae.name = "Element Change";
				eae.valuei = Integer.parseInt(val);
			} else if (command.equals("Drain")) {
				eae.name = "Drain";
				eae.valuef = Float.parseFloat(val);
			} else if (command.equals("Heal")) {
				eae.name = "Heal";
				eae.valuef = Float.parseFloat(val);
			} else if (command.equals("Renew")) {
				eae.name = "Renew";
				eae.valuef = Float.parseFloat(val);
			} else if (command.equals("Death")) {
				eae.name = "Death";
				eae.valuef = Float.parseFloat(val);
			} else if (command.equals("Dispel")) {
				eae.name = "Dispel";
				eae.valuef = Float.parseFloat(val);
			} else if (command.equals("DownTo")) {
				eae.name = "DownTo";
				eae.valuei = Integer.parseInt(val);
			} else if (command.equals("cardPref")) {
				eae.name = "cardPref";
				String[] temp = val.split(";");
				eae.values = temp[0];
				eae.valuei = Integer.parseInt(temp[1]);
			} else if (command.equals("showDialog")) {
				eae.name = "dialog";
				eae.dialog = val.split(";");
			} else if (command.equals("changeMusic")) {
				eae.name = "music";
				eae.values = val;
			} else if (command.startsWith("Boost")) {
				command = command.replace("Boost", "");
				String[] temp = val.split(";");
				eae.name = "Boost ";
				eae.valuei = Integer.parseInt(temp[0]);
				eae.valuef = Float.parseFloat(temp[1]);
				if (command.equals("Mag")) {
					eae.name += "Magic Attack ";
				} else if (command.equals("Off")) {
					eae.name += "Attack ";
				} else if (command.equals("Sup")) {
					eae.name += "Support ";
				} else if (command.equals("MagDef")) {
					eae.name += "Magic Defense ";
				} else if (command.equals("Def")) {
					eae.name += "Defense ";
				} else if (command.equals("Speed") || command.equals("Agility")) {
					eae.name += "Agility ";
				} else if (command.equals("Hp")) {
					eae.name += "Hp ";
				} else if (command.equals("All")) {
					eae.name += "All Status ";
				}
				eae.name += (eae.valuef > 0 ? "Up!" : "Down!");
			}
			effectList.add(eae);
		}
		return effectList;
	}

	public String getName() {
		return name;
	}

	public int getValuei() {
		return valuei;
	}
	
	public float getValuef() {
		return valuef;
	}
	
	public String getValues() {
		return values;
	}

	public String toString() {
		return name;
	}

	public String[] getDialog() {
		return dialog;
	}
}

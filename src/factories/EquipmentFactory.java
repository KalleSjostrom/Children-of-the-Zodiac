/*
 * Classname: HandEquipmentFactory.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/01/2008
 */
package factories;

import java.util.HashMap;
import java.util.StringTokenizer;
import organizer.Organizer;
import villages.villageStory.Parser;
import equipment.AbstractEquipment;
import equipment.Armor;
import equipment.Shield;
import equipment.Weapon;

/**
 * This represents a bank with all the hand equipments in the game.
 * It is designed as a singelton which means there will only 
 * be one object of this class. It reads a file containing information 
 * concerning all the hand equipments in the game. 
 *
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 21 Jan 2008
 */
public class EquipmentFactory extends AbstractFactory {

	private HashMap<String, AbstractEquipment> bank = 
		new HashMap<String, AbstractEquipment>();
	private static EquipmentFactory factory = new EquipmentFactory();

	/**
	 * The private constructor. This creates a new WeaponFactory which 
	 * reads the weapons.bank file and creates one instance of all the 
	 * weapons in the game for future use.
	 */
	private EquipmentFactory() {
		parseFile("equipment.bank");
	}

	/**
	 * Gets the hand equipment with the specified name.
	 * 
	 * @param name the name of the hand equipment.
	 * @return the hand equipment with the given name.
	 */
	public static AbstractEquipment getEquipment(String name) {
		AbstractEquipment ae = factory.bank.get(name);
		if (ae == null) {
			new IllegalArgumentException(
					"There are no equipment with the name " + name + " in the equipment factory").printStackTrace();
			System.exit(0);
		}
		return ae;
	}

	/**
	 * This method implements the executeCommand from the 
	 * AbstractFactory class. It creates a weapon from the string values 
	 * in the string tokenizer.
	 * 
	 * @param command the command to execute. (w for creation of an weapon 
	 * followed by the parameters to the Weapon constructor.)
	 * @param tokenizer the information concerning the parameters 
	 * to the Weapon constructor. 
	 */
	protected void executeCommand(String command, StringTokenizer tokenizer) {
		if (command.equals("w") || command.equals("s") || command.equals("a")) {
			float[] stat = new float[11];
			String name = null;
			int[] slots = null;
			while (tokenizer.hasMoreElements()) {
				String[] s = Parser.getArgument(tokenizer.nextToken());
				Object o = parse(s[0], s[1], stat);
				if (o instanceof String) {
					name = (String) o;
				} else if (o instanceof int[]) {
					slots = (int[]) o;
				}
			}
			AbstractEquipment ae = null;
			if (command.equals("w")) {
				ae = new Weapon(stat, name, slots);
			} else if (command.equals("s")) {
				ae = new Shield(stat, name, slots);
			} else if (command.equals("a")) {
				ae = new Armor(stat, name, slots);
			}
			bank.put(name, ae);
		}
	}

	private Object parse(String command, String value, float[] stat) {
		Object o = null;
		if (command.equals("for")) {
			stat[AbstractEquipment.FOR_WHOM] = Integer.parseInt(value);
		} else if (command.equals("defense")) {
			stat[AbstractEquipment.DEFENSE] = Integer.parseInt(value) / 100f;
		} else if (command.equals("magicDefense")) {
			stat[AbstractEquipment.MAGIC_DEFENSE] = Integer.parseInt(value) / 100f;;
		} else if (command.equals("agility")) {
			stat[AbstractEquipment.AGILITY] = Integer.parseInt(value) / 100f;
		} else if (command.equals("evade")) {
			stat[AbstractEquipment.EVADE] = Integer.parseInt(value) / 100f;
		} else if (command.equals("hit")) {
			stat[AbstractEquipment.HIT] = Integer.parseInt(value) / 100f;
		} else if (command.equals("attack")) {
			stat[AbstractEquipment.ATTACK] = Integer.parseInt(value) / 100f;
		} else if (command.equals("magicAttack")) {
			stat[AbstractEquipment.MAGIC_ATTACK] = Integer.parseInt(value) / 100f;
		} else if (command.equals("supportAttack")) {
			stat[AbstractEquipment.SUPPORT_ATTACK] = Integer.parseInt(value) / 100f;
		} else if (command.equals("price")) {
			stat[AbstractEquipment.PRICE] = Integer.parseInt(value);
		} else if (command.equals("name")) {
			o = Organizer.convertKeepCase(value);
		} else if (command.equals("slots")) {
			String[] v = value.split(":");
			if (!(v.length == 1 && v[0].equals("_"))) {
				int[] slots = new int[v.length];
				for (int i = 0; i < v.length; i++) {
					slots[i] = Integer.parseInt(v[i]);
				}
				o = slots;
			} else {
				o = new int[0];
			}
		}
		return o;
	}
}

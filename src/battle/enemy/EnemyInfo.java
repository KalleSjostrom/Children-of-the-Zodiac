package battle.enemy;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import battle.enemy.AttackInfo.Frame;

public class EnemyInfo {
	
	public static final int SCALE = 0;
	public static final int HEIGHT = 1;
	public static final int DEPTH = 2;
	public static final int X_OFFSET = 3;
	public static final int MIDDLE_POINT = 4;
	public static final int INFO_SIZE = 5;
	
	private HashMap<String, AttackInfo> attack = new HashMap<String, AttackInfo>();
	
	private float[] info = new float[INFO_SIZE];
	
	public void set(int index, float value) {
		info[index] = value;
	}

	public void setAttack(
			String name, float power, 
			int type, int element, boolean isAll, float probability, 
			ArrayList<Frame> frames, int target) {
		attack.put(name, new AttackInfo(name, power, type, element, isAll, probability, frames, target));
	}
	
	public void setAttack(AttackInfo attackInfo) {
		attack.put(attackInfo.getName(), attackInfo);
	}

	public float get(int index) {
		return info[index];
	}
	
	public AttackInfo getAttackInfo(String name) {
		return attack.get(name);
	}

	public AttackInfo getRandomAttack(int type) {
		ArrayList<AttackInfo> list = new ArrayList<AttackInfo>();
		Iterator<String> it = attack.keySet().iterator();
		while (it.hasNext()) {
			AttackInfo ai = attack.get(it.next());
			if (ai.getType() == type) {
				list.add(ai);
			}
		}
		float p = 0;
		float r = (float) Math.random();
		int index = 0;
		boolean found = false;
		for (int i = 0; i < list.size() && !found; i++) {
			p += list.get(i).getProbability();
			if (found = r <= p) {
				index = i;
			}
		}
		return list.get(index);
	}
	
	public AttackInfo getAttack(String name) {
		Iterator<String> it = attack.keySet().iterator();
		while (it.hasNext()) {
			AttackInfo ai = attack.get(it.next());
			if (ai.getName().equals(name)) {
				return ai;
			}
		}
		new IllegalArgumentException("This enemy does not have the attack \"" + name + "\" (Attack list: " + attack + ")").printStackTrace();
		return null;
	}
	
	public String toString() {
		return attack.toString();
	}
}

package settings;

import java.util.HashMap;
import java.util.Iterator;

import particleSystem.drawable.SystemDrawable;
import particleSystem.equations.VectorEquation;


import bodies.Vector3f;

public abstract class Settings implements Cloneable {

	public static final int FALSE = 0;
	public static final int TRUE = 1;
	
	private HashMap<Integer, Setting> settings = new HashMap<Integer, Setting>();
	private String name;
	
	public void setName(String name) {
		this.name = name;
	}
	
	public String getName() {
		return name;
	}
	
	public Iterator<Integer> iterator() {
		return settings.keySet().iterator();
	}
	
	public boolean getBoolean(int i) {
		return get(i).value == TRUE ? true : false;
	}
	
	public String getString(int i) {
		return get(i).string;
	}
	
	public Vector3f getVector(int i) {
		return get(i).vector;
	}
	
	public Vector3f getVector(int i, Vector3f defaultVector) {
		Vector3f v = getVector(i);
		if (v == null) {
			v = defaultVector;
		}
		return v;
	}

	public float getValue(int i) {
		return get(i).value;
	}
	
	public VectorEquation getVectorEquation(int i) {
		return get(i).vectorEquation;
	}
	
	public void setBoolean(int i, boolean b) {
		get(i).value = b ? TRUE : FALSE;
	}
	
	public void setString(int i, String s) {
		get(i).string = s;
	}

	public void setValue(int i, float v) {
		get(i).value = v;
	}

	public void setVector(int i, float x, float y, float z) {
		setVector(i, new Vector3f(x, y, z));
	}
	
	public void setVector(int i, Vector3f vec) {
		get(i).vector = vec;
	}

	public void setVector(int i, float[] pos) {
		setVector(i, pos[0], pos[1], pos[2]);
	}
	
	public void setVector(int i, int[] pos) {
		setVector(i, pos[0], pos[1], pos[2]);
	}
	
	public void setVectorEquation(int i, VectorEquation ve) {
		get(i).vectorEquation = ve;
	}
	
	public void setSystemDrawable(int i, SystemDrawable ve) {
		get(i).systemDrawable = ve;
	}
		
	private Setting get(int i) {
		Setting s = settings.get(i);
		if (s == null) {
			s = new Setting();
			settings.put(i, s);
		}
		return s;
	}
	
	public Settings clone() {
		HashMap<Integer, Setting> sett = new HashMap<Integer, Setting>();
		Iterator<Integer> it = settings.keySet().iterator();
		while (it.hasNext()) {
			Integer key = it.next();
			sett.put(key, settings.get(key).copy());
		}
		Settings s = null;
		try {
			s = (Settings) super.clone();
			s.name = name;
			s.settings = sett;
		} catch (CloneNotSupportedException e) {
			e.printStackTrace();
		}
		return s;
	}
	
	private class Setting {
		private SystemDrawable systemDrawable;
		private VectorEquation vectorEquation;
		private float value;
		private Vector3f vector;
		private String string;
		
		public Setting copy() {
			Setting s = new Setting();
			s.systemDrawable = systemDrawable;
			s.vectorEquation = vectorEquation;
			s.value = value;
			s.vector = vector == null ? null : vector.clone();
			s.string = string;
			return s;
		}
	}
}

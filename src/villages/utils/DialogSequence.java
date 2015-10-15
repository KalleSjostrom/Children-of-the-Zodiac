/*
 * Classname: DialogSequense.java
 * 
 * Version information: 0.7.0
 *
 * Date: 02/02/2008
 */
package villages.utils;

import java.util.HashMap;

/**
 * This class represents a sequence in a dialog.
 * The text to be displayed.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 2 Feb 2008
 */
public class DialogSequence {

	protected String firstLine;
	protected String secondLine;
	protected String name;
	protected String[] alternatives;
	protected boolean question;
	protected boolean first = true;
	protected boolean whisper;
	protected boolean end = false;
	protected boolean inputQ;
	
	private Loot gift;
	private HashMap<String, Integer> triggers;
	private HashMap<String, Integer> triggerAdds;
	private HashMap<String, Integer> beforeTriggers;
	private String imageName;

	public boolean image;
	public int questionNr;
	public int[] prices = new int[4];
	public String takeName;
	public int takeAmount;
	
	/**
	 * Creates a new DialogSequense with the given parameters.
	 * 
	 * @param n the name of the person that talks.
	 * @param fl the first line of text.
	 * @param sl the second line of text.
	 * @param f true, if it is the first (often the villager) 
	 * person that talks.
	 * @param q true, if it is a question.
	 * @param w true if the dialog should write what someone whispers.
	 */
	public DialogSequence(
			String n, String fl, String sl, boolean f, boolean q, boolean w) {
		name = n.trim();
		firstLine = fl.trim();
		secondLine = sl.trim();
		first = f;
		question = q;
		whisper = w;
	}
	
	public DialogSequence(
			String n, String fl, String sl, boolean f, boolean w) {
		this(n, fl, sl, f, false, w);
	}
	
	/**
	 * Creates a new DialogSequense with the given parameters.
	 * 
	 * @param fl the first line of text.
	 * @param sl the second line of text.
	 */
	public DialogSequence(String fl, String sl) {
		firstLine = fl;
		secondLine = sl;
	}
	
	public DialogSequence(String[] dialog) {
		int i = 0;
		if (dialog.length > 2) {
			name = dialog[i++];
		}
		firstLine = dialog[i++];
		secondLine = dialog[i];
	}

	public String getName() {
		return name;
	}

	/**
	 * Sets the list of alternatives to this dialog sequence. This is
	 * used when a villager asks the player for anything. The correct 
	 * value is the index of the correct alternative in the list.
	 *  
	 * @param alt the list of alternatives.
	 * @param correct the correct alternative.
	 */
	public void setAlternatives(String[] alt) {
		alternatives = alt;
	}
	
	public void setEsnd(boolean end) {
		this.end = end;
	}
	
	public String toString() {
		return firstLine + "\n" + secondLine;
	}

	public void setGift(Loot gift) {
		this.gift = gift;
	}

	public Loot getGift() {
		return gift;
	}

	public void setTriggers(HashMap<String, Integer> triggers) {
		this.triggers = triggers;
	}

	public HashMap<String, Integer> getTriggers() {
		return triggers;
	}
	
	public void setTriggerAdds(HashMap<String, Integer> t) {
		this.triggerAdds = t;
	}

	public HashMap<String, Integer> getTriggerAdds() {
		return triggerAdds;
	}
	
	public void setBeforeTriggers(HashMap<String, Integer> t) {
		this.beforeTriggers = t;
	}
	
	public HashMap<String, Integer> getBeforeTriggers() {
		return beforeTriggers;
	}
	
	public void setQuestionNr(int questionNr) {
		this.questionNr = questionNr;
	}

	public void setInputQ(boolean b) {
		inputQ = b;
	}
	
	public boolean isInputQ() {
		return inputQ;
	}

	public void setImage(String imageName) {
		image = true;
		this.imageName = imageName;
	}
	
	public String getImage() {
		return imageName;
	}

	public int[] getPrices() {
		return prices;
	}

	public void setTake(String takeName, int takeAmount) {
		this.takeName = takeName;
		this.takeAmount = takeAmount;
	}
}

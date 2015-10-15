/*
 * Classname: DialogPackage.java
 * 
 * Version information: 0.7.0
 *
 * Date: 08/10/2008
 */
package villages.villageStory;

import java.util.ArrayList;

import villages.utils.DialogSequence;

/**
 * This class contains a list of dialog sequence with a start and stop time.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 08 Oct 2008
 */
public class DialogPackage {

	private ArrayList<DialogSequence> sequense;
	private int startTime;
	private int stopTime;
	private String name;

	/**
	 * Creates a new dialog package containing a list of dialog sequence 
	 * with the given start and end time.
	 * 
	 * @param name 
	 * @param start the time to initiated the dialog sequence.
	 * @param stop the time to stop the dialog sequence.
	 */
	public DialogPackage(String name, int start, int stop) {
		this.name = name;
		sequense = new ArrayList<DialogSequence>();
		startTime = start;
		stopTime = stop;
	}

	public DialogPackage() {
		sequense = new ArrayList<DialogSequence>();
	}

	/**
	 * Stores a dialog sequence in this package. 
	 * 
	 * @param ds the dialog sequence to store.
	 */
	public void add(DialogSequence ds) {
		sequense.add(ds);
	}

	/**
	 * Gets the dialog sequences in this package. 
	 * 
	 * @return the list of dialog sequences.
	 */
	public ArrayList<DialogSequence> getSequense() {
		return sequense; 
	}
	
	/**
	 * Gets the start time for this sequence package.
	 * 
	 * @return the start time for this package.
	 */
	public int getStartTime() {
		return startTime;
	}

	/**
	 * Gets the stop time for this sequence package.
	 * 
	 * @return the stop time for this package.
	 */
	public int getStopTime() {
		return stopTime;
	}
	
	public String getName() {
		return name;
	}
}
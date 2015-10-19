/*
 * Classname: Resurrect.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.support;

import java.util.ArrayList;

import info.SoundMap;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import particleSystem.equations.Line;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.SupportCard;
import character.Character;
import character.Creature;
import factories.Load;

/**
 * The resurrect card is played to resurrect a dead target. 
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class Resurrect extends SupportCard {
	
	private static final String[] SHORT_INFO = {"Resurrects + cures hp", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_RESURRECT};
	private static final int[] DELAYS = {0};
	

	/**
	 * This method is called to calculate the effect of a "Resurrect"-card
	 * being used by the attacker on the given target. This card will
	 * resurrect the target, if the target is an instance of Character and
	 * if the target is alive.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @return the HitElement containing the information about the attack.
	 */
	public HitElement use(Creature target, Character attacker) {
		String mess = "";
		boolean miss = true;
		if (target instanceof Character) {
			Character c = (Character) target;
			miss = c.isAlive();
			if (!miss) {
				mess = "Resurrected!";
			}
			c.cureFromDead();
		}
		HitElement he;
		if (miss) {
			he = new HitElement(this, -1, HitElement.MISS, "");
		} else {
			he = cure(attacker, mess);
		}
		return he;
	}

	/**
	 * Creates the attack percent. This is the amount of percent that this card
	 * should boost the attackers attack. If the attacker attacks with say 17 
	 * in attack and the attack percent is 140 % (1.4f). The attack will be a
	 * total of 23.8 => 24. The created percent is not, however, a single value
	 * but three. One for each level of the card. So a normal battle card could
	 * have 120 % boost for level 1, 160 % boost for level 2 and 300 % boost 
	 * for level 3, for example.
	 * 
	 * In this case, this percentage is the amount to cure with after the 
	 * actual resurrect.
	 *  
	 * @return the list of attack percentage.
	 */
	protected float[] createAttackPercent() {
		return RESURRECT_CURE;
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	protected String[] createTextInfo() {
		return new String[]{
				"The power of resurrection lays within grasp. Mighty forces of the",
				"heavens will be called upon to aid the passed friend of the wielder.",
				"Life is returned to those who lost it when battling a powerful foe."};
	}
	
	protected void createShortInfo() {
		setShortInfo("Brings life to the dead");
		setShortInfo("Cure power " + Math.round(getAttackPercent() * 100) + " %");
	}

	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}
	
	@Override
	protected String[] getSoundEffect() {
		return SOUNDS;
	}

	@Override
	protected int[] getSoundEffectDelay() {
		return DELAYS;
	}
	
	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		return Resurrect.getStaticAnimation(info);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefault();
		
		settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DEAD);
		if (!info.isOnEnemy()) {
			if (info.isOnAll()) {
				ArrayList<Character> list = Load.getCharacters();
				for (int i = 0; i < list.size(); i++) {
					Character c = list.get(i);
					if (!c.isAlive()) {
						Cure.addTargetToSettings(i, settings);
						Cure.addToSystemPacket(psp, settings);
					}
				}
			} else {
				if (!Load.getCharacters().get(info.getTarget()).isAlive()) {
					Cure.addTargetToSettings(info.getTarget(), settings);
					Cure.addToSystemPacket(psp, settings);
				}
			}
		} else {
			float x = -.4f;
			float y = -.6f;
			settings.setVector(AnimSettings.SOURCE, new Vector3f(x, y, -2f));
			settings.setVector(AnimSettings.TARGET, new Vector3f(0, y + 2, -2f));
			Line l = new Line(settings.getVector(AnimSettings.SOURCE), .8f);
			settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, l);
			Cure.addToSystemPacket(psp, settings);
		}
		return psp;
	}
}

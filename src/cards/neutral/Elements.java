/*
 * Classname: Elements.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.neutral;

import particleSystem.EnemySystem;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import cards.AnimationSettingsFactory;
import cards.Card;
import cards.support.Cure;
import character.Character;
import character.Creature;

/**
 * This class combines the shared price grouping for the change element cards.
 * All these cards should have the same price regardless of element.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public abstract class Elements extends Card {
	
	public static final String TEXT = "Elem Change!";
	private static final String[] SHORT_INFO = {"Changes targets element", ""};

	/**
	 * This method is called to calculate the effect of a "Change attribute"-
	 * card being used by the attacker on the given target. This card will
	 * temporarily change the element attribute of the target. The attacker
	 * is not important when casting this card.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the character who is attacking.
	 * @return the HitElement containing the information about the attack.
	 */
	public HitElement use(
			Creature target, Character attacker) {
		return Card.checkPreferences(target, attacker, this, TEXT, true);
	}
	
	/**
	 * This method returns null because this card does not have any attack
	 * percentage, so this method should not be called.
	 * 
	 * @return null this card does not have an attack percent.
	 */
	protected float[] createAttackPercent() {
		return null;
	}
	
	protected void createShortInfo() {
		String elem = "";
		switch (element) {
		case Card.FIRE_ELEMENT : elem = "fire"; break;
		case Card.ICE_ELEMENT : elem = "ice"; break;
		case Card.WIND_ELEMENT : elem = "wind"; break;
		case Card.EARTH_ELEMENT : elem = "earth"; break;
		}
		setShortInfo("Changes the targets element to " + elem);
	}
	
	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}
	
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		if (info.isOnEnemy()) {
			AnimSettings settings = AnimationSettingsFactory.getDefaultNoFade();
			settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DELAYED);
			settings.setValue(AnimSettings.READY_MODE_DELAY_TIME, 500);
			settings.setValue(AnimSettings.SPEED, 12);
			settings.setValue(AnimSettings.COLOR, element);
			
			EnemySystem es = new EnemySystem(settings, info.getEnemy());
			psp.add(es, 0);
		} else {
			return Cure.getStaticAnimation(info);
		}
		return psp;
	}
	
	public boolean canBeMerged() {
		return false;
	}
}

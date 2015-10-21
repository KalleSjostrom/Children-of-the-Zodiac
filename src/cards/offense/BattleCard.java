/*
 * Classname: BattleCard.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.offense;

import info.SoundMap;
import info.Values;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import particleSystem.drawable.SwordBackground;
import settings.AnimSettings;
import sound.SoundPlayer;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;
import character.Character;
import character.Creature;

/**
 * The battle card is the most basic of physical attacking cards. It has
 * nothing special about it. 
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class BattleCard extends Card {
	
	private static final String[] SHORT_INFO = {"Attack", ""};
	static final String[] SOUNDS = {
		SoundMap.BATTLE_ATTACK_KIN, SoundMap.BATTLE_ATTACK_CELIS,
		SoundMap.BATTLE_ATTACK_BOREALIS, SoundMap.BATTLE_ATTACK_ZALZI
	};
	private int lastAttacker;
	
	/**
	 * This method is called to calculate the effect of a "Battle"-card
	 * being used by the attacker on the given target. This card will
	 * damage the target.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the character who is attacking.
	 * @return the HitElement containing the information about the attack.
	 */
	@Override
	public HitElement use(Creature target, Character attacker) {
		return attack(target, attacker);
	}

	/**
	 * Creates the attack percent. This is the amount of percent that this card
	 * should boost the attackers attack. If the attacker attacks with say 17 
	 * in attack and the attack percent is 140 % (1.4f). The attack will be a
	 * total of 23.8 => 24. The created percent is not, however, a single value
	 * but three. One for each level of the card. So a normal battle card could
	 * have 120 % boost for level 1, 160 % boost for level 2 and 300 % boost for 
	 * level 3, for example.
	 *  
	 * @return the list of attack percentage.
	 */
	@Override
	protected float[] createAttackPercent() {
		return STANDARD_ATTACK;
	}
	
	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	@Override
	protected String[] createTextInfo() {
		return new String[]{
				"This card is often found in every adventurers deck. It is",
				"the fundamental part of any deck because of its cheapness",
				"and versatilely of not beeing bound by an element."};
	}
	
	@Override
	protected void createShortInfo() {
		setShortInfo("Power: " + Math.round(getAttackPercent() * 100) + " %");
	}

	@Override
	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}
	
	public void playSound() {
		String s = SOUNDS[lastAttacker];
		int[] i = getSoundEffectDelay();
		playBattleSound(s, i[0]);
	}
	
	public static void playBattleSound(final String effect, final int delay) {
		if (delay > 0) {
			new Thread() {
				public void run() {
					Values.sleep(delay);
					SoundPlayer.playSoundWithRandom(effect, 2);
				}
			}.start();
		} else {
			SoundPlayer.playSoundWithRandom(effect, 2);
		}
	}
	
	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		Character attacker = info.getAttacker();
		if (attacker != null) {
			lastAttacker = attacker.getIndex();
		}
		return BattleCard.getStaticAnimation(info);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		
		psp.add(new ParticleSystem(getDefaultBattleCardSettings(info.getLevel())), 0);
		if (info.getAttacker().getName().equals("Zalzi")) {
			psp.add(new ParticleSystem(getDefaultBattleCardSettings(info.getLevel())), 280);
		}
		return psp;
	}
	
	public static AnimSettings getDefaultBattleCardSettings(int level) {
		AnimSettings settings = AnimationSettingsFactory.getDefaultSword();
		Vector3f source = settings.getVector(AnimSettings.SOURCE);
		Vector3f targetvec = settings.getVector(AnimSettings.TARGET);
		
//		int level = 3; // new Random().nextInt(3)+1;
		float size = 0;
		switch (level) {
		case 1:
			settings.setValue(AnimSettings.EMITTANCE_PERIOD, .024f);
			size = .5f;
			break;
		case 2:
			settings.setValue(AnimSettings.EMITTANCE_PERIOD, .022f);
			size = .6f;
			break;
		case 3:
			settings.setValue(AnimSettings.EMITTANCE_PERIOD, .02f);
			size = .7f;
			break;
		default:
			break;
		}
		
		source.x = (float) (Math.random() - .5f) * size;
		source.y = (float) Math.random();
		source.y -= 1;
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, .08f);

		targetvec.x = source.x + (source.x <= 0 ? size : -size);
		targetvec.y = source.y + (source.y <= 0 ? size : -size);
		Vector3f st = source.subtract(targetvec);
		float l = st.length() / 2f;
		source.addLocal(st.mult(l));
		targetvec.subtractLocal(st.mult(l));
		SwordBackground sb = new SwordBackground(source, targetvec);
		settings.setSystemDrawable(AnimSettings.SYSTEM_DRAWABLE, sb);
		return settings;
	}
}

/*
 * Classname: SpiritAssult.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.offense;

import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import particleSystem.equations.CircularWave;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;
import character.Character;
import character.Creature;

/**
 * The spirit assault will damage then enemy with the power of the dead.
 * If any of the party members are dead, there offensive powers will be added
 * to the caster of this card.
 * 
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class ChameleonStrike extends Card {
	
	private static final String[] SHORT_INFO = {
		"Attack using the element", "opposite the enemy's element"};
	private int lastAttacker;

	/**
	 * The spirit assault will damage then enemy with the power of the dead.
	 * If any of the party members are dead, there offensive powers will be added
	 * to the caster of this card.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
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
		return STANDARD_ATTACK_HIGH;
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
				"As the chameleon changes appearance after environment, this card changes",
				"its element depending on target. It can swiftly turn into flames or frosty",
				"ice, blow a gale or shake the ground. Their strenght is turned to weakness."};
	}
	
	@Override
	protected void createShortInfo() {
		setShortInfo("Power: " + Math.round(getAttackPercent() * 100) + " %");
		setShortInfo("Attacks with the element opposite the enemy's element");
	}

	@Override
	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}
	
	public void playSound() {
		String s = BattleCard.SOUNDS[lastAttacker];
		BattleCard.playBattleSound(s, 800);
	}

	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		Character attacker = info.getAttacker();
		if (attacker != null) {
			lastAttacker = attacker.getIndex();
		}
		return ChameleonStrike.getStaticAnimation(info);
	}

	private static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = BattleCard.getDefaultBattleCardSettings(info.getLevel());
		
		float cutSize = 0;
		float particleSize = 0;
		switch (info.getLevel()) {
		case 1:
			cutSize = .5f;
			particleSize = .1f;
			break;
		case 2:
			cutSize = .7f;
			particleSize = .2f;
			break;
		case 3:
			cutSize = .9f;
			particleSize = .3f;
			break;
		}
		settings.setVector(AnimSettings.TARGET, new Vector3f(cutSize, cutSize, -6));
		settings.setVector(AnimSettings.SOURCE, new Vector3f(-cutSize, -cutSize, -6));
		psp.add(new ParticleSystem(settings), 800);
		
		AnimSettings def = AnimationSettingsFactory.getDefault();
		def.getVector(AnimSettings.SOURCE).z = 0;
		def.setValue(AnimSettings.SIZE, particleSize);
		def.setValue(AnimSettings.SPEED, 15f);
		def.setVector(AnimSettings.TARGET, new Vector3f(0, 0, -14));
		def.setVector(AnimSettings.SOURCE, new Vector3f(0, 0, -6));
		float period = .225f * 3;
		float radius = .25f;
		
		settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DESTROYED);
		
		settings = AnimationSettingsFactory.getCircleWave(def, FIRE_ELEMENT, 0);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, .006f);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .006f);
		Card.setSourceTargetVectorToLength(14, settings);

		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE);
		settings.setVector(AnimSettings.GRAVITY, new Vector3f(0, .001f, 0));
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, .12f);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, .03f);
		settings.setValue(AnimSettings.NR_PARTICLES, 600);
		
		CircularWave wave = new CircularWave(period, radius * 3, 0, false, true, -6);
		settings.setValue(AnimSettings.COLOR, FIRE_ELEMENT);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 0);
		
		wave = new CircularWave(period, radius * 2.5f, (float) Math.PI / 2, false, true, -6);
		settings.setValue(AnimSettings.COLOR, EARTH_ELEMENT);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 0);
		
		wave = new CircularWave(period, radius * 2, (float) Math.PI, false, true, -6);
		settings.setValue(AnimSettings.COLOR, WIND_ELEMENT);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 0);
		
		wave = new CircularWave(period, radius * 1.5f, 3 * (float) Math.PI / 2f, false, true, -6);
		settings.setValue(AnimSettings.COLOR, ICE_ELEMENT);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 0);
		return psp;
	}
}

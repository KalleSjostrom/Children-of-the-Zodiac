/*
 * Classname: Ice.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.magic;

import info.SoundMap;
import info.Values;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import settings.AnimSettings;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;

/**
 * This class represents the Ice magic in the game. The Ice magic 
 * is a basic magic with ice attribute.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class Ice extends Magic {
	
	private static final String[] SHORT_INFO = {"Ice magic", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_ICE, SoundMap.MAGICS_ICE, SoundMap.MAGICS_ICE};
	private static final int[] DELAYS = {295, 200, 200};
	
	/**
	 * This method sets the element to ice.
	 */
	@Override
	protected void setElement() {
		element = ICE_ELEMENT;
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
				"A violent frost is not enough to describe the icy coldness of this",
				"magic card. This artic magic will freeze the target upon collision",
				"destroying, with ease, a firey defense."};
	}

	@Override
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
		info.setLevel(getLevel());
		return Ice.getStaticAnimation(info);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
//		int level = new Random().nextInt(3) + 1;
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefault();
		
		if (!info.isOnEnemy()) {
			Vector3f source = info.getEnemy().getTempSource();
			settings.setVector(AnimSettings.TARGET, new Vector3f(0, -.5f, -1.1f));
			settings.setVector(AnimSettings.SOURCE, source == null ? new Vector3f(0, 0, -6) : source);
			settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z);
		} else {
			
		}
		
		settings.setValue(AnimSettings.SPEED, 5);
		settings.setValue(AnimSettings.COLOR, ICE_ELEMENT);
		
		settings.setValue(AnimSettings.NR_PARTICLES, 200);
		settings.setValue(AnimSettings.EMITTANCE_PERIOD, .1f);
		
		settings.setValue(AnimSettings.NR_TEXTURES, 7);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.JITTER_1);
		settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.JITTER_2);
		settings.setValue(AnimSettings.NR_TEXTURES + 3, ParticleSystem.JITTER_3);
		settings.setValue(AnimSettings.NR_TEXTURES + 4, ParticleSystem.JITTER_4);
		settings.setValue(AnimSettings.NR_TEXTURES + 5, ParticleSystem.JITTER_2_45);
		settings.setValue(AnimSettings.NR_TEXTURES + 6, ParticleSystem.JITTER_3_45);
		settings.setValue(AnimSettings.NR_TEXTURES + 7, ParticleSystem.JITTER_4_45);
		
		Card.setSourceTargetVectorToLength(6, settings);
		psp.add(new ParticleSystem(settings), 0);
		if (info.getLevel() > 1) {
			settings.getVector(AnimSettings.SOURCE).x -= .3f;
			settings.getVector(AnimSettings.SOURCE).y += .3f;
			settings.getVector(AnimSettings.TARGET).x -= .3f;
			settings.getVector(AnimSettings.TARGET).y += .3f;
			psp.add(new ParticleSystem(settings), 200);
		}
		if (info.getLevel() > 2) {
			settings.getVector(AnimSettings.SOURCE).x += .5f;
			settings.getVector(AnimSettings.SOURCE).y += .2f;
			settings.getVector(AnimSettings.TARGET).x += .5f;
			settings.getVector(AnimSettings.TARGET).y += .2f;
			psp.add(new ParticleSystem(settings), 400);
		}
		return psp;
	}
}

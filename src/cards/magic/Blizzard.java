/*
 * Classname: Blizzard.java
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
import sound.SoundPlayer;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;

/**
 * This class represents the Blizzard magic in the game. A Blizzard is a strong
 * version of the ice magic.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class Blizzard extends PowerMagic {
	
	private static final String[] SHORT_INFO = {"Powerful ice magic", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_BLIZZARD, SoundMap.MAGICS_BLIZZARD, SoundMap.MAGICS_BLIZZARD,
		SoundMap.MAGICS_BLIZZARD, SoundMap.MAGICS_BLIZZARD, SoundMap.MAGICS_BLIZZARD};
	private static final int[] DELAYS = {1, 200, 200, 200, 200, 200};
	

	public void playSound() {
		final int[] soundEffectDelay = getSoundEffectDelay();
		final String[] soundEffect = getSoundEffect();
		final int size = soundEffectDelay.length;
		boolean found = false;
		for (int i = 0; i < size && !found; i++) {
			found = soundEffectDelay[0] > 0;
		}
		if (found) {
			new Thread() {
				public void run() {
					for (int i = 0; i < size; i++) {
						Values.sleep(soundEffectDelay[i]);
						SoundPlayer.playSound(soundEffect[i]);
					}
				}
			}.start();
		} else {
			for (int i = 0; i < size; i++) {
				SoundPlayer.playSound(soundEffect[i]);
			}
		}
	}
	
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
				"Razor sharp ice crystals rains heavely from the sky whilst the cold",
				"paralyzes the enemies. This blizzard bears the names of Cancer,",
				"Scorpius and Pisces and will exhaust even the largest of fires."};
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
		return Blizzard.getStaticAnimation(info);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefault();
		settings.setVector(AnimSettings.SOURCE, 
				new Vector3f((float) (.5f + Math.random() * 2), 3, -5.9f));
		settings.setValue(AnimSettings.SPEED, 6);
		settings.setValue(AnimSettings.COLOR, ICE_ELEMENT);
		settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Y_LESS_TARGET_Y);
		
		if (!info.isOnEnemy()) {
			settings.getVector(AnimSettings.TARGET).z = -2;
			settings.getVector(AnimSettings.TARGET).y = -1f;
		}
		
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

		psp.add(new ParticleSystem(settings), 0);
		psp.add(new ParticleSystem(settings), 600);
		settings.getVector(AnimSettings.SOURCE).x -= .3f;
		settings.getVector(AnimSettings.SOURCE).y += .3f;
		settings.getVector(AnimSettings.TARGET).x -= .3f;
		settings.getVector(AnimSettings.TARGET).y += .3f;
		psp.add(new ParticleSystem(settings), 200);
		psp.add(new ParticleSystem(settings), 800);
		settings.getVector(AnimSettings.SOURCE).x += .5f;
		settings.getVector(AnimSettings.SOURCE).y += .2f;
		settings.getVector(AnimSettings.TARGET).x += .5f;
		settings.getVector(AnimSettings.TARGET).y += .2f;
		psp.add(new ParticleSystem(settings), 400);
		psp.add(new ParticleSystem(settings), 1000);
		return psp;
	}
}

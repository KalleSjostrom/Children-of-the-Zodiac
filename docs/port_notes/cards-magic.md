# Port notes: cards-magic (`src/cards/*.gd`, `src/cards/magic`, `src/cards/neutral`)

I ported 18 skeleton files: BlackDeath, BlackUltima, Colliding, Death, Demolish,
Earth, Flame, SacredBeam, SerphiaDeath, Slow, SmallSacredBeam, Tornado, Ultima,
Elements, TheElementOfEarth/Fire/Ice/Wind. I did not change the files that were
already ported (AbstractCard, AnimationSettingsFactory, Card, SupportCard,
BlackFire, BlackWind, Blizzard, Fire, Flare, Ice, Magic, PowerMagic, Wind).
`tools/check.sh src/cards/*.gd src/cards/magic src/cards/neutral` reports
`CHECKED 31 scripts, 0 failed`.

## API notes for callers

- All class names, method names and signatures are the same as in the skeletons
  and Java. Each card has a static `getStaticAnimation(info)` that returns a
  `ParticleSystemPacket`. The exception is `Demolish.getStaticAnimation(info,
  demolished)`, which takes a second parameter, as in Java.
  `Demolish.getAlternativeStaticAnimation(nrTarget, target, onEnemy, onAll,
  enemy)` is also ported. It is unused, as in Java.
- `Demolish` calculates its effect in `getAnimation(info)` through `useBefore`.
  `use()` returns the `HitElement` calculated there. Battle code must therefore
  call `getAnimation` before `use`, as the Java battle code does.
- `Flame` is an unfinished card in the original. `use()` returns null,
  `createAttackPercent()` returns null and `createShortInfo()` does nothing.
  Only its animation (`FlameParticleSystem`) is real.
- `Death`/`BlackDeath`/`SerphiaDeath`/`Elements` return `null` from
  `createAttackPercent()`, as in Java. The kill cards deal damage equal to
  `target.getAttribute(Creature.HP)`.
- `Elements.getAnimation` uses `Cure.getStaticAnimation(info)` (cards.support)
  when the card is used on the party.
- These cards have no threads or sleeps. All delays are the packet delays in ms
  (`psp.add(system, delayMs)`), as in Java.

## Faithful oddities (not fixed)

- `BlackUltima.randomTarget(t)` returns a copy of `t` and *then* randomizes
  `t`. The first system therefore gets the unrandomized target. In
  `BlackUltima`, the interpolation info is calculated before TARGET is set, so
  it uses the default target.
- `Ultima`: `amlifier = max(random + 0.3, 1)` is always at least 1, as in Java.
- `Earth` on the party side sets SOURCE to `getTempSource()` with no null check.
  `BlackDeath`/`SerphiaDeath`/`Slow` (party side) dereference `getTempSource()`
  with no null check either. Both are the same as in Java.
- `SerphiaDeath` has the sound `""` (the real sound is commented out in Java).

## Local workarounds

- None needed. Java `switch` fall-through (Earth levels 3→2→1) is ported as
  chained `if` blocks, the same way as in `Fire.gd`.

## Already-ported files

- `Card.setShortInfo` and `AbstractCard.createSortingValue`/`createShortInfo`
  are `pass`. This matches Java (`setShortInfo` is commented out there).

## Cross-unit observations

- During checks, `src/battle/Clock.gd:8` reported a runtime static-initializer
  error: `Out of bounds get index '1'` on `Values.ORIGINAL_RESOLUTION[Values.X]`.
  The likely cause is a static-init order cycle: Values is not initialized yet
  when Clock loads. It did not fail any of my scripts. It belongs to the battle
  unit, which should make `DEFAULT_X_POS` lazy or move it to `_static_init`.

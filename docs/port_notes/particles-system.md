# Port notes: particles-system (`src/particleSystem/**`, 31 files)

All 31 files are fully ported; `tools/check.sh src/particleSystem` reports
`CHECKED 31 scripts, 0 failed`.

## API notes for callers

- Constructors follow the merged skeleton signatures:
  `XxxParticleSystem.new(settings[, enemy])`, `Particle.new(color, settings, body)`,
  `ParticleSystemPacket.new([useStartStop = true])`, `SaveSystem.new(x, z)`.
- `ParticleSystem.update(elapsedTime)` / `ParticleSystemPacket.update(elapsedTime)`:
  the time is in **seconds**, as in Java. The packet's delays are in ms
  (`delay - elapsed*1000`). Callers that get ms from the framework must divide
  by 1000, as the Java callers did.
- `ParticleSystemPacket.add(...)` is one merged method: `add(system, delay)`,
  `add(index, system, delay)` and `add()` (no args: sets `added`, returns true).
- `ParticleSystem.load()` (static, called by `factories.Load`) now really loads
  the particle texture names into `ParticleSystem.particleTexture`. Java did that in a
  static initializer. Here it runs lazily, from `load()` or the first constructor,
  so it never touches `ImageHandler` during script loading.
  `SaveSystem.particleTexture` also loads lazily, in its first constructor call.
- `ParticleSystem.BLEND_MODE_NO_BLEND` is `-1` as in Java. The skeleton had `1`,
  which was a generator bug.
- `ParticleSystem.InterpolationInfo` is the inner class (use
  `ParticleSystem.InterpolationInfo.new(ve, source, sourceToTarget, totalTime)`).
- Interfaces `VectorEquation` / `SystemDrawable` are duck-typed (implementations do
  not extend them).
- `ShatterParticleSystem.createParticle(c, settings)` with arguments creates a
  `Particle` with that color. Without arguments it uses the inherited `createParticle()`.

## Local workarounds / deviations

- `ParticleSystem.update`: Java's iterator loop with `it.remove()` is now an
  in-place compaction (`_updateParticles`, private helper). Order and counters stay
  the same, and the shared `particles` Array object is kept. The gravity force uses
  one reused temp `Vector3f`, not one per particle per frame.
  `p.addForce(null)` is skipped, because Java's `Vector3f.addLocal(null)` does nothing.
  `FlameParticleSystem.create` reuses the same helper for its duplicated loop.
- Threads: `ImageParticleSystem` / `SlowParticleSystem` fade/blink threads
  are coroutines (`_animate()` using `await Scheduler.sleep`, not awaited);
  `ParticleSystem.isReady` IS_DELAYED uses `Scheduler.after`.
- `ShatterEmitter` / `Flame2Emitter.getImage`: `Raster.getPixels` and the alpha raster
  are rebuilt with `Image.get_pixel` (r8/g8/b8/a8, rows stored bottom-up as in
  Java). `ShatterEmitter.enemyName` starts as `null`. Java never assigns it, so
  the image is always re-read, the same as in Java.
- `SaveSystem`: `Arrays.sort` is now `sort_custom` with an index tie-break, which
  gives a stable order.
- `SphereParticle`: the static GLU/quadric are not needed. It calls
  `g.gluSphere(quad, size, 50, 50)` on the Graphics object. 50x50 spheres per
  particle are expensive in the GL emulation (faithful, but a possible
  performance hotspot).

## Faithfully ported oddities (not fixed)

- `RandomWave.modifyVector` recurses forever, as in Java. It is never called
  (only `getVectorAfterTime` is used).
- `Flame2Emitter` / `ShatterEmitter`: when no opaque pixel is found, `continue` skips
  the time decrement and drops the popped particle, as in Java.
- `ParticleSystem.drawable` is never set (Java has no setter), so it is always null.

## Cross-unit observations

- During checks, `src/villages/VillageLoader.gd` failed to parse
  (`Identifier "Door" not declared`). That broke the first load of
  `ParticleSystem.gd`/`EnemySystem.gd` through the dependency chain
  (Values → Graphics → … → VillageLoader). Recompiling them on their own passed.
  This is the villages unit's issue.
- These files depend on the `bodies` port (`PointBody`, `Vector3f` overloads:
  `Vector3f.new(Vector3f)` copy, `add/subtract/mult(scalar)`, `normalize`,
  `normalizeLocal`, `multLocal`, `clone`, `distanceSquared`, `lengthSquared`), on
  `AnimSettings.getValue/getVector/getBoolean/getVectorEquation/clone`, and on
  `BattleEnemy.getInfo/getTempHeight/setScale/getCurrentImageName/shake/slice/
  cancelColorChange/setColor/getSourceColor`, plus `EnemyInfo.get_`.

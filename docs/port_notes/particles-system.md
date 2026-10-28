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

## Own random numbers (the battle effects phase, docs/ARCHITECTURE.md)

- Port deviation: the card and enemy effects draw from `ParticleSystem.rand` (a `JRandom`), not from J's shared
  generator (Java: `Math.random`): `Particle` (mass, size, noise, fades, the destroy kick, velocity), the gravity
  jitter in `ParticleSystem._updateParticles`, `getRandomVector`/`getRandomCircleVector`/`getRandomSphereVector`,
  `ParticleValues.getColor(COLOR_RANDOM)`, `Flame2Emitter`, `ShatterEmitter`, the equations `Line`, `RandomWave`,
  `WhirlWind`, and the effect positions the cards draw while building their systems
  (`AnimationSettingsFactory.getDefault`, `BattleCard`, `Blizzard`, `Earth`, `Ultima`, `BlackUltima`).
  `Main._init_deterministic` seeds it. Normal play does not change; a seeded run's battle draws (critical hits,
  `EnemyLogic`, drops) no longer depend on how many random numbers the effects use, so the GPU effects can replace
  the simulation without shifting them. `SaveParticle.rand` was already the save points' own.
- `--hide-particles` (`Main.hide_particles`, dev): `ParticleSystem.draw` and `ShatterParticleSystem.draw` draw no
  particles but set the same GL state (`Particle.place_particle`: the colour and the last texture coordinate of the
  quad). `SaveSystem.draw` / `place_particles` likewise. The sphere, image, slow and enemy systems are not hidden.

## Bridge to the GPU effects (the battle effects phase, docs/ARCHITECTURE.md section 11)

- `ParticleSystem.gpu_path()`: the systems drawn as particles (not `SphereParticleSystem`, `ImageParticleSystem`,
  `SlowParticleSystem`, `EnemySystem`) are drawn by `EffectParticles3D` (not with `--legacy=battle_effects`). Such a
  system (`gpu`) keeps its logic with a smaller pool (`reduce_for_waits`: at most `GPU_WAIT_PARTICLES` = 64, the time
  step longer and isDead's limit smaller by the same factor; not for `FlareEmitter`, whose 400 particles its destroy
  counts, nor for an isDeadLimit of 0 up to 256 particles; not with `--legacy=effect_waits`). Its draw makes the same
  GL state changes without quads (`Particle.place_particle`) and hands its node the state (`show_gpu`, `gpu_state`,
  `gpu_settings`, `_gpu_points`, `_equation_uniforms`). Bridge members: `gpu`, `gpu_amount`, `gpu_emit_step` (the
  legacy pool and step, which the GPU draws), `gpu_seed` (from `gpu_rand`), `gpu_age`, `gpu_stepped`, `gpu_elapsed`,
  `gpu_destroys`, `gpu_plains`, `gpu_kills`, `gpu_preprocess`, `gpu_shown`.
- `ParticleSystemPacket.update` adds every frame's elapsed time to its started GPU systems (`gpu_elapsed`,
  `gpu_age`) before its 30 Hz steps.
- `destroy`, `plainDestroy` and `kill` count their calls; `update` counts the time it stepped.
- `FlameParticleSystem.create` skips the 200-step pre-run on the GPU path (`gpu_preprocess` warms the GPU system up
  instead), not with `--legacy=effect_waits`.
- `ShatterParticleSystem.draw`: the same GPU branch.
- `ParticleSystem.gpu_rand` (`JRandom.new(0)`): the GPU systems' seeds. Main seeds it from a hash of `--seed`, not
  from `J.nextSeed()`: that would shift every later unseeded `JRandom` (encounter steps, battles) against the
  goldens.
- `SaveSystem`: on the GPU path (`WeatherSystem.gpu_path`) no particles and no warm-up; `update` counts, and
  `place_particles` returns the state of `SaveParticles3D` (`place_gpu`; the GL colour stays: the last particle's is
  not known, lit objects ignore it and the weather sets its own). Bridge members: `gpu`, `gpu_seed` (from
  `SaveParticle.rand`), `gpu_center` (the static `pos` is shared by every save point), `gpu_updates`.

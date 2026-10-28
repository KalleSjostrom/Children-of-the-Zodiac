# Port notes: particles-bodies (`bodies`, `commands`)

32 files ported (`src/bodies/**`, `src/commands/*`). `tools/check.sh src/bodies src/commands`:
`CHECKED 32 scripts, 0 failed`.

## API notes for callers

- Class names (from class_map): `bodies.emitter.Emitter` -> `BodiesEmitter`,
  `bodies.particles.Particle` -> `BodiesParticle`, `bodies.particles.SnowParticle` -> `BodiesSnowParticle`,
  `bodies.particles.ParticleValues` -> `BodiesParticleValues`, `bodies.system.ParticleSystem` -> `BodiesParticleSystem`.
- `Vector3f` is a mutable `RefCounted` with typed `float` fields `x/y/z` that is shared by reference, as in Java.
  Merged overloads dispatch on the argument types:
  - `set_(Vector3f)`, `set_(x, y, z)`, `set_(index, value)`: two arguments means the index form.
  - `add/subtract(vec[, result])` or `(fx, fy, fz)`.
  - `mult(scalar|vec[, store])`, `multLocal/divide/divideLocal(scalar|vec)`.
  - `cross(v[, result])` or `(x, y, z, result)`.
  - `interpolate(final, amount)` or `(begin, final, amount)`; `scaleAdd(s, add)` or `(s, mult, add)`.

  `ZERO`, `UNIT_*` are created in `_static_init`. `clone()` returns a new vector. `get_(i)` replaces Java `get`,
  and `str(v)` gives `"(x, y, z)"`. `readExternal`/`writeExternal` use `get_float`/`store_float` (FileAccess) or `put_float`.
- `AbstractEmitter.emitFrom(pool = null, master = null)` merges three methods:
  - `emitFrom()`: the abstract method. It returns true when the pool is empty.
  - `emitFrom(Array pool, Body master)`.
  - `emitFrom(Body b, EmitterShape warmer)`.

  The subclasses `BodiesEmitter` and `MasterSlaveEmitter` override only the no-argument form and pass the other forms to `super`.
- `Body.draw(g, t, pPos)` draws only when `t is GameTexture`. Otherwise it is the empty Java `draw(g, int x, int y)`.
  `Body.setColor(c, a)` ignores `a`, because Java only has `setColor(Vector3f)`.
- `PointBody.update(elapsedTime, body = null)`: `body` is ignored. Particle/emitter `update` receive **seconds**
  (ParticleSystem divides the ms value by 1000, as in Java). `BodiesParticleSystem.update(f)` takes ms.
- `BodiesParticleSystem`: `warmUp()` is the method and `warmUp_` is the field. `draw(g)` (one argument) goes through
  `Sprite.draw` -> `drawSprite` -> `drawIt`; `draw(g, x, y)` sets the system position first. `setWind(force, turbulence)`
  is static. `WindCommand.setForce` keeps the given Vector3f by reference, as in Java.
- `SystemLoader.getLoader()` parses `Values.ParticleSystemsMaps + "particleSystems.info"` through `AbstractMapLoader`
  (GameResourceLoader). `parseFile(name)` with one argument is the Java `parseFile(String fileName)`.
  `buildSystem(name)` returns an Array of `BodiesParticleSystem`.
- New local helper `SystemLoader.settingKeys(settings) -> Array`: the keys of a `Settings` in ascending order, which is
  the order of Java's `HashMap<Integer,…>` keySet. It accepts a Java-style iterator, an Array or a Dictionary from
  `Settings.iterator()`. The Particle and ParticleSystem constructors use it.

## Local deviations and workarounds

- `PointBody.update` adds `force * dt * invMass` and `velocity * dt` with the three-float `addLocal` instead of creating
  temporary vectors with `mult`. The result is the same; it only avoids per-particle allocations.
- Guards against Java crash paths:
  - `ParticleSystem.enqueue` checks that the system has bodies before it calls `iterator().next()`.
  - `MasterSlaveEmitter` calls `push_error` when the master or slave pool is missing (Java would throw an NPE).
  - `ImageShape` calls `push_error` when the image is missing, and returns a zero position for a 0-size image.
  - `BodiesParticle` skips `parseArgs` when settings is null.
- `ImageShape` reads the alpha channel with `Image.get_pixel(x, y).a8` (Java: `getAlphaRaster`).
- Random numbers (particles phase, 2026-10-27): Java draws every random number of these classes from the shared
  `Math.random()` (the shapes' emit positions and directions, the particles' fades and colours, the star twinkle,
  the wind's turbulence and `SystemLoader.getValueFromInterval`). The port draws them from a generator of their own,
  `BodiesParticleSystem.rand` (a `JRandom`), which `Main._init_deterministic` seeds like `WeatherParticle.rand`.
  Normal play is unchanged (both are unseeded); in a seeded run the villagers, stores and battles no longer depend on
  how many numbers the particles drew, so the GPU systems (which run no legacy simulation) leave every other draw as
  it was.
- `Vector3f.equals` compares with `!=` (Java `Float.compare` differs only for NaN and -0.0). `hashCode` emulates
  `floatToIntBits` with 32-bit wrap.

## Cross-unit expectations (settings unit)

- `Settings.setVector(i, x, y, z)` must accept an Array as `x`: an int[] from `Parser.getPos` or a float[] from
  `Parser.getFloatPos`, as in Java `setVector(int, int[])` / `setVector(int, float[])`. `getVector(i)` must return a
  `Vector3f`; it is shared by reference, as in Java.
- `Settings.getString(i)` must return `null` for unset keys. `buildSystem` and `getValueFromInterval` test for `null`.
- `Settings.getBoolean/getValue` must handle unset keys (in Java `get(i)` creates a default Setting).

## Bridge to the GPU systems (particles phase, docs/ARCHITECTURE.md section 9)

- `BodiesParticleSystem.gpu_path()`: the village and cutscene systems are drawn by `VillageParticles2D` (not
  `--legacy=particles` or `--legacy=villages`). Then a system (`gpu`) builds no bodies; `update` keeps its activation
  check and its 5 x LOGIC_INTERVAL guard and calls `gpu_run` (game time for the GPU system, the emitter's clock, the
  wind's turbulence) instead of stepping; `warmUp` and SystemLoader's master/slave warm-up call `gpu_warm`;
  `place_particles` returns `gpu_view()` (the state VillageParticles2D takes). Bridge members: `gpu`, `gpu_elapsed`,
  `gpu_warm_up`, `gpu_seed` (drawn from `rand` at construction), `definition` (the settings' name), `particle_kind`.
- `AbstractEmitter.advance(elapsedTime)`: `update` without bodies (the clock and `setFade`'s time step change as if every
  emission found a body).
- `WindCommand.drift(elapsedTime)`: `execute`'s turbulence as a per-second rate (the variance of 30 steps a second).
- `drawIt` with `--hide-particles` (`Main.hide_particles`): no background image and no particles, the same GL state and
  `modifySize` calls.

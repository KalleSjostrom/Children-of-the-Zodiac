# Converting particles

The village and cutscene particle systems run on the GPU (the particles
phase of `docs/MODERNIZATION_PLAN.md`, section 6.4; the conventions are in
`docs/ARCHITECTURE.md` section 9), as do the dungeon weather, the save
points (section 4 below) and the card and enemy effects (section 5). Each
system of `maps/ParticleSystems/particleSystems.info` is a generated scene,
`scenes/common/particles/systems/<system>.tscn`. The `.info` file stays the
source (decision 5 is open): edit it, then regenerate. Run everything from
bash in the project root, Godot with `< /dev/null`.

## 1. Regenerating after editing particleSystems.info

```
tools/import/particles_to_scenes.sh                  # every system
tools/import/particles_to_scenes.sh smokesystem      # some systems
```

The generator (`tools/import/particles_to_scenes.gd`) reads the file with the
legacy `SystemLoader`, so every value is the one the game reads, and writes
for each system:

* `<system>.tscn`: a `VillageParticles2D` (a `GPUParticles2D`). Its process
  material is the shader of the system's particle class
  (`fire_particle.gdshader`, `smoke_particle.gdshader`,
  `rainbow_particle.gdshader`, `snow_particle.gdshader`,
  `star_particle.gdshader`, with `particles.gdshaderinc` and
  `distance_fade.gdshaderinc`) with the system's settings as uniforms: the
  emitter shape and its position, the force, mass, size, colour, fade, the
  smoke's `max` and the snow's `height`. The node has the texture, the
  blending (`CanvasItemMaterial` ADD for `additive=true`), `amount`,
  `lifetime` and the warm-up (`preprocess`; a warm-up shape warms up to the
  steady state, the snow in coarse steps, `warm_up_fps`, as its law is
  linear). A `background=` image is a
  `Background` child (`Sprite2D`, drawn behind the particles). A
  master/slave emitter's slave system (Pass to Zazo's fire smoke) is a
  child that the master runs; it emits on its own at the rate the master's
  deaths feed the legacy slave, each particle where a master particle dies
  (its shader steps that particle's law). Not a Godot sub-emitter: which
  slot takes which request varies between runs, so seeded runs would not
  repeat.
* `<system>_points.png` for an image shape: the pixels it emits from (alpha
  >= 100 after the legacy scaling, `flipX` applied), one per texel; imported
  lossless, without mipmaps.

The rates: a legacy system emits one body per time step of its emitter while
its pool of `nrParticles` bodies has one, so both limit the rate; a GPU
system emits `amount / lifetime` particles a second. The generator steps
single legacy particles (the real classes and commands, 30 steps a second)
over a grid of their random inputs to find their mean and longest life, and
takes the lower limit. `lifetime` is the longest life (a particle dies by its
own law before its slot comes round again). The output lists, per system,
the shader, `amount`, the rate and the lives.

A system whose particle kind has no class (`rainparticle`, `sandparticle`:
the original's `ParticleFactory` makes null bodies for them, and nothing
builds those systems) gets no scene; the generator says so.

Generating twice writes the same files (the node unique_ids and the resource
ids are made deterministic). A new system needs nothing else: a `.vil`
`particlesystem` line or a cutscene `actor name="...System"` builds the legacy
system, and `LegacyParticles2D` instances the scene named after it.

## 2. Tuning a system's look in the editor

Open `scenes/common/particles/systems/<system>.tscn`. The root exports:

| Property | Effect |
|---|---|
| `intensity` | multiplies the alpha every particle is drawn with. The additive fires, rainbows and smokes start at 0.6 (the legacy glow was too bright), the additive snow and stars at 0.85, the others at 1 |
| `size_scale` | multiplies the drawn size of every particle |
| `amount` | the number of particle slots: the system emits `amount / lifetime` particles a second, so it scales how many are alive |

The editor previews the system at its emitter's position (`@tool`). Save
the scene; the game uses it everywhere the system appears.

Regenerating keeps these: `intensity` and `size_scale` as they are,
`amount` by its ratio to the generated value (`default_amount`), so a
changed `nrParticles` or time step still counts. `--reset-tuning` takes them
all from the data again.

What the data decides stays in `particleSystems.info` (texture, colour,
size, mass, force, shape, fade, `nrParticles`, `timeStep`, `warmUp`):
change it there and regenerate. The shaders' laws (how a particle moves,
fades and grows) are the legacy classes' as per-second rates; changing them
changes every system of the class.

## 3. Checking

* `tools/check.sh` (the shaders compile when the scenes load in a run).
* Parity: `tools/parity/parity.sh ab "--legacy=particles" "" 'particles_*'`
  shows the legacy and the GPU look side by side (they differ by design);
  `--hide-particles` hides the systems in both paths for comparing
  everything else (docs/ARCHITECTURE.md section 7).
* Frame rate: normal runs (not `--seed`), AutoPlay's `fps=`.

## 4. The dungeon weather and the save points

The rain, the snow and the save points' particles run on the GPU too (the
dungeon particles phase; `docs/ARCHITECTURE.md` section 10). They have no
data file: their laws are the legacy classes' (`src/weather`,
`SaveParticle`), in `weather_particle.gdshader` and `save_particle.gdshader`
as per-second rates at 60 steps a second, and their values are in three
scenes of `scenes/common/particles/`:

| Scene | What |
|---|---|
| `Rain.tscn`, `Snow.tscn` | `WeatherParticles3D`: 10,000 particles, the texture, the quad's size, the force per legacy step (`force_y`: rain -0.2, snow -0.003) and the height below which a particle starts again (`respawn_below`) |
| `SaveParticles3D.tscn` | 2,000 particles, the texture, the quad (0.15, its corner a whole quad from the particle: the legacy `size / 2`) |

Each exports `intensity` (the drawn alpha) and `size_scale` (the drawn
size); `amount` sets the number of particles (the save point's warm-up
stays the legacy 400 steps). They start at 1: the look of today's 60 FPS.
Open the scene, change, save; every floor uses it. A weather floor draws
two instances of its weather scene (the back and the front pass, the same
seed); a save point draws its scene as its `Particles` child.

Which floors have rain or snow is the floor's style (`DungeonStyle`, the
`.map` file's weather flags; `docs/CONVERTING_DUNGEONS.md`).

## 5. The card and enemy effects

The effects that the legacy code draws as particles run on the GPU (the
battle effects phase; `docs/ARCHITECTURE.md` section 11). They have no data
file and no scene per effect: the cards build their systems in code
(`getStaticAnimation`, `AnimSettings`), and every system's settings go to
`effect_particle.gdshader` as uniforms when it is first drawn
(`ParticleSystem.gpu_settings`). So a changed or new card effect needs
nothing else: if it uses the existing emitters, equations and settings, its
GPU system runs its laws. A new emitter type, vector equation or particle
law (a new `Particle` subclass, a new `AnimSettings` value that changes
motion or life) needs the same law in `effect_particle.gdshader` (its
emitter kind, equation kind or uniform) and in
`ParticleSystem.gpu_settings`. A system whose class overrides `draw` with
something that is not particles stays legacy (the sphere, image, slow and
enemy colour systems: list it in `ParticleSystem._init`'s test).

The legacy system still decides when the battle goes on, with a pool of at
most 64 particles (`ParticleSystem.reduce_for_waits`). Check a changed
effect's waits against the legacy ones with `--legacy=effect_waits` (the
whole pool) or `--legacy=battle_effects` (the legacy effect).

Checking:

* The console's `cast <card>[:<level>][:all]` plays cards on a party
  member's turn (README); `cast next` plays the rounds of the game argument
  `--casts=` (parity cases `effects_*`, scripts `effects_boss`,
  `effects_area`; an enemy's effects: `effects_enemy`). The enemies' Flame,
  SerphiaDeath and BlackDeath cannot be cast by the party (they read the
  attacking enemy).
* `tools/parity/parity.sh ab "--legacy=battle_effects" "" 'effects_*'` shows
  the legacy and the GPU effects side by side (they differ by design: other
  random numbers, smooth emission, waits within about 0.1 s).
* `--hide-particles --legacy=effect_waits` makes a battle identical to the
  legacy one with `--hide-particles` (everything but the effects' pixels).
* Frame rate: normal runs (not `--seed`), AutoPlay's `fps=`.

I've done all six deliverables and left them uncommitted in the working tree. The village and cutscene particles now run on the GPU, Home of the Gods and Dellna reach 60 FPS, and with the particles hidden every parity case is identical to the goldens.

One commit before starting: your pending `docs/MODERNIZATION_PLAN.md` edit (decision 6, rows P/P2) is committed as `9bbc5054`, so the tree was clean as the prompt asked. Nothing else is committed.

## What changed

**Deliverable 0 (before any conversion)**
- **Own generator.** Every random draw in `src/bodies`, `src/commands` and SystemLoader's intervals now uses `BodiesParticleSystem.rand`. It is seeded in `Main._init_deterministic` and noted as a port deviation in [particles-bodies.md](docs/port_notes/particles-bodies.md). [verify_villages.gd](tools/import/verify_villages.gd) seeds it per build too.
- **`--hide-particles`** (dev). Without this flag nothing could be compared "with the particles hidden" against goldens taken before the conversion, so I added it here rather than in deliverable 2. It hides the particles in every path and keeps the GL state they leave.
- **Dellna snow and wind restored.** I re-ran the converter for Dellna; the scene is byte-identical to its state before 7130b377.

**Deliverable 2**
- **Generator:** [particles_to_scenes.gd](tools/import/particles_to_scenes.gd) and `.sh`. It reads the data through SystemLoader and the legacy classes and writes 51 scenes plus 17 emission-point PNGs to `scenes/common/particles/systems/`. Running it twice writes identical files.
  - Rain and sand get no scene: their particle kinds have no class in the original, so the original can't build them either.
  - Rates come from stepping single legacy particles and taking the lower of the two legacy limits (time step and pool size); `amount = rate × lifetime`.
- **Node layout** of a generated system:
  ```
  <system>  VillageParticles2D (GPUParticles2D, local coords, fixed seed; ADD material if additive;
  │         process material = the class's shader with the .info values as uniforms)
  ├── Background (Sprite2D)          door systems' blackness.png, drawn behind the particles
  └── <slave> (VillageParticles2D)   Pass to Zazo's fire smoke
  ```
- **Shaders:** one per class (`fire_`, `rainbow_`, `smoke_`, `snow_`, `star_particle.gdshader`). Shapes, emit force and random numbers are shared in `particles.gdshaderinc`, the fire/rainbow fade in `distance_fade.gdshaderinc`. Each per-step law is a per-second rate at 30 steps/s, integrated with the frame's delta. `start()` also does the emission's own first step.
- **How a system takes its state.** I chose to have `LegacyParticles2D` instance the scene named by the legacy system's definition, rather than the converter writing it into the village scenes. Reasons:
  - The slot keeps the data the legacy loader and `--legacy=particles` need.
  - Cutscene actors' systems only exist at run time.
  - Each system's look lives in one scene used everywhere.

  On the GPU path, `BodiesParticleSystem` builds no bodies and runs no simulation:
  - `update` keeps its activation check and long-frame guard, and accumulates game time.
  - `AbstractEmitter.advance` keeps the emitter's clock and fade running.
  - `WindCommand.drift` keeps the shared wind's turbulence running, as a per-second rate.
  - `warmUp` becomes `preprocess`.
  - `place_particles` returns `gpu_view()`.

  The node then runs for exactly that game time (via `speed_scale`), follows the emitter position, time step and wind, and hides while inactive.
- **Legacy path:** `--legacy=particles` keeps the old simulation and quads.

## Facts from deliverable 1 that differ from the prompt
- **Stars never re-roll their colour.** `DoubleBackground.update` never steps the bottom layer (same in Java), and the stars are the only systems on it.
- **Master/slave runs at twice its rate.** The slave system steps the same emitter, so Pass to Zazo's fire emits 33/s instead of 16.7/s (Java too).
- **Cutscene actor particles are drawn in screen space.** The actor moves only the emitter; live particles stay where they were emitted and don't scroll with the village. Stars are also screen-space.
- **Legacy particles speed up below 30 FPS.** `originalFrameStep` takes all pending time as one step, so at Home of the Gods' 6 FPS the god particles rose about 5× too high.
- **The snow is limited by its time step, not its pool.** About 5,370 of 6,000 flakes are alive.
- **Not every system warms up.** Systems that start inactive (the gods, the exit door) and cutscene systems never warm up.
- **`modifySize`'s clamp never binds,** because max ≤ 0.7.

## Parity
- **Golden vs. after, both hidden: all 347 cases identical** (5,984 shots, logs too).
  - The compare also lists 15 shots of `tour_berca_2` as "only in A". That is a leftover directory from an older golden, not a case.
  - Error counts match except two WASAPI audio-device errors in one golden run.
- **GPU path recorded twice:** 791 of 791 shots identical.
  - First version: Godot's sub-emitter made Pass to Zazo's smoke differ between runs, because GPU slot assignment isn't deterministic.
  - Fix: the slave now emits on its own at the legacy-fed rate, and each smoke particle starts where a simulated fire particle dies. This deviates from "master/slave as a sub-emitter" in favour of repeatable seeded runs.
- **`--legacy=particles` vs. the unconverted recording:** 791 of 791 identical.
- **New cases, recorded twice:** 97 of 97 identical. The cases are `particles_pass_to_zazo_behind`, `particles_hotg_god_start` (talking to Gemini starts its system), `particles_home_of_celis`, and the two Menthu cutscenes. The 34 particle cases with the legacy particles shown were also recorded twice: 791 of 791 identical.

## Look, legacy vs. GPU
Contact sheets per system are in [tools/parity/out/p_sheets/](tools/parity/out/p_sheets/), legacy on the left. Shapes, colours, sizes, layers, positions and motion match. Apart from intensity, the differences are:
- **All systems:** softer edges from sub-pixel filtering; emission spread evenly instead of the legacy's per-step bursts.
- **Snow:** starts in its steady state (about 5,200 flakes) instead of 6,000 spread evenly.
- **Pensara North:** the turbulent wind wanders differently in each path.
- **Pass to Zazo's smoke:** a little lighter and longer.
- **Stars:** different random positions and colours.

Default intensity is 0.6 for fire, rainbow and smoke. I gave snow and stars 0.85, because at 0.6 the snow was nearly invisible.

## Frame rate and load time (normal runs, legacy → GPU)

| | Capped FPS | Uncapped FPS | Load |
|---|---|---|---|
| Home of the Gods, all 12 gods | 8 → 60 | 7.5 → 930 | 1.84 → 0.60 s |
| Dellna with snow | 18 → 60 | 18 → 1,270 | 1.67 → 0.46 s |
| Zazo | 60 → 60 | 452 → 980 | 1.05 → 0.28 s |
| Berca Menthu cutscene | 18 → 60 | 18 → 1,530 | 0.53 → 0.23 s |

Dellna's load was 0.89 s until I gave the snow coarse warm-up steps. Its law is linear, so the result is the same.

## Deliverable 5
The full list is in plan section 6.11. Main points:
- **Dungeon weather:**
  - **Laws:** fixed columns, respawn on falling out, no fade.
  - **Drawing:** facing-oriented axis-aligned quads; a back pass and a front pass with a 30.7° view cone; particles between 7 and 7.5 units ahead are drawn by neither pass.
  - **Front pass over battles:** it must sort after the 3D bridge's battle batches.
  - **Random numbers:** rain's initial heights draw 10,000 numbers from `J.random`, so give it its own generator first (as deliverable 0 did here).
- **Save points:** 2,000 particles per save point, with a 400-step warm-up in the constructor (800,000 updates per save point at floor load).
- **Card effects:**
  - **Waits:** destroyed/ready/dead are mostly timers or distance in disguise, and fit within the ±100 ms.
  - **Easy to move to GPU particles:** the plain emitters and the equation-driven cards.
  - **Hard:** Shatter, the lit spheres, DemolishEmitter, Flare's particle count, and the image/clock systems.
  - **Per-frame interim:** doubles a CPU cost that is already about 100 ms per step for Wind level 3, so I don't recommend it.
- **Flame pre-run:** neither path removes the 200 × 3,000-particle loop by itself; a GPU version replaces it with `preprocess`. It can be fixed on its own first, by caching the state or dropping the loop Java duplicates.

## Surprises and things the plan got wrong
- Plan 6.4's mapping (preset curves, sub-emitter, wind as turbulence) became one shader per class running the laws directly. I updated 6.4, 6.9, 6.10, 6.11, 13 and 14.
- `Settings.get_` creates an empty entry when a missing key is read (as Java's `get` does). An early version of the generator broke the particles it built this way.
- Not mine, but you should know: `verify_villages --all` passes 230 of 234 builds. The four failures are "Zazo at Night - 0"'s loot, whose `.vil` line changed in 7d6f42bf without the scene being reconverted.

Docs are updated: [ARCHITECTURE.md](docs/ARCHITECTURE.md) section 9 "Particles" plus the flags, [HANDOFF.md](docs/HANDOFF.md), the plan, and the new [CONVERTING_PARTICLES.md](docs/CONVERTING_PARTICLES.md). `tools/check.sh` reports 0 failed.
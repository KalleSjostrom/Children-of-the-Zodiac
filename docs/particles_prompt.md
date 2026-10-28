Implement the particles phase of docs/MODERNIZATION_PLAN.md (section 14, row P) in this
Godot 4.7 project: the village and cutscene particle systems (src/bodies, src/commands; the
systems of maps/ParticleSystems/particleSystems.info) move from the GDScript simulation to
GPU particles. Convert no other particles: the dungeon weather, the save points and the
battle and card effects stay as they are.

Why now: the GDScript simulation holds Home of the Gods at 6 FPS with its 12 god systems
active (12 × 3,000 particles) and Dellna at 12-18 FPS (6,000 snow particles), in the legacy
and the scene path alike (plan 6.8): the drawing is not the bottleneck, the simulation is.
Dellna's snow is switched off for that reason (commit 7130b377). Phase 3 does not depend on
this work, nor this on phase 3.

Read first:
- docs/MODERNIZATION_PLAN.md: sections 2.4, 2.5, 3, 6.4, 6.8 and 6.9 (the particle
  findings of phase 1), 12, 13 (decision 6 is decided for particles) and 14;
- docs/ARCHITECTURE.md, all of it: the bridge (section 4), the rules for new code, the
  flags, determinism and the parity workflow (section 7), and section 9 (villages as
  scenes: the layer nodes, LegacyParticles2D, how the village and the cutscene hand the
  scene what the legacy drawing drew);
- docs/HANDOFF.md: how to run Godot, AutoPlay and tools/check.sh;
- docs/PORTING.md: the rules for legacy files you touch;
- docs/port_notes/particles-bodies.md, docs/port_notes/villages.md and
  docs/port_notes/story.md.

State:
- Phases 1 and 2 are committed (36d0b35e, 150c6b6d)
  Every village and cutscene draws its particles through LegacyParticles2D
  (scenes/common/particles/): the legacy simulation runs (BodiesParticleSystem.update)
  and the node draws the quads the legacy draw would draw (place_particles).
- "Dellna - 0" hides its snow ("00 snowsystem": visible = false, start_active = false),
  and the same commit changed its wind_force from (10, 0, 0), the .vil's
  "wind 10;0;0 .1", to (0, 0, 0). The wind only moves smoke systems, so Dellna's four
  smokes rise straight today. Restore the snow and the wind.
- The later Java revision (../Children-of-the-Zodiac-master) commented out
  ParticleSystem.drawIt and Body.draw: that build drew no village or cutscene particles
  (it still ran the simulation). The port follows the earlier revision in
  _java_reference, which draws them.
- Tools you can reuse: parity.sh --jobs=<n> (8 on this machine), case patterns,
  --ignore-world, --tolerance; the particles_* cases (Home of the Gods with every god
  system active, Dellna, Pensara North's wind -10 and turbulence 1, Pass to Zazo's fire
  sorted with the sprites), the tours and story cases; AutoPlay pos, console; --status,
  --start, --start-time; tools/parity/contact_sheet.gd.
- The goldens in tools/parity/out are stale.
- --seed runs read no game pad and advance a game clock by one fixed step per frame, so
  blocking work does not show in their timings. Measure frame rates and load times in
  normal runs. Do not type while a recording runs: a new run's window takes the focus.
- If the Godot editor is open on the project, it imports new files and generates .uid
  files. Close it while recording.
- Start from a clean, committed tree. This prompt file doesn't count.

Decisions (plan section 13):
- Decision 6, time base, for particles: today's speeds, updated every frame with the
  frame's delta. The legacy systems step 30 times a second (Values.originalFrameStep,
  commit 6dad0c75), and their laws mix per-second motion with per-step fades. The GPU
  version turns every per-step law into a per-second rate at 30 steps/s (a fade of f per
  step: 30·f per second; a probability p per step: 1 − (1 − p)^(30·dt) per frame; an
  amount that grows per step: integrated over dt), so nothing moves or fades faster or
  slower than today, but it is smooth at any frame rate (fixed_fps 0, no 30 Hz steps).
  Only --legacy=particles keeps the 30 steps.
- The look does not have to match the legacy pixels. The legacy additive systems are too
  bright ("too much bloom"). Keep each system's motion, colours, shapes, sizes, layer and
  timing, but give the additive systems a softer default intensity. The generated scenes
  export intensity, amount and size per system, so I can tune them in the editor. Nothing
  else is restyled.   <-- EDIT IF NEEDED
- Step B for the logic: the legacy objects stay in charge of what decides things: which
  systems a village or cutscene builds, a system's activation by Database status, the
  cutscene's emitter fade (KIND_FADE_PARTICLE_SYSTEM), the village's wind line, and the
  villager layer's sort key (BodiesParticleSystem.getY). The nodes take that state from
  them every frame. No signals replacing polled logic.
- Decision 5, text formats: not made. particleSystems.info and particles.var stay the
  source; the generated scenes are rebuilt from them.
- Make no other open decision.

Deliverables, in this order. Do (0) and (1) before converting anything, so that the
goldens are recorded on unconverted code.

0. The particles' own random numbers
   - The legacy particles draw from J's shared generator, as villagers, stores and battles
     do. Removing the simulation would shift every later draw in a seeded run, and the
     goldens could no longer show that nothing else changed. Give every random draw of the
     village and cutscene particles a generator of its own (src/bodies, src/commands,
     SystemLoader's intervals, and whatever else a particle system draws while it is
     built, warmed up, stepped or drawn: find them all), seeded in
     Main._init_deterministic like WeatherParticle.rand, SaveParticle.rand and
     BattleParticle.rand.
   - This is a port deviation (Java shares Math.random): note it in
     docs/port_notes/particles-bodies.md. Normal play does not change; seeded runs do,
     which is why the goldens come after it.
   - tools/check.sh reports 0 failed. Record goldens of all cases
     (tools/parity/parity.sh record golden --jobs=8, and bridge_test, which is "extra").

1. Facts and coverage
   - Facts to verify before relying on them:
     * The motion law. A particle's default force (+9.82 × mass) cancels GravityCommand
       (−9.82 × mass), and the command queue runs last in, first out: check whether a
       particle then moves at the constant velocity its emit force gives it in its first
       step, plus the wind's acceleration in smoke systems only
       (BodiesParticleSystem.enqueue).
     * The life laws of the five particle classes: BodiesParticle (fade per step),
       FireParticle and RainbowParticle (the fade grows with the distance from the emit
       point), SmokeParticle (grows to max, then turns; modifySize clamps life while it
       draws), BodiesSnowParticle (alive while above -height, no fade), StarParticle
       (never moves or dies, re-rolls its colour with probability 0.01 per step, drawn
       without the system's position).
     * Emission: the emitter emits one pooled body per timeStep while the pool has one, so
       timeStep and nrParticles both limit the rate; GPU particles emit amount / lifetime
       per second. Warm-up: warmUp steps at build time, or warmUpShape (snow and stars
       place every particle on a box at build time).
     * The shapes: line (with LineShape.modifyDirection's spread), box, circle, and image
       (17 systems: pixels with alpha >= 100, scaled, flipX).
     * MasterSlaveEmitter: Pass to Zazo's firesystem re-emits a firesmokesystem particle
       from each fire particle it re-emits, at half its velocity.
     * godDoorEntrySystem and godDoorExitSystem draw blackness.png under their particles.
     * Where each system draws: the layer nodes (Ground, Actors sorted with the sprites,
       Effects); a cutscene actor's system that moves with the actor (do its live
       particles move with it?); systems that start inactive and start on a status while
       the village is shown.
     * What reads a system's state besides its drawing (getY for the sort, the position
       set while drawing, Village.getParticleSystem for the cutscene fade): that stays.
   - Coverage: the particles_* cases, the tours of the ten variants with systems, and
     story_elder_of_dellna. Add cases for what they do not show: "Talking to Menthu" and
     the Berca Desert--South West node1 cutscene (the Menthu and Ophiuchus systems), Home
     of Celis's smoke, a god system starting while Home of the Gods is shown (if the game
     does that), and a system on the Actors layer with a sprite passing in front of and
     behind it. Plan the routes with pos in headless probe runs.
   - Record goldens of the new cases, then record them a second time and show the
     self-diff is 0. Never edit game code while a recording runs: each case starts Godot
     fresh and would pick up the edit.

2. The GPU systems (step B)
   - A generator under tools/import/ builds one scene per system from
     particleSystems.info (through SystemLoader, so the values are the ones the game
     reads), in scenes/common/particles/: a GPUParticles2D whose particle shader
     (shader_type particles) runs the legacy laws of its particle class, with the
     system's texture, blending (additive: an ADD material), amount, emission shape
     (image: emission points baked from the alpha), master/slave as a sub-emitter, and the
     background image. Running it twice changes no file.
   - The village scenes and the cutscene actors use the generated systems. Choose how
     (LegacyParticles2D instancing the system named by system_name, or the converter
     writing the generated scene in its place) and say why.
   - On the scene path the legacy simulation does not run, and no legacy body is built or
     warmed up: the load time of Home of the Gods and Dellna must drop as well.
   - --legacy=particles (Main.is_legacy("particles")) keeps the legacy simulation and
     LegacyParticles2D's drawing.
   - Seeded runs must stay repeatable: a fixed seed per system, and particle time that
     does not come from the wall clock (the game clock, or Godot's --fixed-fps in the
     parity runs: choose and document it). A second recording of the new path is
     identical, so later phases keep their goldens.
   - A dev flag that hides the village and cutscene particles in both paths, for the
     comparison below.

3. Parity, look and speed
   - golden vs. after, both with the particles hidden: every case identical, logs
     identical. Explain any difference with its diff image.
   - The new path recorded twice: identical.
   - Legacy vs. GPU (ab "--legacy=particles" "") on the cases that show particles: these
     differ by design. Contact sheets of both, per system, for me to judge the look; say
     what differs besides the intensity.
   - Frame rate and load time in normal runs, legacy vs. GPU: Home of the Gods with every
     god system active, Dellna with its snow, Zazo, a Menthu cutscene.

4. Docs
   - ARCHITECTURE.md: the particles in section 9 (the generated systems, the shaders, the
     generator, the flags, how a system takes its state from the legacy object).
   - HANDOFF.md: the new state.
   - docs/CONVERTING_PARTICLES.md: how to regenerate the systems after editing
     particleSystems.info, and how to tune a system's look in the editor.
   - Plan sections 6.4, 6.9, 13 and 14. Where your findings contradict the plan, update it
     and tell me.

5. Prepare the next particles (do not do them)
   - The dungeon weather (src/weather, DungeonWeather) and the save points (SaveSystem):
     what GPUParticles3D versions need, what draws them today (the back pass, the front
     pass over battles and riddles), and the random numbers they share. Decision 6 for
     them is today's look at 60 FPS, updated with the frame's delta: they step once per
     frame (their per-step laws are per-second rates at 60 steps/s) and never had the
     originalFrameStep correction.
   - The battle and card effects (src/particleSystem). The battle may wait up to about
     100 ms more or less than today for an effect (isDestroyed, isReady, isDead): a timer
     or a lifetime estimate may replace the particle counts. With that, assess:
     * whether the card effects can move to GPUParticles3D before the rest of phase 4.4
       (the battle's 3D chunk is drawn into the scene's World3D with the camera at the
       origin, plan 7.5), and which effects cannot (Shatter, the sphere systems,
       DemolishEmitter, the equations);
     * the cheaper interim: stepping the legacy effects every frame with their per-step
       laws turned into per-second rates, and its CPU cost in GDScript (twice the steps
       at 60 FPS);
     * the Flame pre-run that blocks for 11.4 s (Flame.getStaticAnimation →
       FlameParticleSystem.create): whether it goes away with either, or can be fixed on
       its own first.

Constraints:
- Convert only the village and cutscene particle systems.
- No step C: the legacy objects keep deciding which systems exist and when they run.
- Do not change legacy game logic or content to make parity pass; content quirks stay
  (the rain and sand kinds without a class, the fadeparticlesystem no sequence runs). A
  port bug that the new coverage finds may be fixed before the goldens are recorded, as
  its own listed change. A port bug is a place where the GDScript does what the Java does
  not.
- Normal play changes only in the particles' look, the frame rate and the load time.
  Dev-only flags are fine if documented.
- Legacy files follow PORTING.md (Java names, no redesign; bridge members snake_case).
  New files follow ARCHITECTURE.md.
- tools/check.sh must report 0 failed, also for the scripts under scenes/ and tools/.
  Run Godot from bash with < /dev/null. Screenshots need a window (not --headless).
- Do not commit. Leave the changes in the working tree for me to review.

When done, report:
- what changed (files and why), the node layout of a generated system, the shaders, and
  how a system takes its state from the legacy object;
- the facts of deliverable 1 as you found them, where they differ from this prompt;
- the parity results, explaining every difference: golden vs. after with the particles
  hidden; the new path's self-diff;
- per system, what the GPU version does differently from the legacy (besides the
  intensity), with the contact sheets you checked;
- frame rate and load time, legacy vs. GPU, in normal runs;
- the list from deliverable 5;
- anything that surprised you or that the plan got wrong.
